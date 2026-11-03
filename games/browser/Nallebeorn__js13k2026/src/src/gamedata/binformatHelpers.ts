export const NODE_TYPE_NEW_OBJECT = 0 << 6;
export const NODE_TYPE_TRANSFORM = 1 << 6;
export const NODE_TYPE_COLOR = 2 << 6;
export const NODE_TYPE_SHAPE = 3 << 6;
export const NODE_TYPE_MASK = NODE_TYPE_SHAPE;

export const TRANSFORM_FLAGS_TRANSLATE = 1 << 5;
export const TRANSFORM_FLAGS_ROTATE = 1 << 4;
export const TRANSFORM_FLAGS_POP = 1 << 3;
export const TRANSFORM_FLAGS_MASK =
	TRANSFORM_FLAGS_TRANSLATE | TRANSFORM_FLAGS_ROTATE | TRANSFORM_FLAGS_POP;

export const SHAPE_TYPE_BOX = 0 << 5;
export const SHAPE_TYPE_PILL = 1 << 5;
export const SHAPE_TYPE_MASK = SHAPE_TYPE_PILL;

export const SHAPE_FLAGS_NEW_INDEX = 1 << 4;
export const SHAPE_FLAGS_COLLISION = 1 << 3;
export const SHAPE_FLAGS_VISIBLE = 1 << 2;

export const COLOR_MASK = 0x3f;

export function quantizePosition(float: number) {
	const normalized = Math.min(Math.max(float / 16, -1), 1);
	return Math.round(normalized * 127);
}

export function dequantizePosition(sbyte: number) {
	return (sbyte / 127) * 16;
}

export function quantizeSize(float: number) {
	const normalized = Math.min(Math.max(float / 16, 0), 1);
	return Math.round(normalized * 255);
}

export function dequantizeSize(byte: number) {
	return (byte / 255) * 16;
}

export function quantizeNormal(float: number) {
	const clamped = Math.min(Math.max(float, -1), 1);
	return Math.round(clamped * 127);
}

export function dequantizeNormal(sbyte: number) {
	return sbyte / 127;
}

export function quantizeAngle(float: number) {
	const normalized = (float < 0 ? 360 + float : float) / 360;
	return Math.round((normalized * 256) % 256);
}

export function dequantizeAngle(byte: number) {
	return (byte / 256) * 360;
}

export function quantizeBigPosition(float: number) {
	const fixedPoint = Math.round(float * 16);
	console.assert(fixedPoint >= -0xffff && fixedPoint <= 0xffff);
	return fixedPoint;
}

export function dequantizeBigPosition(sint16: number) {
	return sint16 / 16;
}
