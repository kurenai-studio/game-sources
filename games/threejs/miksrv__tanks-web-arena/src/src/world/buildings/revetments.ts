import * as THREE from 'three'
import type { Terrain } from '../terrain'
import { frameAt, type BuildContext } from './builder'

const FRONT = 8.5 // m, the front berm (the tank's nose goes up to it)
const SIDE = 6 // m, side berms
const THICK = 1.4
const HEIGHT = 1.25
const ROUTE_CLEAR = 30 // m from roads and lane waypoints // m: hull-down for most hulls, the turret free to shoot
const earth = new THREE.Color('#6a5a40')
const sandbag = new THREE.Color('#a8976c')
const BAD_GROUND: readonly string[] = ['water', 'mud', 'road', 'rail', 'town', 'village', 'forest', 'mountain', 'sand']

/** May a revetment stand here: open, level, dry ground clear of buildings. */
function fits(ctx: BuildContext, x: number, z: number): boolean {
	const t = ctx.t
	if (BAD_GROUND.includes(t.biome(x, z)) || !t.passable(x, z) || t.waterDepth(x, z) > 0) return false
	// Off the bots' routes: a tank driving along a lane must not blunder into the U
	if (t.roads.dist(x, z) < ROUTE_CLEAR) return false
	if (t.lanes.some((lane) => lane.some((p) => Math.hypot(p.x - x, p.z - z) < ROUTE_CLEAR))) return false
	const h = t.height(x, z)
	for (const [dx, dz] of [
		[6, 0],
		[-6, 0],
		[0, 6],
		[0, -6],
	])
		if (Math.abs(t.height(x + dx, z + dz) - h) > 1.2) return false
	return ctx.list.every((b) => Math.hypot(b.box.x - x, b.box.z - z) > 18)
}

/** Facing: toward the enemy side of the map for whoever would use it (the base axis, sign by the half it is on). */
function facing(t: Terrain, x: number, z: number): number {
	const { dx, dz } = t.axis
	const sign = x * dx + z * dz < 0 ? 1 : -1
	return Math.atan2(dx * sign, dz * sign)
}

/** An earth U open at the back: a front berm and two side berms with a row of sandbags on top. */
function revetment(ctx: BuildContext, x: number, z: number, face: number) {
	const { t, b } = ctx
	const y = t.height(x, z) - 0.25
	// Builder frame: local x along the facing, local z across it
	const rot = Math.atan2(-Math.cos(face), Math.sin(face))
	const at = frameAt(x, z, -rot)
	const parts: [number, number, number, number][] = [
		[FRONT / 2 - THICK / 2 + 2, 0, THICK, FRONT],
		[0.5, FRONT / 2 - THICK / 2, SIDE, THICK],
		[0.5, -(FRONT / 2 - THICK / 2), SIDE, THICK],
	]
	for (const [a, s, w, d] of parts) {
		const [px, pz] = at(a, s)
		const py = Math.min(y, t.height(px, pz) - 0.25)
		b.box(w, HEIGHT, d, earth, px, py + HEIGHT / 2, pz, rot)
		b.box(w * 0.92, 0.28, d * 0.92, sandbag, px, py + HEIGHT + 0.12, pz, rot)
		ctx.place('wall', px, pz, w, d, rot, py, HEIGHT + 0.25)
	}
}

/**
 * Tank revetments: two or three in front of each base, facing the enemy, and a few on the high ground of each half
 * of the map. Spots are drawn from the map's RNG and kept only on open, level ground.
 */
export function revetments(ctx: BuildContext) {
	const { t, rnd } = ctx
	const { dx, dz, px, pz } = t.axis
	const spots: { x: number; z: number }[] = []
	for (const [i, base] of t.bases.entries()) {
		const f = i === 0 ? 1 : -1
		const n = 2 + Math.floor(rnd() * 2)
		for (let k = 0, tries = 0; k < n && tries < 40; tries++) {
			const ahead = 70 + rnd() * 40
			const across = (rnd() - 0.5) * 110
			const x = base.x + dx * f * ahead + px * across
			const z = base.z + dz * f * ahead + pz * across
			if (!fits(ctx, x, z) || spots.some((s) => Math.hypot(s.x - x, s.z - z) < 20)) continue
			spots.push({ x, z })
			revetment(ctx, x, z, facing(t, x, z))
			k++
		}
	}
	// High ground: the highest of a few candidates in each half
	for (const f of [-1, 1]) {
		for (let k = 0; k < 2; k++) {
			let best: { x: number; z: number; h: number } | null = null
			for (let c = 0; c < 30; c++) {
				const u = f * (60 + rnd() * 180)
				const v = (rnd() - 0.5) * 500
				const x = dx * u + px * v
				const z = dz * u + pz * v
				if (!fits(ctx, x, z) || spots.some((s) => Math.hypot(s.x - x, s.z - z) < 40)) continue
				const h = t.height(x, z)
				if (!best || h > best.h) best = { x, z, h }
			}
			if (!best) continue
			spots.push(best)
			revetment(ctx, best.x, best.z, facing(t, best.x, best.z))
		}
	}
}
