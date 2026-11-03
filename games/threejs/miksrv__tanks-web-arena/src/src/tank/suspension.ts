import * as THREE from 'three'
import type { Terrain } from '../world/terrain'

export interface HullPose {
	pitch: number
	roll: number
	/** Height of the hull origin. */
	y: number
}

const MAX_ROLL = 0.6
const TRACK_SAMPLES = 5
const TRACK_INSET = 0.42 // track centre-line, fraction of the hull width from the axis
const SINK = 0.15 // the hull may settle this far below the ground under its centre

/**
 * Suspension: each track is sampled at five points along its length and a straight line is fitted through them,
 * so a bump under one road wheel tilts the hull a little instead of throwing it onto one track. The hull rides on
 * the two track lines: pitch from their mean slope, roll from the difference of their centre heights. A bridge
 * deck counts only while the hull centre is on it (then it is flat), so approaching a bridge never lifts one side.
 */
export function hullPose(t: Terrain, x: number, z: number, fx: number, fz: number, L: number, W: number): HullPose {
	const deck = t.deckAt(x, z)
	const hAt = (px: number, pz: number) => {
		const g = t.ground(px, pz)
		return deck && deck.h > g ? deck.h : g
	}
	const rx = fz
	const rz = -fx // right vector
	let cL = 0
	let cR = 0
	let slope = 0
	for (const side of SIDES) {
		const sx = x + rx * side * W * TRACK_INSET
		const sz = z + rz * side * W * TRACK_INSET
		const line = fitLine(hAt, sx, sz, fx, fz, L)
		if (side < 0) cL = line.c
		else cR = line.c
		slope += line.s / 2
	}
	return {
		pitch: Math.atan(slope),
		// Positive roll (rotation about the forward axis) lifts the right side
		roll: THREE.MathUtils.clamp(Math.atan2(cR - cL, W * TRACK_INSET * 2), -MAX_ROLL, MAX_ROLL),
		y: Math.max(hAt(x, z) - SINK, (cL + cR) / 2),
	}
}

const SIDES = [-1, 1] as const

/** Least-squares line h = c + s·u through samples at u = −0.4L … 0.4L along the track. */
function fitLine(h: (x: number, z: number) => number, sx: number, sz: number, fx: number, fz: number, L: number) {
	let su = 0
	let sh = 0
	let suu = 0
	let suh = 0
	for (let i = -2; i <= 2; i++) {
		const u = i * L * 0.2
		const v = h(sx + fx * u, sz + fz * u)
		su += u
		sh += v
		suu += u * u
		suh += u * v
	}
	const n = TRACK_SAMPLES
	const s = (n * suh - su * sh) / (n * suu - su * su)
	return { s, c: (sh - s * su) / n }
}
