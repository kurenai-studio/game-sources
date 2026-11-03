import type { LanePoint, Point } from './types'

/** Catmull-Rom spline through every point, resampled every `step` metres (endpoints and knots are hit exactly). */
export function smoothPath(pts: LanePoint[], step: number): Point[] {
	if (pts.length < 3) return pts.map((p) => ({ x: p.x, z: p.z }))
	const out: Point[] = [{ x: pts[0].x, z: pts[0].z }]
	const P = (i: number) => pts[Math.max(0, Math.min(pts.length - 1, i))]
	for (let i = 0; i + 1 < pts.length; i++) {
		const p0 = P(i - 1)
		const p1 = P(i)
		const p2 = P(i + 1)
		const p3 = P(i + 2)
		const n = Math.max(1, Math.round(Math.hypot(p2.x - p1.x, p2.z - p1.z) / step))
		if (p1.fixed && p2.fixed) {
			// A run between fixed points (bridge ramp and deck) stays dead straight
			for (let k = 1; k <= n; k++) {
				const t = k / n
				out.push({ x: p1.x + (p2.x - p1.x) * t, z: p1.z + (p2.z - p1.z) * t })
			}
			continue
		}
		for (let k = 1; k <= n; k++) out.push(catmullRom(p0, p1, p2, p3, k / n))
	}
	return out
}

function catmullRom(p0: Point, p1: Point, p2: Point, p3: Point, t: number): Point {
	const t2 = t * t
	const t3 = t2 * t
	const axis = (a: number, b: number, c: number, d: number) =>
		0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
	return { x: axis(p0.x, p1.x, p2.x, p3.x), z: axis(p0.z, p1.z, p2.z, p3.z) }
}
