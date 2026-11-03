import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Pz. II Luchs (1943): full-width superstructure over the tracks, large interleaved road wheels, wide welded turret
 * without a commander's cupola.
 */
export const luchs: TankDef = {
	id: 'luchs',
	nation: 'germany',
	role: 'light',
	name: 'Pz. II Luchs',
	hp: 400,
	rating: 2.5,
	speed: 16,
	reverse: 6,
	accel: 6.5,
	hullTurn: 1.4,
	turretTurn: 1.2,
	gun: turretGun(50, 72, 70, 2.7, 0.39, 1.5, 835),
	armor: { front: 35, side: 25, rear: 20, top: 15, tFront: 35, tSide: 25, tRear: 20 },
	viewRange: 410,
	camo: 0.26,
	shape: {
		hullL: 4.6,
		hullW: 2.5,
		hullH: 0.8,
		trackH: 0.8,
		turret: true,
		tW: 1.7,
		tL: 1.6,
		tH: 0.7,
		tZ: 0.25,
		gunLen: 2.5,
		gunR: 0.04,
		openTop: false,
		hullLook: {
			outline: [
				[0.02, 0],
				[0.96, 0],
				[1, 0.32],
				[0.88, 0.55],
				[0.86, 1],
				[0.03, 1],
				[0, 0.55],
			],
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.94, 1],
				[0.07, 1],
				[0, 0.5],
			],
			roofW: 0.82,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.42,
			brake: 'none',
		},
		running: {
			kind: 'tracks',
			wheels: 5,
			wheelR: 0.37,
			span: 0.7,
			layout: 'interleaved',
			sprocket: 'front',
		},
	},
}
