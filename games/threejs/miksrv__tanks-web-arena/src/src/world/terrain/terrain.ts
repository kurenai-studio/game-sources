import * as THREE from 'three'
import {
	ARCHETYPES,
	CAPTURE,
	COAST,
	SPOTTING,
	TERRAIN_RES,
	WORLD,
	WORLD_HALF,
	type Archetype,
	type ArchetypeDef,
	type BattleMode,
	type Weather,
} from '../../config'
import { Simplex2D, mulberry32 } from '../../core/noise'
import { MapLayout, type LayoutTarget } from './layout'
import { buildTerrainMesh, buildWaterMesh } from './mesh'
import { Railway } from './railway'
import { bakeRelief, CELL_SIZE, sampleClamped } from './relief'
import { crossingPath, deckAt, River } from './river'
import { RoadNetwork } from './roadNetwork'
import {
	ARCHETYPE_ODDS,
	archetypeRelief,
	rollFlora,
	rollKit,
	rollMode,
	rollStyle,
	rollWeather,
	weighted,
} from './style'
import {
	BIOME_ID,
	BIOME_SPEED,
	WATER_LEVEL,
	type Biome,
	type BuildingKit,
	type Bunker,
	type Crossing,
	type Features,
	type Flora,
	type LanePoint,
	type LayoutAxis,
	type MapSpec,
	type Patch,
	type Point,
	type Relief,
	type Rnd,
	type Season,
	type Settlement,
} from './types'

const { smoothstep } = THREE.MathUtils
const tmpG = new THREE.Vector2()

const BASE_FLAT_RADIUS = 70 // m of levelled ground around each base
const BASE_BIOME_RADIUS = 45
const DEEP_WATER = 1.3 // m: deeper than this is impassable
const FLOODPLAIN = WATER_LEVEL + 2.5 // m: the land beside the river, just above the water
const RIVER_BANK = 22 // m: from the water's edge up to the floodplain
const MAX_PASSABLE_GRADIENT = 0.95
const OUTSIDE_HEIGHT = 120 // the ground "outside the world" is a wall

/**
 * Heightmap world, laid out afresh for every seed: the base-to-base axis points in a random direction, a river
 * (about half of the maps) crosses it at a random tilt and offset with 3–4 bridges and up to two fords, lakes,
 * forests, villages and a ruined town at the middle bridge. Dirt roads run base → crossing → base; the same routes
 * are the bots' lanes.
 */
export class Terrain implements LayoutTarget {
	readonly heights = new Float32Array(TERRAIN_RES * TERRAIN_RES)
	readonly biomes = new Uint8Array(TERRAIN_RES * TERRAIN_RES)
	readonly mesh: THREE.Mesh
	readonly water: THREE.Mesh
	readonly forests: Patch[] = []
	readonly lakes: Patch[] = []
	/** Shallow marsh pools: passable, slow; roads cross them on causeways. */
	readonly bogs: Patch[] = []
	readonly settlements: Settlement[] = []
	readonly bases: Point[] = [] // [0] = USSR, [1] = Germany
	readonly crossings: Crossing[] = [] // sorted along the river; empty when there is none
	readonly lanes: LanePoint[][] = [] // bases[0] → bases[1], one per crossing (or three open lanes)
	readonly bunkers: Bunker[] = []
	windmill: { x: number; z: number; rot: number } | null = null
	readonly hasRiver: boolean
	readonly riverWidth: number
	readonly hills: number
	readonly archetype: Archetype
	/** The archetype's layout numbers. */
	readonly params: ArchetypeDef
	/** Coast maps: which side of the base axis is the sea (+1 / −1), else 0. */
	readonly coastSign: -1 | 0 | 1
	railway: Railway | null = null
	readonly season: Season
	readonly weather: Weather
	readonly mode: BattleMode
	/** Assault: the side that holds its base. */
	readonly defender: 0 | 1
	/** Encounter: the neutral base in the middle (equally far from both bases). */
	neutral: Point | null = null
	readonly relief_: Relief
	readonly features: Features
	/** Tree species planted on this map. */
	readonly flora: Flora
	/** Building variants of its villages. */
	readonly kit: BuildingKit
	/** Unit vectors of the layout: `d` from bases[0] toward bases[1], `p` perpendicular to it. */
	readonly axis: LayoutAxis
	readonly rnd: Rnd
	readonly noise: Simplex2D
	readonly river: River
	readonly roads = new RoadNetwork()
	/** Lane midpoints on maps without a river. */
	readonly anchors: LanePoint[] = []
	/** Natural rolling relief (hills + bumps, no mountains or features), slope-capped; sampled by `heightAnalytic`. */
	private readonly relief: Float32Array
	/** Field / meadow split for this map: the fbm zone threshold (low = mostly fields). */
	private readonly zoneCut: number

