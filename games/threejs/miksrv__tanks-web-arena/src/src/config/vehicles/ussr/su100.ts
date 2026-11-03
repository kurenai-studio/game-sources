import { casemateGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * SU-100 (1944): T-34 hull, the casemate continues the glacis and the sloped sides, a commander's cupola protrudes on
 * the right, 100 mm D-10S in a ball mantlet.
 */
export const su100: TankDef = {
	id: 'su100',
	nation: 'ussr',
	role: 'td',
	name: 'СУ-100',
	hp: 820,
	rating: 6.5,
	speed: 13,
	reverse: 5,
	accel: 4,
	hullTurn: 0.9,
	turretTurn: 0.5,
	gun: casemateGun(100, 178, 300, 7.5, 0.34, 2.0, 895, 0.15),
	armor: { front: 110, side: 45, rear: 45, top: 20, tFront: 110, tSide: 45, tRear: 45 },
	viewRange: 370,
	camo: 0.3,
	shape: {
		hullL: 6.1,
		hullW: 3.0,
		hullH: 0.95,
		trackH: 0.9,
		turret: false,
		tW: 2.05,
		tL: 2.4,
		tH: 0.75,
		tZ: 0.6,
		gunLen: 5.4,
		gunR: 0.07,
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
			kind: 'welded',
			outline: [
				[0, 0],
				[0.99, 0],
				[0.51, 1],
				[0.06, 1],
				[0, 0.55],
			],
			roofW: 0.63,
			cupola: [-0.3, -0.05],
			mountY: 0.45,
		},
		gunLook: {
			mantlet: 'ball',
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
