import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Tiger I (1943): rectangular hull with a vertical front, superstructure over the tracks, interleaved road wheels,
 * horseshoe-shaped turret with a wide mantlet, 88 mm KwK 36.
 */
export const tiger: TankDef = {
	id: 'tiger',
	nation: 'germany',
	role: 'heavy',
	name: 'Tiger I',
	hp: 1200,
	rating: 6.5,
	speed: 10.5,
	reverse: 4,
	accel: 2.8,
	hullTurn: 0.7,
	turretTurn: 0.55,
	gun: turretGun(88, 150, 245, 7.2, 0.33, 2.2, 810, -0.14, 0.28),
	armor: { front: 105, side: 82, rear: 82, top: 30, tFront: 110, tSide: 82, tRear: 82, lowerFront: 100 },
	viewRange: 370,
	camo: 0.06,
	shape: {
		hullL: 6.3,
		hullW: 3.5,
		hullH: 1.25,
		trackH: 1.0,
		turret: true,
		tW: 2.6,
		tL: 2.8,
		tH: 0.9,
		tZ: 0.25,
		gunLen: 5.0,
		gunR: 0.07,
		openTop: false,
		hullLook: {
			outline: [
				[0.01, 0],
				[0.97, 0],
				[1, 0.32],
				[0.92, 0.45],
				[0.92, 1],
				[0.01, 1],
				[0, 0.55],
			],
		},
		turretLook: {
			kind: 'round',
			facets: 12,
			roofW: 1,
			cupola: [0.28, -0.25],
			stowage: true,
			sideTracks: true,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.72,
			brake: 'double',
		},
		running: {
			kind: 'tracks',
			wheels: 8,
			wheelR: 0.4,
			span: 0.78,
			layout: 'interleaved',
			sprocket: 'front',
		},
	},
}