	constructor(
		readonly seed: number,
		spec: MapSpec = {},
	) {
		this.noise = new Simplex2D(seed)
		this.rnd = mulberry32(seed * 7919 + 13)
		const r = this.rnd
		const laneRot = r() * Math.PI * 2
		this.axis = { dx: Math.cos(laneRot), dz: Math.sin(laneRot), px: -Math.sin(laneRot), pz: Math.cos(laneRot) }
		this.hills = WORLD.hills * (0.75 + 0.45 * r())
		const style = rollStyle(r)
		// Archetype, its season, revetments, the coast side and the railway come from a stream of their own
		const extra = mulberry32(seed * 2654435 + 101)
		const archetypeRoll = extra()
		this.archetype = spec.archetype ?? weighted(archetypeRoll, ARCHETYPE_ODDS, 'classic')
		this.params = ARCHETYPES[this.archetype]
		const season = weighted(extra(), this.params.seasons, 'summer')
		this.season = spec.season ?? (this.archetype === 'classic' ? style.season : season)
		this.weather = spec.weather ?? rollWeather(seed, this.season)
		this.mode = spec.mode ?? rollMode(seed)
		this.defender = mulberry32(seed * 31 + 17)() < 0.5 ? 0 : 1
		this.relief_ = archetypeRelief(this.archetype, style.relief)
		this.features = { ...style.features, revetments: extra() < 0.5 }
		this.flora = rollFlora(seed, this.archetype)
		this.kit = rollKit(seed)
		this.coastSign = this.archetype === 'coast' ? (extra() < 0.5 ? 1 : -1) : 0
		const wantsRail = extra() < this.params.railway
		const zoneCut = -0.15 + 0.4 * r()
		this.zoneCut = this.params.fields ?? zoneCut
		// The encounter base sits in the open middle of the map: no river runs through it
		this.hasRiver = r() < this.params.riverChance && this.mode !== 'encounter'
		this.riverWidth = WORLD.riverWidth[0] + r() * (WORLD.riverWidth[1] - WORLD.riverWidth[0])
		// The river flows roughly perpendicular to the base axis; its "across" direction is tilted off the axis a little
		const riverRot = laneRot + (r() - 0.5) * 0.7
		this.river = new River(this.hasRiver, this.riverWidth, riverRot, r, this.noise)
		this.placeBases()
		this.relief = bakeRelief(this.relief_, this.noise, this.hills, this.axis, r() * Math.PI)
		if (wantsRail && !this.hasRiver) this.railway = this.layRailway()
		new MapLayout(this).run()
		this.bake()
		this.mesh = buildTerrainMesh(this)
		this.water = buildWaterMesh(this.season, this.archetype === 'swamp')
	}

	private placeBases() {
		const span = WORLD_HALF - 130
		const { dx, dz, px, pz } = this.axis
		for (const s of [-1, 1]) {
			const v = (this.rnd() - 0.5) * 160
			this.bases.push({ x: s * span * dx + v * px, z: s * span * dz + v * pz })
		}
	}

	/** The railway runs along the line equally far from both bases (through the middle of the map). */
	private layRailway(): Railway {
		const [W, E] = this.bases
		const mid = { x: (W.x + E.x) / 2, z: (W.z + E.z) / 2 }
		const ground = (x: number, z: number) => 8 + this.reliefAt(x, z)
		const inland = (x: number, z: number) => this.seaward(x, z) < COAST.start - 30
		return new Railway(mid, { x: -(E.z - W.z), z: E.x - W.x }, ground, inland)
	}

