import type { HullDims } from './builder'

export interface Wheel {
	x: number
	y: number
	z: number
	r: number
	/** Tyre width, m. */
	w: number
	/** Which side the wheel's outer face looks to (+1 = left). */
	side: 1 | -1
}

/** A circle of the track run in the side view. */
export interface TrackEnd {
	z: number
	y: number
	r: number
}

export interface TrackRun {
	/** Sprocket or idler at either end. */
	rear: TrackEnd
	front: TrackEnd
	/** Lowest run: from the rear road wheel to the front one. */
	groundRear: number
	groundFront: number
	top: number
}

export interface WheelLayout {
	/** Everything that turns: road wheels, sprockets, idlers, lorry wheels. */
	wheels: Wheel[]
	/** Track outline (the same on both sides); null for a lorry. */
	track: TrackRun | null
	/** Return rollers on one side (mirrored on the other). */
	rollers: TrackEnd[]
}

const OUTSET = 0.03 // wheels stand proud of the track side so their faces show

/** Road wheels, sprocket, idler and return rollers from the vehicle's running gear description. */
export function wheelLayout(d: HullDims): WheelLayout {
	const s = d.shape
	const g = s.running
	const L = s.hullL
	const TH = s.trackH
	const trackX = s.hullW / 2 - d.trackW / 2
	const wheels: Wheel[] = []
	const both = (z: number, y: number, r: number, w: number, dx = 0) => {
		for (const side of [1, -1] as const) wheels.push({ x: side * (trackX + dx), y, z, r, w, side })
	}

	if (g.kind === 'truck') {
		;(g.axles ?? []).forEach((a, i) => {
			const twin = i > 0
			both(a * L, g.wheelR, g.wheelR, twin ? d.trackW * 1.6 : d.trackW, twin ? 0.08 : 0)
		})
		return { wheels, track: null, rollers: [] }
	}

	// The track span: the whole hull, or the rear half of a half-track behind its steered front axle.
	const half = g.kind === 'halftrack'
	const zRear = -L * 0.48
	const zFront = half ? -L * 0.04 : L * 0.48
	// Steered front wheels: outer face flush with the road wheels behind.
	if (half) both((g.frontAxle ?? 0.33) * L, g.wheelR * 1.5, g.wheelR * 1.5, 0.3, d.trackW / 2 + OUTSET - 0.15)

	const span = (g.span ?? 0.8) * (half ? 0.5 : 1) * L
	const mid = (g.shift ?? 0) * L + (half ? (zRear + zFront) / 2 : 0)
	const n = g.wheels
	const r = g.wheelR
	const tyreW = d.trackW + 2 * OUTSET
	const zs: number[] = []
	if (g.layout === 'paired') {
		const pairs = n / 2
		for (let p = 0; p < pairs; p++) {
			const c = mid - span / 2 + r * 1.05 + ((span - r * 2.1) * p) / Math.max(1, pairs - 1)
			zs.push(c - r * 1.05, c + r * 1.05)
		}
	} else for (let i = 0; i < n; i++) zs.push(mid - span / 2 + (span * i) / Math.max(1, n - 1))
	zs.forEach((z, i) => {
		// Interleaved rows: the outer wheels stand further out than the inner ones between them.
		if (g.layout === 'interleaved') both(z, r, r, tyreW * 0.45, i % 2 ? d.trackW * 0.3 : d.trackW * 0.3 + 0.07)
		else both(z, r, r, tyreW)
	})

	// Sprocket and idler: the drive end sits high, the idler a little lower.
	const front = g.sprocket !== 'rear'
	const endR = TH * 0.3
	const drive = TH * 0.62
	const idle = TH * 0.5
	const fEnd: TrackEnd = { z: zFront - endR * 0.6, y: front ? drive : idle, r: endR }
	const rEnd: TrackEnd = { z: zRear + endR * 0.6, y: front ? idle : drive, r: endR }
	both(fEnd.z, fEnd.y, fEnd.r, tyreW * 0.7)
	both(rEnd.z, rEnd.y, rEnd.r, tyreW * 0.7)

	const top = d.y0
	const rollers: TrackEnd[] = []
	const nr = g.rollers ?? 0
	for (let i = 0; i < nr; i++) {
		const z = mid - span * 0.38 + (span * 0.76 * (i + 0.5)) / nr
		rollers.push({ z, y: top - 0.11, r: 0.09 })
	}
	return {
		wheels,
		track: { rear: rEnd, front: fEnd, groundRear: zs[0] - r * 0.5, groundFront: zs[zs.length - 1] + r * 0.5, top },
		rollers,
	}
}
