import { howitzer } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Hummel (1943): GW III/IV chassis with Pz. IV running gear, tall open casemate at the rear, 150 mm sFH 18 without a
 * muzzle brake.
 */
export const hummel: TankDef = {
	id: 'hummel',
	nation: 'germany',
	role: 'spg',
	name: 'Hummel',
	hp: 450,
	rating: 4.5,
	speed: 11,
	reverse: 4,
	accel: 3.2,
	hullTurn: 0.75,
	turretTurn: 0.35,
	gun: howitzer(150, 55, 620, 18, 0.7, 5, 7.5, 0.14),
	armor: { front: 40, side: 25, rear: 20, top: 10, tFront: 30, tSide: 20, tRear: 15 },
	viewRange: 300,
	camo: 0.2,
	shape: {
		hullL: 6.0,
		hullW: 2.9,
		hullH: 0.9,
		trackH: 0.85,
		turret: false,
		tW: 2.75,
		tL: 3.2,
		tH: 1.1,
		tZ: -1.3,
		gunLen: 4.5,
		gunR: 0.1,
		openTop: true,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.96, 0],
				[1, 0.32],
				[0.88, 0.5],
				[0.87, 1],
				[0.03, 1],
				[0, 0.58],
			],
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.93, 1],
				[0.01, 1],
			],
			roofW: 0.86,
			mountY: 0.6,
		},
		gunLook: {
			mantlet: 'shield',
			mantletW: 0.3,
			brake: 'none',
			sleeve: 0.9,
		},
		running: {
			kind: 'tracks',
			wheels: 8,
			wheelR: 0.235,
			span: 0.76,
			layout: 'paired',
			rollers: 4,
			sprocket: 'front',
		},
	},
}
