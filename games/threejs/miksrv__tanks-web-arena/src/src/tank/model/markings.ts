import * as THREE from 'three'
import type { Nation } from '../../config'
import { AXIS_Y, AXIS_Z, UNIT_SCALE } from '../../core/math'
import { C, type HullDims, type TankBuilder } from './builder'
import { turretLook } from './turret'

function polygon(pts: [number, number][]): THREE.ShapeGeometry {
	return new THREE.ShapeGeometry(new THREE.Shape(pts.map(([x, y]) => new THREE.Vector2(x, y))))
}

export function star(r: number): THREE.ShapeGeometry {
	const pts: [number, number][] = []
	for (let i = 0; i < 10; i++) {
		const a = (i / 10) * Math.PI * 2 + Math.PI / 2
		const rr = i % 2 ? r * 0.42 : r
		pts.push([Math.cos(a) * rr, Math.sin(a) * rr])
	}
	return polygon(pts)
}

/** A plus-shaped cross with arms `a` long (from the centre) and `t` thick. */
export function cross(a: number, t: number): THREE.ShapeGeometry {
	return polygon([
		[t, t],
		[a, t],
		[a, -t],
		[t, -t],
		[t, -a],
		[-t, -a],
		[-t, -t],
		[-a, -t],
		[-a, t],
		[-t, t],
		[-t, a],
		[t, a],
	])
}

/**
 * Balkenkreuz (Germany) or red star (USSR) on a side plate facing `side` (±1 along x) that leans in toward the roof
 * by `lean` radians.
 */
function mark(host: TankBuilder, nation: Nation, x: number, y: number, z: number, side: number, lean = 0) {
	const q = new THREE.Quaternion().setFromAxisAngle(AXIS_Z, side * lean)
	q.multiply(new THREE.Quaternion().setFromAxisAngle(AXIS_Y, (side * Math.PI) / 2))
	const at = (out: number) =>
		new THREE.Matrix4().compose(
			new THREE.Vector3(x + side * out * Math.cos(lean), y + out * Math.sin(lean), z),
			q,
			UNIT_SCALE,
		)
	if (nation === 'germany') {
		host.part(cross(0.32, 0.09), C.white, at(0))
		host.part(cross(0.2, 0.05), C.track, at(0.006))
	} else host.part(star(0.32), C.red, at(0))
}

/** Half-width and lean of a plate `w` wide at its foot narrowing to `w · roofW` over `h`, at mid-height. */
function sidePlate(w: number, roofW: number, h: number) {
	return { half: (w * (1 + roofW)) / 4 + 0.02, lean: Math.atan2((w / 2) * (1 - roofW), h) }
}

/**
 * National markings on both sides: on the turret or casemate side, and on the hull side for German vehicles (and for
 * Soviet ones whose turret has no flat side, like the hexagonal T-34 turret). Launchers carry them on the body.
 */
export function addMarkings(body: TankBuilder, turret: TankBuilder, d: HullDims, nation: Nation) {
	const s = d.shape
	const W = s.hullW
	for (const side of [1, -1]) {
		if (s.launcher) {
			if (s.running.kind === 'truck')
				mark(body, nation, side * W * 0.45, s.running.wheelR + 1.25, s.hullL * 0.12, side)
			else {
				const p = sidePlate(W, s.hullLook.roofW ?? 1, d.sideH)
				mark(body, nation, side * p.half, d.y0 + d.sideH * 0.5, 0, side, p.lean)
			}
			continue
		}
		const look = turretLook(s)
		const roofW = look.roofW ?? 1
		let turretMarked = true
		if (!s.turret) {
			const p = sidePlate(s.tW, roofW, s.tH)
			mark(body, nation, side * p.half, d.top + s.tH * 0.5, s.tZ - s.tL * 0.1, side, p.lean)
		} else if (look.skirts) {
			mark(turret, nation, side * (s.tW / 2 + 0.23), s.tH * 0.45, -0.1, side)
		} else if (look.sideTracks) {
			turretMarked = false // Tigers carried their crosses on the hull, the turret sides had the spare links
		} else if (look.kind === 'welded') {
			const p = sidePlate(s.tW, roofW, s.tH)
			mark(turret, nation, side * p.half, s.tH * 0.5, 0, side, p.lean)
		} else if ((look.facets ?? 12) % 4 === 0) {
			const p = sidePlate(s.tW * Math.cos(Math.PI / (look.facets ?? 12)), roofW, s.tH)
			mark(turret, nation, side * p.half, s.tH * 0.5, (look.bustle ?? 0) / 2, side, p.lean)
		} else turretMarked = false
		if (nation === 'germany' || !turretMarked) {
			const p = s.hullLook.skirts ? { half: W / 2 + 0.13, lean: 0 } : sidePlate(W, s.hullLook.roofW ?? 1, d.sideH)
			const z = nation === 'germany' ? -s.hullL * 0.25 : -s.hullL * 0.02
			mark(body, nation, side * p.half, d.y0 + d.sideH * 0.5, z, side, p.lean)
		}
	}
}
