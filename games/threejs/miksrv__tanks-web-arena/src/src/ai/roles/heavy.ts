import type { WorldRefs } from '../../tank/tank'
import { StrikeAi } from './strike'
import type { Bot } from './types'

/** m behind the mediums the heavies keep while moving up; in a fight they may come up level (+ this). */
const SUPPORT_GAP = 20
const ENGAGED_LEAD = 10
/** With no mediums left in the group: as far ahead of the rest as a medium may go. */
const LEAD_MAX = 45

/**
 * Heavy tank — the support: follows its group's mediums SUPPORT_GAP behind and comes up level with them once the
 * shooting starts; prefers enemies that are shooting at our tanks (`targeting.ts`); never falls back — the armour is
 * the answer (and an unseen attacker only makes it turn to face the blow).
 */
export class HeavyAi extends StrikeAi {
	protected limit(bot: Bot, _w: WorldRefs, engaged: boolean): number | null {
		const assault = bot.tactics.assaultFront(bot.tank)
		if (assault !== null) return assault + (engaged ? ENGAGED_LEAD : -SUPPORT_GAP)
		const g = bot.tactics.groupFrontWithout(bot.tank)
		return g === null ? null : g + LEAD_MAX
	}

	protected survive() {
		// Heavies hold their ground
	}
}
