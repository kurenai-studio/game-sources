import * as THREE from 'three'
import { COMBAT, CREW, CREW_ROLES, GRAVITY } from '../config'
import type { ShotParams, Tank, WorldRefs } from '../tank/tank'
import { testShell, type HitResult, type ShellSpec } from './armor'
import { HOWITZER } from './ballistics'

interface Shell {
	x: number
	y: number
	z: number
	vx: number
	vy: number
	vz: number
	owner: Tank
	spec: ShellSpec
	he: boolean
	splash: number
	howitzer: boolean
	gravity: number
	life: number
	/** Distance flown, for the tracer length. */
	dist: number
	/** An aircraft bomb: drawn as a bomb by the plane view, not as a tracer. */
	bomb: boolean
}

export interface Impact {
	x: number
	y: number
	z: number
	he: boolean
	splash: number
}

type ContactKind = 'tank' | 'wreck' | 'building' | 'ground'

/** The earliest thing a shell meets on this frame's step. */
interface Contact {
	t: number
	kind: ContactKind
	tank: Tank | null
	hit: HitResult | null
}

const GROUND_STEP = 2.5 // m between ground samples along a step
/** m: a penetration from this far counts toward the sniper medal. */
export const LONG_SHOT = 250
const OUT_OF_WORLD = 2000 // m

/** Shells in flight: segment-swept each frame against tanks (alive or wrecked), buildings, rocks and the ground. */
export class Shells {
	readonly lines: THREE.LineSegments
	readonly list: Shell[] = []
	private readonly pos = new Float32Array(COMBAT.maxShells * 6)
	/** Every shot, right after it is added (muzzle flash, sound, shake). */
	onFire?: (owner: Tank, shot: ShotParams) => void
	onTankHit?: (target: Tank, by: Tank, hit: HitResult, shell: ShellSpec) => void
	onImpact?: (imp: Impact, by: Tank) => void
	onSplashDamage?: (target: Tank, by: Tank, dmg: number) => void
	/** Debug counters for balancing. */
	stats = { fired: 0, tank: 0, wreck: 0, building: 0, ground: 0, pen: 0, nonpen: 0, ricochet: 0, expired: 0 }

