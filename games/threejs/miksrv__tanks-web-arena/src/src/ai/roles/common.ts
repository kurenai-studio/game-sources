import { BOTS } from '../../config'
import { planRetreat } from '../routes'
import type { Bot, Frame } from './types'

/** s at the end of the route with nobody in reach before going to look for the enemy. */
export const SEEK_IDLE = 10
/** Late in the battle (enemy thinned out, or two minutes gone) the idle waits shrink to this share. */
export const LATE_IDLE = 0.35

/**
 * Low health: fall back toward our base, behind cover on the way; stop once out of danger (not while hunting, nor
 * from a base circle it is taking or defending: the capture is worth more than the tank).
 */
export function fallBackWhenHurt(bot: Bot, f: Frame) {
	const me = bot.tank
	if (me.hpFrac < BOTS.retreatHp && bot.mode !== 'retreat' && !bot.hunting && !bot.holdingCircle) {
		const r = planRetreat(f.w, me)
		bot.setPath(r.path, r.holdSpot)
		bot.mode = 'retreat'
	}
	if (bot.mode === 'retreat' && (bot.pathDone || (f.enemyNear > 180 && me.hpFrac > 0.15))) bot.mode = 'hold'
}

/**
 * Contact while moving up (or, with `fromHold`, while holding): close enough → fight. Not on the way to a base to
 * take or defend, nor in its circle: it shoots on the move and from there.
 */
export function joinFight(bot: Bot, range: number, fromHold = false) {
	if (bot.onObjective) return
	const m = bot.mode
	const moving = m === 'advance' || m === 'regroup' || (fromHold && m === 'hold')
	if (moving && bot.target && bot.dist(bot.target) < range) bot.mode = 'engage'
}

/** Counts the seconds a bot stands at the end of its route with nobody in reach. */
export class IdleClock {
	private t = 0

	tick(bot: Bot, dt: number): number {
		const idle = bot.mode === 'hold' && bot.pathDone && !bot.target
		this.t = idle ? this.t + dt : 0
		return this.t
	}

	reset() {
		this.t = 0
	}
}
