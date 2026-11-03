import type * as THREE from 'three'
import { C, outlineEdgeAt, type HullDims, type Outline, type TankBuilder } from './builder'
import type { TrackRun, WheelLayout } from './wheels'

/** Lorry (ZiS-6): ladder frame, long bonnet with the radiator, the cab behind it and mudguards over every axle. */
function truckHull(b: TankBuilder, d: HullDims, base: THREE.Color, w: WheelLayout) {
	const s = d.shape
	const L = s.hullL
	const W = s.hullW
	const r = s.running.wheelR
	const frameY = r + 0.12
	const nose = L / 2
	const bonnetL = 1.45
	const cabL = 1.35
	const cabZ = nose - bonnetL - cabL / 2
	b.box(W * 0.45, 0.22, L * 0.97, C.steel, 0, frameY, -0.05)
	// Bonnet narrowing to the radiator, the grille in front and the bumper below.
	b.prism(
		[
			[nose - bonnetL, frameY],
			[nose - 0.05, frameY],
			[nose - 0.05, frameY + 0.85],
			[nose - bonnetL, frameY + 0.95],
		],
		W * 0.5,
		W * 0.42,
		base,
	)
	b.box(W * 0.4, 0.7, 0.05, C.window, 0, frameY + 0.45, nose - 0.03)
	b.box(W * 0.85, 0.12, 0.12, C.steel, 0, frameY - 0.05, nose + 0.05)
	// Cab: sloped windscreen, roof, side windows.
	b.prism(
		[
			[cabZ - cabL / 2, frameY],
			[cabZ + cabL / 2, frameY],
			[cabZ + cabL / 2, frameY + 1.05],
			[cabZ + cabL / 2 - 0.2, frameY + 1.6],
			[cabZ - cabL / 2, frameY + 1.6],
		],
		W * 0.88,
		W * 0.84,
		base,
	)
	b.box(W * 0.7, 0.45, 0.04, C.window, 0, frameY + 1.32, cabZ + cabL / 2 - 0.08, false, 0, -0.38)
	for (const side of [1, -1]) b.box(0.04, 0.4, cabL * 0.45, C.window, side * W * 0.43, frameY + 1.3, cabZ + 0.1)
	b.cyl(0.11, 0.11, 0.1, 8, C.white, W * 0.32, frameY + 0.85, nose - bonnetL * 0.25, false, Math.PI / 2)
	// Mudguards: a curved one over the front wheel, flat plates over the rear bogie; a running board under the cab.
	for (const side of [1, -1]) {
		const x = side * (W / 2 - 0.2)
		const front = w.wheels.find((wh) => wh.side === side)
		if (front) {
			b.prism(
				[
					[front.z - r * 1.3, r * 1.25],
					[front.z - r * 0.6, r * 2.1],
					[front.z + r * 0.6, r * 2.1],
					[front.z + r * 1.3, r * 1.4],
					[front.z + r * 1.3, r * 1.55],
					[front.z + r * 0.65, r * 2.2],
					[front.z - r * 0.65, r * 2.2],
					[front.z - r * 1.4, r * 1.35],
				],
				0.42,
				0.42,
				base,
				x,
			)
		}
		b.box(0.36, 0.05, cabL, C.steel, x, r * 1.25, cabZ)
		b.box(0.5, 0.05, L * 0.3, C.steel, side * (W / 2 - 0.22), r * 2.15, -L * 0.3)
	}
	b.box(W * 0.8, 0.1, L * 0.42, C.wood, 0, frameY + 0.15, -L * 0.24)
}

/** Track band in the side view: a long belt round the sprocket, idler and road wheels. */
function trackOutline(t: TrackRun): Outline {
	const { front: f, rear: r } = t
	const k = Math.SQRT1_2
	return [
		[t.groundRear, 0],
		[t.groundFront, 0],
		[f.z + f.r * k, f.y - f.r * k],
		[f.z + f.r, f.y],
		[f.z + f.r * 0.5, t.top],
		[r.z - r.r * 0.5, t.top],
		[r.z - r.r, r.y],
		[r.z - r.r * k, r.y - r.r * k],
	]
}

/**
 * Upper hull from its side outline (sloped side plates narrow it toward the roof), the lower hull and nose plate
 * between the tracks, track bands with fenders, return rollers and the vehicle's fittings.
 */
