import * as THREE from 'three'
import { TERRAIN_RES, WORLD, WORLD_HALF } from '../../config'
import type { Simplex2D } from '../../core/noise'
import type { LayoutAxis, Relief } from './types'

const { smoothstep } = THREE.MathUtils
const EROSION_PASSES = 40
/** Steppe gullies (balki): depth, and how thin the noise's zero lines are cut (closer to 1 = narrower). */
const GULLY_DEPTH = 6.5
const GULLY_EDGE = [0.9, 0.985] as const
/** Pass: the ridge across the middle of the map, and the saddles where the three lanes go over it. */
const RIDGE_HEIGHT = 24
const RIDGE_SPAN = [55, 210] as const // m from the middle line: full height inside, gone outside
const SADDLES = [-200, 0, 200] // m across the axis (the lane anchors on a dry map)
const SADDLE_WIDTH = [28, 85] as const

/** Grid step in metres. */
export const CELL_SIZE = (WORLD_HALF * 2) / (TERRAIN_RES - 1)

/** Height of the base relief at (x, z) for each relief style, before erosion. */
function reliefNoise(
	style: Relief,
	n: Simplex2D,
	hills: number,
	axis: LayoutAxis,
	rc: number,
	rs: number,
	x: number,
	z: number,
): number {
	const bumps = () => WORLD.detail * n.noise(x * 0.03, z * 0.03)
	switch (style) {
		case 'plains': // wide, low swells and softer bumps
			return hills * 0.4 * n.fbm(x * 0.0028, z * 0.0028, 3) + WORLD.detail * 0.6 * n.noise(x * 0.03, z * 0.03)
		case 'ridges': {
			// long crests in a random direction: ridged noise stretched 3:1
			const u = x * rc + z * rs
			const v = -x * rs + z * rc
			const ridge = 1 - Math.abs(n.noise(u * 0.0022 + 5, v * 0.0066 - 3))
			return hills * (0.9 * ridge * ridge - 0.35) + hills * 0.35 * n.fbm(x * 0.0038, z * 0.0038, 3) + bumps()
		}
		case 'valley': {
			// a lowland along the base-to-base axis, ground climbing toward both flanks
			const p = Math.abs(x * axis.px + z * axis.pz)
			return hills * 0.6 * n.fbm(x * 0.0038, z * 0.0038, 4) + 16 * smoothstep(p, 110, 420) + bumps()
		}
		case 'steppe': {
			// Nearly flat, cut by long meandering gullies along the zero lines of a low-frequency noise
			const ridged = 1 - Math.abs(n.noise(x * 0.0042 + 17, z * 0.0042 - 9))
			const gully = smoothstep(ridged, GULLY_EDGE[0], GULLY_EDGE[1]) * GULLY_DEPTH
			return (
				hills * 0.22 * n.fbm(x * 0.0025, z * 0.0025, 3) +
				WORLD.detail * 0.5 * n.noise(x * 0.03, z * 0.03) -
				gully
			)
		}
		case 'pass': {
			// A ridge across the base axis, low saddles where the lanes cross it
			const u = Math.abs(x * axis.dx + z * axis.dz)
			const p = x * axis.px + z * axis.pz
			const saddle = Math.max(...SADDLES.map((v) => 1 - smoothstep(Math.abs(p - v), ...SADDLE_WIDTH)))
			const ridge = RIDGE_HEIGHT * (1 - smoothstep(u, ...RIDGE_SPAN)) * (1 - 0.85 * saddle)
			return hills * 0.5 * n.fbm(x * 0.0038, z * 0.0038, 4) + ridge + bumps()
		}
		default:
			return hills * n.fbm(x * 0.0038, z * 0.0038, 4) + bumps()
	}
}

/**
 * Thermal erosion: grain slides off every slope steeper than `WORLD.maxSlope` until none is left. Gauss–Seidel:
 * each neighbour pair is settled in place, so a pass never overshoots; ~30 passes reach a fixed point.
 */
function erode(g: Float32Array) {
	const r = TERRAIN_RES
	const lim = WORLD.maxSlope * CELL_SIZE
	const limD = lim * Math.SQRT2
	const settle = (a: number, b: number, l: number) => {
		const d = g[a] - g[b]
		if (d > l) {
			const m = (d - l) / 2
			g[a] -= m
			g[b] += m
		} else if (d < -l) {
			const m = (-d - l) / 2
			g[a] += m
			g[b] -= m
		}
	}
	for (let pass = 0; pass < EROSION_PASSES; pass++) {
		for (let j = 0; j < r - 1; j++) {
			for (let i = 0; i < r - 1; i++) {
				const k = j * r + i
				settle(k, k + 1, lim)
				settle(k, k + r, lim)
				settle(k, k + r + 1, limD)
				if (i > 0) settle(k, k + r - 1, limD)
			}
		}
	}
}

/**
 * The rolling base relief on the heightmap grid: fbm hills plus small bumps, then thermal erosion. Hilly maps keep
 * their valleys and crests but lose the cliffs: tall hills turn into plateaus with climbable sides, hollows into
 * flat-bottomed basins. `ridgeAngle` orients the ridges style.
 */
export function bakeRelief(style: Relief, n: Simplex2D, hills: number, axis: LayoutAxis, ridgeAngle: number) {
	const g = new Float32Array(TERRAIN_RES * TERRAIN_RES)
	const rc = Math.cos(ridgeAngle)
	const rs = Math.sin(ridgeAngle)
	for (let j = 0; j < TERRAIN_RES; j++) {
		for (let i = 0; i < TERRAIN_RES; i++) {
			const x = -WORLD_HALF + i * CELL_SIZE
			const z = -WORLD_HALF + j * CELL_SIZE
			g[j * TERRAIN_RES + i] = reliefNoise(style, n, hills, axis, rc, rs, x, z)
		}
	}
	erode(g)
	return g
}

/** Bilinear sample of a heightmap-sized grid, clamped at the world edge. */
export function sampleClamped(g: Float32Array, x: number, z: number): number {
	const n = TERRAIN_RES - 1
	const r = TERRAIN_RES
	const fx = THREE.MathUtils.clamp(((x + WORLD_HALF) / (WORLD_HALF * 2)) * n, 0, n - 1e-6)
	const fz = THREE.MathUtils.clamp(((z + WORLD_HALF) / (WORLD_HALF * 2)) * n, 0, n - 1e-6)
	const i = Math.floor(fx)
	const j = Math.floor(fz)
	const tx = fx - i
	const tz = fz - j
	return (
		(g[j * r + i] * (1 - tx) + g[j * r + i + 1] * tx) * (1 - tz) +
		(g[(j + 1) * r + i] * (1 - tx) + g[(j + 1) * r + i + 1] * tx) * tz
	)
}
