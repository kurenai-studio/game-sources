import * as THREE from 'three'
import { COAST, WORLD, WORLD_HALF, type ArchetypeDef, type BattleMode } from '../../config'
import type { Railway } from './railway'
import { crossingPath, type River } from './river'
import type { RoadNetwork } from './roadNetwork'
import { smoothPath } from './smoothPath'
import {
	WATER_LEVEL,
	type Bunker,
	type Crossing,
	type Features,
	type LanePoint,
	type LayoutAxis,
	type Patch,
	type Point,
	type Relief,
	type Rnd,
	type Settlement,
} from './types'

/** The terrain state the layout fills in (Terrain implements it). */
export interface LayoutTarget {
	readonly rnd: Rnd
	readonly axis: LayoutAxis
	readonly bases: Point[]
	readonly features: Features
	readonly river: River
	readonly hasRiver: boolean
	readonly riverWidth: number
	readonly crossings: Crossing[]
	readonly settlements: Settlement[]
	readonly forests: Patch[]
	readonly lakes: Patch[]
	readonly bogs: Patch[]
	readonly bunkers: Bunker[]
	readonly lanes: LanePoint[][]
	readonly roads: RoadNetwork
	readonly anchors: LanePoint[]
	readonly mode: BattleMode
	readonly params: ArchetypeDef
	readonly relief_: Relief
	readonly railway: Railway | null
	neutral: Point | null
	windmill: { x: number; z: number; rot: number } | null
	heightAnalytic(x: number, z: number, withBridges?: boolean): number
	reliefAt(x: number, z: number): number
	seaward(x: number, z: number): number
}

const pick = (rnd: Rnd, [a, b]: readonly [number, number]) => a + Math.floor(rnd() * (b - a + 1))
const TOWN_RADIUS = 95
const PLACE_TRIES = 80
const LAKE_TRIES = 250
const WINDMILL_CANDIDATES = 60

/**
 * Places everything on a fresh map, in a fixed order (it is the map's RNG sequence): crossings and the central
 * town, villages, farmsteads, forests, bridge decks, roads and lanes, bunkers, lakes and the windmill.
 */
export class MapLayout {
	private readonly r: Rnd
	private readonly playable = WORLD_HALF - WORLD.mountainBand
	private readonly halfRiver: number

	constructor(private readonly t: LayoutTarget) {
		this.r = t.rnd
		this.halfRiver = t.riverWidth / 2
	}

	run() {
		if (this.t.hasRiver) this.crossingsAndTown()
		else this.anchorsAndTown()
		this.villages()
		this.farmsteads()
		this.forestPatches()
		this.bridgeDecks()
		this.roadsAndLanes()
		this.bunkerPositions()
		this.lakePatches()
		this.bogPatches()
		this.windmillSpot()
	}

	// ---------------------------------------------------------------- placement rules

	/** Clear of every settlement, the bases (neutral one too), the railway, and inland of a coast. */
	private clearOfPlaces(x: number, z: number, rr: number) {
		const { settlements, bases, neutral, railway } = this.t
		return (
			settlements.every((s) => Math.hypot(s.x - x, s.z - z) > s.r + rr + 20) &&
			bases.every((b) => Math.hypot(b.x - x, b.z - z) > rr + 90) &&
			(!neutral || Math.hypot(neutral.x - x, neutral.z - z) > rr + 70) &&
			(!railway || railway.dist(x, z) > rr + 18) &&
			this.t.seaward(x, z) < COAST.start - rr - 30
		)
	}

	private clearOfBridges(x: number, z: number, rr: number) {
		return this.t.crossings.every(
			(c) => c.kind === 'ford' || Math.hypot(c.x - x, c.z - z) > rr + c.half + WORLD.bridgeRamp[1] + 10,
		)
	}

	private riverGap(x: number, z: number) {
		return Math.abs(this.t.river.dist(x, z))
	}

	/** A random point in the playable square inset by `inset`. */
	private randomPoint(inset: number): Point {
		const r = this.r
		const x = (r() * 2 - 1) * (this.playable - inset)
		const z = (r() * 2 - 1) * (this.playable - inset)
		return { x, z }
	}

	// ---------------------------------------------------------------- steps

