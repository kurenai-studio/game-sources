import { casemateGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * StuH 42 (1943): StuG III casemate with a short, thick 105 mm howitzer with a muzzle brake in a "Saukopf" mantlet.
 */
export const stuh42: TankDef = {
	id: 'stuh42',
	nation: 'germany',
	role: 'td',
	name: 'StuH 42',
	hp: 760,
	rating: 4.5,
	speed: 11,
	reverse: 4.5,
	accel: 4.2,
	hullTurn: 0.95,
	turretTurn: 0.55,
	gun: { ...casemateGun(105, 64, 380, 9, 0.5, 2.6, 470, 0.18), derp: true, splash: 4 },
	armor: { front: 80, side: 30, rear: 30, top: 16, tFront: 80, tSide: 30, tRear: 30 },
	viewRange: 360,
	camo: 0.3,
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
		gunLen: 2.4,
		gunR: 0.09,
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
