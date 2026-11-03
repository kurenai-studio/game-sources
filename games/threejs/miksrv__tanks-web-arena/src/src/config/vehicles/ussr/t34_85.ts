import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * T-34-85 (1944): T-34 hull with a 60° glacis and sloped sides, Christie road wheels, cast turret with a bustle, 85 mm
 * ZiS-S-53 without a muzzle brake.
 */
export const t34_85: TankDef = {
	id: 't34_85',
	nation: 'ussr',
	role: 'medium',
	name: 'Т-34-85',
	hp: 760,
	rating: 5.5,
	speed: 15,
	reverse: 5,
	accel: 4.5,
	hullTurn: 1.0,
	turretTurn: 0.9,
	gun: turretGun(85, 128, 185, 5.6, 0.37, 2.1, 790),
	armor: { front: 95, side: 55, rear: 45, top: 20, tFront: 90, tSide: 75, tRear: 52 },
	viewRange: 380,
	camo: 0.16,
	shape: {
		hullL: 6.1,
		hullW: 3.0,
		hullH: 0.95,
		trackH: 0.9,
		turret: true,
		tW: 2.2,
		tL: 2.6,
		tH: 0.8,
		tZ: 0.45,
		gunLen: 4.0,
		gunR: 0.06,
		openTop: false,
		hullLook: {
			outline: [
				[0.02, 0],
				[0.96, 0],
				[1, 0.12],
				[0.79, 1],
				[0.07, 1],
				[0, 0.42],
			],
			roofW: 0.68,
			lowerNose: 0.55,
			drums: 2,
		},
		turretLook: {
			kind: 'round',
			facets: 12,
			roofW: 0.82,
			bustle: 0.5,
			cupola: [0.22, -0.2],
			mountY: 0.45,
		},
		gunLook: {
			mantlet: 'round',
			mantletW: 0.42,
			brake: 'none',
		},
		running: {
			kind: 'tracks',
			wheels: 5,
			wheelR: 0.41,
			span: 0.78,
			sprocket: 'rear',
		},
	},
}
