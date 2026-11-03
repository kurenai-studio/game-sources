import { add, clamp, dot, length, scale, sub, transformVec3, withLength, type Vec3 } from "../core/math.ts";

export interface SphereCollider {
	pos: Vec3,
	r: number,
	vector?: undefined,
}

export interface CapsuleCollider {
	pos: Vec3,
	vector: Vec3,
	r: number,
	balloon?: number,
}

export interface BoxCollider {
	min: Vec3,
	max: Vec3,
	safePoint?: Vec3 | false,
}

export function translateCollider<T extends Collider>(collider: T, pos: Vec3): T {
	return "r" in collider
		? ({ pos: add(collider.pos, pos), ...collider } as T)
		: ({ min: add(collider.min, pos), max: add(collider.max, pos) } as T);
}

export function transformCollider<T extends Collider>(
	collider: T,
	transform: DOMMatrix,
): T {
	if ("r" in collider) {
		return {
			pos: transformVec3(transform, collider.pos, 1),
			r: collider.r,
			vector: transformVec3(transform, collider.vector, 0),
		} as T;
	}

	const cornerA = transformVec3(transform, collider.min, 1);
	const cornerB = transformVec3(transform, collider.max, 1);

	return {
		min: cornerA.map((a, idx) => Math.min(a, cornerB[idx]!)),
		max: cornerA.map((a, idx) => Math.max(a, cornerB[idx]!)),
	} as T;
}

export type Collider = BoxCollider | CapsuleCollider;

export interface Collision {
	depth: number,
	depenetration: 0 | Vec3,
	safePoint?: 0 | Vec3,
	balloon?: number,
}

export interface ConfirmedCollision {
	depth: number,
	depenetration: Vec3,
	safePoint?: 0 | Vec3,
	balloon?: number,
}

export function penetrateSphereGeneric(pos: Vec3, r: number, b: Collider) {
	if ("r" in b) {
		return penetrateSphereCapsule({ pos, r }, b as CapsuleCollider)
	}

	return penetrateSphereBox({ pos, r }, b);
}

export function penetrateSphereCapsule(a: SphereCollider, b: CapsuleCollider) {
	const pos = add(
		b.pos,
		scale(
			b.vector,
			clamp(dot(sub(a.pos, b.pos), b.vector) / dot(b.vector, b.vector), 0, 1),
		),
	);
	const delta = sub(a.pos, pos)
	const depth = Math.max(0, a.r - length(delta) + b.r)

	return {
		projected: pos,
		depth,
		depenetration: depth && withLength(delta, depth),
		balloon: b.balloon
	};
}

export function penetrateSphereBox(a: SphereCollider, b: BoxCollider) {
	const clamped = a.pos.map((v, idx) => clamp(v, b.min[idx]!, b.max[idx]!)) as Vec3;
	const delta = sub(a.pos, clamped);
	const depth = Math.max(0, a.r - length(delta));
	return {
		// closest: clamped,
		depth: depth,
		depenetration: depth && withLength(delta, depth),
		safePoint: depth && b.safePoint,
	};
}