	/** 0 inside the town, 1 well outside it (the railway runs at street level through a town). */
	private outsideTown(x: number, z: number): number {
		const town = this.settlements.find((s) => s.kind === 'town')
		return town ? smoothstep(Math.hypot(x - town.x, z - town.z), town.r * 0.8, town.r * 1.25) : 1
	}

	/** Coast maps: metres toward the sea from the base axis (−∞ elsewhere). */
	seaward(x: number, z: number): number {
		return this.coastSign ? (x * this.axis.px + z * this.axis.pz) * this.coastSign : -Infinity
	}

	/** Smoothed road centre-lines, one polyline per lane (props plant alleys along them). */
	get roadPaths(): Point[][] {
		return this.roads.paths
	}

	// ---------------------------------------------------------------- river
	/** Signed distance across the river axis (negative on the bases[0] side); +∞ when the map has no river. */
	riverDist(x: number, z: number): number {
		return this.river.dist(x, z)
	}
	/** −1 / +1 for the two banks, 0 when there is no river. */
	riverSide(x: number, z: number): -1 | 0 | 1 {
		return this.river.side(x, z)
	}
	/** Waypoints through a crossing, starting on the bank `fromSide` (−1 / +1) and ending on the far bank. */
	crossingPath(c: Crossing, fromSide: number): LanePoint[] {
		return crossingPath(c, fromSide)
	}
	/** The bridge whose deck covers (x, z), if any. */
	deckAt(x: number, z: number): Crossing | null {
		return deckAt(this.crossings, x, z)
	}

	// ---------------------------------------------------------------- height & biome (analytic)
	/** Bilinear sample of the baked relief (clamped at the world edge). */
	reliefAt(x: number, z: number): number {
		return sampleClamped(this.relief, x, z)
	}

	/** Normalised distance to a lake centre (1 = its noisy shoreline radius). */
	private lakeD(l: Patch, i: number, x: number, z: number): number {
		const dist = Math.hypot(x - l.x, z - l.z)
		if (dist > l.r * 2.9) return Infinity
		return dist / (l.r * (1 + 0.25 * this.noise.noise(x * 0.02 + i * 13, z * 0.02 - i * 7)))
	}

	/** The ground height at (x, z) from all the map features; baked into the grid once the layout is done. */
	heightAnalytic(x: number, z: number, withBridges = true): number {
		let h = 8 + this.reliefAt(x, z)
		h = this.withMountains(h, x, z)
		if (this.coastSign) h = this.withCoast(h, x, z)
		// Flat ground for bases and settlements, blended out over a wide ring so no cliff forms at the edge
		for (const s of this.settlements) h = this.flattened(h, x, z, s.x, s.z, s.r)
		for (const b of this.bases) h = this.flattened(h, x, z, b.x, b.z, BASE_FLAT_RADIUS)
		if (this.neutral) h = this.flattened(h, x, z, this.neutral.x, this.neutral.z, CAPTURE.flatRadius)
		if (this.hasRiver) h = this.withRiverValley(h, x, z)
		this.lakes.forEach((l, i) => (h = this.withLake(h, l, i, x, z)))
		this.bogs.forEach((l, i) => (h = this.withBog(h, l, i, x, z)))
		if (this.railway) h = this.railway.shape(h, x, z, this.roads.dist(x, z), this.outsideTown(x, z))
		h = this.withCauseway(h, x, z)
		if (withBridges) for (const c of this.crossings) if (c.kind === 'bridge') h = this.withEmbankment(h, c, x, z)
		return h
	}

	/** Mountains at the edge (none on the sea side of a coast map). */
	private withMountains(h: number, x: number, z: number) {
		const edge = Math.max(Math.abs(x), Math.abs(z))
		const coast = this.coastSign ? 1 - smoothstep(this.seaward(x, z), 120, COAST.start) : 1
		const m = smoothstep(edge, WORLD_HALF - WORLD.mountainBand, WORLD_HALF - 20) * coast
		return h + m * m * WORLD.mountainHeight * (0.6 + 0.5 * this.noise.fbm(x * 0.012 + 3, z * 0.012, 3))
	}

