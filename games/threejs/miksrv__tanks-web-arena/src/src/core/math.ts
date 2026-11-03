import * as THREE from 'three'

/** World axes (shared, never mutate). */
export const AXIS_X = new THREE.Vector3(1, 0, 0)
export const AXIS_Y = new THREE.Vector3(0, 1, 0)
export const AXIS_Z = new THREE.Vector3(0, 0, 1)
export const UNIT_SCALE = new THREE.Vector3(1, 1, 1)
export const IDENTITY = new THREE.Matrix4()

/** Degrees per radian, rounded the way the gameplay numbers were tuned (57.3). */
export const RAD_TO_DEG = 57.3

/** Angle wrapped into (−π, π]. */
export const wrapAngle = (a: number) => Math.atan2(Math.sin(a), Math.cos(a))

/** Heading of the vector (dx, dz): 0 along +z, growing toward +x (forward = (sin, 0, cos)). */
export const headingTo = (dx: number, dz: number) => Math.atan2(dx, dz)

/** Distance on the ground plane. */
export const distXZ = (a: { x: number; z: number }, b: { x: number; z: number }) => Math.hypot(a.x - b.x, a.z - b.z)

/** Standard normal sample (Box–Muller). */
export function gaussian(): number {
	let u = 0
	let v = 0
	while (!u) u = Math.random()
	while (!v) v = Math.random()
	return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v)
}

/** Uniform in (−k/2, k/2). */
export const jitter = (k: number) => (Math.random() - 0.5) * k
