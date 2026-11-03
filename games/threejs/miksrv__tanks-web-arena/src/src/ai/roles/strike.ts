import type { WorldRefs } from '../../tank/tank'
import type { LanePoint } from '../../world/terrain'
import { vantage } from '../positions'
import { CENTRE_INDEX, leaveBase, pickLane, watchPoint } from '../routes'
import { driveToSpot, faceToward, friendSpots } from '../steering'
import type { DriveCommand, Pt } from '../types'
import { IdleClock, LATE_IDLE, SEEK_IDLE, joinFight } from './common'
import type { Bot, Frame, RoleAi, RoundPlan } from './types'

/** Contact closer than this (m) while moving up turns into a fight. */
const CONTACT_RANGE = 180
/** Nobody waits for the group while still leaving the base. */
const REGROUP_MIN_PROGRESS = 80
/** Resume once this far back inside the allowed lead (no stop-go at the limit). */
const REGROUP_HYSTERESIS = 12
const REGROUP_MAX = 25 // s waiting for the group before going on anyway
const REGROUP_COOLDOWN = 15
/** s a strike group holds the centre with nobody in reach before pushing on along its lane. */
const CENTRE_IDLE = 12

const rand = (k: number) => (Math.random() - 0.5) * k

/**
 * A strike group tank (mediums and heavies share this): along the group's lane to high ground short of the centre,
 * fight for the centre, then — once it is quiet — push on up the lane; never too far ahead of the rest of the group
 * (`limit` says how far is too far for each class).
 */
export abstract class StrikeAi implements RoleAi {
	/** The rest of the lane, pushed along once the centre has been quiet a while. */
	private push: Pt[] | null = null
	private regroupSpot: Pt | null = null
	private regroupTimer = 0
	private regroupCooldown = 0
	private readonly idle = new IdleClock()
	/** An assault's defender: holds the middle until late in the battle. */
	private defence = false
	/** An assault's attacker. */
	private attack = false

	/** The furthest progress (m along the axis) the team allows us, or null for no limit. */
	protected abstract limit(bot: Bot, w: WorldRefs, engaged: boolean): number | null
	/** Low health and the like. */
	protected abstract survive(bot: Bot, f: Frame): void

	plan(w: WorldRefs, bot: Bot): RoundPlan {
		// Along the group's lane, spread a little across it (the crossing itself is taken exactly) to high ground short
		// of the centre with a view across it
		const t = w.terrain
		const lane = pickLane(w, bot.tank.team, bot.tactics.laneOf(bot.tank))
		const off = rand(40)
		const { px, pz } = t.axis
		const spread = (p: LanePoint): Pt =>
			p.fixed ? p : { x: p.x + px * off + rand(16), z: p.z + pz * off + rand(16) }
		const c = Math.min(CENTRE_INDEX, lane.length - 2)
		const before = lane[c - 1]
		const centre = lane[c]
		const around = { x: before.x + (centre.x - before.x) * 0.75, z: before.z + (centre.z - before.z) * 0.75 }
		const across = lane[Math.max(c + 1, lane.length - CENTRE_INDEX)] // just past the middle, on the enemy side
		const holdSpot = vantage(w, around, 35, { watch: watchPoint(t, across) })
		// An assault's defenders hold the middle: they never push on into the attackers' half
		this.defence = t.mode === 'assault' && t.defender === bot.tank.team
		this.attack = t.mode === 'assault' && !this.defence
		this.push = this.defence ? null : lane.slice(c).map(spread)
		this.regroupSpot = null
		this.regroupTimer = this.regroupCooldown = 0
		this.idle.reset()
		return {
			mode: 'advance',
			path: [
				...leaveBase(lane)
					.slice(0, c - 1)
					.map(spread),
				holdSpot,
			],
			holdSpot,
		}
	}

	think(bot: Bot, f: Frame) {
		this.regroupCooldown -= f.dt
		this.survive(bot, f)
		joinFight(bot, CONTACT_RANGE)
		// Holding the centre is a fight for it, not sitting under fire (a base circle is held from inside it)
		if (bot.mode === 'hold' && bot.target && !bot.onObjective) bot.mode = 'engage'
		this.updateRegroup(bot, f)
		this.moveOnWhenQuiet(bot, f)
	}

	/** How far we are past the point the team allows (≤ 0 = fine). */
	aheadBy(bot: Bot, w: WorldRefs, engaged: boolean): number {
		// The last enemy, or a base to take or save, does not wait for the group
		if (bot.hunting || bot.onObjective) return -Infinity
		const me = bot.tank
		const p = bot.tactics.progress(w, me.pos.x, me.pos.z)
		if (p < REGROUP_MIN_PROGRESS) return -Infinity
		const max = this.limit(bot, w, engaged)
		return max === null ? -Infinity : p - max
	}

	/** Waiting for the group: on the chosen spot, nose toward the enemy base. */
	drive(bot: Bot, w: WorldRefs, cmd: DriveCommand): boolean {
		if (bot.mode !== 'regroup') return false
		if (!driveToSpot(w, bot.tank, cmd, this.regroupSpot, 5, 0.7)) {
			faceToward(bot.tank, cmd, bot.target ? bot.target.pos : w.terrain.bases[1 - bot.tank.team])
		}
		return true
	}

	/** Out ahead of the group: stop on the best ground nearby and wait for it; go on once it is up (or after a while). */
	private updateRegroup(bot: Bot, f: Frame) {
		const { w } = f
		if (bot.mode === 'advance' && this.regroupCooldown <= 0 && this.aheadBy(bot, w, false) > 0) {
			const me = bot.tank
			const enemy = w.terrain.bases[1 - me.team]
			this.regroupSpot = vantage(w, { x: me.pos.x, z: me.pos.z }, 25, {
				watch: watchPoint(w.terrain, enemy),
				avoid: friendSpots(w, me),
			})
			this.regroupTimer = 0
			bot.mode = 'regroup'
		}
		if (bot.mode !== 'regroup') return
		this.regroupTimer += f.dt
		if (this.aheadBy(bot, w, false) < -REGROUP_HYSTERESIS || this.regroupTimer > REGROUP_MAX || bot.hunting) {
			bot.mode = 'advance'
			this.regroupSpot = null
			this.regroupCooldown = REGROUP_COOLDOWN
		}
	}

	/** Nobody in reach for a while: from the centre push on up the lane; after that go looking for the enemy. */
	private moveOnWhenQuiet(bot: Bot, f: Frame) {
		const idle = this.idle.tick(bot, f.dt)
		if (bot.defending || bot.capturing || (this.defence && !bot.tactics.late)) return
		const patience = bot.tactics.late ? LATE_IDLE : 1
		if (this.push) {
			if (idle <= CENTRE_IDLE * patience) return
			// The assault's attack goes in as one wave, once the battle turns late, not tank by tank into the guns
			if (this.attack && !bot.tactics.late) return
			// Past the middle, a base to take beats driving on: the neutral one, or the defence's in an assault
			if (!(f.w.terrain.mode !== 'standard' && bot.capture(f.w, true))) {
				bot.setPath(this.push, null)
				bot.mode = 'advance'
			}
			this.push = null
			this.idle.reset()
		} else if (idle > SEEK_IDLE * patience) {
			bot.seek(f.w, f.time)
			this.idle.reset()
		}
	}
}
