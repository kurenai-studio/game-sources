import { casemateGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * SU-152 (1943): KV-1S chassis with a large casemate, 152 mm ML-20S with a long recoil-cylinder armour jacket and a
 * slotted muzzle brake.
 */
export const su152: TankDef = {
	id: 'su152',
	nation: 'ussr',
	role: 'td',
	name: 'СУ-152',
	hp: 950,
	rating: 6,
	speed: 9.5,
	reverse: 4,
	accel: 3,
	hullTurn: 0.7,
	turretTurn: 0.4,
	gun: { ...casemateGun(152, 125, 700, 16, 0.55, 3.4, 600, 0.17), splash: 5 },
	armor: { front: 75, side: 60, rear: 60, top: 25, tFront: 75, tSide: 60, tRear: 60 },
	viewRange: 340,
	camo: 0.2,
	shape: {
		hullL: 6.7,
		hullW: 3.3,
		hullH: 1.1,
		trackH: 1.0,
		turret: false,
		tW: 3.1,
		tL: 3.4,
		tH: 0.95,
		tZ: 0.95,
		gunLen: 4.4,
		gunR: 0.1,
		openTop: false,
		hullLook: {
			outline: [
				[0.04, 0],
				[0.95, 0],
				[1, 0.3],
				[0.92, 0.62],
				[0.9, 1],
				[0.03, 1],
				[0, 0.62],
			],
			lowerNose: 0.4,
		},
		turretLook: {
			kind: 'welded',
			outline: [
				[0, 0],
				[1, 0],
				[0.86, 1],
				[0.05, 1],
				[0, 0.6],
			],
			roofW: 0.8,
			mountY: 0.42,
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.32,
			brake: 'multi',
			sleeve: 1.1,
		},
		running: {
			kind: 'tracks',
			wheels: 6,
			wheelR: 0.3,
			span: 0.76,
			rollers: 3,
			sprocket: 'rear',
		},
	},
}
