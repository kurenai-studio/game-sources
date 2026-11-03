import type { AmmoDef, AmmoId } from './types'

// Shells: multipliers on the gun's stock values. Howitzers treat HE as stock and AP as the alternative.
export const AMMO: Record<AmmoId, AmmoDef> = {
	ap: {
		id: 'ap',
		label: 'ББ',
		key: '1',
		penMult: 1,
		dmgMult: 1,
		speedMult: 1,
		normalization: 0.087,
		ricochet: 1.22,
		he: false,
		count: Infinity,
	},
	apcr: {
		id: 'apcr',
		label: 'ПК',
		key: '2',
		penMult: 1.32,
		dmgMult: 0.88,
		speedMult: 1.25,
		normalization: 0.035,
		ricochet: 1.22,
		he: false,
		count: 12,
	},
	he: {
		id: 'he',
		label: 'ОФ',
		key: '3',
		penMult: 0.3,
		dmgMult: 1.45,
		speedMult: 0.85,
		normalization: 0,
		ricochet: 9,
		he: true,
		count: Infinity,
	},
}
export const AMMO_IDS = Object.keys(AMMO) as AmmoId[]
