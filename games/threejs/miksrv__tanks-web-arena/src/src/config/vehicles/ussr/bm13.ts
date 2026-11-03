import { rockets } from '../../guns'
import type { TankDef } from '../../types'

/**
 * BM-13 Katyusha (1941): three-axle ZiS-6 with a long bonnet, a cab and a pack of eight launch rails above it.
 */
export const bm13: TankDef = {
	id: 'bm13',
	nation: 'ussr',
	role: 'spg',
	name: 'БМ-13 «Катюша»',
	hp: 300,
	rating: 4,
	speed: 16,
	reverse: 5,
	accel: 5,
	hullTurn: 1.0,
	turretTurn: 0.4,
	gun: rockets(132, 130, 28, 1.4, 4.5, 4.5, 0.17, 16),
	armor: { front: 10, side: 8, rear: 8, top: 3, tFront: 8, tSide: 6, tRear: 6 },
	viewRange: 320,
	camo: 0.22,
	shape: {
		hullL: 6.4,
		hullW: 2.3,
		hullH: 0.67,
		trackH: 0.95,
		turret: false,
		tW: 2.0,
		tL: 2.0,
		tH: 0.9,
		tZ: -2.8,
		gunLen: 3.6,
		gunR: 0.07,
		openTop: true,
		launcher: 'rails',
		hullLook: {
			outline: [
				[0, 0],
				[1, 0],
				[1, 1],
				[0, 1],
			],
		},
		running: {
			kind: 'truck',
			wheels: 3,
			wheelR: 0.45,
			axles: [0.31, -0.2, -0.37],
		},
	},
}
