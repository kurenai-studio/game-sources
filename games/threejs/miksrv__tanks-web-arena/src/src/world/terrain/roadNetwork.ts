import { WORLD_HALF } from '../../config'
import type { Point } from './types'

type Segment = [ax: number, az: number, bx: number, bz: number]

const CELL = 48 // m
const REACH = 24 // m: the grid answers exactly within this distance of a road

/** Smoothed dirt roads: polylines for props, dense segments with a spatial grid for distance queries. */
export class RoadNetwork {
	/** Smoothed road centre-lines, one polyline per lane (props plant alleys along them). */
	readonly paths: Point[][] = []
	private readonly segments: Segment[] = [] // ≈ 12 m each
	private readonly grid = new Map<number, number[]>() // cell → indices into `segments`

	add(path: Point[]) {
		this.paths.push(path)
		for (let j = 0; j + 1 < path.length; j++)
			this.segments.push([path[j].x, path[j].z, path[j + 1].x, path[j + 1].z])
	}

	/** Index the segments; call once every road is added. */
	buildGrid() {
		this.grid.clear()
		const cell = (v: number) => Math.floor((v + WORLD_HALF) / CELL)
		this.segments.forEach(([ax, az, bx, bz], idx) => {
			const i0 = cell(Math.min(ax, bx) - REACH)
			const i1 = cell(Math.max(ax, bx) + REACH)
			const j0 = cell(Math.min(az, bz) - REACH)
			const j1 = cell(Math.max(az, bz) + REACH)
			for (let i = i0; i <= i1; i++) {
				for (let j = j0; j <= j1; j++) {
					const key = i * 1024 + j
					const list = this.grid.get(key)
					if (list) list.push(idx)
					else this.grid.set(key, [idx])
				}
			}
		})
	}

	/** Distance to the nearest road centre-line. Exact within 24 m (grid lookup); beyond that a full scan when `far`. */
	dist(x: number, z: number, far = false): number {
		if (far) return this.nearest(x, z, this.segments.keys())
		const key = Math.floor((x + WORLD_HALF) / CELL) * 1024 + Math.floor((z + WORLD_HALF) / CELL)
		const list = this.grid.get(key)
		return list ? this.nearest(x, z, list) : REACH
	}

	private nearest(x: number, z: number, indices: Iterable<number>): number {
		let best = Infinity
		for (const idx of indices) {
			const [ax, az, bx, bz] = this.segments[idx]
			const dx = bx - ax
			const dz = bz - az
			const l2 = dx * dx + dz * dz || 1
			const t = Math.max(0, Math.min(1, ((x - ax) * dx + (z - az) * dz) / l2))
			best = Math.min(best, Math.hypot(x - (ax + dx * t), z - (az + dz * t)))
		}
		return best
	}
}
