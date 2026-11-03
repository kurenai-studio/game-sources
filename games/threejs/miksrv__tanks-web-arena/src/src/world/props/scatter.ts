import { WORLD, WORLD_HALF } from '../../config'
import type { Terrain, TreeSpecies } from '../terrain'
import type { PropSet, Rock } from './types'

type Rnd = () => number

const BARE: readonly string[] = ['water', 'mud', 'road', 'base', 'town', 'mountain', 'sand', 'rail']

/** Where vegetation may stand: not in water, mud, roads, bases, the town, the mountains, on a beach or a railway. */
function okGround(t: Terrain, x: number, z: number): boolean {
	return !BARE.includes(t.biome(x, z))
}

/** Clear of settlements (plus `pad`), the river banks and the crossings. */
function farFromPlaces(t: Terrain, x: number, z: number, pad: number): boolean {
	return (
		t.settlements.every((s) => Math.hypot(s.x - x, s.z - z) > s.r + pad) &&
		Math.abs(t.riverDist(x, z)) > 45 &&
		t.crossings.every((c) => Math.hypot(c.x - x, c.z - z) > 70)
	)
}

/** On a bank: near the river, a lake or a bog (willows grow there). */
function nearWater(t: Terrain, x: number, z: number): boolean {
	const near = (p: { x: number; z: number; r: number }, k: number) => Math.hypot(p.x - x, p.z - z) < p.r * k + 12
	return (
		Math.abs(t.riverDist(x, z)) < t.riverWidth / 2 + 30 ||
		t.lakes.some((l) => near(l, 1.5)) ||
		t.bogs.some((b) => near(b, 1.7))
	)
}

const MIN_WILLOWS = 15

class Scatter {
	readonly set: PropSet = { trees: [], bushes: [], rocks: [], hay: [], fences: [] }

	constructor(
		private readonly t: Terrain,
		private readonly rnd: Rnd,
	) {}

	private tree(x: number, z: number, species: TreeSpecies, s: number) {
		this.set.trees.push({ x, z, h: this.t.height(x, z), s, species, fallen: false, fallT: 0, dirX: 1, dirZ: 0 })
	}

	/** A forest or lone tree: one of the map's conifer or leafy species, a willow on a bank where the map has them. */
	private wildSpecies(x: number, z: number, conifer: boolean): TreeSpecies {
		const { flora } = this.t
		if (flora.waterside && nearWater(this.t, x, z)) return flora.waterside
		return conifer ? flora.conifer : flora.leafy
	}

	/** Forests: dense stands inside each forest patch. */
	forests() {
		const { t, rnd } = this
		for (const f of t.forests) {
			const n = Math.floor(f.r * f.r * 0.02)
			for (let k = 0; k < n; k++) {
				const a = rnd() * Math.PI * 2
				const d = Math.sqrt(rnd()) * f.r * 0.97
				const x = f.x + Math.cos(a) * d
				const z = f.z + Math.sin(a) * d
				if (!okGround(t, x, z)) continue
				this.tree(x, z, this.wildSpecies(x, z, rnd() < t.flora.coniferShare), 0.8 + rnd() * 0.6)
			}
		}
	}

	/** A sprinkle of lone trees outside the fields. */
	loneTrees() {
		const { t, rnd } = this
		for (let k = 0; k < 260; k++) {
			const x = (rnd() * 2 - 1) * (WORLD_HALF - 90)
			const z = (rnd() * 2 - 1) * (WORLD_HALF - 90)
			if (!okGround(t, x, z) || t.biome(x, z) === 'field') continue
			this.tree(x, z, this.wildSpecies(x, z, rnd() < 0.5), 0.7 + rnd() * 0.7)
		}
	}

	/** Alleys: rows of trees on both sides of some roads. */
	alleys() {
		const { t, rnd } = this
		if (!t.features.alleys) return
		for (const path of t.roadPaths) {
			if (rnd() < 0.4) continue
			let acc = 0
			for (let i = 0; i + 1 < path.length; i++) {
				const a = path[i]
				const b = path[i + 1]
				const dx = b.x - a.x
				const dz = b.z - a.z
				const l = Math.hypot(dx, dz) || 1
				acc += l
				if (acc < 11) continue
				acc = 0
				for (const side of [1, -1]) {
					const x = b.x - (dz / l) * side * 7.5
					const z = b.z + (dx / l) * side * 7.5
					if (!okGround(t, x, z) || !farFromPlaces(t, x, z, 10)) continue
					this.tree(x, z, t.flora.alley, 0.75 + rnd() * 0.3)
				}
			}
		}
	}

	/** Orchards: a grid of apple trees beside a village or a farm. */
	orchards() {
		const { t, rnd } = this
		for (const s of t.settlements) {
			if (!s.orchard) continue
			const a = s.rot + (Math.PI / 2) * (rnd() < 0.5 ? 1 : -1)
			const cx = s.x + Math.cos(a) * (s.r + 20)
			const cz = s.z + Math.sin(a) * (s.r + 20)
			const c = Math.cos(s.rot)
			const sn = Math.sin(s.rot)
			for (let i = -2; i <= 2; i++) {
				for (let j = -2; j <= 2; j++) {
					const x = cx + c * i * 6 - sn * j * 6
					const z = cz + sn * i * 6 + c * j * 6
					if (!okGround(t, x, z) || Math.abs(t.riverDist(x, z)) < 30) continue
					this.tree(x, z, 'apple', 0.7 + rnd() * 0.2)
				}
			}
		}
	}