	/** Crossings along the river; the slot nearest the middle gets the town bridge. */
	private crossingsAndTown() {
		const { t, r } = this
		const nb = pick(r, WORLD.bridges)
		const nf = Math.floor(r() * (WORLD.fordsMax + 1))
		const n = nb + nf
		// On a coast the crossings keep off the beach: the river's length runs roughly across the base axis
		const span = t.seaward(0, 0) === -Infinity ? 540 : 430
		const shift = t.seaward(t.axis.px, t.axis.pz) > 0 ? -55 : 55
		const off = span === 540 ? 0 : shift
		const step = span / n
		const vs = Array.from({ length: n }, (_, i) => off - span / 2 + step * (i + 0.5) + (r() - 0.5) * step * 0.5)
		const mid = vs.reduce((bi, v, i) => (Math.abs(v) < Math.abs(vs[bi]) ? i : bi), 0)
		const kinds: Crossing['kind'][] = vs.map(() => 'ford')
		kinds[mid] = 'bridge'
		const rest = vs
			.map((_, i) => i)
			.filter((i) => i !== mid)
			.sort(() => r() - 0.5)
		for (let i = 0; i < nb - 1; i++) kinds[rest[i]] = 'bridge'
		vs.forEach((v, i) => t.crossings.push(t.river.crossing(v, kinds[i], r)))
		const town = t.crossings[mid]
		this.addTown(town.x, town.z, Math.atan2(town.nz, town.nx))
	}

	/**
	 * No river: three open lane anchors across the axis; the town sits on the middle one (a railway, which runs along
	 * the same line, goes through it as a station). In an encounter the middle anchor is the neutral base instead (on
	 * the line equally far from both bases, nearest the map centre) and the town moves to a flank.
	 */
	private anchorsAndTown() {
		const { t, r } = this
		const { dx, dz, px, pz } = t.axis
		for (const v of [-200, 0, 200]) {
			const u = (r() - 0.5) * 160
			// The pass relief has its saddles exactly on the lane lines
			const vv = t.relief_ === 'pass' ? v : v + (r() - 0.5) * 60
			t.anchors.push({ x: u * dx + vv * px, z: u * dz + vv * pz, fixed: true })
		}
		// The town moves to the flank away from any sea
		const flank = () => {
			const [a, b] = [t.anchors[0], t.anchors[2]]
			const sa = t.seaward(a.x, a.z)
			const sb = t.seaward(b.x, b.z)
			return sa === sb ? (r() < 0.5 ? a : b) : sa < sb ? a : b
		}
		if (t.mode === 'encounter') {
			const [W, E] = t.bases
			const mx = (W.x + E.x) / 2
			const mz = (W.z + E.z) / 2
			const l = Math.hypot(E.x - W.x, E.z - W.z) || 1
			const bx = -(E.z - W.z) / l // along the bisector
			const bz = (E.x - W.x) / l
			const k = -(mx * bx + mz * bz)
			t.neutral = { x: mx + bx * k, z: mz + bz * k }
			t.anchors[1] = { ...t.neutral, fixed: true }
			const f = flank()
			this.addTown(f.x, f.z, Math.atan2(dz, dx))
			return
		}
		const a = t.anchors[1]
		this.addTown(a.x, a.z, Math.atan2(dz, dx))
	}

	private addTown(x: number, z: number, rot: number) {
		const variant = this.r() < 0.35 ? 'factory' : 'ruins'
		this.t.settlements.push({
			kind: 'town',
			x,
			z,
			r: TOWN_RADIUS,
			rot,
			variant,
			church: true,
			walls: false,
			orchard: false,
		})
	}

	private villages() {
		const { t, r } = this
		const nv = pick(r, t.params.villages)
		for (let v = 0; v < nv; v++) {
			for (let k = 0; k < PLACE_TRIES; k++) {
				const { x, z } = this.randomPoint(60)
				if (this.riverGap(x, z) < 50 + this.halfRiver + 25) continue
				if (!this.clearOfPlaces(x, z, 50) || !this.clearOfBridges(x, z, 50)) continue
				const rot = r() * Math.PI
				const church = r() < 0.7
				const walls = r() < 0.5
				const orchard = r() < 0.45
				t.settlements.push({ kind: 'village', x, z, r: 50, rot, variant: 'village', church, walls, orchard })
				break
			}
		}
	}

	/** Farmsteads: a house and a barn on their own, off in the fields. */
	private farmsteads() {
		const { t, r } = this
		const n = t.features.farms ? pick(r, [1, 3]) : 0
		for (let f = 0; f < n; f++) {
			for (let k = 0; k < PLACE_TRIES; k++) {
				const { x, z } = this.randomPoint(40)
				if (this.riverGap(x, z) < 22 + this.halfRiver + 25) continue
				if (!this.clearOfPlaces(x, z, 22) || !this.clearOfBridges(x, z, 22)) continue
				const rot = r() * Math.PI
				const walls = r() < 0.5
				const orchard = r() < 0.5
				t.settlements.push({
					kind: 'village',
					x,
					z,
					r: 22,
					rot,
					variant: 'farm',
					church: false,
					walls,
					orchard,
				})
				break
			}
		}
	}

