import { CAPTURE, MATCH, WORLD, WORLD_HALF } from '../config'
import { capturableBy, inZone, type CaptureZone } from '../game/capture'
import type { Tank, WorldRefs } from '../tank/tank'
import { scatterNear } from './positions'
import type { BotMode, Pt } from './types'

const UPDATE_INTERVAL = 0.4 // s
/** A last sighting older than this is no lead any more: the hunt sweeps the map instead. */
const LEAD_FRESH = 45 // s

/** What the team needs to know about one of its bots, and the orders it can give it. */
export interface Member {
	readonly tank: Tank
	readonly mode: BotMode
	/** Go and stop the capture of `zone`. */
	defend(w: WorldRefs, zone: CaptureZone): void
	/** Go and take a base circle (`force`: whatever the odds); false when there is none to take. */
	capture(w: WorldRefs, force: boolean): boolean
	readonly capturing: boolean
	readonly defending: boolean
}

/**
 * Bots sent back to break up a capture, by battle mode (at least one more than the capturers in the circle). An
 * assault's defence has one base and loses with it; a neutral circle is half the map's worth.
 */
const DEFENDERS = { standard: 2, encounter: 3, assault: 4 }
/** Capture points past which bots already in a fight are pulled back to the circle too. */
const DEFEND_URGENT = 50
/** Share of idle bots that go and take a base instead of looking for the enemy, by battle mode. */
const CAPTURE_CHANCE = { standard: 0.3, encounter: 0.5, assault: 0.7 }
const CAPTURE_CHANCE_LATE = { standard: 0.55, encounter: 0.8, assault: 1 }
/** s before the end: a side that can only win by a capture (the assault's attack, both sides of an encounter) rushes the base. */
const HURRY_TIME = 110

/** The enemy is "thinned out" (scouts raid, everyone closes in) at this share of its starting strength or less. */
const FEW_ENEMIES = 0.6
/** s into the battle after which everyone closes in anyway, so the round does not drag on. */
const LATE_TIME = 120
const ASSAULT_LATE_TIME = 80

/** Chance of splitting the strike group in two (when there are two lanes and enough tanks). */
const TWO_GROUPS_CHANCE = 0.55

const pick = <T>(a: readonly T[]): T => a[Math.floor(Math.random() * a.length)]
const zoneDist = (z: CaptureZone, t: Tank) => Math.hypot(z.x - t.pos.x, z.z - t.pos.z)

/** A random open spot well inside the circle. */
export function spotInZone(w: WorldRefs, z: CaptureZone): Pt {
	for (let i = 0; i < 20; i++) {
		const a = Math.random() * Math.PI * 2
		const d = Math.sqrt(Math.random()) * CAPTURE.radius * 0.6
		const p = { x: z.x + Math.cos(a) * d, z: z.z + Math.sin(a) * d }
		if (inZone(z, p.x, p.z) && w.terrain.passable(p.x, p.z) && w.terrain.waterDepth(p.x, p.z) <= 0) return p
	}
	return { x: z.x, z: z.z }
}

/** Lane indices ordered across the axis (one flank, the middle, the other flank). */
function lanesAcross(w: WorldRefs): number[] {
	const { px, pz } = w.terrain.axis
	return w.terrain.lanes
		.map((l, i) => {
			const m = l[Math.floor(l.length / 2)]
			return { i, side: m.x * px + m.z * pz }
		})
		.sort((a, b) => a.side - b.side)
		.map((o) => o.i)
}

/**
 * One side's shared picture: the strike groups (mediums + heavies) and the lanes they take, how far up its lane each
 * group's assault (mediums) and the whole group have got, where each enemy was last seen, and the last enemy standing.
 * The plan varies by round: one group on a flank or in the middle, or two groups on two lanes (left and right, or a
 * flank and the middle).
 */
export class TeamTactics {
	/** Lane (index into `terrain.lanes`) of each strike group. */
	readonly groupLanes: number[]
	/** Group the tank destroyers back up (and its lane). */
	readonly ambushGroup: number
	readonly ambushLane: number
	/** The enemy is down to FEW_ENEMIES of its strength. */
	fewEnemies = false
	/** Thinned out, or LATE_TIME into the battle: no more waiting about, close in. */
	late = false
	/** The only enemy left alive (everyone hunts it), else null. */
	lastEnemy: Tank | null = null
	private readonly groupOf = new Map<Tank, number>()
	/** Per group: progress of each of its tanks still in the push (not falling back). */
	private fronts: { tank: Tank; progress: number }[][] = []
	private readonly seen = new Map<Tank, { x: number; z: number; t: number }>()
	private timer = 0
	private start: number | null = null
	private enemyStart = 0
	/** Bots sent to break up a capture, until it is reset. */
	readonly defenders = new Set<Tank>()
	/** The enemy the player called everyone onto, and until when. */
	private focus: { tank: Tank; until: number } | null = null

