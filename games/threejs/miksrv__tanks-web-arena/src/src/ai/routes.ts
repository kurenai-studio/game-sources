import type { Tank, WorldRefs } from '../tank/tank'
import type { LanePoint, Terrain } from '../world/terrain'
import { flatSpot } from './positions'
import type { Pt } from './types'

/** Route from a to b that crosses the river only over a bridge or through a ford. */
export function routeAcross(t: Terrain, from: Pt, to: Pt): Pt[] {
	const sf = t.riverSide(from.x, from.z)
	const st = t.riverSide(to.x, to.z)
	if (sf === 0 || st === 0 || sf === st || !t.crossings.length) return [to]
	let best = t.crossings[0]
	let bd = Infinity
	for (const c of t.crossings) {
		const d = Math.hypot(c.x - from.x, c.z - from.z) + Math.hypot(to.x - c.x, to.z - c.z)
		if (d < bd) {
			bd = d
			best = c
		}
	}
	return [...t.crossingPath(best, sf), to]
}

/** Point `ahead` metres toward the enemy base of `team` and `side` metres across the lane axis from (x, z). */
export function offsetOnAxis(t: Terrain, team: 0 | 1, x: number, z: number, ahead: number, side: number): Pt {
	const { dx, dz, px, pz } = t.axis
	const f = team === 0 ? 1 : -1
	return { x: x + dx * f * ahead + px * side, z: z + dz * f * ahead + pz * side }
}

/**
 * Index of the first point of the lane's middle (the near end of the crossing, or the open-ground anchor): lanes run
 * base, gate, two bends, the middle points, two bends, gate, base.
 */
export const CENTRE_INDEX = 4

/** Lane `index` (a random one when null) from our base toward the enemy base (copied: the plan may bend it). */
export function pickLane(w: WorldRefs, team: 0 | 1, index: number | null): LanePoint[] {
	const lanes = w.terrain.lanes
	const lane = lanes[index ?? Math.floor(Math.random() * lanes.length)].map((p) => ({ ...p }))
	return team === 1 ? lane.slice().reverse() : lane
}

/** A point lifted to eye height above the ground: what a hidden tank should keep in view. */
export function watchPoint(t: Terrain, p: Pt) {
	return { x: p.x, y: t.height(p.x, p.z) + 1.5, z: p.z }
}

/**
 * The lane without its first point: that is our base centre, the middle of the spawn formation, and steering every
 * tank there first makes the whole row converge on one spot. The lane gate is the first point to head for.
 */
export function leaveBase(lane: LanePoint[]): LanePoint[] {
	return lane.slice(1)
}

/** Fall back toward our own base, behind the nearest building on the way if there is one (artillery: level ground). */
export function planRetreat(w: WorldRefs, me: Tank): { path: Pt[]; holdSpot: Pt } {
	const own = w.terrain.bases[me.team]
	const dx = own.x - me.pos.x
	const dz = own.z - me.pos.z
	const l = Math.hypot(dx, dz) || 1
	const cover = w.buildings.nearest(me.pos.x + (dx / l) * 60, me.pos.z + (dz / l) * 60, 80)
	const goal = cover
		? { x: cover.box.x + (dx / l) * 14, z: cover.box.z + (dz / l) * 14 }
		: { x: me.pos.x + (dx / l) * 120, z: me.pos.z + (dz / l) * 120 }
	const spot = me.def.gun.howitzer ? flatSpot(w.terrain, goal.x, goal.z, 30) : w.terrain.findSpot(goal.x, goal.z, 14)
	return { path: routeAcross(w.terrain, { x: me.pos.x, z: me.pos.z }, spot), holdSpot: spot }
}
