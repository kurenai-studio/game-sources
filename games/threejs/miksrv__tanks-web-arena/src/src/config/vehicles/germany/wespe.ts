import { howitzer } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Wespe (1943): lengthened Pz. II chassis, open casemate at the rear, 105 mm leFH 18M with a muzzle brake.
 */
export const wespe: TankDef = {
	id: 'wespe',
	nation: 'germany',
	role: 'spg',
	name: 'Wespe',
	hp: 380,
	rating: 3.5,
	speed: 12.5,
	reverse: 4.5,
	accel: 4.5,
	hullTurn: 1.0,
	turretTurn: 0.45,
	gun: howitzer(105, 45, 380, 10, 0.6, 4, 5, 0.3),
	armor: { front: 30, side: 15, rear: 10, top: 5, tFront: 20, tSide: 10, tRear: 10 },
	viewRange: 300,
	camo: 0.24,
	shape: {
		hullL: 4.8,
		hullW: 2.3,
		hullH: 0.8,
		trackH: 0.8,
		turret: false,
		tW: 2.2,
		tL: 2.6,
		tH: 1.0,
		tZ: -1.0,
		gunLen: 2.9,
		gunR: 0.07,
		openTop: true,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.96, 0],
				[1, 0.32],
				[0.86, 0.55],
				[0.84, 1],
				[0.03, 1],
				[0, 0.55],
			],
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.86, 1],
				[0.03, 1],
			],
			roofW: 0.78,
			mountY: 0.6,
		},
		gunLook: {
			mantlet: 'shield',
			mantletW: 0.35,
			brake: 'double',
			sleeve: 0.5,
		},
		running: {
			kind: 'tracks',
			wheels: 5,
			wheelR: 0.28,
			span: 0.72,
			rollers: 3,
			sprocket: 'front',
		},
	},
}