	private forestPatches() {
		const { t, r } = this
		const nf = pick(r, t.params.forests)
		for (let f = 0; f < nf; f++) {
			for (let k = 0; k < PLACE_TRIES; k++) {
				const rr = 38 + r() * 45
				const { x, z } = this.randomPoint(rr)
				if (this.riverGap(x, z) < rr + this.halfRiver + 20 || !this.clearOfPlaces(x, z, rr)) continue
				if (t.forests.some((o) => Math.hypot(o.x - x, o.z - z) < o.r + rr + 10)) continue
				t.forests.push({ x, z, r: rr })
				break
			}
		}
	}

	/** Bridge decks: a little below the lower bank, always above the water; the ramp grows with the higher bank. */
	private bridgeDecks() {
		const { t } = this
		for (const c of t.crossings) {
			if (c.kind !== 'bridge') continue
			const reach = c.half + WORLD.bridgeRamp[0]
			const g = [-1, 1].map((s) => t.heightAnalytic(c.x + c.nx * s * reach, c.z + c.nz * s * reach, false))
			c.h = THREE.MathUtils.clamp(Math.min(g[0], g[1]) - 2, WATER_LEVEL + 2.5, WATER_LEVEL + 6)
			c.ramp = THREE.MathUtils.clamp(
				(Math.max(g[0], g[1]) - c.h) / 0.22,
				WORLD.bridgeRamp[0],
				WORLD.bridgeRamp[1],
			)
		}
	}

	/**
	 * Roads and lanes: base → crossing → base for every crossing (or straight through an anchor). Each lane leaves
	 * the base from its own gate (spread 45 m apart across the axis) and winds through two intermediate points with
	 * small lateral offsets; the road itself is a Catmull-Rom spline through the waypoints, exact at the crossings.
	 */
	private roadsAndLanes() {
		const { t, r } = this
		const { px, pz } = t.axis
		const [W, E] = t.bases
		const sideW = t.river.side(W.x, W.z) || -1
		const mids: LanePoint[][] = t.hasRiver
			? t.crossings.map((c) => crossingPath(c, sideW))
			: t.anchors.map((a) => [a])
		const rank = mids
			.map((m, i) => ({ i, p: m[0].x * px + m[0].z * pz }))
			.sort((a, b) => a.p - b.p)
			.map((o) => o.i)
		const gate = (base: Point, toward: LanePoint, k: number): Point => {
			const off = (k - (mids.length - 1) / 2) * 45
			const ddx = toward.x - base.x
			const ddz = toward.z - base.z
			const l = Math.hypot(ddx, ddz) || 1
			return { x: base.x + px * off + (ddx / l) * 40, z: base.z + pz * off + (ddz / l) * 40 }
		}
		const bend = (a: Point, b: Point, k: number, amp: number): Point => {
			const ddx = b.x - a.x
			const ddz = b.z - a.z
			const l = Math.hypot(ddx, ddz) || 1
			const s = (r() - 0.5) * 2 * amp
			return { x: a.x + ddx * k - (ddz / l) * s, z: a.z + ddz * k + (ddx / l) * s }
		}
		mids.forEach((mid, i) => {
			const first = mid[0]
			const last = mid[mid.length - 1]
			const k = rank.indexOf(i)
			const gW = gate(W, first, k)
			const gE = gate(E, last, k)
			const lane: LanePoint[] = [
				W,
				gW,
				bend(gW, first, 0.35, 45),
				bend(gW, first, 0.7, 35),
				...mid,
				bend(last, gE, 0.3, 35),
				bend(last, gE, 0.65, 45),
				gE,
				E,
			]
			t.lanes.push(lane)
			t.roads.add(smoothPath(lane.slice(1, -1), 12)) // the base centres are where tanks stand, not road
		})
		t.roads.buildGrid()
	}