function trackedHull(b: TankBuilder, d: HullDims, base: THREE.Color, w: WheelLayout) {
	const s = d.shape
	const look = s.hullLook
	const L = s.hullL
	const W = s.hullW
	const TH = s.trackH
	const { y0, top, sideH, trackW, outline } = d
	const roofW = W * (look.roofW ?? 1)
	const t = w.track
	if (!t) return
	b.prism(outline, W, roofW, base)

	// Lower hull: the nose plate runs from the upper hull's nose down to the belly.
	const belly = TH * 0.22
	const noseZ = outlineEdgeAt(outline, y0 + 0.01, 1)
	const tailZ = outlineEdgeAt(outline, y0 + 0.01, -1)
	const lowerNose = look.lowerNose ?? 0.35
	b.prism(
		[
			[tailZ + 0.25, belly],
			[noseZ - lowerNose, belly],
			[noseZ, y0 + 0.02],
			[tailZ, y0 + 0.02],
		],
		W - 2 * trackW + 0.02,
		W - 2 * trackW + 0.02,
		base,
	)

	// Track bands, fenders and Schürzen.
	const track = trackOutline(t)
	const trackZ0 = t.rear.z - t.rear.r
	const trackZ1 = t.front.z + t.front.r
	for (const side of [1, -1]) {
		const x = side * (W / 2 - trackW / 2)
		b.prism(track, trackW, trackW, C.track, x, undefined, false)
		const fenderL = trackZ1 - trackZ0 + 0.1
		b.box(trackW + 0.1, 0.05, fenderL, base, x + side * 0.03, t.top + 0.03, (trackZ0 + trackZ1) / 2, true)
		if (look.skirts) {
			const sy0 = TH * 0.42
			const sy1 = y0 + sideH * 0.5
			b.box(0.04, sy1 - sy0, L * 0.84, base, side * (W / 2 + 0.1), (sy0 + sy1) / 2, -L * 0.03, true)
		}
		for (const r of w.rollers) {
			b.cyl(r.r, r.r, 0.1, 6, base, x + side * (trackW / 2 - 0.02), r.y, r.z, false, 0, Math.PI / 2)
		}
	}
	if (s.running.kind === 'halftrack') {
		const fw = w.wheels[0]
		for (const side of [1, -1]) {
			const x = side * Math.abs(fw.x)
			b.box(0.42, 0.05, fw.r * 2.6, base, x, fw.r * 2.05, fw.z, true)
			b.box(0.42, 0.05, 0.5, base, x, fw.r * 1.75, fw.z + fw.r * 1.45, true, 0, -0.6)
		}
	}

	// Rear: exhausts against the rear plate, towing eyes on the nose.
	const exY = y0 + sideH * 0.45
	const rearZ = outlineEdgeAt(outline, exY, -1)
	for (const x of [-W * 0.22, W * 0.22]) b.cyl(0.09, 0.09, 0.45, 6, C.steel, x, exY, rearZ - 0.15, false, Math.PI / 2)
	for (const x of [-W * 0.3, W * 0.3]) b.box(0.2, 0.16, 0.25, C.steel, x, y0 - 0.05, noseZ + 0.02)

	// Headlight on the left of the nose, antenna at the right rear, tool box on the left fender.
	const hlY = y0 + sideH * 0.35
	b.cyl(0.11, 0.11, 0.12, 8, C.white, W * 0.32, hlY, outlineEdgeAt(outline, hlY, 1) + 0.04, false, Math.PI / 2)
	b.cyl(0.015, 0.015, 2.2, 3, C.steel, -roofW * 0.4, top + 1.1, -L * 0.32)
	if (!look.skirts) b.box(0.3, 0.2, 1.0, C.steel, W / 2 - trackW / 2, t.top + 0.13, -L * 0.18, true)

	if (look.spareTracks) {
		const y = y0 + sideH * 0.3
		const z = outlineEdgeAt(outline, y, 1)
		for (let i = 0; i < 4; i++) b.box(0.32, 0.5, 0.08, C.track, (i - 1.5) * 0.36, y, z + 0.03, false, 0, 0.25)
	}
	if (look.drums) {
		// Cylindrical fuel tanks lying along the sloped side plates at the rear.
		const y = y0 + sideH * 0.45
		const x = (W + (roofW - W) * 0.45) / 2 + 0.12
		for (let i = 0; i < look.drums; i++) {
			const z = -L * 0.38 + i * 0.95
			for (const side of [1, -1]) b.cyl(0.19, 0.19, 0.8, 6, base, side * x, y, z, true, Math.PI / 2)
		}
	}
}

export function buildHull(b: TankBuilder, d: HullDims, base: THREE.Color, w: WheelLayout) {
	if (d.shape.running.kind === 'truck') truckHull(b, d, base, w)
	else trackedHull(b, d, base, w)
}
