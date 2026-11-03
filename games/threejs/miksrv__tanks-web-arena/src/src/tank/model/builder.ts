import * as THREE from 'three'
import type { Nation, OutlinePoint, ShapeDef } from '../../config'
import { IDENTITY } from '../../core/math'
import { MergedGeometryBuilder, placeEuler, type Painter } from '../../render/geometryBuilder'

// Local frame: forward = +z, up = +y, +x = the vehicle's left side; origin on the ground under the hull centre.

/** Tank palette. */
export const C = {
	ussr: new THREE.Color('#5f6b3c'),
	germany: new THREE.Color('#b3a06a'),
	blotch: new THREE.Color('#6b7a46'),
	track: new THREE.Color('#2a2724'),
	rubber: new THREE.Color('#1c1b1a'),
	steel: new THREE.Color('#3a3a3a'),
	white: new THREE.Color('#e8e8e8'),
	red: new THREE.Color('#c62828'),
	window: new THREE.Color('#2a2a30'),
	wood: new THREE.Color('#6b5a3c'),
	interior: new THREE.Color('#3b3a30'),
}

/** A side outline in metres: [z, y] pairs. */
export type Outline = [number, number][]

/** Scale a normalised outline to a part `len` long and `h` high, centred on `z0` along z and standing on `y0`. */
export function scaleOutline(o: readonly OutlinePoint[], len: number, h: number, z0 = 0, y0 = 0): Outline {
	return o.map(([z, y]) => [z0 + (z - 0.5) * len, y0 + y * h])
}

/** Front-most (dir 1) or rear-most (dir −1) point of an outline at height y. */
export function outlineEdgeAt(o: Outline, y: number, dir: 1 | -1): number {
	let best = -Infinity
	for (let i = 0; i < o.length; i++) {
		const [za, ya] = o[i]
		const [zb, yb] = o[(i + 1) % o.length]
		if ((y < ya && y < yb) || (y > ya && y > yb) || ya === yb) continue
		best = Math.max(best, dir * (za + ((y - ya) / (yb - ya)) * (zb - za)))
	}
	return best === -Infinity ? 0 : dir * best
}

/** Nation camouflage: a gentle brightness wave, plus green blotches on German vehicles. */
export function camoPainter(nation: Nation, seed: number): Painter {
	return (x, y, z, b, out) => {
		const n = Math.sin(x * 2.1 + seed) * Math.cos(z * 1.7 - seed * 0.3) + Math.sin(y * 3.3 + z * 0.9 + seed)
		out.copy(b).multiplyScalar(0.92 + 0.06 * n)
		if (nation === 'germany' && n > 0.9) out.lerp(C.blotch, 0.75)
	}
}

/** Merged-geometry builder with the primitives a tank is made of. `camo` runs the camouflage painter. */
export class TankBuilder extends MergedGeometryBuilder {
	box(
		w: number,
		h: number,
		d: number,
		color: THREE.Color,
		x: number,
		y: number,
		z: number,
		camo = false,
		rotY = 0,
		rotX = 0,
	) {
		this.addTemp(new THREE.BoxGeometry(w, h, d), color, placeEuler(x, y, z, rotX, rotY, 0), camo)
	}

	cyl(
		rTop: number,
		rBot: number,
		h: number,
		seg: number,
		color: THREE.Color,
		x: number,
		y: number,
		z: number,
		camo = false,
		rotX = 0,
		rotZ = 0,
	) {
		this.addTemp(new THREE.CylinderGeometry(rTop, rBot, h, seg), color, placeEuler(x, y, z, rotX, 0, rotZ), camo)
	}