	/** The sea: past COAST.start the ground falls away to the sea bed. */
	private withCoast(h: number, x: number, z: number) {
		const c = this.seaward(x, z)
		if (c <= COAST.start) return h
		return h + (COAST.depth - h) * smoothstep(c, COAST.start, COAST.sea)
	}

	private flattened(h: number, x: number, z: number, cx: number, cz: number, r: number) {
		const d = Math.hypot(x - cx, z - cz) / r
		if (d >= 1.7) return h
		const k = smoothstep(d, 0.55, 1.7)
		const flat = Math.max(WATER_LEVEL + 3, 8 + this.reliefAt(cx, cz))
		return flat + (h - flat) * k
	}

	/**
	 * River valley: the bed, a low bank up to the floodplain a couple of metres above the water, then the valley side
	 * climbing gently back to the surrounding ground; fords raise the bed.
	 */
	private withRiverValley(h: number, x: number, z: number) {
		const rd = Math.abs(this.riverDist(x, z))
		const w = this.riverWidth / 2
		const plain = Math.min(h, FLOODPLAIN)
		// The valley side is wider where the surrounding ground is higher (slope ≤ ~0.15)
		const sideW = 90 + Math.max(0, h - plain - 6) * 8
		if (rd >= w + RIVER_BANK + sideW) return h
		const ground = plain + (h - plain) * smoothstep(rd, w + RIVER_BANK, w + RIVER_BANK + sideW)
		let fordK = 0
		for (const c of this.crossings) {
			if (c.kind !== 'ford') continue
			const along = Math.abs(-(x - c.x) * c.nz + (z - c.z) * c.nx)
			fordK = Math.max(fordK, 1 - smoothstep(along, 10, c.half))
		}
		const bed = WATER_LEVEL - 2.4 + fordK * 1.9 + 0.4 * this.noise.noise(x * 0.1, z * 0.1)
		const k = smoothstep(rd, w, w + RIVER_BANK)
		return rd < w ? bed : bed + (Math.max(ground, bed + 1) - bed) * k
	}

	/**
	 * Lakes: a bowl with a noisy shoreline. The land around is held near the water level and only climbs back to the
	 * natural ground beyond 1.5 r, so the shore itself is a gentle ramp.
	 */
	private withLake(h: number, l: Patch, i: number, x: number, z: number) {
		const d = this.lakeD(l, i, x, z)
		if (d >= 2.8) return h
		const bed = WATER_LEVEL - 3.5 + 0.4 * this.noise.noise(x * 0.1, z * 0.1)
		const basin = Math.min(h, WATER_LEVEL + 4)
		const rim = basin + (h - basin) * smoothstep(d, 1.4, 2.8)
		const k = smoothstep(d, 0.35, 1.5)
		return d < 0.35 ? bed : bed + (Math.max(rim, bed + 1) - bed) * k
	}

	/**
	 * Bogs: a shallow pool (0.5–1 m of water, passable but slow) with the ground around held just above the water,
	 * so a marsh rather than a bowl.
	 */
	private withBog(h: number, l: Patch, i: number, x: number, z: number) {
		const d = this.lakeD(l, i + 40, x, z)
		if (d >= 2.4) return h
		const bed = WATER_LEVEL - 0.75 + 0.25 * this.noise.noise(x * 0.15, z * 0.15)
		const basin = Math.min(h, WATER_LEVEL + 1.5)
		const rim = basin + (h - basin) * smoothstep(d, 1.2, 2.4)
		return bed + (Math.max(rim, bed + 0.3) - bed) * smoothstep(d, 0.6, 1.25)
	}

	/** Roads never drown: outside the river valley a low causeway carries them through hollows. */
	private withCauseway(h: number, x: number, z: number) {
		if (h >= WATER_LEVEL + 1 || Math.abs(this.riverDist(x, z)) <= this.riverWidth / 2 + 60) return h
		const rdist = this.roads.dist(x, z)
		if (rdist >= 14) return h
		return h + (WATER_LEVEL + 1 - h) * (1 - smoothstep(rdist, 5, 14))
	}

