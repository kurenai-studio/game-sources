// World size and map generation. Units: metres.

export const WORLD_HALF = 450 // playable area is [-450, 450] on X and Z (900 × 900 m)
export const TERRAIN_RES = 256 // heightmap resolution (≈ 3.5 m per cell)
export const GRAVITY = 9.8

export const WORLD = {
	hills: 17, // m amplitude of rolling terrain (each map scales it 0.75–1.2)
	maxSlope: 0.3, // steepest natural slope (rise/run ≈ 17°): anything steeper is levelled off into plateaus and basins
	detail: 2, // m amplitude of the small bumps on top of the hills
	mountainBand: 110, // m from the edge where the terrain climbs into mountains
	mountainHeight: 70,
	rocks: 70,
	// Forest, village, lake, bush and haystack counts and the river chance are per archetype (ARCHETYPES)
	riverWidth: [14, 26] as const, // m, bed width range of the meandering stream
	bridges: [3, 4] as const, // bridges on a map with a river — never fewer than three
	fordsMax: 2, // extra shallow crossings
	bridgeWidth: 11, // m, deck width
	bridgeRamp: [60, 110] as const, // m, embankment from each deck end up to the natural ground: longer for a higher bank
}

/** What kind of country a map is: each archetype sets its own layout numbers, relief and seasons. */
export type Archetype = 'classic' | 'steppe' | 'swamp' | 'pass' | 'coast'

export interface ArchetypeDef {
	label: string
	weight: number // share of random maps
	seasons: { summer: number; autumn: number; winter: number }
	riverChance: number
	forests: readonly [number, number]
	villages: readonly [number, number]
	lakes: readonly [number, number] // on a map with a river
	lakesDry: readonly [number, number] // on a map without one
	bogs: readonly [number, number] // shallow marsh pools (passable, slow); roads cross them on causeways
	railway: number // chance of a railway embankment on a map without a river
	haystacks: number
	bushClusters: number
	/** Field / meadow split override (low = mostly fields), or null for the map's own roll. */
	fields: number | null
}

export const ARCHETYPES: Record<Archetype, ArchetypeDef> = {
	classic: {
		label: 'средняя полоса',
		weight: 0.44,
		seasons: { summer: 0.5, autumn: 0.25, winter: 0.25 },
		riverChance: 0.5,
		forests: [7, 12],
		villages: [1, 3],
		lakes: [0, 2],
		lakesDry: [1, 3],
		bogs: [0, 0],
		railway: 0.3,
		haystacks: 35,
		bushClusters: 60,
		fields: null,
	},
	steppe: {
		label: 'степь',
		weight: 0.16,
		seasons: { summer: 0.6, autumn: 0.28, winter: 0.12 },
		riverChance: 0.3,
		forests: [1, 4],
		villages: [2, 3],
		lakes: [0, 1],
		lakesDry: [0, 1],
		bogs: [0, 0],
		railway: 0.9,
		haystacks: 70,
		bushClusters: 45,
		fields: -0.35,
	},
	swamp: {
		label: 'болота',
		weight: 0.14,
		seasons: { summer: 0.45, autumn: 0.45, winter: 0.1 },
		riverChance: 0.45,
		forests: [11, 16],
		villages: [1, 2],
		lakes: [0, 1],
		lakesDry: [0, 1],
		bogs: [5, 8],
		railway: 0,
		haystacks: 12,
		bushClusters: 85,
		fields: 0.2,
	},
	pass: {
		label: 'перевал',
		weight: 0.12,
		seasons: { summer: 0.35, autumn: 0.25, winter: 0.4 },
		riverChance: 0,
		forests: [6, 10],
		villages: [1, 2],
		lakes: [0, 0],
		lakesDry: [0, 1],
		bogs: [0, 0],
		railway: 0,
		haystacks: 20,
		bushClusters: 60,
		fields: null,
	},
	coast: {
		label: 'побережье',
		weight: 0.14,
		seasons: { summer: 0.6, autumn: 0.3, winter: 0.1 },
		riverChance: 0.5,
		forests: [5, 9],
		villages: [1, 3],
		lakes: [0, 1],
		lakesDry: [1, 2],
		bogs: [0, 0],
		railway: 0.25,
		haystacks: 30,
		bushClusters: 60,
		fields: null,
	},
}

