import { autocannon } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Pz. II F (1941): stepped front, five road wheels on leaf springs with four return rollers, small turret with a
 * commander's cupola, 20 mm KwK 30.
 */
export const pz2f: TankDef = {
	id: 'pz2f',
	nation: 'germany',
	role: 'light',
	name: 'Pz. II F',
	hp: 330,
	rating: 2,
	speed: 11,
	reverse: 4.5,
	accel: 6,
	hullTurn: 1.35,
	turretTurn: 1.3,
	gun: autocannon(20, 35, 14, 0.55, 0.48, 1.2, 780),
	armor: { front: 35, side: 20, rear: 15, top: 10, tFront: 30, tSide: 15, tRear: 15 },
	viewRange: 380,
	camo: 0.32,
	shape: {
		hullL: 4.6,
		hullW: 2.2,
		hullH: 0.75,
		trackH: 0.75,
		turret: true,
		tW: 1.3,
		tL: 1.3,
		tH: 0.6,
		tZ: 0.25,
		gunLen: 1.3,
		gunR: 0.03,
		openTop: false,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.96, 0],
				[1, 0.3],
				[0.86, 0.48],
				[0.85, 1],
				[0.03, 1],
				[0, 0.6],
			],
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.92, 1],
				[0.08, 1],
			],
			roofW: 0.78,
			cupola: [0, -0.15],
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.45,
			brake: 'none',
		},
		running: {
			kind: 'tracks',
			wheels: 5,
			wheelR: 0.28,
			span: 0.66,
			rollers: 4,
			sprocket: 'front',
		},
	},
}
