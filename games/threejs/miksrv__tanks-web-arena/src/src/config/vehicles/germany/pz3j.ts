import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Pz. III J (1942): stepped front with spare track links, six road wheels with three return rollers, turret with a
 * commander's cupola at the rear and a stowage bin, long 50 mm KwK 39 L/60.
 */
export const pz3j: TankDef = {
	id: 'pz3j',
	nation: 'germany',
	role: 'medium',
	name: 'Pz. III J',
	hp: 560,
	rating: 3.5,
	speed: 14,
	reverse: 5,
	accel: 5,
	hullTurn: 1.1,
	turretTurn: 1.1,
	gun: turretGun(50, 85, 70, 2.4, 0.36, 1.6, 835),
	armor: { front: 60, side: 30, rear: 30, top: 15, tFront: 55, tSide: 30, tRear: 30 },
	viewRange: 380,
	camo: 0.2,
	shape: {
		hullL: 5.5,
		hullW: 2.9,
		hullH: 0.9,
		trackH: 0.85,
		turret: true,
		tW: 2.0,
		tL: 2.2,
		tH: 0.75,
		tZ: 0.3,
		gunLen: 3.0,
		gunR: 0.045,
		openTop: false,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.96, 0],
				[1, 0.32],
				[0.87, 0.5],
				[0.86, 1],
				[0.03, 1],
				[0, 0.58],
			],
			spareTracks: true,
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0.05],
				[0.06, 0],
				[1, 0],
				[1, 0.5],
				[0.9, 1],
				[0.08, 1],
			],
			roofW: 0.75,
			cupola: [0, -0.42],
			stowage: true,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.45,
			brake: 'none',
		},
		running: {
			kind: 'tracks',
			wheels: 6,
			wheelR: 0.26,
			span: 0.7,
			layout: 'paired',
			rollers: 3,
			sprocket: 'front',
		},
	},
}
