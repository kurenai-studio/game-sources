import { autocannon } from '../../guns'
import type { TankDef } from '../../types'

/**
 * T-60 (1941): small tank with an octagonal turret offset to the left and a 20 mm TNSh gun.
 */
export const t60: TankDef = {
	id: 't60',
	nation: 'ussr',
	role: 'light',
	name: 'Т-60',
	hp: 340,
	rating: 2,
	speed: 12,
	reverse: 5,
	accel: 6.5,
	hullTurn: 1.4,
	turretTurn: 1.3,
	gun: autocannon(20, 35, 14, 0.55, 0.5, 1.2, 815),
	armor: { front: 35, side: 15, rear: 15, top: 10, tFront: 25, tSide: 15, tRear: 15 },
	viewRange: 390,
	camo: 0.34,
	shape: {
		hullL: 4.1,
		hullW: 2.3,
		hullH: 0.65,
		trackH: 0.7,
		turret: true,
		tW: 1.1,
		tL: 1.2,
		tH: 0.6,
		tZ: 0.3,
		gunLen: 1.3,
		gunR: 0.03,
		openTop: false,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.95, 0],
				[1, 0.35],
				[0.78, 0.8],
				[0.74, 1],
				[0.04, 1],
				[0, 0.55],
			],
		},
		turretLook: {
			kind: 'round',
			facets: 8,
			roofW: 0.8,
			x: 0.25,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.4,
			brake: 'none',
		},
		running: {
			kind: 'tracks',
			wheels: 4,
			wheelR: 0.25,
			span: 0.62,
			rollers: 3,
			sprocket: 'front',
		},
	},
}
