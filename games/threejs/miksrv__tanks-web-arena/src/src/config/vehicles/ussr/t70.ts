import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * T-70 (1942): GAZ light tank, welded faceted turret offset to the left, 45 mm gun, drive sprocket at the front.
 */
export const t70: TankDef = {
	id: 't70',
	nation: 'ussr',
	role: 'light',
	name: 'Т-70',
	hp: 420,
	rating: 2.5,
	speed: 13,
	reverse: 5,
	accel: 6,
	hullTurn: 1.3,
	turretTurn: 1.1,
	gun: turretGun(45, 62, 55, 2.4, 0.42, 1.6, 760),
	armor: { front: 50, side: 25, rear: 20, top: 15, tFront: 45, tSide: 30, tRear: 25 },
	viewRange: 400,
	camo: 0.28,
	shape: {
		hullL: 4.3,
		hullW: 2.3,
		hullH: 0.75,
		trackH: 0.75,
		turret: true,
		tW: 1.3,
		tL: 1.4,
		tH: 0.65,
		tZ: 0.3,
		gunLen: 2.0,
		gunR: 0.045,
		openTop: false,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.96, 0],
				[1, 0.38],
				[0.8, 0.92],
				[0.78, 1],
				[0.04, 1],
				[0, 0.55],
			],
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.88, 1],
				[0.1, 1],
			],
			roofW: 0.7,
			x: 0.25,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.35,
			brake: 'none',
		},
		running: {
			kind: 'tracks',
			wheels: 5,
			wheelR: 0.27,
			span: 0.72,
			rollers: 3,
			sprocket: 'front',
		},
	},
}
