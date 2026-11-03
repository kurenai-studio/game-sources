import { casemateGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Ferdinand (1943): long hull with a vertical 200 mm front, huge casemate at the rear, Porsche road wheels on bogies,
 * drive sprocket at the rear, 88 mm Pak 43/2.
 */
export const ferdinand: TankDef = {
	id: 'ferdinand',
	nation: 'germany',
	role: 'td',
	name: 'Ferdinand',
	hp: 1400,
	rating: 7,
	speed: 7,
	reverse: 3,
	accel: 2,
	hullTurn: 0.5,
	turretTurn: 0.35,
	gun: casemateGun(88, 200, 245, 7.2, 0.3, 2.3, 1000, 0.24),
	armor: { front: 200, side: 80, rear: 80, top: 30, tFront: 200, tSide: 80, tRear: 80 },
	viewRange: 350,
	camo: 0.05,
	shape: {
		hullL: 6.8,
		hullW: 3.4,
		hullH: 1.15,
		trackH: 1.0,
		turret: false,
		tW: 3.0,
		tL: 3.2,
		tH: 1.3,
		tZ: -1.6,
		gunLen: 6.0,
		gunR: 0.07,
		openTop: false,
		hullLook: {
			outline: [
				[0.01, 0],
				[0.97, 0],
				[1, 0.4],
				[0.99, 1],
				[0.01, 1],
				[0, 0.6],
			],
			lowerNose: 0.3,
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.85, 1],
				[0.08, 1],
				[0, 0.5],
			],
			roofW: 0.78,
			mountY: 0.5,
		},
		gunLook: {
			mantlet: 'ball',
			brake: 'double',
		},
		running: {
			kind: 'tracks',
			wheels: 6,
			wheelR: 0.4,
			span: 0.72,
			layout: 'paired',
			sprocket: 'rear',
		},
	},
}
