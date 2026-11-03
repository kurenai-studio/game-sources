import type { WorldRefs } from '../../tank/tank'
import { TD_HEIGHT, vantage } from '../positions'
import { offsetOnAxis, pickLane, routeAcross, watchPoint } from '../routes'
import { friendSpots } from '../steering'
import { IdleClock, LATE_IDLE, SEEK_IDLE, fallBackWhenHurt, joinFight } from './common'
import type { Bot, Frame, RoleAi, RoundPlan } from './types'

/** Contact closer than this (m) while moving up turns into a fight; from an ambush spot it shoots from there. */
const CONTACT_RANGE = 230
/** s between two moves after being flushed out of a hiding spot. */
const RELOCATE_COOLDOWN = 12
/** How often (s) it checks on its group, how far behind it sits (m), and how far the group may get before it follows. */
const FOLLOW_CHECK = 6
const FOLLOW_BEHIND = 80
const FOLLOW_SLACK = 50

/**
 * Tank destroyer — the ambush: backs one strike group from high ground (height counts most for it; in a bush when
 * there is one) about FOLLOW_BEHIND behind it, watching the ground ahead of it, and moves up as the group does.
 * Flushed out by a hit, it moves to another hiding spot; late in the battle it stops waiting at the back and goes
 * looking for the enemy.
 */
export class TankDestroyerAi implements RoleAi {
	private relocateTimer = 0
	private followTimer = 0
	private readonly idle = new IdleClock()

	plan(w: WorldRefs, bot: Bot): RoundPlan {
		// One third along the group's lane, watching the lane ahead
		const lane = pickLane(w, bot.tank.team, bot.tactics.ambushLane)
		const p = lane[Math.min(2, lane.length - 1)]
		const ahead = lane[Math.min(lane.length - 1, Math.floor(lane.length * 0.6))]
		const holdSpot = vantage(w, p, 60, { bushes: true, height: TD_HEIGHT, watch: watchPoint(w.terrain, ahead) })
		this.relocateTimer = this.followTimer = 0
		this.idle.reset()
		const me = bot.tank
		return { mode: 'advance', path: routeAcross(w.terrain, { x: me.pos.x, z: me.pos.z }, holdSpot), holdSpot }
	}

	think(bot: Bot, f: Frame) {
		this.relocateTimer -= f.dt
		fallBackWhenHurt(bot, f)
		const sent = bot.onObjective || bot.defending
		if (bot.mode === 'hold' && f.hurt && this.relocateTimer <= 0 && !sent) this.relocate(bot, f.w)
		joinFight(bot, CONTACT_RANGE)
		this.followGroup(bot, f)
		if (bot.tactics.late && !bot.defending && !bot.capturing && this.idle.tick(bot, f.dt) > SEEK_IDLE * LATE_IDLE) {
			bot.seek(f.w, f.time)
			this.idle.reset()
		}
	}

	/** Flushed out of a hiding spot: another one a little further along. */
	private relocate(bot: Bot, w: WorldRefs) {
		const me = bot.tank
		this.relocateTimer = RELOCATE_COOLDOWN
		const ahead = 50 + (Math.random() - 0.5) * 80
		const o = offsetOnAxis(w.terrain, me.team, me.pos.x, me.pos.z, ahead, (Math.random() - 0.5) * 120)
		bot.goTo(w, vantage(w, o, 30, { bushes: true, height: TD_HEIGHT, avoid: friendSpots(w, me) }))
	}

	/** The group has moved on: a new spot FOLLOW_BEHIND behind its centre, watching the ground ahead of it. */
	private followGroup(bot: Bot, f: Frame) {
		const tac = bot.tactics
		if (tac.late || bot.mode !== 'hold' || bot.target || bot.defending || bot.capturing) return
		this.followTimer -= f.dt
		if (this.followTimer > 0) return
		this.followTimer = FOLLOW_CHECK
		const centre = tac.groupCentre(tac.ambushGroup) ?? tac.leadCentre()
		if (!centre) return
		const { w } = f
		const me = bot.tank
		const want = offsetOnAxis(w.terrain, me.team, centre.x, centre.z, -FOLLOW_BEHIND, 0)
		const spot = bot.holdSpot
		if (spot && Math.hypot(spot.x - want.x, spot.z - want.z) < FOLLOW_SLACK) return
		const look = offsetOnAxis(w.terrain, me.team, centre.x, centre.z, 150, 0)
		bot.goTo(
			w,
			vantage(w, want, 40, {
				bushes: true,
				height: TD_HEIGHT,
				watch: watchPoint(w.terrain, look),
				avoid: friendSpots(w, me),
			}),
		)
	}
}
