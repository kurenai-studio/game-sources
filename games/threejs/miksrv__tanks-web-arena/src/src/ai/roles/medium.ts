import { fallBackWhenHurt } from './common'
import { StrikeAi } from './strike'
import type { Bot, Frame } from './types'

/** m a medium may run ahead of the rest of its strike group before it stops to wait. */
const LEAD_MAX = 45

/**
 * Medium tank — the assault: leads its strike group up the lane and into the fight for the centre, but never more
 * than LEAD_MAX ahead of the rest of the group; falls back when badly hurt. In a fight it takes the high ground and
 * reloads in cover, or keeps rolling when there is none (`fight.ts`).
 */
export class MediumAi extends StrikeAi {
	protected limit(bot: Bot): number | null {
		const g = bot.tactics.groupFrontWithout(bot.tank)
		return g === null ? null : g + LEAD_MAX
	}

	protected survive(bot: Bot, f: Frame) {
		fallBackWhenHurt(bot, f)
	}
}