	/** Bridge embankments: flat at deck height past each deck end, then rising to the natural ground over the ramp. */
	private withEmbankment(h: number, c: Crossing, x: number, z: number) {
		const dx = x - c.x
		const dz = z - c.z
		const reach = c.half + c.ramp + 24
		if (Math.abs(dx) > reach || Math.abs(dz) > reach) return h
		const along = Math.abs(dx * c.nx + dz * c.nz)
		const across = Math.abs(-dx * c.nz + dz * c.nx)
		if (along < c.half - 12 || along > c.half + c.ramp || across > c.hw + 22) return h
		// Under the last metres of the deck the bank is cut so it never pokes through; past the end, the embankment
		// climbs linearly: the gentlest climb for a given ramp
		const ramp = THREE.MathUtils.clamp((along - c.half - 2) / (c.ramp - 2), 0, 1)
		const emb = along < c.half - 3 ? Math.min(h, c.h - 0.2) : c.h + (Math.max(h, WATER_LEVEL + 1.2) - c.h) * ramp
		// Side slopes no steeper than ~0.33: the shoulder widens with the embankment's height
		return h + (emb - h) * (1 - smoothstep(across, c.hw, c.hw + Math.max(4, Math.abs(emb - h) * 3)))
	}

	biomeAnalytic(x: number, z: number, h: number): Biome {
		if (h < WATER_LEVEL + 0.2) return 'water'
		if (this.seaward(x, z) > COAST.start - 40 && h < WATER_LEVEL + COAST.beach) return 'sand'
		const edge = Math.max(Math.abs(x), Math.abs(z))
		if (h > 26 || edge > WORLD_HALF - WORLD.mountainBand + 40) return 'mountain'
		if (this.onBridgeRamp(x, z)) return 'road'
		if (Math.abs(this.riverDist(x, z)) < this.riverWidth / 2 + 7) return 'mud'
		for (let i = 0; i < this.lakes.length; i++) if (this.lakeD(this.lakes[i], i, x, z) < 0.8) return 'mud'
		for (let i = 0; i < this.bogs.length; i++) if (this.lakeD(this.bogs[i], i + 40, x, z) < 1.45) return 'mud'
		for (const b of this.bases) if (Math.hypot(x - b.x, z - b.z) < BASE_BIOME_RADIUS) return 'base'
		const nb = this.neutral
		if (nb && Math.hypot(x - nb.x, z - nb.z) < CAPTURE.biomeRadius) return 'base'
		for (const s of this.settlements) if (Math.hypot(x - s.x, z - s.z) < s.r) return s.kind
		const road = this.roads.dist(x, z)
		if (road < 4.5) return 'road'
		if (this.railway?.onTrack(x, z, road)) return 'rail'
		for (const f of this.forests) if (Math.hypot(x - f.x, z - f.z) < f.r) return 'forest'
		const zone = this.noise.fbm(x * 0.006 + 11, z * 0.006 - 5, 2)
		return zone > this.zoneCut ? 'field' : 'meadow'
	}

	private onBridgeRamp(x: number, z: number) {
		for (const c of this.crossings) {
			if (c.kind !== 'bridge') continue
			const dx = x - c.x
			const dz = z - c.z
			const reach = c.half + c.ramp + 12
			if (Math.abs(dx) > reach || Math.abs(dz) > reach) continue
			const along = Math.abs(dx * c.nx + dz * c.nz)
			const across = Math.abs(-dx * c.nz + dz * c.nx)
			if (along >= c.half - 3 && along <= c.half + c.ramp && across <= c.hw + 1) return true
		}
		return false
	}

	private bake() {
		for (let j = 0; j < TERRAIN_RES; j++) {
			for (let i = 0; i < TERRAIN_RES; i++) {
				const x = -WORLD_HALF + i * CELL_SIZE
				const z = -WORLD_HALF + j * CELL_SIZE
				const h = this.heightAnalytic(x, z)
				this.heights[j * TERRAIN_RES + i] = h
				this.biomes[j * TERRAIN_RES + i] = BIOME_ID.indexOf(this.biomeAnalytic(x, z, h))
			}
		}
	}

