import type { AnyVec, Vec2, Vec3 } from "../core/math.ts";
import type { Color } from "./colors.ts";
import type { RenderObjectHandle } from "./objects.gen.ts";

export const CLOUD = "cloud";
export const CLOOD = "cloudCentred";
export const NPC = "npc";
export const SHARD = "shard";
export const BALLOON = "balloon";
type Cloud = [type: typeof CLOUD, y: number, min: Vec2, max: Vec2, safe?: boolean];
type CloudCentred = [type: typeof CLOOD, y: number, pos: Vec2, size: Vec2, safe?: boolean];
type Npc = [type: typeof NPC, obj: RenderObjectHandle, pos: Vec3, angle: number, say: string, minShards?: number];
type Shard = [type: typeof SHARD, color: Color, pos: Vec3 | Vec3[]];
type Balloon = [type: typeof BALLOON, pos: Vec3];
type LevelObject = [type: RenderObjectHandle, pos: Vec3, euler?: Vec3, color?: Color];

type LevelNode = Cloud | CloudCentred | Npc | Shard | Balloon | LevelObject;

export type LevelDescriptor = LevelNode[];

export function offset(ofs: Vec3, nodes: LevelNode[]) {
	return nodes.map(node => {
		if (node[0] == CLOUD) {
			node[1] += ofs[1];
			node[2][0] += ofs[0];
			node[2][1] += ofs[2];
			node[3][0] += ofs[0];
			node[3][1] += ofs[2];
		} else if (node[0] == NPC || node[0] == SHARD) {
			if (Array.isArray(node[2][0])) {
				node[2] = node[2].map(pos => add(pos as Vec3, ofs)) as Vec3[];
			} else {
				node[2] = add(node[2] as Vec3, ofs);
			}
		} else if (node[0] == CLOOD) {
			node[2][0] += ofs[0];
			node[1] += ofs[1];
			node[2][1] += ofs[2];
		} else if (node[0] == BALLOON) {
			node[1] = add(node[1], ofs);
		} else {
			node[1] = add(node[1], ofs);
		}

		return node;
	});
}

export function add<T extends AnyVec>(lhs: T, rhs: NoInfer<T>): T {
	return lhs.map((a, i) => a + rhs[i]!) as T;
}
