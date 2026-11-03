import { COAST, WORLD_HALF } from '../../config'
import { Spotting } from '../../game/spotting'
import type { Tank, WorldRefs } from '../../tank/tank'
import { vantage } from '../positions'
import { offsetOnAxis, pickLane, routeAcross, watchPoint } from '../routes'
import { friendSpots } from '../steering'
import { reachOf } from '../targeting'
import type { TeamTactics } from '../team'
import type { Pt } from '../types'
import { fallBackWhenHurt, joinFight } from './common'
import type { Bot, Frame, RoleAi, RoundPlan } from './types'

/** An enemy this close (m) is reason enough to move off. */
const DANGER = 110
/** A scout only fights (when it fights at all) closer than this (m). */
const CONTACT_RANGE = 230
/** s between two slips away from danger (a shot always moves it at once). */
const SLIP_COOLDOWN = 5
/** s a scout stops at a lookout before driving on. */
const PAUSE: readonly [number, number] = [2, 5]
/** s between re-plans of a raid route (the enemy artillery may have moved). */
const RAID_REPLAN = 10
/** m off the straight line a raid swings round a flank. */
const FLANK = 150

const rand = (k: number) => (Math.random() - 0.5) * k

/**
 * Light tank — the scout. No sitting in bushes: it keeps driving from lookout to lookout ahead of its team's leading
 * strike group, lighting the enemy up for the artillery; it shoots only at an exposed track (to pin the target down for
 * the artillery, `gunner.ts`) and moves off at once after a shot, a hit, or an enemy getting close. Once the enemy is
 * thinned out it swings round a flank into their rear and goes for their artillery.
 */
export class LightAi implements RoleAi {
	private shots = 0
	private pause = 0
	private slipCooldown = 0
	private raidReplan = 0

	/** Raiding the enemy rear: the enemy is thinned out (but not down to the last tank: then everyone hunts). */
	static raiding(tac: TeamTactics) {
		return tac.fewEnemies && !tac.lastEnemy
	}

	plan(w: WorldRefs, bot: Bot): RoundPlan {
		// First lookout: high ground just past the middle of a lane
		const lane = pickLane(w, bot.tank.team, null)
		const mid = lane[Math.floor(lane.length * 0.5)]
		const ahead = lane[Math.floor(lane.length * 0.75)]
		const goal = { x: mid.x + rand(120), z: mid.z + rand(120) }
		const holdSpot = vantage(w, goal, 70, { bushes: true, watch: watchPoint(w.terrain, ahead) })
		this.shots = this.pause = this.slipCooldown = this.raidReplan = 0
		return { mode: 'advance', path: [lane[1], ...routeAcross(w.terrain, lane[1], holdSpot)], holdSpot }
	}

	/** Raiding: the enemy artillery whenever it is in sight and in reach. */
	preferTarget(bot: Bot, w: WorldRefs, time: number): Tank | null {
		if (!LightAi.raiding(bot.tactics)) return null
		const arty = bot.tactics.enemyArtillery(w)
		const ok = arty && Spotting.visibleTo(bot.tank.team, arty, time) && bot.dist(arty) <= reachOf(bot.tank)
		return ok ? arty : null
	}

	think(bot: Bot, f: Frame) {
		const { w, dt } = f
		const tac = bot.tactics
		this.slipCooldown -= dt
		this.raidReplan -= dt
		const raid = LightAi.raiding(tac)
		// Taking or defending a base, or on the player's order, it is no scout for now: it stays put and shoots freely
		const sent = bot.onObjective || bot.defending
		bot.gunner.trackHunter = !raid && !bot.hunting && !sent
		const shot = bot.gunner.shots !== this.shots
		this.shots = bot.gunner.shots
		fallBackWhenHurt(bot, f)
		// It fights only when raiding, or to get at the enemy artillery
		if (bot.target && (raid || bot.target.def.role === 'spg')) joinFight(bot, CONTACT_RANGE, true)
		if (bot.mode === 'retreat' || bot.mode === 'hunt' || bot.mode === 'engage' || sent) return
		if (raid) {
			this.raid(bot, f)
			return
		}
		const threat = shot || ((f.hurt || f.enemyNear < DANGER) && this.slipCooldown <= 0)
		if (threat) {
			const me = bot.tank
			const from = bot.target ?? (me.lastHitBy?.alive ? me.lastHitBy : null)
			if (from || shot) this.slipAway(bot, w, from ? from.pos : this.enemyward(bot, w, -60))
			return
		}
		if (!bot.pathDone && bot.mode !== 'hold') return
		this.pause -= dt
		if (this.pause > 0) return
		this.pause = PAUSE[0] + Math.random() * (PAUSE[1] - PAUSE[0])
		this.nextLookout(bot, w)
	}

