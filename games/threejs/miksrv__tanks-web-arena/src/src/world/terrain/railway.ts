import * as THREE from 'three'
import { RAIL, WORLD, WORLD_HALF } from '../../config'
import type { Point } from './types'

const { smoothstep, clamp } = THREE.MathUtils
const STEP = 8 // m between profile samples
const SMOOTH = 10 // samples each side in the box filter (±80 m), applied three times
const END_FADE = 40 // m over which the bank runs out at each end

/**
 * A straight railway on the line equally far from both bases, from mountain foot to mountain foot. Its rail top
 * follows a smoothed profile of the natural ground plus RAIL.bank, so it runs on an embankment over the hollows and
 * in a cutting through the rises; it comes down to the ground at level crossings with the roads.
 */
export class Railway {
	/** Unit direction along the track and its normal. */
	readonly dx: number
	readonly dz: number
	/** Usable stretch of the line: s from `s0` to `s1` (s = 0 at `origin`). */
	readonly s0: number
	readonly s1: number
	private readonly profile: Float32Array

	/**
	 * `ground` is the natural ground height the profile follows; `keep` says where track may run at all (the sea
	 * side of a coast map is not).
	 */
	constructor(
		readonly origin: Point,
		dir: Point,
		ground: (x: number, z: number) => number,
		private readonly keep: (x: number, z: number) => boolean,
	) {
		const l = Math.hypot(dir.x, dir.z) || 1
		this.dx = dir.x / l
		this.dz = dir.z / l
		// The track ends where the mountains begin
		const inner = WORLD_HALF - WORLD.mountainBand + 15
		let s0 = 0
		let s1 = 0
		while (this.inside(s0 - STEP, inner)) s0 -= STEP
		while (this.inside(s1 + STEP, inner)) s1 += STEP
		this.s0 = s0
		this.s1 = s1
		const n = Math.round((s1 - s0) / STEP) + 1
		let prof: Float32Array = new Float32Array(n)
		for (let i = 0; i < n; i++) {
			const p = this.at(s0 + i * STEP)
			prof[i] = ground(p.x, p.z)
		}
		for (let pass = 0; pass < 3; pass++) prof = boxFilter(prof, SMOOTH)
		this.profile = prof
	}

	private inside(s: number, inner: number) {
		const p = this.at(s)
		return Math.abs(p.x) < inner && Math.abs(p.z) < inner && this.keep(p.x, p.z)
	}

	/** Point on the track at distance `s`. */
	at(s: number): Point {
		return { x: this.origin.x + this.dx * s, z: this.origin.z + this.dz * s }
	}

	/** Distance along the track of the point's foot. */
	along(x: number, z: number): number {
		return (x - this.origin.x) * this.dx + (z - this.origin.z) * this.dz
	}

	/** Unsigned distance from the track centre line. */
	dist(x: number, z: number): number {
		return Math.abs(-(x - this.origin.x) * this.dz + (z - this.origin.z) * this.dx)
	}

	/** Rail top height at `s` (the bank runs out toward the ends). */
	railTop(s: number): number {
		const f = clamp((s - this.s0) / STEP, 0, this.profile.length - 1)
		const i = Math.min(Math.floor(f), this.profile.length - 2)
		const k = f - i
		return this.profile[i] * (1 - k) + this.profile[i + 1] * k + RAIL.bank
	}

	/** 0 past the ends, 1 along the usable stretch. */
	fade(s: number): number {
		return smoothstep(s, this.s0, this.s0 + END_FADE) * (1 - smoothstep(s, this.s1 - END_FADE, this.s1))
	}

	/**
	 * Ground height with the railway cut in: the crown flat at the rail top, the sides sloping back to the natural
	 * ground (bank or cutting), nothing within a road's reach (a level crossing). `roadDist` is the distance to the
	 * nearest road; `inTown` (0…1) brings the bank down to the street level of a town the line runs through.
	 */
	shape(h: number, x: number, z: number, roadDist: number, inTown = 1): number {
		const d = this.dist(x, z)
		if (d > 40) return h
		const s = this.along(x, z)
		const f = this.fade(s) * smoothstep(roadDist, RAIL.crossing[0], RAIL.crossing[1]) * inTown
		if (f <= 0) return h
		const top = this.railTop(s)
		const side = Math.abs(top - h) / RAIL.slope
		const k = d <= RAIL.top ? 1 : 1 - clamp((d - RAIL.top) / (side + 0.01), 0, 1)
		return h + (top - h) * k * f
	}

	/** On the ballast of the track (the rail biome). */
	onTrack(x: number, z: number, roadDist: number): boolean {
		return this.dist(x, z) < RAIL.top - 0.5 && this.fade(this.along(x, z)) > 0.5 && roadDist > RAIL.crossing[0]
	}
}

function boxFilter(a: Float32Array, r: number): Float32Array {
	const out = new Float32Array(a.length)
	for (let i = 0; i < a.length; i++) {
		let sum = 0
		let n = 0
		for (let j = Math.max(0, i - r); j <= Math.min(a.length - 1, i + r); j++) {
			sum += a[j]
			n++
		}
		out[i] = sum / n
	}
	return out
}