/** Coast maps: one flank (across the base axis) runs down to the sea. Distances from the map's middle line, m. */
export const COAST = {
	start: 240, // the ground starts to fall toward the sea
	sea: 330, // and is sea bed from here
	depth: -6.5, // m, sea bed height
	beach: 2.4, // m above the water: sand below this on the sea side
}

/** Railway on its embankment along the line equally far from both bases. */
export const RAIL = {
	bank: 1.8, // m, rail top above the smoothed ground profile
	top: 3.5, // m, half width of the embankment crown
	slope: 0.45, // side slope (rise per metre)
	crossing: [8, 22] as const, // m from a road: the bank comes down to a level crossing
	trains: [1, 2] as const,
	wagons: [3, 6] as const,
}

/** Tree species. A map plants only a few of them: one per role, rolled from FLORA. */
export type TreeSpecies = 'pine' | 'spruce' | 'linden' | 'birch' | 'oak' | 'poplar' | 'willow' | 'apple'

/** Tree species odds of an archetype, per role. Orchards are always apple trees. */
export interface FloraDef {
	conifer: Partial<Record<TreeSpecies, number>> // forests and lone trees
	leafy: Partial<Record<TreeSpecies, number>> // forests and lone trees
	alley: Partial<Record<TreeSpecies, number>> // rows along the roads
	willow: number // chance of willows by the water (they take the place of a separate alley species)
	coniferShare: readonly [number, number] // share of conifers in the forests
}

export const FLORA: Record<Archetype, FloraDef> = {
	classic: {
		conifer: { pine: 0.5, spruce: 0.5 },
		leafy: { linden: 0.35, birch: 0.4, oak: 0.25 },
		alley: { linden: 0.35, birch: 0.35, poplar: 0.3 },
		willow: 0.45,
		coniferShare: [0.4, 0.7],
	},
	steppe: {
		conifer: { pine: 1 },
		leafy: { oak: 0.5, linden: 0.3, birch: 0.2 },
		alley: { poplar: 0.7, linden: 0.3 },
		willow: 0.35,
		coniferShare: [0.15, 0.4],
	},
	swamp: {
		conifer: { spruce: 0.55, pine: 0.45 },
		leafy: { birch: 0.75, linden: 0.25 },
		alley: { birch: 0.7, poplar: 0.3 },
		willow: 0.75,
		coniferShare: [0.35, 0.6],
	},
	pass: {
		conifer: { spruce: 0.7, pine: 0.3 },
		leafy: { birch: 0.45, oak: 0.35, linden: 0.2 },
		alley: { linden: 0.4, birch: 0.4, poplar: 0.2 },
		willow: 0.2,
		coniferShare: [0.55, 0.8],
	},
	coast: {
		conifer: { pine: 0.85, spruce: 0.15 },
		leafy: { oak: 0.4, linden: 0.4, birch: 0.2 },
		alley: { poplar: 0.55, linden: 0.45 },
		willow: 0.3,
		coniferShare: [0.45, 0.75],
	},
}

/** Building variants: each map rolls which of them its villages use. */
export const BUILDING_KIT = {
	chapel: 0.35, // a village church is a small chapel instead
	brickHouses: 0.5, // chance a map has two-storey brick houses at all
	brickShare: [0.15, 0.4] as const, // their share of a village's houses on such a map
	warehouse: 0.5, // barns in the villages are long kolkhoz warehouses
	waterTower: 0.45, // a water tower at the edge of one village
}
