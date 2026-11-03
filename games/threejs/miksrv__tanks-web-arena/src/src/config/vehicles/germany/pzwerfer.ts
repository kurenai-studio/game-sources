import { rockets } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Panzerwerfer 42 (1943): armoured Maultier half-track — wheels at the front, tracks at the rear, a ten-barrel
 * Nebelwerfer on the roof.
 */
export const pzwerfer: TankDef = {
	id: 'pzwerfer',
	nation: 'germany',
	role: 'spg',
	name: 'Panzerwerfer 42',
	hp: 320,
	rating: 4,
	speed: 14,
	reverse: 4.5,
	accel: 4.5,
	hullTurn: 1.0,
	turretTurn: 0.4,
	gun: rockets(150, 200, 32, 1.5, 4.8, 5.5, 0.22, 10),
	armor: { front: 10, side: 8, rear: 8, top: 8, tFront: 8, tSide: 8, tRear: 8 },
	viewRange: 320,
	camo: 0.22,
	shape: {
		hullL: 6.0,
		hullW: 2.3,
		hullH: 1.25,
		trackH: 0.7,
		turret: false,
		tW: 2.0,
		tL: 2.0,
		tH: 0.7,
		tZ: -0.9,
		gunLen: 2.3,
		gunR: 0.09,
		openTop: false,
		launcher: 'tubes',
		hullLook: {
			outline: [
				[0.02, 0],
				[0.97, 0],
				[1, 0.25],
				[0.95, 0.45],
				[0.72, 0.62],
				[0.64, 1],
				[0.03, 1],
				[0, 0.55],
			],
			roofW: 0.82,
		},
		running: {
			kind: 'halftrack',
			wheels: 4,
			wheelR: 0.22,
			frontAxle: 0.33,
			sprocket: 'front',
		},
	},
}