	/** Bunkers: concrete pillboxes flanking a lane a little before the crossing on each side. */
	private bunkerPositions() {
		const { t, r } = this
		if (!t.features.bunkers) return
		for (const lane of t.lanes) {
			if (r() < 0.4) continue
			const legs = [
				[lane[1], lane[2]],
				[lane[lane.length - 2], lane[lane.length - 3]],
			]
			for (const [a, b] of legs) {
				const x = (a.x + b.x) / 2
				const z = (a.z + b.z) / 2
				const ddx = b.x - a.x
				const ddz = b.z - a.z
				const l = Math.hypot(ddx, ddz) || 1
				const side = r() < 0.5 ? 1 : -1
				const bx = x + (-ddz / l) * side * 17
				const bz = z + (ddx / l) * side * 17
				if (this.riverGap(bx, bz) < 50 || !this.clearOfPlaces(bx, bz, 6)) continue
				if (t.heightAnalytic(bx, bz, false) < WATER_LEVEL + 1.5) continue
				if (t.forests.some((o) => Math.hypot(o.x - bx, o.z - bz) < o.r + 6)) continue
				t.bunkers.push({ x: bx, z: bz, rot: Math.atan2(ddx, ddz) })
			}
		}
	}

	/** Lakes sit in hollows: the centre and a ring at 2.5 r must all be low ground. */
	private inHollow(x: number, z: number, rr: number) {
		const { t } = this
		if (8 + t.reliefAt(x, z) > 13) return false
		for (let a = 0; a < 8; a++) {
			const h = 8 + t.reliefAt(x + Math.cos(a * 0.785) * rr * 2.5, z + Math.sin(a * 0.785) * rr * 2.5)
			if (h > 15) return false
		}
		return true
	}

	/** Lakes: off the roads, away from everything else. */
	private lakePatches() {
		const { t, r } = this
		const nl = pick(r, t.hasRiver ? t.params.lakes : t.params.lakesDry)
		for (let l = 0; l < nl; l++) {
			for (let k = 0; k < LAKE_TRIES; k++) {
				const rr = 30 + r() * 35
				const x = (r() * 2 - 1) * (this.playable - rr - 10)
				const z = (r() * 2 - 1) * (this.playable - rr - 10)
				if (this.riverGap(x, z) < rr + 70 || !this.clearOfPlaces(x, z, rr)) continue
				if (t.roads.dist(x, z, true) < rr + 12) continue
				if (t.bases.some((b) => Math.hypot(b.x - x, b.z - z) < rr + 100)) continue
				if (!this.inHollow(x, z, rr)) continue
				if (t.forests.some((o) => Math.hypot(o.x - x, o.z - z) < o.r + rr - 15)) continue
				if (t.lakes.some((o) => Math.hypot(o.x - x, o.z - z) < o.r + rr + 20)) continue
				t.lakes.push({ x, z, r: rr })
				break
			}
		}
	}

	/**
	 * Bogs: shallow marsh pools away from the places and the river; unlike lakes they may lie across a road (which
	 * then crosses them on a causeway — a corduroy road).
	 */
	private bogPatches() {
		const { t, r } = this
		const n = pick(r, t.params.bogs)
		for (let l = 0; l < n; l++) {
			for (let k = 0; k < PLACE_TRIES; k++) {
				const rr = 24 + r() * 26
				const { x, z } = this.randomPoint(rr + 10)
				if (this.riverGap(x, z) < rr + 70 || !this.clearOfPlaces(x, z, rr)) continue
				if (!this.clearOfBridges(x, z, rr)) continue
				if (t.forests.some((o) => Math.hypot(o.x - x, o.z - z) < o.r * 0.6 + rr)) continue
				if ([...t.lakes, ...t.bogs].some((o) => Math.hypot(o.x - x, o.z - z) < o.r + rr + 25)) continue
				t.bogs.push({ x, z, r: rr })
				break
			}
		}
	}

	/** Windmill: the highest open spot of a few dozen candidates, a landmark on a hill. */
	private windmillSpot() {
		const { t, r } = this
		if (!t.features.windmill) return
		let best: { x: number; z: number; h: number } | null = null
		for (let k = 0; k < WINDMILL_CANDIDATES; k++) {
			const { x, z } = this.randomPoint(50)
			if (this.riverGap(x, z) < 60 || !this.clearOfPlaces(x, z, 8) || t.roads.dist(x, z, true) < 25) continue
			if (t.forests.some((o) => Math.hypot(o.x - x, o.z - z) < o.r + 12)) continue
			if (t.lakes.some((o) => Math.hypot(o.x - x, o.z - z) < o.r + 35)) continue
			if (t.bunkers.some((o) => Math.hypot(o.x - x, o.z - z) < 20)) continue
			const h = t.heightAnalytic(x, z, false)
			if (!best || h > best.h) best = { x, z, h }
		}
		if (best) t.windmill = { x: best.x, z: best.z, rot: r() * Math.PI * 2 }
	}
}
