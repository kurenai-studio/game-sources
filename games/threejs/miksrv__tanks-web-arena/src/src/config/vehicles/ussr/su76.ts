import { howitzer } from '../../guns'
import type { TankDef } from '../../types'

/**
 * SU-76M (1943): lengthened T-70 chassis, engine at the front, rear-open casemate with sloped walls, divisional ZiS-3
 * with a muzzle brake.
 */
export const su76: TankDef = {
	id: 'su76',
	nation: 'ussr',
	role: 'spg',
	name: 'СУ-76М',
	hp: 380,
	rating: 3,
	speed: 13,
	reverse: 5,
	accel: 4.5,
	hullTurn: 1.0,
	turretTurn: 0.5,
	gun: howitzer(76, 40, 250, 5.5, 0.55, 3.4, 4, 0.26),
	armor: { front: 35, side: 15, rear: 15, top: 10, tFront: 35, tSide: 15, tRear: 15 },
	viewRange: 300,
	camo: 0.26,
	shape: {
		hullL: 5.0,
		hullW: 2.7,
		hullH: 0.8,
		trackH: 0.8,
		turret: false,
		tW: 2.5,
		tL: 2.6,
		tH: 0.95,
		tZ: -1.1,
		gunLen: 3.2,
		gunR: 0.05,
		openTop: true,
		hullLook: {
			outline: [
				[0.02, 0],
				[0.96, 0],
				[1, 0.4],
				[0.76, 1],
				[0.03, 1],
				[0, 0.5],
			],
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.84, 1],
				[0.12, 1],
				[0, 0.55],
			],
			roofW: 0.82,
			mountY: 0.6,
		},
		gunLook: {
			mantlet: 'shield',
			mantletW: 0.35,
			brake: 'single',
		},
		running: {
			kind: 'tracks',
			wheels: 6,
			wheelR: 0.27,
			span: 0.76,
			rollers: 3,
			sprocket: 'front',
		},
	},
}
