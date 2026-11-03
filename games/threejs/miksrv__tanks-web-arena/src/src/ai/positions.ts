import type { Tank, WorldRefs } from '../tank/tank'
import type { Terrain } from '../world/terrain'
import type { Pt } from './types'

/** How much a spot on a slope is worth losing per unit of gradient (m of the score). */
const SLOPE_WEIGHT = 120
/** Vantage scoring: metres of score per metre of height gained over the start point. */
const HEIGHT_WEIGHT = 2.5
/** Tank destroyers snipe: height counts this many times more for them (a long view, a hull-down aimed shot). */
export const TD_HEIGHT = 2.2
const LOS_BONUS = 60
const BUSH_BONUS = 25
const CROWD_DIST = 12
const MAX_CANDIDATES = 32 // each costs a line-of-sight probe
const EYE = 2.4 // m above the ground for vantage line-of-sight probes

const rnd = (k: number) => (Math.random() - 0.5) * k

/** Steepest gradient under a hull standing at (x, z): the centre and four points 3 m out. */
export function slopeAt(t: Terrain, x: number, z: number): number {
	const h = (dx: number, dz: number) => t.height(x + dx, z + dz)
	const e = 3
	const gx = Math.max(Math.abs(h(e, 0) - h(0, 0)), Math.abs(h(0, 0) - h(-e, 0))) / e
	const gz = Math.max(Math.abs(h(0, e) - h(0, 0)), Math.abs(h(0, 0) - h(0, -e))) / e
	return Math.hypot(gx, gz)
}

function usable(t: Terrain, x: number, z: number) {
	return t.passable(x, z) && t.waterDepth(x, z) <= 0 && !t.deckAt(x, z)
}

const crowded = (p: Pt, avoid: readonly Pt[]) => avoid.some((a) => Math.hypot(a.x - p.x, a.z - p.z) < CROWD_DIST)

/**
 * The flattest open spot within `radius` of (cx, cz), nearer ones preferred; the centre itself when nothing is
 * better. Artillery needs level ground: a tilted hull eats the elevation the long arc needs.
 */
export function flatSpot(t: Terrain, cx: number, cz: number, radius: number, avoid: readonly Pt[] = []): Pt {
	let best: Pt = { x: cx, z: cz }
	let bs = usable(t, cx, cz) && !crowded(best, avoid) ? slopeAt(t, cx, cz) * SLOPE_WEIGHT : Infinity
	for (let i = 0; i < 48; i++) {
		const a = Math.random() * Math.PI * 2
		const d = Math.sqrt(Math.random()) * radius
		const p = { x: cx + Math.cos(a) * d, z: cz + Math.sin(a) * d }
		if (!usable(t, p.x, p.z) || crowded(p, avoid)) continue
		const s = slopeAt(t, p.x, p.z) * SLOPE_WEIGHT + d * 0.05
		if (s < bs) {
			bs = s
			best = p
		}
	}
	return best
}

export interface VantageOpts {
	/** Point to keep in view (an enemy, or the stretch of lane the enemy will come along). */
	watch?: { x: number; y: number; z: number } | null
	/** Bushes count extra (scouts, tank destroyers). */
	bushes?: boolean
	/** Teammates' spots to keep clear of. */
	avoid?: readonly Pt[]
	/** × the worth of height (1 by default). */
	height?: number
}

/**
 * A firing position within `radius` of `around`: higher ground is better, a view of `watch` far better, a bush helps
 * the stealthy ones; steep slopes and crowding are out.
 */