	constructor(
		readonly team: 0 | 1,
		w: WorldRefs,
		bots: readonly Tank[],
	) {
		const lanes = lanesAcross(w)
		const strike = bots.filter((t) => t.def.role === 'medium' || t.def.role === 'heavy')
		if (lanes.length >= 2 && strike.length >= 3 && Math.random() < TWO_GROUPS_CHANCE) {
			// Two different lanes: both flanks, or a flank and the middle
			const a = pick(lanes)
			this.groupLanes = [a, pick(lanes.filter((l) => l !== a))]
		} else this.groupLanes = [pick(lanes)]
		// Deal the mediums, then the heavies, so each group gets a share of both
		const n = this.groupLanes.length
		let k = Math.floor(Math.random() * n)
		for (const role of ['medium', 'heavy'] as const) {
			for (const t of strike) if (t.def.role === role) this.groupOf.set(t, k++ % n)
		}
		this.ambushGroup = Math.floor(Math.random() * n)
		this.ambushLane = this.groupLanes[this.ambushGroup]
	}

	/**
	 * Our base (or the neutral one) is being taken: the nearest bots that are not busy fighting go back to it
	 * (artillery never does) — more of them in an assault's defence and against more capturers, and those in a fight
	 * too once the capture is far gone (or it is the assault's only base). They are released once the capture is down
	 * to zero.
	 */
	private defendBases(w: WorldRefs, members: readonly Member[]) {
		const mode = w.terrain.mode
		const defence = mode === 'assault' && w.terrain.defender === this.team
		for (const z of w.zones) {
			const threatened = z.capturing !== null && z.capturing !== this.team && z.points > 0
			if (!threatened) continue
			const capturers = w.tanks.filter((t) => t.alive && t.team === z.capturing && inZone(z, t.pos.x, t.pos.z))
			const want = Math.max(DEFENDERS[mode], capturers.length + 1)
			const urgent = defence || z.points > DEFEND_URGENT
			const sent = members.filter((m) => this.defenders.has(m.tank) && m.tank.alive).length
			const free = members
				.filter((m) => m.tank.alive && !this.defenders.has(m.tank) && m.tank.def.role !== 'spg')
				.filter((m) => m.mode !== 'retreat' && (urgent || m.mode !== 'engage'))
				.sort((a, b) => zoneDist(z, a.tank) - zoneDist(z, b.tank))
			for (const m of free.slice(0, Math.max(0, want - sent))) {
				this.defenders.add(m.tank)
				m.defend(w, z)
			}
		}
		if (w.zones.every((z) => z.points <= 0 || z.capturing === this.team)) this.defenders.clear()
	}

	/** The player's "attack that one": everyone who can see it prefers it for a while. */
	focusOn(t: Tank, until: number) {
		this.focus = { tank: t, until }
	}

	/** The called-out target, while the call holds and it lives. */
	focused(time: number): Tank | null {
		const f = this.focus
		return f && f.tank.alive && time < f.until ? f.tank : null
	}

	/** The clock is running out: everyone not fighting or defending makes for the circle. */
	private rush(w: WorldRefs, members: readonly Member[]) {
		for (const m of members) {
			if (!m.tank.alive || m.capturing || m.defending) continue
			if (m.mode === 'engage' || m.mode === 'retreat') continue
			m.capture(w, true)
		}
	}

	/** The nearest base `me` could take, or null (artillery never captures). */
	zoneToTake(w: WorldRefs, me: Tank): CaptureZone | null {
		if (me.def.gun.howitzer) return null
		let best: CaptureZone | null = null
		for (const z of w.zones) {
			if (!capturableBy(z, this.team)) continue
			if (!best || zoneDist(z, me) < zoneDist(best, me)) best = z
		}
		return best
	}

	/** Chance that an idle bot goes for the base rather than for the enemy. */
	captureChance(w: WorldRefs): number {
		const mode = w.terrain.mode
		if (mode === 'assault' && w.terrain.defender === this.team) return 0
		return Math.max(CAPTURE_CHANCE[mode], this.late ? CAPTURE_CHANCE_LATE[mode] : 0)
	}

	/** Lane for `t`: its group's (the first group's for anyone outside the strike groups). */
	laneOf(t: Tank): number {
		return this.groupLanes[this.groupOf.get(t) ?? 0]
	}

	/** Metres from our base toward the enemy base along the layout axis. */
	progress(w: WorldRefs, x: number, z: number): number {
		const own = w.terrain.bases[this.team]
		const { dx, dz } = w.terrain.axis
		const f = this.team === 0 ? 1 : -1
		return ((x - own.x) * dx + (z - own.z) * dz) * f
	}