	// ---------------------------------------------------------------- queries
	/** Bilinear height of the ground itself from the baked grid (bridge decks ignored). Outside the world → a wall. */
	ground(x: number, z: number): number {
		const n = TERRAIN_RES - 1
		const fx = ((x + WORLD_HALF) / (WORLD_HALF * 2)) * n
		const fz = ((z + WORLD_HALF) / (WORLD_HALF * 2)) * n
		if (fx < 0 || fz < 0 || fx >= n || fz >= n) return OUTSIDE_HEIGHT
		const i = Math.floor(fx)
		const j = Math.floor(fz)
		const tx = fx - i
		const tz = fz - j
		const h = this.heights
		const r = TERRAIN_RES
		const a = h[j * r + i]
		const b = h[j * r + i + 1]
		const c = h[(j + 1) * r + i]
		const d = h[(j + 1) * r + i + 1]
		return (a * (1 - tx) + b * tx) * (1 - tz) + (c * (1 - tx) + d * tx) * tz
	}

	/** Surface height: the ground, or a bridge deck where one spans it. */
	height(x: number, z: number): number {
		const h = this.ground(x, z)
		const deck = this.deckAt(x, z)
		return deck && deck.h > h ? deck.h : h
	}

	biome(x: number, z: number): Biome {
		if (this.deckAt(x, z)) return 'road'
		const n = TERRAIN_RES - 1
		const i = Math.round(((x + WORLD_HALF) / (WORLD_HALF * 2)) * n)
		const j = Math.round(((z + WORLD_HALF) / (WORLD_HALF * 2)) * n)
		if (i < 0 || j < 0 || i > n || j > n) return 'mountain'
		return BIOME_ID[this.biomes[j * TERRAIN_RES + i]]
	}

	waterDepth(x: number, z: number): number {
		return Math.max(0, WATER_LEVEL - this.height(x, z))
	}

	/** Height gradient (rise per metre along x and z) by central differences. */
	gradient(x: number, z: number, out: THREE.Vector2): THREE.Vector2 {
		const e = 1.5
		out.set(
			(this.height(x + e, z) - this.height(x - e, z)) / (2 * e),
			(this.height(x, z + e) - this.height(x, z - e)) / (2 * e),
		)
		return out
	}

	/** Unit surface normal. */
	normal(x: number, z: number, out: THREE.Vector3): THREE.Vector3 {
		const e = 1.5
		out.set(this.height(x - e, z) - this.height(x + e, z), 2 * e, this.height(x, z - e) - this.height(x, z + e))
		return out.normalize()
	}

	/** Ground movement multiplier at a point (surface type, water depth). */
	surfaceSpeed(x: number, z: number): number {
		const b = this.biome(x, z)
		if (b === 'water') return this.waterDepth(x, z) > DEEP_WATER ? 0 : BIOME_SPEED.water
		return BIOME_SPEED[b]
	}

	passable(x: number, z: number): boolean {
		if (this.waterDepth(x, z) > DEEP_WATER) return false
		return this.gradient(x, z, tmpG).length() < MAX_PASSABLE_GRADIENT
	}

	/** Heightmap line of sight between two eye points (buildings are checked separately). */
	lineOfSight(ax: number, ay: number, az: number, bx: number, by: number, bz: number): boolean {
		const d = Math.hypot(bx - ax, bz - az)
		const steps = Math.max(2, Math.ceil(d / SPOTTING.losStep))
		for (let i = 1; i < steps; i++) {
			const t = i / steps
			if (this.height(ax + (bx - ax) * t, az + (bz - az) * t) > ay + (by - ay) * t) return false
		}
		return true
	}

	/** Random open spot near (cx, cz): no water, gentle slope, not on a bridge. Falls back to the centre. */
	findSpot(cx: number, cz: number, radius: number, avoid: Point[] = [], away = 10): Point {
		for (let t = 0; t < 200; t++) {
			const a = Math.random() * Math.PI * 2
			const d = Math.sqrt(Math.random()) * radius
			const x = cx + Math.cos(a) * d
			const z = cz + Math.sin(a) * d
			if (!this.passable(x, z) || this.waterDepth(x, z) > 0 || this.deckAt(x, z)) continue
			if (avoid.some((p) => Math.hypot(p.x - x, p.z - z) < away)) continue
			return { x, z }
		}
		return { x: cx, z: cz }
	}
}
