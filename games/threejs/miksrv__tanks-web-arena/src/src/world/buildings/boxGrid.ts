import { WORLD_HALF } from '../../config'
import type { OBB } from '../obb'

const CELL = 32 // m
const PAD = 1 // m added around every footprint, so rounding at a cell edge never drops a box
const EXTENT = WORLD_HALF + 80 // m: the grid reaches past the playable edge (bunkers and bridges sit near it)
const SIZE = Math.ceil((2 * EXTENT) / CELL)

const index = (v: number) => Math.floor((v + EXTENT) / CELL)
const inside = (i: number, j: number) => i >= 0 && j >= 0 && i < SIZE && j < SIZE

/**
 * Uniform grid over the map for a fixed set of boxes. A box is listed in every cell its footprint touches, so a
 * query only has to look at the cells it covers; each box is reported once per query.
 */
export class BoxGrid {
	private readonly cells = new Array<number[] | undefined>(SIZE * SIZE)
	/** Query number that last reported each box (dedup without a Set). */
	private readonly stamp: Uint32Array
	private query = 0

	constructor(boxes: readonly OBB[]) {
		this.stamp = new Uint32Array(boxes.length)
		boxes.forEach((b, n) => {
			const ex = Math.abs(b.cos) * b.hw + Math.abs(b.sin) * b.hd + PAD
			const ez = Math.abs(b.sin) * b.hw + Math.abs(b.cos) * b.hd + PAD
			const i0 = Math.max(0, index(b.x - ex))
			const i1 = Math.min(SIZE - 1, index(b.x + ex))
			const j0 = Math.max(0, index(b.z - ez))
			const j1 = Math.min(SIZE - 1, index(b.z + ez))
			for (let i = i0; i <= i1; i++) for (let j = j0; j <= j1; j++) (this.cells[i * SIZE + j] ??= []).push(n)
		})
	}

	/** Boxes listed in the cells under the square of half-size `r` around (x, z), written into `out`. */
	near(x: number, z: number, r: number, out: number[]): number[] {
		out.length = 0
		this.query++
		const i0 = Math.max(0, index(x - r))
		const i1 = Math.min(SIZE - 1, index(x + r))
		const j0 = Math.max(0, index(z - r))
		const j1 = Math.min(SIZE - 1, index(z + r))
		for (let i = i0; i <= i1; i++) for (let j = j0; j <= j1; j++) this.collect(i, j, out)
		return out
	}

	/** Boxes listed in the cells the segment (ax, az)→(bx, bz) passes through (a grid walk), written into `out`. */
	along(ax: number, az: number, bx: number, bz: number, out: number[]): number[] {
		out.length = 0
		this.query++
		let i = index(ax)
		let j = index(az)
		const dx = bx - ax
		const dz = bz - az
		const si = Math.sign(dx)
		const sj = Math.sign(dz)
		// Segment parameter at the next vertical / horizontal cell edge, and its increment per cell
		let tx = si ? ((i + (si > 0 ? 1 : 0)) * CELL - EXTENT - ax) / dx : Infinity
		let tz = sj ? ((j + (sj > 0 ? 1 : 0)) * CELL - EXTENT - az) / dz : Infinity
		const stepX = si ? CELL / Math.abs(dx) : Infinity
		const stepZ = sj ? CELL / Math.abs(dz) : Infinity
		let left = Math.abs(index(bx) - i) + Math.abs(index(bz) - j)
		this.collect(i, j, out)
		while (left-- > 0) {
			if (tx < tz) {
				i += si
				tx += stepX
			} else {
				j += sj
				tz += stepZ
			}
			this.collect(i, j, out)
		}
		return out
	}

	private collect(i: number, j: number, out: number[]) {
		if (!inside(i, j)) return
		const c = this.cells[i * SIZE + j]
		if (!c) return
		for (const n of c) {
			if (this.stamp[n] === this.query) continue
			this.stamp[n] = this.query
			out.push(n)
		}
	}
}
