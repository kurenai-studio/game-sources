import type { Nation, TankDef } from '../types'
import { GERMANY_TANKS } from './germany'
import { USSR_TANKS } from './ussr'

// One file per vehicle (`ussr/t34_85.ts`, `germany/tiger.ts`, …) holds its numbers and its silhouette. To add a
// vehicle, copy the closest one, give it a new id and list it in its nation's `index.ts`.

export const TANKS: Record<string, TankDef> = Object.fromEntries(
	[...USSR_TANKS, ...GERMANY_TANKS].map((d) => [d.id, d]),
)
export const TANK_IDS = Object.keys(TANKS)
export const tanksOf = (n: Nation) => TANK_IDS.filter((id) => TANKS[id].nation === n)
