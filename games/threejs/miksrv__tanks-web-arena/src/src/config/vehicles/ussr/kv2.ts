import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * KV-2 (1940): KV-1 hull under a huge, tall "barn" turret with a 152 mm M-10T howitzer.
 */
export const kv2: TankDef = {
	id: 'kv2',
	nation: 'ussr',
	role: 'heavy',
	name: 'КВ-2',
	hp: 1150,
	rating: 5,
	speed: 7.5,
	reverse: 3,
	accel: 2.2,
	hullTurn: 0.55,
	turretTurn: 0.4,
	gun: { ...turretGun(152, 75, 700, 20, 0.6, 3.6, 430, -0.08, 0.2), derp: true, splash: 5 },
	armor: { front: 95, side: 75, rear: 70, top: 30, tFront: 75, tSide: 75, tRear: 70 },
	viewRange: 330,
	camo: 0.04,
	shape: {
		hullL: 6.7,
		hullW: 3.3,
		hullH: 1.2,
		trackH: 1.0,
		turret: true,
		tW: 2.6,
		tL: 2.9,
		tH: 1.5,
		tZ: 0.35,
		gunLen: 3.3,
		gunR: 0.1,
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
				[0, 0],
				[1, 0],
				[1, 0.72],
				[0.9, 1],
				[0.02, 1],
				[0, 0.9],
			],
			roofW: 0.94,
			mountY: 0.42,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.42,
			brake: 'none',
			sleeve: 0.6,
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
