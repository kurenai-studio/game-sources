import { WORLD_HALF } from '../config'

/** Spatial hash for cheap "what is near (x, z)" queries over a fixed set of points. */
export class SpatialGrid<T extends { x: number; z: number }> {
	private readonly cells = new Map<number, T[]>()

	constructor(private readonly cell: number) {}

	private index(v: number) {
		return Math.floor((v + WORLD_HALF) / this.cell)
	}

	private static key(i: number, j: number) {
		return (i << 10) | j
	}

	add(item: T) {
		const k = SpatialGrid.key(this.index(item.x), this.index(item.z))
		const list = this.cells.get(k)
		if (list) list.push(item)
		else this.cells.set(k, [item])
	}

	/** Items in the cells overlapping the square of half-size `r` around (x, z), written into `out`. */
	near(x: number, z: number, r: number, out: T[]): T[] {
		out.length = 0
		const i0 = this.index(x - r)
		const i1 = this.index(x + r)
		const j0 = this.index(z - r)
		const j1 = this.index(z + r)
		for (let i = i0; i <= i1; i++) {
			for (let j = j0; j <= j1; j++) {
				const c = this.cells.get(SpatialGrid.key(i, j))
				if (c) for (const it of c) out.push(it)
			}
		}
		return out
	}
}
