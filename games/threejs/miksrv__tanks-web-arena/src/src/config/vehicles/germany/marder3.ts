import { casemateGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Marder III (Sd.Kfz. 139, 1942): Pz. 38(t) chassis with four large road wheels, tall open casemate with the shield of
 * a captured 76 mm Pak 36(r).
 */
export const marder3: TankDef = {
	id: 'marder3',
	nation: 'germany',
	role: 'td',
	name: 'Marder III',
	hp: 420,
	rating: 4,
	speed: 12,
	reverse: 4.5,
	accel: 5,
	hullTurn: 1.1,
	turretTurn: 0.5,
	gun: casemateGun(76, 125, 160, 5.0, 0.34, 1.9, 740, 0.28),
	armor: { front: 25, side: 12, rear: 10, top: 5, tFront: 15, tSide: 10, tRear: 8 },
	viewRange: 370,
	camo: 0.36,
	shape: {
		hullL: 4.6,
		hullW: 2.2,
		hullH: 0.75,
		trackH: 0.75,
		turret: false,
		tW: 2.1,
		tL: 2.0,
		tH: 1.0,
		tZ: -0.1,
		gunLen: 3.4,
		gunR: 0.05,
		openTop: true,
		hullLook: {
			outline: [
				[0.03, 0],
				[0.96, 0],
				[1, 0.32],
				[0.88, 0.55],
				[0.87, 1],
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
				[0.12, 1],
				[0, 0.5],
			],
			roofW: 0.86,
			mountY: 0.7,
		},
		gunLook: {
			mantlet: 'shield',
			mantletW: 0.55,
			brake: 'double',
		},
		running: {
			kind: 'tracks',
			wheels: 4,
			wheelR: 0.39,
			span: 0.55,
			rollers: 2,
			sprocket: 'front',
		},
	},
}
