import type { WorldRefs } from '../../tank/tank'
import { flatSpot } from '../positions'
import { planRetreat } from '../routes'
import type { Bot, Frame, RoleAi, RoundPlan } from './types'

/** An enemy this close (m) sends the artillery back toward the base. */
const DANGER = 90
/** s the gun may be stuck at its elevation stop before moving to level ground. */
const TILT_RELOCATE = 3

/**
 * Self-propelled gun — the artillery: stands on level ground by its spawn point (the base is levelled; a tilted hull
 * eats the elevation the long arc needs) and drops shells on whatever the team has spotted, targets that have stood
 * still first (`targeting.ts`), never on a friend's head (`gunner.ts`). Moves off when an enemy gets close, or to
 * flatter ground when the slope keeps the barrel at its stop. It never joins a fight.
 */
export class ArtilleryAi implements RoleAi {
	plan(w: WorldRefs, bot: Bot): RoundPlan {
		const me = bot.tank
		const holdSpot = flatSpot(w.terrain, me.pos.x, me.pos.z, 40)
		return { mode: 'hold', path: [holdSpot], holdSpot }
	}

	think(bot: Bot, f: Frame) {
		const me = bot.tank
		if (f.enemyNear < DANGER && bot.mode !== 'relocate') {
			const r = planRetreat(f.w, me)
			bot.setPath(r.path, r.holdSpot)
			bot.mode = 'relocate'
		} else if (bot.mode === 'relocate' && bot.pathDone) bot.mode = 'hold'
		else if (bot.mode === 'hold' && bot.gunner.elevTimer > TILT_RELOCATE) {
			// The barrel is at its stop: this slope is no good, find level ground nearby
			const spot = flatSpot(f.w.terrain, me.pos.x, me.pos.z, 35, [{ x: me.pos.x, z: me.pos.z }])
			bot.setPath([spot], spot)
			bot.mode = 'relocate'
			bot.gunner.elevTimer = 0
		}
	}
}
