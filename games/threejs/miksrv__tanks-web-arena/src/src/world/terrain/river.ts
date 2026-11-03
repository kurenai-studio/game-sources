import { WORLD } from '../../config'
import type { Simplex2D } from '../../core/noise'
import type { Crossing, LanePoint, Rnd } from './types'

interface RiverParams {
	cos: number
	sin: number
	off: number
	amp: number
	freq: number
	phase: number
	noise: number
}

/**
 * The meandering river, in its own frame: `u` across the river (positive toward bases[1]), `v` along it.
 * The random parameters are drawn in the constructor (part of the map's RNG sequence).
 */
export class River {
	private readonly p: RiverParams

	constructor(
		readonly present: boolean,
		readonly width: number,
		rot: number,
		r: Rnd,
		private readonly noise: Simplex2D,
	) {
		this.p = {
			cos: Math.cos(rot),
			sin: Math.sin(rot),
			off: (r() - 0.5) * 200,
			amp: 20 + r() * 40,
			freq: 0.006 + r() * 0.006,
			phase: r() * 6.28,
			noise: 15 + r() * 20,
		}
	}

	private toUV(x: number, z: number): [number, number] {
		const { cos, sin } = this.p
		return [x * cos + z * sin, -x * sin + z * cos]
	}
	private toWorld(u: number, v: number): [number, number] {
		const { cos, sin } = this.p
		return [u * cos - v * sin, u * sin + v * cos]
	}
	/** River centre `u` for a given `v`: a slow meander plus noise. */
	private centreU(v: number): number {
		const p = this.p
		return p.off + p.amp * Math.sin(v * p.freq + p.phase) + p.noise * this.noise.noise(v * 0.004, 7.3)
	}

	/** Signed distance across the river axis (negative on the bases[0] side); +∞ when the map has no river. */
	dist(x: number, z: number): number {
		if (!this.present) return Infinity
		const [u, v] = this.toUV(x, z)
		return u - this.centreU(v)
	}

	/** −1 / +1 for the two banks, 0 when there is no river. */
	side(x: number, z: number): -1 | 0 | 1 {
		return this.present ? (Math.sign(this.dist(x, z)) as -1 | 0 | 1) : 0
	}

	/** A bridge or ford at river coordinate `v`, square to the local flow. Bridges draw their style from `r`. */
	crossing(v: number, kind: Crossing['kind'], r: Rnd): Crossing {
		const u = this.centreU(v)
		const s = (this.centreU(v + 2) - this.centreU(v - 2)) / 4
		const inv = 1 / Math.hypot(1, s)
		const { cos, sin } = this.p
		const [x, z] = this.toWorld(u, v)
		// Normal (1, −s) in the river frame, expressed in world space
		const nx = (cos + s * sin) * inv
		const nz = (sin - s * cos) * inv
		const w = this.width / 2
		if (kind === 'ford') return { kind, x, z, nx, nz, half: 26, hw: w + 20, h: 0, ramp: 0, style: 'stone' }
		const style = r() < 0.5 ? 'stone' : 'wood'
		return { kind, x, z, nx, nz, half: w + 22, hw: WORLD.bridgeWidth / 2, h: 0, ramp: WORLD.bridgeRamp[0], style }
	}
}

/** Waypoints through a crossing, starting on the bank `fromSide` (−1 / +1) and ending on the far bank. */
export function crossingPath(c: Crossing, fromSide: number): LanePoint[] {
	const at = (d: number): LanePoint => ({ x: c.x + c.nx * d, z: c.z + c.nz * d, fixed: true })
	if (c.kind === 'ford') return [at(fromSide * 30), at(0), at(-fromSide * 30)]
	const near = c.half + 8
	const far = c.half + c.ramp + 12
	return [at(fromSide * far), at(fromSide * near), at(0), at(-fromSide * near), at(-fromSide * far)]
}

/** The bridge whose deck covers (x, z), if any. */
export function deckAt(crossings: readonly Crossing[], x: number, z: number): Crossing | null {
	for (const c of crossings) {
		if (c.kind !== 'bridge') continue
		const dx = x - c.x
		const dz = z - c.z
		const reach = c.half + c.hw
		if (Math.abs(dx) > reach || Math.abs(dz) > reach) continue
		if (Math.abs(dx * c.nx + dz * c.nz) <= c.half && Math.abs(-dx * c.nz + dz * c.nx) <= c.hw) return c
	}
	return null
}
