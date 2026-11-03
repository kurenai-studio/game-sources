import type { Vec3 } from "../core/math.ts";
import type { Color } from "./colors.ts";
import type { COLOR_RAINBOW } from "./colors.ts";

export interface ObjectDescriptor {
	name: string,
	nodes: ObjectNode[],
}

export type ObjectNode = (BaseObjectNode & {shape?: undefined}) | BoxDescriptor | PillDescriptor;

interface BaseObjectNode {
	color?: Color | typeof COLOR_RAINBOW,
	newObjectIndex?: boolean;
	translate?: Vec3;
	euler?: Vec3,
	slotName?: string,
	children?: ObjectNode[];
	collision?: boolean;
	visible?: boolean;
};

interface BoxDescriptor extends BaseObjectNode {
	shape: "box";
	a1: number;
	b1?: number;
	height?: number;
	a2?: number;
	b2?: number;
}

interface PillDescriptor extends BaseObjectNode {
	shape: "pill";
	bottomRadius: number;
	topRadius?: number;
	height?: number;
}
