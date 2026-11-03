import type * as THREE from 'three'
import { hitBoxes } from './armor'
import type { Tank, WorldRefs } from '../tank/tank'

/**
 * Where a shell fired right now would land: the parabola from `origin` along `dir` at `speed` under `gravity`,
 * marched in short segments against tanks (other than `self`), buildings and the ground. Writes the end point
 * to `out` and returns the tank that would be struck, if any. Used by the gun marker, not by live shells.
 */
export function traceShot(
	w: WorldRefs,
	origin: THREE.Vector3,
	dir: THREE.Vector3,
	speed: number,
	gravity: number,
	maxTime: number,
	self: Tank | null,
	out: THREE.Vector3,
): Tank | null {
	const step = Math.max(0.004, 7 / speed) // ≈ 7 m per segment
	let ax = origin.x
	let ay = origin.y
	let az = origin.z
	let t = 0
	const vx = dir.x * speed
	const vz = dir.z * speed
	while (t < maxTime) {
		t += step
		const bx = origin.x + vx * t
		const by = origin.y + dir.y * speed * t - 0.5 * gravity * t * t
		const bz = origin.z + vz * t
		for (const tk of w.tanks) {
			if (tk === self || !tk.view.group.visible || !tk.nearSegment(ax, az, bx, bz)) continue
			const h = hitBoxes(tk, ax, ay, az, bx, by, bz)
			if (h) {
				out.set(h.x, h.y, h.z)
				return tk
			}
		}
		const tb = w.buildings.raySegment(ax, ay, az, bx, by, bz)
		if (tb >= 0) {
			out.set(ax + (bx - ax) * tb, ay + (by - ay) * tb, az + (bz - az) * tb)
			return null
		}
		if (by < w.terrain.height(bx, bz)) {
			// Refine the ground contact inside this segment
			let lo = 0
			let hi = 1
			for (let i = 0; i < 5; i++) {
				const m = (lo + hi) / 2
				const my = ay + (by - ay) * m
				if (my < w.terrain.height(ax + (bx - ax) * m, az + (bz - az) * m)) hi = m
				else lo = m
			}
			out.set(ax + (bx - ax) * hi, ay + (by - ay) * hi, az + (bz - az) * hi)
			return null
		}
		ax = bx
		ay = by
		az = bz
	}
	out.set(ax, ay, az)
	return null
}