	/** A point `ahead` m from us toward the enemy base. */
	private enemyward(bot: Bot, w: WorldRefs, ahead: number): Pt {
		const me = bot.tank
		return offsetOnAxis(w.terrain, me.team, me.pos.x, me.pos.z, ahead, 0)
	}

	/** Off 40–60 m further away from `from` and to one side, onto ground that still sees it. */
	private slipAway(bot: Bot, w: WorldRefs, from: Pt) {
		const me = bot.tank
		this.slipCooldown = SLIP_COOLDOWN
		this.pause = 0
		const dx = me.pos.x - from.x
		const dz = me.pos.z - from.z
		const l = Math.hypot(dx, dz) || 1
		const back = 40 + Math.random() * 20
		const side = (Math.random() < 0.5 ? 1 : -1) * (20 + Math.random() * 25)
		const around = {
			x: me.pos.x + (dx / l) * back - (dz / l) * side,
			z: me.pos.z + (dz / l) * back + (dx / l) * side,
		}
		bot.goTo(
			w,
			vantage(w, around, 30, { bushes: true, watch: watchPoint(w.terrain, from), avoid: friendSpots(w, me) }),
		)
	}

	/** The next lookout: 70–140 m ahead of the leading friendly group, off to either side, with a view forward. */
	private nextLookout(bot: Bot, w: WorldRefs) {
		const me = bot.tank
		const lead = bot.tactics.leadCentre() ?? { x: me.pos.x, z: me.pos.z }
		const o = offsetOnAxis(w.terrain, me.team, lead.x, lead.z, 70 + Math.random() * 70, rand(240))
		const enemy = w.terrain.bases[1 - me.team]
		bot.goTo(w, vantage(w, o, 40, { bushes: true, watch: watchPoint(w.terrain, enemy), avoid: friendSpots(w, me) }))
	}

	/**
	 * Into the enemy rear for their artillery: round a flank to where it was last seen, or to their base; with no
	 * artillery left, look for whoever was seen last.
	 */
	private raid(bot: Bot, f: Frame) {
		if (this.raidReplan > 0 && !bot.pathDone) return
		this.raidReplan = RAID_REPLAN
		const { w, time } = f
		const tac = bot.tactics
		const me = bot.tank
		const from = { x: me.pos.x, z: me.pos.z }
		const arty = tac.enemyArtillery(w)
		if (!arty) {
			bot.seek(w, time)
			return
		}
		const goal = tac.lastSighting(arty) ?? w.terrain.bases[1 - me.team]
		const dx = goal.x - from.x
		const dz = goal.z - from.z
		const l = Math.hypot(dx, dz) || 1
		bot.mode = 'advance'
		if (l < 200) {
			bot.setPath(routeAcross(w.terrain, from, goal), null)
			return
		}
		const half = WORLD_HALF - 40
		const bendAt = (side: number) => ({
			x: Math.max(-half, Math.min(half, from.x + dx * 0.6 - (dz / l) * FLANK * side)),
			z: Math.max(-half, Math.min(half, from.z + dz * 0.6 + (dx / l) * FLANK * side)),
		})
		let side = this.flankSide(bot, w, goal)
		// The outer flank of a coast map may be the sea: go round the landward side instead
		const out = bendAt(side)
		if (w.terrain.seaward(out.x, out.z) > COAST.start - 60) side = -side
		const b = bendAt(side)
		const bend = w.terrain.findSpot(b.x, b.z, 40)
		bot.setPath([...routeAcross(w.terrain, from, bend), ...routeAcross(w.terrain, bend, goal)], null)
	}

	/** Swing round the outer side (the fighting is in the middle of the map). */
	private flankSide(bot: Bot, w: WorldRefs, goal: Pt): number {
		const { px, pz } = w.terrain.axis
		const across = goal.x * px + goal.z * pz
		const dx = goal.x - bot.tank.pos.x
		const dz = goal.z - bot.tank.pos.z
		// The perpendicular (−dz, dx) · (px, pz) tells which way "side = +1" points across the axis
		const k = -dz * px + dx * pz
		return Math.sign(k) === Math.sign(across) || across === 0 ? 1 : -1
	}
}
