import { casemateGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * SU-85 (1943): casemate merged with the T-34 glacis and sides, commander's cupola on the left, 85 mm D-5S in a ball
 * mantlet.
 */
export const su85: TankDef = {
	id: 'su85',
	nation: 'ussr',
	role: 'td',
	name: 'СУ-85',
	hp: 760,
	rating: 5,
	speed: 13.5,
	reverse: 5,
	accel: 4.2,
	hullTurn: 0.95,
	turretTurn: 0.5,
	gun: casemateGun(85, 128, 185, 5.2, 0.35, 2.0, 790, 0.17),
	armor: { front: 95, side: 45, rear: 45, top: 20, tFront: 95, tSide: 45, tRear: 45 },
	viewRange: 360,
	camo: 0.31,
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
		gunLen: 4.6,
		gunR: 0.065,
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
			cupola: [0.25, -0.2],
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
