import type { Tank } from '../../tank/tank'
import { HeavyAi } from './heavy'
import { LightAi } from './light'
import { MediumAi } from './medium'
import { ArtilleryAi } from './spg'
import { TankDestroyerAi } from './td'
import type { RoleAi } from './types'

export type { Bot, Frame, RoleAi, RoundPlan } from './types'

/** The behaviour for `tank`'s vehicle class: one module per class in this folder. */
export function createRoleAi(tank: Tank): RoleAi {
	switch (tank.def.role) {
		case 'light':
			return new LightAi()
		case 'medium':
			return new MediumAi()
		case 'heavy':
			return new HeavyAi()
		case 'td':
			return new TankDestroyerAi()
		case 'spg':
			return new ArtilleryAi()
	}
}
