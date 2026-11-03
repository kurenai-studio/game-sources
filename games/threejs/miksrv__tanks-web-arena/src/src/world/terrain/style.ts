import {
	ARCHETYPES,
	BUILDING_KIT,
	FLORA,
	MATCH,
	WEATHER_ODDS,
	type Archetype,
	type BattleMode,
	type Weather,
} from '../../config'
import { mulberry32 } from '../../core/noise'
import type { BuildingKit, Features, Flora, Relief, Rnd, Season } from './types'

// The rolls that decide what a map is like: season, relief, features, archetype, weather and battle mode.

/** Season, relief style and feature mix of a map, drawn from its RNG. */
export function rollStyle(r: Rnd) {
	const sr = r()
	const season: Season = sr < 0.5 ? 'summer' : sr < 0.75 ? 'autumn' : 'winter'
	const rr = r()
	const relief: Relief = rr < 0.4 ? 'rolling' : rr < 0.6 ? 'plains' : rr < 0.8 ? 'ridges' : 'valley'
	const ob = r()
	const features: Omit<Features, 'revetments'> = {
		alleys: r() < 0.5,
		bunkers: r() < 0.5,
		obstacles: ob < 0.4 ? 'hedgehogs' : ob < 0.65 ? 'teeth' : 'none',
		windmill: r() < 0.45,
		farms: r() < 0.65,
	}
	return { season, relief, features }
}

/** A key by its weight (the weights add up to 1). */
export function weighted<K extends string>(r: number, odds: Partial<Record<K, number>>, fallback: K): K {
	let acc = 0
	for (const [k, p] of Object.entries(odds) as [K, number][]) {
		acc += p
		if (r < acc) return k
	}
	return fallback
}

/** Weather and the battle mode come from their own RNG streams, so they never shift the layout of a seed. */
export const rollWeather = (seed: number, season: Season): Weather =>
	weighted(mulberry32(seed * 104729 + 71)(), WEATHER_ODDS[season], 'clear')
export const rollMode = (seed: number): BattleMode =>
	weighted(mulberry32(seed * 7907 + 3)(), MATCH.modeOdds, 'standard')
export const ARCHETYPE_ODDS = Object.fromEntries(Object.entries(ARCHETYPES).map(([k, a]) => [k, a.weight])) as Record<
	Archetype,
	number
>

/** The relief an archetype is built on (classic and coast maps keep the rolled one). */
export function archetypeRelief(a: Archetype, rolled: Relief): Relief {
	if (a === 'steppe') return 'steppe'
	if (a === 'pass') return 'pass'
	if (a === 'swamp') return 'plains'
	if (a === 'coast' && rolled === 'valley') return 'rolling'
	return rolled
}

/** Tree species of a map, from a stream of their own: one per role, so a map has two to four of them. */
export function rollFlora(seed: number, archetype: Archetype): Flora {
	const r = mulberry32(seed * 48271 + 29)
	const def = FLORA[archetype]
	const conifer = weighted(r(), def.conifer, 'pine')
	const leafy = weighted(r(), def.leafy, 'linden')
	const willow = r() < def.willow
	// Willows take the place of a separate alley species: at most three besides the orchards' apples
	const alley = willow ? leafy : weighted(r(), def.alley, leafy)
	const coniferShare = def.coniferShare[0] + r() * (def.coniferShare[1] - def.coniferShare[0])
	return { conifer, leafy, alley, waterside: willow ? 'willow' : null, coniferShare }
}

/** Building variants of a map, from a stream of their own. */
export function rollKit(seed: number): BuildingKit {
	const r = mulberry32(seed * 69621 + 47)
	const [b0, b1] = BUILDING_KIT.brickShare
	return {
		chapel: r() < BUILDING_KIT.chapel,
		brick: r() < BUILDING_KIT.brickHouses ? b0 + r() * (b1 - b0) : 0,
		warehouse: r() < BUILDING_KIT.warehouse,
		waterTower: r() < BUILDING_KIT.waterTower,
	}
}
