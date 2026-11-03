import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * T-34-76 (1942): hexagonal "nut" turret with two round hatches ("Mickey Mouse"), 76 mm F-34.
 */
export const t34_76: TankDef = {
	id: 't34_76',
	nation: 'ussr',
	role: 'medium',
	name: 'Т-34-76',
	hp: 680,
	rating: 4,
	speed: 15,
	reverse: 5,
	accel: 4.8,
	hullTurn: 1.05,
	turretTurn: 1.0,
	gun: turretGun(76, 86, 115, 3.9, 0.4, 2.0, 660),
	armor: { front: 95, side: 55, rear: 45, top: 20, tFront: 70, tSide: 60, tRear: 50 },
	viewRange: 370,
	camo: 0.18,
	shape: {
		hullL: 6.0,
		hullW: 3.0,
		hullH: 0.95,
		trackH: 0.9,
		turret: true,
		tW: 1.9,
		tL: 2.1,
		tH: 0.7,
		tZ: 0.55,
		gunLen: 3.2,
		gunR: 0.055,
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
			facets: 6,
			roofW: 0.82,
			twinHatches: true,
			mountY: 0.45,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.35,
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
