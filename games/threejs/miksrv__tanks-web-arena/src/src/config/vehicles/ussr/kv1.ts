import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * KV-1 (1941): tall box hull with a wedge-shaped nose, six road wheels with return rollers, welded turret with an
 * overhanging rear, 76 mm ZiS-5.
 */
export const kv1: TankDef = {
	id: 'kv1',
	nation: 'ussr',
	role: 'heavy',
	name: 'КВ-1',
	hp: 1100,
	rating: 4.5,
	speed: 8.5,
	reverse: 3.5,
	accel: 2.4,
	hullTurn: 0.6,
	turretTurn: 0.55,
	gun: turretGun(76, 90, 115, 4.2, 0.42, 2.6, 680),
	armor: { front: 95, side: 75, rear: 70, top: 30, tFront: 95, tSide: 75, tRear: 75 },
	viewRange: 340,
	camo: 0.07,
	shape: {
		hullL: 6.7,
		hullW: 3.3,
		hullH: 1.2,
		trackH: 1.0,
		turret: true,
		tW: 2.3,
		tL: 2.7,
		tH: 0.85,
		tZ: 0.35,
		gunLen: 3.4,
		gunR: 0.055,
		openTop: false,
		hullLook: {
			outline: [
				[0.04, 0],
				[0.95, 0],
				[1, 0.3],
				[0.92, 0.62],
				[0.9, 1],
				[0.03, 1],
				[0, 0.62],
			],
			lowerNose: 0.4,
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0.3],
				[0.12, 0],
				[1, 0],
				[1, 0.82],
				[0.92, 1],
				[0.04, 1],
			],
			roofW: 0.78,
			mountY: 0.45,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.38,
			brake: 'none',
		},
		running: {
			kind: 'tracks',
			wheels: 6,
			wheelR: 0.3,
			span: 0.76,
			rollers: 3,
			sprocket: 'rear',
		},
	},
}
