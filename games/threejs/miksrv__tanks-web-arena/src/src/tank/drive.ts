import * as THREE from 'three'
import { DRIVE, WORLD_HALF } from '../config'
import { RAD_TO_DEG, wrapAngle } from '../core/math'
import type { Terrain } from '../world/terrain'
import type { Tank } from './tank'

const { clamp } = THREE.MathUtils
const tmpG = new THREE.Vector2()
const DEEP_WATER = 1.3
const EDGE_MARGIN = 8 // m from the world edge

/** Engine and tracks: speed toward the throttle's target, hull turn, then the move with terrain walls. */
export function drive(me: Tank, dt: number, t: Terrain) {
	updateSpeed(me, dt, t)
	updateHeading(me, dt)
	const ox = me.pos.x
	const oz = me.pos.z
	me.pos.x += me.fx * me.speed * dt
	me.pos.z += me.fz * me.speed * dt
	if (hitsWall(me, t)) {
		me.pos.x = ox
		me.pos.z = oz
		me.speed *= -0.1
	}
}

function updateSpeed(me: Tank, dt: number, t: Terrain) {
	const def = me.def
	const surface = t.surfaceSpeed(me.pos.x, me.pos.z)
	t.gradient(me.pos.x, me.pos.z, tmpG)
	const slopeAhead = tmpG.x * me.fx + tmpG.y * me.fz // rise per metre forward
	const dir = Math.sign(me.throttle) || Math.sign(me.speed)
	const uphill = Math.max(0, slopeAhead * dir)
	const slopeF = Math.max(0.15, 1 - Math.atan(uphill) * RAD_TO_DEG * DRIVE.slopeSpeed)
	let target = 0
	const crew = me.crew.drive * me.engine
	if (me.throttle > 0) target = def.speed * surface * slopeF * crew
	else if (me.throttle < 0) target = -def.reverse * surface * crew
	if (me.tracked > 0 || surface === 0) target = 0
	const braking = me.throttle === 0 || Math.sign(me.throttle) !== Math.sign(me.speed)
	const a = def.accel * (braking ? 2.2 : 1) * (0.6 + 0.4 * surface) * crew
	me.speed += clamp(target - me.speed, -a * dt, a * dt)
}

function updateHeading(me: Tank, dt: number) {
	const def = me.def
	let steer = me.tracked > 0 ? 0 : me.steer
	// Casemates: when the gun cannot reach the aim point, the hull turns toward it
	if (!def.shape.turret && steer === 0) {
		const want = wrapAngle(Math.atan2(me.aimTarget.x - me.pos.x, me.aimTarget.z - me.pos.z) - me.yaw)
		if (Math.abs(want) > def.gun.arc * 0.85) steer = clamp(want * 2, -0.7, 0.7)
	}
	const speedK = 1 - 0.35 * Math.min(1, Math.abs(me.speed) / def.speed)
	const yawTarget = steer * def.hullTurn * me.crew.drive * speedK * (me.speed < -0.5 ? -1 : 1)
	me.yawRate += (yawTarget - me.yawRate) * Math.min(1, 6 * dt)
	me.yaw += me.yawRate * dt
	me.syncAxes()
}

/** Steep ground ahead, deep water or the world edge. */
function hitsWall(me: Tank, t: Terrain): boolean {
	t.gradient(me.pos.x, me.pos.z, tmpG)
	const ahead = (tmpG.x * me.fx + tmpG.y * me.fz) * Math.sign(me.speed || 1)
	if (ahead > DRIVE.maxSlope || t.waterDepth(me.pos.x, me.pos.z) > DEEP_WATER) return true
	const edge = WORLD_HALF - EDGE_MARGIN
	return Math.abs(me.pos.x) > edge || Math.abs(me.pos.z) > edge
}
