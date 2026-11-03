import * as THREE from 'three'
import { AXIS_Y, IDENTITY, UNIT_SCALE } from '../core/math'

/** Recolours a vertex at world-space (x, y, z): camouflage noise on top of the part's base colour. */
export type Painter = (x: number, y: number, z: number, base: THREE.Color, out: THREE.Color) => void

/** Placement matrix: translation plus a rotation about the vertical axis. */
export function placeY(x: number, y: number, z: number, rotY = 0): THREE.Matrix4 {
	return new THREE.Matrix4().compose(
		new THREE.Vector3(x, y, z),
		new THREE.Quaternion().setFromAxisAngle(AXIS_Y, rotY),
		UNIT_SCALE,
	)
}

/** Placement matrix: translation plus Euler rotation. */
export function placeEuler(x: number, y: number, z: number, rx: number, ry: number, rz: number): THREE.Matrix4 {
	return new THREE.Matrix4().compose(
		new THREE.Vector3(x, y, z),
		new THREE.Quaternion().setFromEuler(new THREE.Euler(rx, ry, rz)),
		UNIT_SCALE,
	)
}

/**
 * Bakes many small primitives into one non-indexed geometry with per-vertex colour, so a whole village or a whole
 * tank part is a single draw call. Parts are transformed on the CPU when they are added.
 */
export class MergedGeometryBuilder {
	private readonly pos: number[] = []
	private readonly nrm: number[] = []
	private readonly col: number[] = []
	private readonly v = new THREE.Vector3()
	private readonly nm = new THREE.Matrix3()
	private readonly c = new THREE.Color()

	constructor(private readonly paint?: Painter) {}

	/** Append `geo` (not consumed) transformed by `m`; `painted` runs the painter over every vertex. */
	add(geo: THREE.BufferGeometry, color: THREE.Color, m: THREE.Matrix4 = IDENTITY, painted = false) {
		const g = geo.index ? geo.toNonIndexed() : geo
		if (!g.attributes.normal) g.computeVertexNormals()
		const p = g.attributes.position
		const n = g.attributes.normal
		this.nm.getNormalMatrix(m)
		for (let i = 0; i < p.count; i++) {
			this.v.fromBufferAttribute(p, i).applyMatrix4(m)
			this.pos.push(this.v.x, this.v.y, this.v.z)
			if (painted && this.paint) this.paint(this.v.x, this.v.y, this.v.z, color, this.c)
			else this.c.copy(color)
			this.col.push(this.c.r, this.c.g, this.c.b)
			this.v.fromBufferAttribute(n, i).applyMatrix3(this.nm).normalize()
			this.nrm.push(this.v.x, this.v.y, this.v.z)
		}
		if (g !== geo) g.dispose()
	}

	/** Append and dispose a temporary geometry. */
	protected addTemp(geo: THREE.BufferGeometry, color: THREE.Color, m: THREE.Matrix4, painted = false) {
		this.add(geo, color, m, painted)
		geo.dispose()
	}

	build(): THREE.BufferGeometry {
		const geo = new THREE.BufferGeometry()
		geo.setAttribute('position', new THREE.Float32BufferAttribute(this.pos, 3))
		geo.setAttribute('normal', new THREE.Float32BufferAttribute(this.nrm, 3))
		geo.setAttribute('color', new THREE.Float32BufferAttribute(this.col, 3))
		return geo
	}
}
