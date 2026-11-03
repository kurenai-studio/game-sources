import type * as THREE from 'three'
import { MAP_PRESETS, type Archetype, type BattleMode, type Weather } from '../config'
import type { Hud } from '../hud'
import { Buildings } from '../world/buildings'
import { Props } from '../world/props'
import { Terrain, type MapSpec } from '../world/terrain'

/** Everything generated for one map; built off-screen so the next round can start without a hitch. */
export interface GeneratedMap {
	terrain: Terrain
	props: Props
	buildings: Buildings
	minimap: HTMLCanvasElement
	/** The garage choice it was made for (a new choice means a new map). */
	key: string
}

/** The garage's map and battle mode choice: a preset id or 'random', a mode or 'random'. */
export interface MapChoice {
	map: string
	mode: BattleMode | 'random'
}

/** What the next map must be, from the garage choice and the test hooks' forced values (those win). */
export interface MapRequest {
	seed: number | null
	spec: MapSpec
	key: string
}

/** Forced values from the test hooks (null = not forced). */
interface Forced {
	archetype: Archetype | null
	weather: Weather | null
	mode: BattleMode | null
}

export function mapRequest(choice: MapChoice, forced: Forced, testSeed: number | null): MapRequest {
	const p = MAP_PRESETS.find((m) => m.id === choice.map)
	const spec: MapSpec = {
		archetype: forced.archetype ?? p?.archetype,
		season: p?.season,
		weather: forced.weather ?? p?.weather,
		mode: forced.mode ?? (choice.mode === 'random' ? undefined : choice.mode),
	}
	return { seed: testSeed ?? p?.seed ?? null, spec, key: mapKey(choice) }
}

/** Maps made for the same choice share this key. */
export const mapKey = (c: MapChoice) => `${c.map}|${c.mode}`

/** Generate a map (~0.2 s). A random seed unless the request names one. */
export function generateMap(hud: Hud, req: MapRequest): GeneratedMap {
	const terrain = new Terrain(req.seed ?? Math.floor(Math.random() * 1e6), req.spec)
	const minimap = hud.bakeMap(terrain)
	return { terrain, props: new Props(terrain), buildings: new Buildings(terrain), minimap, key: req.key }
}

export function disposeMap(map: GeneratedMap) {
	map.props.dispose()
	map.buildings.dispose()
	for (const m of [map.terrain.mesh, map.terrain.water]) {
		m.geometry.dispose()
		;(m.material as THREE.Material).dispose()
	}
}
