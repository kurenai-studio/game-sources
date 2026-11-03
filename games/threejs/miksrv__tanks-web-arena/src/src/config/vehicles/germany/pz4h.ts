import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Pz. IV H (1943): stepped front with spare track links, eight road wheels on bogies, side skirts on the hull and
 * around the turret, 75 mm KwK 40 L/48 with a double-baffle muzzle brake.
 */
export const pz4h: TankDef = {
	id: 'pz4h',
	nation: 'germany',
	role: 'medium',
	name: 'Pz. IV H',
	hp: 720,
	rating: 4.5,
	speed: 11.5,
	reverse: 4.5,
	accel: 4,
	hullTurn: 0.95,
	turretTurn: 0.85,
	gun: turretGun(75, 118, 140, 4.3, 0.36, 2.0, 790),
	armor: { front: 85, side: 35, rear: 25, top: 20, tFront: 55, tSide: 35, tRear: 30 },
	viewRange: 390,
	camo: 0.14,
	shape: {
		hullL: 5.9,
		hullW: 2.9,
		hullH: 1.0,
		trackH: 0.85,
		turret: true,
		tW: 2.1,
		tL: 2.3,
		tH: 0.8,
		tZ: 0.25,
		gunLen: 3.6,
		gunR: 0.06,
		openTop: false,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.96, 0],
				[1, 0.32],
				[0.88, 0.5],
				[0.87, 1],
				[0.03, 1],
				[0, 0.58],
			],
			spareTracks: true,
			skirts: true,
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[1, 0.4],
				[0.86, 1],
				[0.1, 1],
				[0, 0.6],
			],
			roofW: 0.72,
			cupola: [0, -0.4],
			stowage: true,
			skirts: true,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.38,
			brake: 'double',
		},
		running: {
			kind: 'tracks',
			wheels: 8,
			wheelR: 0.235,
			span: 0.76,
			layout: 'paired',
			rollers: 4,
			sprocket: 'front',
		},
	},
}