	/** A handful of willows is not worth a mesh of its own: they become the map's leafy species. */
	fewWillows() {
		const { flora } = this.t
		const willows = this.set.trees.filter((tr) => tr.species === flora.waterside)
		if (willows.length < MIN_WILLOWS) for (const tr of willows) tr.species = flora.leafy
	}

	/** Anti-tank obstacles: rows of steel hedgehogs or dragon's teeth flanking a lane halfway to the crossing. */
	obstacles() {
		const { t, rnd } = this
		const kind = t.features.obstacles
		if (kind === 'none') return
		for (const lane of t.lanes) {
			if (rnd() < 0.4) continue
			const legs = [
				[lane[1], lane[2]],
				[lane[lane.length - 2], lane[lane.length - 3]],
			]
			for (const [a, b] of legs) {
				const px = a.x + (b.x - a.x) * 0.55
				const pz = a.z + (b.z - a.z) * 0.55
				const dx = b.x - a.x
				const dz = b.z - a.z
				const l = Math.hypot(dx, dz) || 1
				for (let k = -7; k <= 7; k++) {
					if (Math.abs(k) < 2) continue // the road itself stays open
					const x = px + (-dz / l) * k * 3.3
					const z = pz + (dx / l) * k * 3.3
					if (!okGround(t, x, z) || !farFromPlaces(t, x, z, 4)) continue
					this.set.rocks.push({ x, z, r: 1.1, kind: kind === 'hedgehogs' ? 'hedgehog' : 'tooth' })
				}
			}
		}
	}

	/** Bushes in clusters, favouring forest edges and meadows. */
	bushes() {
		const { t, rnd } = this
		for (let c = 0; c < t.params.bushClusters; c++) {
			let cx: number
			let cz: number
			if (rnd() < 0.5 && t.forests.length) {
				const f = t.forests[Math.floor(rnd() * t.forests.length)]
				const a = rnd() * Math.PI * 2
				cx = f.x + Math.cos(a) * (f.r + 6)
				cz = f.z + Math.sin(a) * (f.r + 6)
			} else {
				cx = (rnd() * 2 - 1) * (WORLD_HALF - 110)
				cz = (rnd() * 2 - 1) * (WORLD_HALF - 110)
			}
			const n = 3 + Math.floor(rnd() * 6)
			for (let k = 0; k < n; k++) {
				const x = cx + (rnd() - 0.5) * 16
				const z = cz + (rnd() - 0.5) * 16
				if (!okGround(t, x, z)) continue
				this.set.bushes.push({ x, z, r: 2.2 + rnd() * 1.6 })
			}
		}
	}

	/** Rocks in the mountains and over meadows and forests (keep trying until the quota is met). */
	rocks() {
		const { t, rnd } = this
		const rocks = this.set.rocks
		for (let k = 0; k < WORLD.rocks * 12 && rocks.length < WORLD.rocks; k++) {
			const edge = rnd() < 0.6
			const x = (rnd() * 2 - 1) * (WORLD_HALF - 60)
			const z = (rnd() * 2 - 1) * (WORLD_HALF - 60)
			const b = t.biome(x, z)
			if (edge ? b !== 'mountain' : b !== 'meadow' && b !== 'forest') continue
			if (rocks.some((o) => Math.hypot(o.x - x, o.z - z) < 6)) continue
			const rock: Rock = { x, z, r: 1.2 + rnd() * 2.2, kind: 'rock' }
			rocks.push(rock)
		}
	}

	/** Haystacks in the fields. */
	haystacks() {
		const { t, rnd } = this
		const n = t.params.haystacks
		for (let k = 0; k < n * 3 && this.set.hay.length < n; k++) {
			const x = (rnd() * 2 - 1) * (WORLD_HALF - 120)
			const z = (rnd() * 2 - 1) * (WORLD_HALF - 120)
			if (t.biome(x, z) !== 'field') continue
			this.set.hay.push({ x, z, crushed: false })
		}
	}

	/** Wooden fences around villages, one 3 m segment at a time, stopping at water. */
	fences() {
		const { t, rnd } = this
		for (const s of t.settlements) {
			if (s.kind !== 'village') continue
			const n = s.variant === 'farm' ? 2 : 3 + Math.floor(rnd() * 3)
			for (let f = 0; f < n; f++) {
				const a0 = rnd() * Math.PI * 2
				const len = 12 + rnd() * 20
				const r0 = s.r * (0.55 + rnd() * 0.4)
				const x0 = s.x + Math.cos(a0) * r0
				const z0 = s.z + Math.sin(a0) * r0
				const dir = a0 + Math.PI / 2 + (rnd() - 0.5)
				for (let d = 0; d < len; d += 3) {
					const x = x0 + Math.cos(dir) * d
					const z = z0 + Math.sin(dir) * d
					if (t.biome(x, z) === 'water') break
					this.set.fences.push({ x, z, rot: -dir, down: false })
				}
			}
		}
	}
}

/** Scatter vegetation and clutter over a map. The order of the steps is fixed: it is the map's RNG sequence. */
export function scatterProps(terrain: Terrain): PropSet {
	const s = new Scatter(terrain, terrain.rnd)
	s.forests()
	s.loneTrees()
	s.alleys()
	s.orchards()
	s.fewWillows()
	s.obstacles()
	s.bushes()
	s.rocks()
	s.haystacks()
	s.fences()
	return s.set
}
