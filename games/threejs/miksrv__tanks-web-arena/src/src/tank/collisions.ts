import { COMBAT } from '../config'
import type { Tank } from './tank'
import type { WorldRefs } from './types'

const push = { x: 0, z: 0 }
const RAM_MIN_SPEED = 3 // m/s closing speed for a ram
const NUDGE_SLIDE = 1.5 // m/s sideways slide around a hull in the way

/** Buildings, props and other tanks against the hull: push-outs, slowdowns, crushed trees and rams. */
export function resolveCollisions(me: Tank, w: WorldRefs, dt: number) {
	collideWithWorld(me, w, dt)
	for (const o of w.tanks) if (o !== me) collideWithTank(me, o, dt)
}

/** How fast speed into an obstacle bleeds off (1/s, scaled by how head-on the contact is). */
const WALL_DAMPING = 4

/**
 * Three circles along the hull against buildings and props. The push-outs move the hull back out, which by itself
 * makes it slide along a wall; the speed is then damped by how head-on the contact is (cos² of the angle between the
 * heading and the wall normal), so a glancing touch keeps most of the speed and ramming a wall nearly stops the tank.
 */
function collideWithWorld(me: Tank, w: WorldRefs, dt: number) {
	const s = me.def.shape
	const r = s.hullW / 2 + 0.15
	let nx = 0
	let nz = 0
	for (const o of [s.hullL * 0.33, 0, -s.hullL * 0.33]) {
		const px = me.pos.x + me.fx * o
		const pz = me.pos.z + me.fz * o
		if (w.buildings.collideCircle(px, pz, r, push)) {
			me.pos.x += push.x
			me.pos.z += push.z
			nx += push.x
			nz += push.z
		}
		const slow = w.props.crush(px, pz, r, me.fx * me.speed, me.fz * me.speed, push)
		if (push.x || push.z) {
			me.pos.x += push.x
			me.pos.z += push.z
			nx += push.x
			nz += push.z
		}
		if (slow < 1) me.speed *= 1 - (1 - slow) * Math.min(1, dt * 4)
	}
	dampIntoObstacle(me, nx, nz, dt)
}

/** Bleed off the part of the speed that drives into the obstacle whose push-out is (nx, nz). */
function dampIntoObstacle(me: Tank, nx: number, nz: number, dt: number) {
	const l = Math.hypot(nx, nz)
	if (l < 1e-6) return
	// The push points away from the obstacle: moving into it means the velocity opposes the push
	const c = ((me.fx * nx + me.fz * nz) / l) * Math.sign(me.speed)
	if (c >= 0) return
	me.speed *= 1 - c * c * Math.min(1, WALL_DAMPING * dt)
}

function collideWithTank(me: Tank, o: Tank, dt: number) {
	const d = Math.hypot(o.pos.x - me.pos.x, o.pos.z - me.pos.z)
	const rr = me.radius + o.radius
	if (d > rr || d < 1e-4) return
	const nx = (o.pos.x - me.pos.x) / d
	const nz = (o.pos.z - me.pos.z) / d
	// Separate by mass; a wreck does not move
	const wa = o.alive ? o.mass / (me.mass + o.mass) : 1
	const wb = o.alive ? me.mass / (me.mass + o.mass) : 0
	const pen = rr - d
	me.pos.x -= nx * pen * wa
	me.pos.z -= nz * pen * wa
	if (o.alive) {
		o.pos.x += nx * pen * wb
		o.pos.z += nz * pen * wb
	}
	const rel = me.speed * (me.fx * nx + me.fz * nz) - (o.alive ? o.speed * (o.fx * nx + o.fz * nz) : 0)
	if (rel > RAM_MIN_SPEED && me.alive && (me.uid < o.uid || !o.alive)) {
		// Ram: resolved once per pair (the other tank's update sees the same closing speed and would double it)
		me.speed *= 0.3
		if (o.alive) {
			o.speed *= 0.3
			if (o.team !== me.team) me.stats.rams++
			o.damage(rel * COMBAT.ramDamageMult * (me.mass / o.mass) * 2, me)
			me.damage(rel * COMBAT.ramDamageMult * (o.mass / me.mass), o)
		}
	} else if (rel > 0 && rel <= RAM_MIN_SPEED) {
		// Nudging: bleed a little speed and slide sideways around the other hull instead of grinding to a halt
		me.speed *= 0.92
		const side = me.fx * nz - me.fz * nx > 0 ? -1 : 1
		me.pos.x += me.fz * side * NUDGE_SLIDE * dt
		me.pos.z += -me.fx * side * NUDGE_SLIDE * dt
	}
}