	update(w: WorldRefs, members: readonly Member[], time: number, dt: number) {
		for (const o of w.tanks) {
			if (o.team !== this.team && o.alive && o.spottedBy[this.team])
				this.seen.set(o, { x: o.pos.x, z: o.pos.z, t: time })
		}
		this.timer -= dt
		if (this.timer > 0) return
		this.timer = UPDATE_INTERVAL
		const enemies = w.tanks.filter((o) => o.team !== this.team && o.alive)
		this.lastEnemy = enemies.length === 1 ? enemies[0] : null
		if (this.start === null) {
			this.start = time
			this.enemyStart = enemies.length
		}
		this.fewEnemies = enemies.length <= Math.ceil(this.enemyStart * FEW_ENEMIES)
		// An assault's defence does not tire of waiting: only losses send it forward. The attack presses on sooner.
		const mode = w.terrain.mode
		const defence = mode === 'assault' && w.terrain.defender === this.team
		const lateTime = mode === 'assault' ? ASSAULT_LATE_TIME : LATE_TIME
		this.late = this.fewEnemies || (!defence && time - this.start > lateTime)
		this.defendBases(w, members)
		if (mode !== 'standard' && !defence && time - this.start > MATCH.roundTime - HURRY_TIME) this.rush(w, members)
		this.fronts = this.groupLanes.map(() => [])
		for (const m of members) {
			const g = this.groupOf.get(m.tank)
			if (g === undefined || !m.tank.alive || m.mode === 'retreat') continue
			this.fronts[g].push({ tank: m.tank, progress: this.progress(w, m.tank.pos.x, m.tank.pos.z) })
		}
	}

	/** Mean progress of the mediums of `me`'s group still pushing; null with none left. */
	assaultFront(me: Tank): number | null {
		const g = this.groupOf.get(me)
		const a = g === undefined ? [] : (this.fronts[g] ?? []).filter((f) => f.tank.def.role === 'medium')
		return a.length ? a.reduce((s, f) => s + f.progress, 0) / a.length : null
	}

	/** Mean progress of the rest of `me`'s group (null when `me` is on its own). */
	groupFrontWithout(me: Tank): number | null {
		const g = this.groupOf.get(me)
		const others = g === undefined ? [] : (this.fronts[g] ?? []).filter((f) => f.tank !== me)
		return others.length ? others.reduce((s, f) => s + f.progress, 0) / others.length : null
	}

	/** Mean position of group `g`'s tanks still in the push; null when none are left. */
	groupCentre(g: number): Pt | null {
		const f = this.fronts[g] ?? []
		if (!f.length) return null
		return {
			x: f.reduce((s, e) => s + e.tank.pos.x, 0) / f.length,
			z: f.reduce((s, e) => s + e.tank.pos.z, 0) / f.length,
		}
	}

	/** Centre of the strike group furthest up the map (where the scouts work ahead of). */
	leadCentre(): Pt | null {
		let best = -1
		let bp = -Infinity
		this.fronts.forEach((f, g) => {
			const p = f.length ? f.reduce((s, e) => s + e.progress, 0) / f.length : -Infinity
			if (p > bp) {
				bp = p
				best = g
			}
		})
		return best < 0 ? null : this.groupCentre(best)
	}

	/** An enemy self-propelled gun still alive (the one seen most recently first), if any. */
	enemyArtillery(w: WorldRefs): Tank | null {
		const spgs = w.tanks.filter((o) => o.team !== this.team && o.alive && o.def.role === 'spg')
		spgs.sort((a, b) => (this.seen.get(b)?.t ?? -1) - (this.seen.get(a)?.t ?? -1))
		return spgs[0] ?? null
	}

	/** Where the team last saw `o` and when; null if never. */
	lastSighting(o: Tank) {
		return this.seen.get(o) ?? null
	}

	/** The enemy seen most recently (alive), if any sighting is still fresh. */
	freshestSighting(w: WorldRefs, time: number): Tank | null {
		let best: Tank | null = null
		let bt = time - LEAD_FRESH
		for (const o of w.tanks) {
			const s = o.alive && o.team !== this.team ? this.seen.get(o) : undefined
			if (s && s.t > bt) {
				bt = s.t
				best = o
			}
		}
		return best
	}

	/**
	 * Next place for a hunter to look for `prey`: around where it was last seen (each bot on its own bearing), or,
	 * with no fresh lead, anywhere on the enemy's half of the map.
	 */
	searchPoint(w: WorldRefs, prey: Tank | null, slot: number, slots: number, time: number): Pt {
		// Search inside the playable ground, never up in the mountains round the edge
		const half = WORLD_HALF - WORLD.mountainBand - 10
		const s = prey && this.lastSighting(prey)
		if (s && time - s.t < LEAD_FRESH) {
			const a = (slot / Math.max(1, slots)) * Math.PI * 2 + Math.random() * 0.8
			const r = 40 + Math.random() * 90
			return scatterNear(w.terrain, s.x + Math.cos(a) * r, s.z + Math.sin(a) * r, 30, half)
		}
		const enemy = w.terrain.bases[1 - this.team]
		const { px, pz } = w.terrain.axis
		const side = (slot / Math.max(1, slots - 1) - 0.5) * 2 * half * 0.8 + (Math.random() - 0.5) * 120
		const k = Math.random() * 0.7 // from the enemy base back toward the middle
		const x = enemy.x * (1 - k) + px * side
		const z = enemy.z * (1 - k) + pz * side
		return scatterNear(w.terrain, x, z, 60, half)
	}
}
