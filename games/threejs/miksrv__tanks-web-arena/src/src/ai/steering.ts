import * as THREE from 'three'
import { wrapAngle } from '../core/math'
import type { Tank, WorldRefs } from '../tank/tank'
import type { DriveCommand, Pt } from './types'

const { clamp } = THREE.MathUtils

/** Steer toward a point; slow right down when it is far off the nose. */
export function steerTo(me: Tank, cmd: DriveCommand, p: Pt, speedK = 1) {
	const d = wrapAngle(Math.atan2(p.x - me.pos.x, p.z - me.pos.z) - me.yaw)
	cmd.steer = clamp(d * 2, -1, 1)
	cmd.throttle = Math.abs(d) > 1.4 ? 0.3 : speedK
}

/** Back toward a point behind us, keeping the front to the enemy (reverse steering is mirrored). */
export function reverseTo(me: Tank, cmd: DriveCommand, p: Pt) {
	const nose = wrapAngle(Math.atan2(me.pos.x - p.x, me.pos.z - p.z) - me.yaw)
	if (Math.abs(nose) > 2) {
		steerTo(me, cmd, p, 0.7) // it is ahead of us after all
		return
	}
	cmd.steer = clamp(nose * 2, -1, 1) * (me.speed < -0.5 ? -1 : 1)
	cmd.throttle = -0.8
}

/** Turn the hull on the spot so the gun arc covers `p`. */
export function faceToward(me: Tank, cmd: DriveCommand, p: Pt) {
	const d = wrapAngle(Math.atan2(p.x - me.pos.x, p.z - me.pos.z) - me.yaw)
	if (Math.abs(d) > me.def.gun.arc * 0.8) cmd.steer = clamp(d * 2, -1, 1)
}

/** Another tank (or a wreck) stands on the point: close enough is good enough, do not try to drive through it. */
export function occupied(w: WorldRefs, me: Tank, p: Pt) {
	return w.tanks.some((o) => o !== me && Math.hypot(o.pos.x - p.x, o.pos.z - p.z) < o.radius + 5)
}

/** Drive to `spot` unless already within `near` m of it (or it is taken and we are close): true while driving. */
export function driveToSpot(w: WorldRefs, me: Tank, cmd: DriveCommand, spot: Pt | null, near: number, speedK: number) {
	if (!spot) return false
	const d = Math.hypot(spot.x - me.pos.x, spot.z - me.pos.z)
	if (d <= near || (d < near + 12 && occupied(w, me, spot))) return false
	steerTo(me, cmd, spot, speedK)
	return true
}

/** Where `me`'s teammates stand (to keep from piling onto one spot). */
export function friendSpots(w: WorldRefs, me: Tank): Pt[] {
	return w.tanks.filter((f) => f !== me && f.alive && f.team === me.team).map((f) => ({ x: f.pos.x, z: f.pos.z }))
}
