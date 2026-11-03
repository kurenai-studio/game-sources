import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Panther D (1943): long sloped glacis and sloped sides, interleaved road wheels, side skirts, turret set forward,
 * rounded mantlet, 75 mm KwK 42 L/70.
 */
export const panther: TankDef = {
	id: 'panther',
	nation: 'germany',
	role: 'medium',
	name: 'Panther D',
	hp: 1000,
	rating: 6.5,
	speed: 13,
	reverse: 4.5,
	accel: 3.6,
	hullTurn: 0.85,
	turretTurn: 0.7,
	gun: turretGun(75, 170, 140, 5.0, 0.3, 2.0, 925),
	armor: { front: 135, side: 45, rear: 40, top: 20, tFront: 100, tSide: 45, tRear: 45 },
	viewRange: 390,
	camo: 0.1,
	shape: {
		hullL: 6.9,
		hullW: 3.3,
		hullH: 1.05,
		trackH: 0.95,
		turret: true,
		tW: 2.4,
		tL: 2.8,
		tH: 0.85,
		tZ: 0.4,
		gunLen: 5.3,
		gunR: 0.06,
		openTop: false,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.97, 0],
				[1, 0.06],
				[0.74, 1],
				[0.05, 1],
				[0, 0.55],
			],
			roofW: 0.78,
			lowerNose: 0.6,
			skirts: true,
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.94, 1],
				[0.1, 1],
				[0, 0.35],
			],
			roofW: 0.68,
			cupola: [0.27, -0.25],
		},
		gunLook: {
			mantlet: 'round',
			mantletW: 0.45,
			brake: 'double',
		},
		running: {
			kind: 'tracks',
			wheels: 8,
			wheelR: 0.43,
			span: 0.8,
			layout: 'interleaved',
			sprocket: 'front',
		},
	},
}