	constructor() {
		const geo = new THREE.BufferGeometry()
		geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3))
		geo.setDrawRange(0, 0)
		const mat = new THREE.LineBasicMaterial({ color: '#ffd080', transparent: true, opacity: 0.9 })
		this.lines = new THREE.LineSegments(geo, mat)
		this.lines.frustumCulled = false
	}

	fire(owner: Tank, p: ShotParams) {
		if (this.list.length >= COMBAT.maxShells) this.list.shift()
		this.stats.fired++
		this.list.push({
			x: p.origin.x,
			y: p.origin.y,
			z: p.origin.z,
			vx: p.dir.x * p.speed,
			vy: p.dir.y * p.speed,
			vz: p.dir.z * p.speed,
			owner,
			spec: { pen: p.pen, dmg: p.dmg, caliber: p.caliber, ammo: p.ammo },
			he: p.ammo.he,
			splash: p.splash,
			howitzer: p.howitzer,
			gravity: p.howitzer ? HOWITZER.gravity : GRAVITY,
			life: p.howitzer ? COMBAT.howitzerShellLife : COMBAT.shellLife,
			dist: 0,
			bomb: false,
		})
		this.onFire?.(owner, p)
	}

	/** A bomb released from the player's plane: it falls from `at` with the plane's velocity (no muzzle effects). */
	drop(owner: Tank, at: THREE.Vector3, vel: THREE.Vector3, spec: ShellSpec, splash: number, life: number) {
		if (this.list.length >= COMBAT.maxShells) this.list.shift()
		this.stats.fired++
		this.list.push({
			x: at.x,
			y: at.y,
			z: at.z,
			vx: vel.x,
			vy: vel.y,
			vz: vel.z,
			owner,
			spec,
			he: spec.ammo.he,
			splash,
			howitzer: false,
			gravity: GRAVITY,
			life,
			dist: 0,
			bomb: true,
		})
	}

	update(dt: number, w: WorldRefs) {
		for (let i = this.list.length - 1; i >= 0; i--) {
			const s = this.list[i]
			s.vy -= s.gravity * dt
			const ax = s.x
			const ay = s.y
			const az = s.z
			const bx = s.x + s.vx * dt
			const by = s.y + s.vy * dt
			const bz = s.z + s.vz * dt
			s.life -= dt
			s.dist += Math.hypot(bx - ax, by - ay, bz - az)
			const c = this.sweep(s, w, ax, ay, az, bx, by, bz)
			if (!c) {
				s.x = bx
				s.y = by
				s.z = bz
				if (s.life <= 0 || Math.abs(s.x) > OUT_OF_WORLD) {
					this.list.splice(i, 1)
					this.stats.expired++
				}
				continue
			}
			this.count(c)
			if (c.kind === 'tank' && c.tank && c.hit) this.applyHit(s, c.tank, c.hit)
			const imp: Impact = {
				x: ax + (bx - ax) * c.t,
				y: ay + (by - ay) * c.t,
				z: az + (bz - az) * c.t,
				he: s.he,
				splash: s.splash,
			}
			this.onImpact?.(imp, s.owner)
			if (s.he && s.splash > 0) this.splash(imp, s, w, c.tank)
			this.list.splice(i, 1)
		}
		this.writeTracers()
	}

	/** The earliest contact on the step a → b: tanks and wrecks, buildings, the ground, then rocks. */
	private sweep(
		s: Shell,
		w: WorldRefs,
		ax: number,
		ay: number,
		az: number,
		bx: number,
		by: number,
		bz: number,
	): Contact | null {
		let best: Contact | null = null
		for (const t of w.tanks) {
			if (t === s.owner || !t.nearSegment(ax, az, bx, bz)) continue
			const h = testShell(t, ax, ay, az, bx, by, bz, s.spec)
			if (h && h.t < (best?.t ?? 2)) best = { t: h.t, kind: t.alive ? 'tank' : 'wreck', tank: t, hit: h }
		}
		const tb = w.buildings.raySegment(ax, ay, az, bx, by, bz)
		if (tb >= 0 && tb < (best?.t ?? 2)) best = { ...(best ?? { tank: null, hit: null }), t: tb, kind: 'building' }
		const tg = this.groundContact(w, ax, ay, az, bx, by, bz)
		if (tg >= 0 && tg < (best?.t ?? 2)) best = { ...(best ?? { tank: null, hit: null }), t: tg, kind: 'ground' }
		if (!best && w.props.blocksSegment(ax, ay, az, bx, by, bz))
			best = { t: 0.5, kind: 'building', tank: null, hit: null }
		return best
	}

	/** First sample along the step that is under the ground (parameter 0..1), or −1. */
	private groundContact(w: WorldRefs, ax: number, ay: number, az: number, bx: number, by: number, bz: number) {
		const steps = Math.max(1, Math.ceil(Math.hypot(bx - ax, bz - az) / GROUND_STEP))
		for (let k = 1; k <= steps; k++) {
			const tt = k / steps
			if (ay + (by - ay) * tt < w.terrain.height(ax + (bx - ax) * tt, az + (bz - az) * tt)) return tt
		}
		return -1
	}

	private count(c: Contact) {
		this.stats[c.kind]++
		if (c.kind !== 'tank' || !c.hit) return
		if (c.hit.ricochet) this.stats.ricochet++
		else if (c.hit.penetrated) this.stats.pen++
		else this.stats.nonpen++
	}

	/** Damage and module effects of a direct hit on a live tank. */
	private applyHit(s: Shell, target: Tank, hit: HitResult) {
		this.tally(s, target, hit)
		if (hit.damage > 0) {
			if (hit.tracked && target.tracked <= 0) target.tracked = COMBAT.trackRepair
			if (hit.fire && target.burning <= 0) target.burning = COMBAT.fireTime
			if (hit.gunHit) target.gunDamaged = COMBAT.gunDamageTime
			if (hit.engine) target.engineDamaged = COMBAT.engineTime
			if (hit.ring) target.ringDamaged = COMBAT.ringTime
			if (hit.crew) target.crew.wound(hit.crew)
			if (hit.ammoRack === 'damaged') target.rackDamaged = COMBAT.rackDamageTime
			// A detonation takes whatever is left of the tank
			if (hit.ammoRack === 'boom') {
				target.detonated = true
				hit.damage = Math.max(hit.damage, target.hp)
			}
			target.damage(hit.damage, s.owner)
		} else if (hit.tracked && target.tracked <= 0 && hit.part === 'tracks') {
			target.tracked = COMBAT.trackRepair
		}
		this.onTankHit?.(target, s.owner, hit, s.spec)
	}

	/** The shooter's and the target's battle stats for a direct hit. */
	private tally(s: Shell, target: Tank, hit: HitResult) {
		const by = s.owner.stats
		const enemy = s.owner.team !== target.team
		if (enemy && hit.penetrated) {
			by.pens++
			if (Math.hypot(target.pos.x - s.owner.pos.x, target.pos.z - s.owner.pos.z) >= LONG_SHOT) by.longPens++
			if (hit.crew || hit.ammoRack || hit.gunHit || hit.engine || hit.ring) by.crits++
			if (hit.fire && target.burning <= 0) by.fires++
		}
		if (enemy && hit.tracked && target.tracked <= 0) by.tracks++
		if (!hit.penetrated && hit.part !== 'tracks' && hit.damage < s.spec.dmg) {
			target.stats.blocked += s.spec.dmg - hit.damage
			target.stats.blockedHits++
		}
	}

	/** HE blast: every tank within the radius takes falling damage through its roof armour. */
	private splash(imp: Impact, s: Shell, w: WorldRefs, direct: Tank | null) {
		for (const t of w.tanks) {
			if (!t.alive || t === direct) continue
			const d = Math.hypot(t.pos.x - imp.x, t.pos.z - imp.z) - t.radius * 0.5
			if (d > s.splash) continue
			const k = 1 - Math.max(0, d) / s.splash
			const raw = s.spec.dmg * 0.6 * k * (1 + (Math.random() - 0.5) * 0.5)
			const dmg = Math.max(0, raw - t.def.armor.top * 1.1)
			if (dmg <= 0) continue
			if (Math.random() < 0.3 * k && t.tracked <= 0) t.tracked = COMBAT.trackRepair
			const crewK = CREW.splashChance * k * (t.def.shape.openTop ? CREW.openTopSplash : 1)
			if (Math.random() < crewK) t.crew.wound(CREW_ROLES[Math.floor(Math.random() * CREW_ROLES.length)])
			t.damage(dmg, s.owner)
			this.onSplashDamage?.(t, s.owner, dmg)
		}
	}

	/** Tracer streaks behind every shell in flight. */
	private writeTracers() {
		const arr = this.pos
		let k = 0
		for (const s of this.list) {
			if (k >= COMBAT.maxShells) break
			if (s.bomb) continue
			const v = Math.hypot(s.vx, s.vy, s.vz) || 1
			const tl = Math.min(COMBAT.tracerLen, s.dist)
			const o = k * 6
			arr[o] = s.x
			arr[o + 1] = s.y
			arr[o + 2] = s.z
			arr[o + 3] = s.x - (s.vx / v) * tl
			arr[o + 4] = s.y - (s.vy / v) * tl
			arr[o + 5] = s.z - (s.vz / v) * tl
			k++
		}
		const g = this.lines.geometry
		g.setDrawRange(0, k * 2)
		;(g.attributes.position as THREE.BufferAttribute).needsUpdate = true
	}
}
