import * as THREE from 'three'
import { UNIT_SCALE } from '../../core/math'
import type { Crossing } from '../terrain'
import { C, type BuildContext } from './builder'

/** Road bridge: deck on piers with abutments at both ends, a stone parapet or a timber rail. */
export function bridge(ctx: BuildContext, c: Crossing) {
	const { t, b } = ctx
	const rot = Math.atan2(-c.nz, c.nx) // builder's local x axis along the bridge normal
	const stone = c.style === 'stone'
	const L = c.half
	const hw = c.hw
	const H = c.h
	const at = (along: number, across: number): [number, number] => [
		c.x + c.nx * along - c.nz * across,
		c.z + c.nz * along + c.nx * across,
	]
	b.box(2 * L, 0.8, 2 * hw, stone ? C.concrete : C.plank, c.x, H - 0.4, c.z, rot)
	for (const s of [-1, 1]) {
		const [x, z] = at(s * (L + 1), 0)
		b.box(3, 6, 2 * hw + 1, stone ? C.stone : C.timber, x, H - 3.8, z, rot) // abutment
	}
	// Piers down to the river bed
	const n = Math.max(2, Math.round(L / 8))
	for (let i = -n + 1; i <= n - 1; i++) {
		const along = (i * L) / n
		const [x, z] = at(along, 0)
		const g = t.ground(x, z) - 0.5
		const ph = H - 0.8 - g
		if (ph <= 0) continue
		if (stone) {
			b.box(2.4, ph, 2 * hw - 1, C.stone, x, g + ph / 2, z, rot)
			continue
		}
		for (const s of [-1, 1]) {
			const [px, pz] = at(along, s * (hw - 1))
			b.box(0.6, ph, 0.6, C.timber, px, g + ph / 2, pz, rot)
		}
	}
	// Parapets or rails
	for (const s of [-1, 1]) {
		const [x, z] = at(0, s * (hw - 0.3))
		if (stone) {
			b.box(2 * L, 1.0, 0.5, C.stone, x, H + 0.5, z, rot)
			continue
		}
		b.box(2 * L, 0.12, 0.14, C.timber, x, H + 1.05, z, rot)
		for (let a = -L + 1; a <= L - 1; a += 3) {
			const [px, pz] = at(a, s * (hw - 0.3))
			b.box(0.22, 1.1, 0.22, C.timber, px, H + 0.55, pz, rot)
		}
	}
}

/** Concrete pillbox: a squat box with a firing slit toward `rot`, sunk a little into the ground. */
export function bunker(ctx: BuildContext, x: number, z: number, rot: number) {
	const { t, b } = ctx
	const y = t.height(x, z) - 0.7
	const w = 7
	const d = 5.5
	const h = 2.4
	const front = d / 2 + 0.03
	b.box(w, h, d, C.concrete, x, y + h / 2, z, -rot)
	b.box(w + 0.8, 0.4, d + 0.8, C.stone, x, y + h + 0.2, z, -rot)
	b.box(3.2, 0.35, 0.1, C.window, x + Math.sin(rot) * front, y + h * 0.65, z + Math.cos(rot) * front, -rot) // slit
	ctx.place('bunker', x, z, w + 0.8, d + 0.8, -rot, y, h + 0.4)
}

/** Windmill: a tapered timber tower with a cap and four sails, facing `rot`. */
export function windmill(ctx: BuildContext, x: number, z: number, rot: number) {
	const { t, b } = ctx
	const y = t.height(x, z) - 0.3
	const h = 9
	const fx = Math.sin(rot)
	const fz = Math.cos(rot)
	b.shape(new THREE.CylinderGeometry(2.0, 3.0, h, 8), C.timber, new THREE.Matrix4().makeTranslation(x, y + h / 2, z))
	b.shape(new THREE.ConeGeometry(2.4, 2.2, 8), C.roofGrey, new THREE.Matrix4().makeTranslation(x, y + h + 1.1, z))
	b.box(0.5, 0.6, 1.0, C.window, x, y + 2.5, z, rot)
	const hx = x + fx * 2.6
	const hz = z + fz * 2.6
	const hy = y + h + 0.3
	const axle = new THREE.Matrix4().compose(
		new THREE.Vector3(x + fx * 1.3, hy, z + fz * 1.3),
		new THREE.Quaternion().setFromEuler(new THREE.Euler(Math.PI / 2, rot, 0, 'YXZ')),
		UNIT_SCALE,
	)
	b.shape(new THREE.CylinderGeometry(0.2, 0.2, 2.8, 6), C.timber, axle)
	for (let k = 0; k < 4; k++) {
		const q = new THREE.Quaternion().setFromEuler(new THREE.Euler(0, rot, (k * Math.PI) / 2 + 0.4, 'YXZ'))
		const off = new THREE.Vector3(0, 4.0, 0).applyQuaternion(q)
		const sail = new THREE.Matrix4().compose(new THREE.Vector3(hx + off.x, hy + off.y, hz + off.z), q, UNIT_SCALE)
		b.shape(new THREE.BoxGeometry(0.9, 8, 0.12), C.plank, sail)
	}
	ctx.place('mill', x, z, 6, 6, rot, y, h + 2)
}
