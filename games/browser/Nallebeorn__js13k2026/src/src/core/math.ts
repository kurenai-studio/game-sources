export const IDENTITY = new DOMMatrix;

export function degtorad(degrees: number) {
	return degrees * Math.PI / 180;
}

/*export function radtodeg(radians: number) {
	return radians * 180 / Math.PI;
} */

export function angleFromDirection(x: number, z: number) {
	return 90 - Math.atan2(z, x) * 180 / Math.PI;
}

export function rotateTowards(degrees: number, target: number, delta: number) {
	const difference = (target - degrees + 540) % 360 - 180;
    return Math.abs(difference) <= delta
        ? target
        : degrees + Math.sign(difference) * delta;
}

export function clamp(x: number, min: number, max: number) {
	return x < min ? min : (x > max ? max : x);
}

export function lerp(a: number, b: number, t: number) {
	return a + (b - a) * t;
}

export function lerpv(a: Vec3, b: Vec3 | undefined, t: number) {
	return a.map((x, i) => lerp(x, b ? b[i]! : x, t));
}

export function spring(current: number, currentSpeed: number): number {
	return lerp(currentSpeed, -current * 5, 0.2);
}

export function easeInBack(x: number): number {
	const c1 = 1.8;
	const c3 = c1 + 1;

	return c3 * x * x * x - c1 * x * x;
}

export type Vec2 = [number, number];
export type Vec3 = [number, number, number];
export type Vec4 = [number, number, number, number];

export type AnyVec = Vec2 | Vec3 | Vec4;

export type Mat4 = [
	number, number, number, number,
	number, number, number, number,
	number, number, number, number,
	number, number, number, number,
]

export interface Transform {
	translation?: Vec3 | 0 | undefined,
	euler?: Vec3 | 0 | undefined,
	scale?: number,
	yscale?: number | undefined,
}

export function add<T extends AnyVec>(lhs: T, rhs: NoInfer<T>): T {
	return lhs.map((a, i) => a + rhs[i]!) as T;
}

export function sub<T extends AnyVec>(lhs: T, rhs: NoInfer<T>): T {
return lhs.map((a, i) => a - rhs[i]!) as T;
}

export function scale<T extends AnyVec>(lhs: T, scale: number): T {
return lhs.map(a => a * scale) as T;
}


export function midpoint<T extends AnyVec>(a: T, b: NoInfer<T>): T {
	return scale(add(a, b), .5);
}
export function dot<T extends AnyVec>(lhs: T, rhs: NoInfer<T>): number {
	return lhs.reduce((sum, a, i) => sum + a * rhs[i]!, 0);
}

export function length<T extends AnyVec>(vec: T): number {
	return Math.sqrt(dot(vec, vec));
}

export function getForward(transform: DOMMatrix): Vec3 {
	return [
		-transform.m31,
		-transform.m32,
		-transform.m33,
	]
}

export function getPos(transform: DOMMatrix): Vec3 {
	return [
		transform.m41,
		transform.m42,
		transform.m43,
	];
}

export function transformVec3(transform: DOMMatrix, vec: Vec3, w: number): Vec3 {
	return pointAsVec3(transform.transformPoint(new DOMPoint(...vec, w)));
}

export function pointAsVec3(point: DOMPoint): Vec3 {
	return [point.x, point.y, point.z];
}

export function normalize<T extends AnyVec>(vec: T): T {
	return vec.map(a => a / length(vec)) as T;
}

export function withLength<T extends AnyVec>(vec: T, len: number): T {
	return vec.map(a => length(vec) && len * a / length(vec)) as T;
}

export function projectPerspective(fovyFactor: number, aspect: number, near: number): DOMMatrix {
	const f = fovyFactor;
	return new DOMMatrix([
		f / aspect, 0,  0,				 0,
		0, 					f,  0, 				 0,
		0, 					0, -1,				-1,
		0, 					0, -2 *  near, 0,
	]);
}

export function createMatrix(transform?: Transform): DOMMatrix {
	let matrix = IDENTITY;
	if (transform?.translation) matrix = matrix.translate(...transform.translation);
	if (transform?.euler) matrix = matrix.rotate(...transform.euler);
	if (transform?.scale) matrix = matrix.scale(transform.scale, transform.scale, transform.scale);
	if (transform?.yscale) matrix = matrix.scale(1, transform.yscale, 1);
	return matrix;
}

export function identityMat4(): Mat4 {
	return [
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1,
	];
}