export function vantage(w: WorldRefs, around: Pt, radius: number, o: VantageOpts = {}): Pt {
	const t = w.terrain
	const h0 = t.height(around.x, around.z)
	const cands: Pt[] = [around]
	for (let i = 0; i < 18; i++) {
		const a = Math.random() * Math.PI * 2
		const d = Math.sqrt(Math.random()) * radius
		cands.push({ x: around.x + Math.cos(a) * d, z: around.z + Math.sin(a) * d })
	}
	if (o.bushes) {
		for (const b of w.props.bushes) {
			if (cands.length >= MAX_CANDIDATES) break
			if (Math.hypot(b.x - around.x, b.z - around.z) < radius) cands.push(b)
		}
	}
	let best = around
	let bs = -Infinity
	for (const p of cands) {
		if (!usable(t, p.x, p.z) || (o.avoid && crowded(p, o.avoid))) continue
		const slope = slopeAt(t, p.x, p.z)
		if (slope > 0.3) continue
		const h = t.height(p.x, p.z)
		let s =
			(h - h0) * HEIGHT_WEIGHT * (o.height ?? 1) -
			slope * SLOPE_WEIGHT * 0.3 -
			Math.hypot(p.x - around.x, p.z - around.z) * 0.2
		if (o.bushes && w.props.bushAt(p.x, p.z)) s += BUSH_BONUS
		if (o.watch && seesPoint(w, p, h + EYE, o.watch)) s += LOS_BONUS
		if (s > bs) {
			bs = s
			best = p
		}
	}
	// Nothing usable around (a lake, a bog, the sea): the nearest open spot instead
	return usable(t, best.x, best.z) ? best : t.findSpot(around.x, around.z, radius + 30)
}

function seesPoint(w: WorldRefs, p: Pt, y: number, q: { x: number; y: number; z: number }) {
	return w.terrain.lineOfSight(p.x, y, p.z, q.x, q.y, q.z) && !w.buildings.blocksLos(p.x, y, p.z, q.x, q.y, q.z)
}

/**
 * A spot close behind us (away from `threat`) where its gun cannot see our turret roof: behind a house first, else
 * down the back of a rise. Null when there is no such cover within ~25 m.
 */
export function coverFrom(w: WorldRefs, me: Tank, threat: Tank): Pt | null {
	const t = w.terrain
	const dx = me.pos.x - threat.pos.x
	const dz = me.pos.z - threat.pos.z
	const l = Math.hypot(dx, dz) || 1
	const ux = dx / l
	const uz = dz / l
	const gy = threat.pos.y + threat.view.hullTop + threat.view.gun.position.y
	const top = me.view.hullTop + me.def.shape.tH * 0.8
	const hidden = (p: Pt) =>
		!seesPoint(w, { x: threat.pos.x, z: threat.pos.z }, gy, { x: p.x, y: t.height(p.x, p.z) + top, z: p.z })
	const cands: Pt[] = []
	const b = w.buildings.nearest(me.pos.x, me.pos.z, 30)
	if (b) {
		const bx = b.box.x - threat.pos.x
		const bz = b.box.z - threat.pos.z
		const bl = Math.hypot(bx, bz) || 1
		const back = Math.max(b.box.hw, b.box.hd) + me.def.shape.hullL * 0.6 + 2
		cands.push({ x: b.box.x + (bx / bl) * back, z: b.box.z + (bz / bl) * back })
	}
	for (const d of [7, 11, 16, 22]) {
		for (const a of [0, 0.45, -0.45]) {
			const c = Math.cos(a)
			const s = Math.sin(a)
			cands.push({ x: me.pos.x + (ux * c - uz * s) * d, z: me.pos.z + (uz * c + ux * s) * d })
		}
	}
	for (const p of cands) {
		if (Math.hypot(p.x - me.pos.x, p.z - me.pos.z) > 28 || !usable(t, p.x, p.z)) continue
		if (w.props.rockAt(p.x, p.z, me.def.shape.hullW * 0.6)) continue
		if (hidden(p)) return p
	}
	return null
}

/** Random usable point near (x, z), kept inside the map. */
export function scatterNear(t: Terrain, x: number, z: number, spread: number, half: number): Pt {
	for (let i = 0; i < 20; i++) {
		const p = { x: clampTo(x + rnd(spread), half), z: clampTo(z + rnd(spread), half) }
		if (usable(t, p.x, p.z)) return p
	}
	return t.findSpot(clampTo(x, half), clampTo(z, half), spread)
}

const clampTo = (v: number, half: number) => Math.max(-half, Math.min(half, v))