	/**
	 * Side outline (z, y) extruded across x around `x0`: `wBot` wide at its lowest point, narrowing linearly to `wTop`
	 * at its highest (sloped side plates). `inner` makes an open-topped compartment: no roof or floor, and the inside
	 * faces in that colour. `painted` runs the camouflage painter.
	 */
	prism(
		outline: Outline,
		wBot: number,
		wTop: number,
		color: THREE.Color,
		x0 = 0,
		inner?: THREE.Color,
		painted = true,
	) {
		const pts = THREE.ShapeUtils.isClockWise(outline.map(([z, y]) => new THREE.Vector2(z, y)))
			? [...outline].reverse()
			: outline
		let yMin = Infinity
		let yMax = -Infinity
		for (const [, y] of pts) {
			yMin = Math.min(yMin, y)
			yMax = Math.max(yMax, y)
		}
		const half = (y: number) => (wBot + (wTop - wBot) * ((y - yMin) / (yMax - yMin || 1))) / 2
		const pos: number[] = []
		const tri = (a: THREE.Vector3, b: THREE.Vector3, c: THREE.Vector3) =>
			pos.push(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z)
		const v = (side: number, i: number) => {
			const [z, y] = pts[i % pts.length]
			return new THREE.Vector3(x0 + side * half(y), y, z)
		}
		// Side caps: a triangle counter-clockwise in (z, y) faces −x, so the left (+x) cap takes the other winding.
		for (const t of THREE.ShapeUtils.triangulateShape(
			pts.map(([z, y]) => new THREE.Vector2(z, y)),
			[],
		)) {
			const [[za, ya], [zb, yb], [zc, yc]] = t.map((i) => pts[i])
			const [a, b, c] = (zb - za) * (yc - ya) - (yb - ya) * (zc - za) > 0 ? t : [t[0], t[2], t[1]]
			tri(v(1, a), v(1, c), v(1, b))
			tri(v(-1, a), v(-1, b), v(-1, c))
		}
		// Edge bands; an open compartment drops the roof and floor runs.
		const eps = 1e-3
		for (let i = 0; i < pts.length; i++) {
			const ya = pts[i][1]
			const yb = pts[(i + 1) % pts.length][1]
			if (inner && ((ya > yMax - eps && yb > yMax - eps) || (ya < yMin + eps && yb < yMin + eps))) continue
			tri(v(1, i), v(1, i + 1), v(-1, i + 1))
			tri(v(1, i), v(-1, i + 1), v(-1, i))
		}
		this.addTemp(flatGeometry(pos), color, IDENTITY, painted)
		if (inner) {
			const rev: number[] = []
			for (let i = 0; i < pos.length; i += 9)
				rev.push(...pos.slice(i, i + 3), ...pos.slice(i + 6, i + 9), ...pos.slice(i + 3, i + 6))
			this.addTemp(flatGeometry(rev), inner, IDENTITY)
		}
	}

	/** Any temporary geometry under a matrix. */
	part(geo: THREE.BufferGeometry, color: THREE.Color, m: THREE.Matrix4, camo = false) {
		this.addTemp(geo, color, m, camo)
	}
}

/** Non-indexed triangles with flat normals. */
function flatGeometry(pos: number[]): THREE.BufferGeometry {
	const geo = new THREE.BufferGeometry()
	geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3))
	geo.computeVertexNormals()
	return geo
}

/** Vertical dimensions of the hull shared by the part builders. */
export interface HullDims {
	shape: ShapeDef
	/** Track width. */
	trackW: number
	/** Fender line: the top of the track run and the bottom of the upper hull. */
	y0: number
	/** Hull roof height (the turret ring). */
	top: number
	/** Height of the upper hull side, top − y0. */
	sideH: number
	/** Upper hull side outline in metres. */
	outline: Outline
}

export function hullDims(s: ShapeDef): HullDims {
	// The roof stands hullH over the hull floor (a little below the track top; the hit box spans floor to roof); the
	// upper hull is drawn from the fender line so the top run of the track and its return rollers stay in view.
	const top = s.trackH * 0.72 + s.hullH
	const y0 = Math.min(top - 0.3, Math.max(s.trackH * 0.97, s.running.wheelR * 2 + 0.06))
	return {
		shape: s,
		trackW: s.running.kind === 'truck' ? 0.3 : 0.55,
		y0,
		top,
		sideH: top - y0,
		outline: scaleOutline(s.hullLook.outline, s.hullL, top - y0, 0, y0),
	}
}
