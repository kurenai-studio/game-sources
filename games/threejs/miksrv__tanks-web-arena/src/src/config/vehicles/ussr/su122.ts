import { howitzer } from '../../guns'
import type { TankDef } from '../../types'

/**
 * SU-122 (1943): SU-85 casemate on a T-34 hull, short 122 mm M-30S howitzer in a massive cast "bell" mantlet.
 */
export const su122: TankDef = {
	id: 'su122',
	nation: 'ussr',
	role: 'spg',
	name: 'СУ-122',
	hp: 480,
	rating: 4,
	speed: 11,
	reverse: 4,
	accel: 3.5,
	hullTurn: 0.8,
	turretTurn: 0.4,
	gun: howitzer(122, 50, 450, 14, 0.62, 4.2, 6, 0.17),
	armor: { front: 60, side: 45, rear: 40, top: 15, tFront: 60, tSide: 45, tRear: 40 },
	viewRange: 300,
	camo: 0.2,
	shape: {
		hullL: 6.0,
		hullW: 3.0,
		hullH: 0.95,
		trackH: 0.9,
		turret: false,
		tW: 2.05,
		tL: 2.4,
		tH: 0.75,
		tZ: 0.6,
		gunLen: 2.6,
		gunR: 0.09,
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
			mountY: 0.45,
		},
		gunLook: {
			mantlet: 'ball',
			brake: 'none',
			sleeve: 0.5,
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
