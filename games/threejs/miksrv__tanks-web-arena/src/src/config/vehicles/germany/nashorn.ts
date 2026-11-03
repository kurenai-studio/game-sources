import { casemateGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Nashorn (1943): GW III/IV chassis, tall open casemate with sloped sides, very long 88 mm Pak 43/1 L/71.
 */
export const nashorn: TankDef = {
	id: 'nashorn',
	nation: 'germany',
	role: 'td',
	name: 'Nashorn',
	hp: 620,
	rating: 6,
	speed: 12,
	reverse: 4.5,
	accel: 4,
	hullTurn: 0.9,
	turretTurn: 0.45,
	gun: casemateGun(88, 200, 245, 7.5, 0.3, 2.1, 1000, 0.26),
	armor: { front: 30, side: 20, rear: 20, top: 5, tFront: 15, tSide: 10, tRear: 10 },
	viewRange: 380,
	camo: 0.3,
	shape: {
		hullL: 6.2,
		hullW: 2.9,
		hullH: 0.85,
		trackH: 0.85,
		turret: false,
		tW: 2.7,
		tL: 3.4,
		tH: 1.2,
		tZ: -1.1,
		gunLen: 6.4,
		gunR: 0.07,
		openTop: true,
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
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.9, 1],
				[0.03, 1],
			],
			roofW: 0.82,
			mountY: 0.6,
		},
		gunLook: {
			mantlet: 'shield',
			mantletW: 0.35,
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
