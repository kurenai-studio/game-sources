import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * IS-2 (1944): long hull with a straightened glacis, elongated cast turret, 122 mm D-25T with a double-baffle muzzle
 * brake.
 */
export const is2: TankDef = {
	id: 'is2',
	nation: 'ussr',
	role: 'heavy',
	name: 'ИС-2',
	hp: 1250,
	rating: 7,
	speed: 10,
	reverse: 4,
	accel: 2.6,
	hullTurn: 0.65,
	turretTurn: 0.6,
	gun: turretGun(122, 178, 390, 11.5, 0.43, 2.9, 780, -0.08, 0.3),
	armor: { front: 155, side: 90, rear: 60, top: 30, tFront: 110, tSide: 95, tRear: 90 },
	viewRange: 350,
	camo: 0.07,
	shape: {
		hullL: 6.8,
		hullW: 3.1,
		hullH: 1.1,
		trackH: 1.0,
		turret: true,
		tW: 2.6,
		tL: 3.0,
		tH: 0.9,
		tZ: 0.25,
		gunLen: 5.5,
		gunR: 0.08,
		openTop: false,
		hullLook: {
			outline: [
				[0.02, 0],
				[0.96, 0],
				[1, 0.15],
				[0.84, 1],
				[0.06, 1],
				[0, 0.5],
			],
			roofW: 0.88,
			lowerNose: 0.6,
			drums: 2,
		},
		turretLook: {
			kind: 'round',
			facets: 12,
			roofW: 0.78,
			bustle: 0.6,
			cupola: [0.25, -0.15],
			mountY: 0.45,
		},
		gunLook: {
			mantlet: 'round',
			mantletW: 0.5,
			brake: 'double',
		},
		running: {
			kind: 'tracks',
			wheels: 6,
			wheelR: 0.28,
			span: 0.76,
			rollers: 3,
			sprocket: 'rear',
		},
	},
}
