import { turretGun } from '../../guns'
import type { TankDef } from '../../types'

/**
 * Pz.Kpfw. KV-1 753(r): captured KV-1 in German service (1942–43), rearmed with a 75 mm KwK 40 L/48 with a muzzle
 * brake, with a commander's cupola. Hull and armour as on the Soviet KV-1; German optics see slightly farther.
 */
export const kv1r: TankDef = {
	id: 'kv1r',
	nation: 'germany',
	role: 'heavy',
	name: 'KV-1 753(r)',
	hp: 1100,
	rating: 4.5,
	speed: 8.5,
	reverse: 3.5,
	accel: 2.4,
	hullTurn: 0.6,
	turretTurn: 0.55,
	gun: turretGun(75, 118, 140, 4.4, 0.38, 2.3, 790),
	armor: { front: 95, side: 75, rear: 70, top: 30, tFront: 95, tSide: 75, tRear: 75 },
	viewRange: 350,
	camo: 0.07,
	shape: {
		hullL: 6.7,
		hullW: 3.3,
		hullH: 1.2,
		trackH: 1.0,
		turret: true,
		tW: 2.3,
		tL: 2.7,
		tH: 0.85,
		tZ: 0.35,
		gunLen: 3.7,
		gunR: 0.05,
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
				[0, 0.3],
				[0.12, 0],
				[1, 0],
				[1, 0.82],
				[0.92, 1],
				[0.04, 1],
			],
			roofW: 0.78,
			mountY: 0.45,
			cupola: [0.2, -0.3],
		},
		gunLook: {
			mantlet: 'box',
			mantletW: 0.38,
			brake: 'double',
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
