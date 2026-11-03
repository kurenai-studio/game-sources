import { casemateGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * StuG III G (1943): Pz. III chassis, low casemate with a sloped front, commander's cupola on the left, "Saukopf"
 * mantlet, side skirts.
 */
export const stug3: TankDef = {
	id: 'stug3',
	nation: 'germany',
	role: 'td',
	name: 'StuG III G',
	hp: 780,
	rating: 4.5,
	speed: 11,
	reverse: 4.5,
	accel: 4.2,
	hullTurn: 0.95,
	turretTurn: 0.55,
	gun: casemateGun(75, 118, 140, 4.0, 0.32, 1.8, 790, 0.18),
	armor: { front: 95, side: 35, rear: 30, top: 18, tFront: 95, tSide: 35, tRear: 30 },
	viewRange: 370,
	camo: 0.32,
	shape: {
		hullL: 5.5,
		hullW: 2.9,
		hullH: 0.85,
		trackH: 0.85,
		turret: false,
		tW: 2.7,
		tL: 2.65,
		tH: 0.6,
		tZ: 0.65,
		gunLen: 3.6,
		gunR: 0.06,
		openTop: false,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.96, 0],
				[1, 0.32],
				[0.87, 0.5],
				[0.86, 1],
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
				[1, 0.3],
				[0.8, 1],
				[0.05, 1],
				[0, 0.75],
			],
			roofW: 0.86,
			cupola: [0.3, -0.15],
			mountY: 0.4,
		},
		gunLook: {
			mantlet: 'saukopf',
			brake: 'double',
		},
		running: {
			kind: 'tracks',
			wheels: 6,
			wheelR: 0.26,
			span: 0.7,
			layout: 'paired',
			rollers: 3,
			sprocket: 'front',
		},
	},
}
