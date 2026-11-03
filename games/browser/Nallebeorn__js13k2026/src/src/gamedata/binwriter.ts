import type { ObjectDescriptor, ObjectNode } from "./objectsSchema.ts";
import {
	quantizePosition,
	quantizeAngle,
	quantizeSize,
	NODE_TYPE_TRANSFORM,
	TRANSFORM_FLAGS_TRANSLATE,
	TRANSFORM_FLAGS_ROTATE,
	NODE_TYPE_SHAPE,
	SHAPE_TYPE_BOX,
	SHAPE_TYPE_PILL,
	SHAPE_FLAGS_NEW_INDEX,
	NODE_TYPE_NEW_OBJECT,
	NODE_TYPE_COLOR,
  TRANSFORM_FLAGS_POP,
	SHAPE_FLAGS_COLLISION,
	SHAPE_FLAGS_VISIBLE,
	quantizeBigPosition,
} from "./binformatHelpers.ts";
import { BALLOON, CLOOD, CLOUD, NPC, SHARD, type LevelDescriptor } from "./levelSchema.ts";
import { COLOR_COUNT, palette } from "./colors.ts";
import type { Vec3 } from "../core/math.ts";

export function serializeObjects(
  objects: ObjectDescriptor[],
  dv?: DataView,
  startPos?: number,
): {
 	objectNames: string[],
  slotNames: Record<string, Record<string, number>>,
	pos: number,
} {
 	const objectNames: string[] = [];
	const slotNames: Record<string, Record<string, number>> = {}

  let pos = startPos ?? 0;

	for (const obj of objects) {
    objectNames.push(obj.name);

		let transformSlotIndex = 0;
		const serializeNode = (node: ObjectNode) => {
			const hasTransform = node.translate || node.euler || node.slotName;
			if (node.color != undefined) {
				dv?.setUint8(pos++, NODE_TYPE_COLOR | node.color);
			}

			if (hasTransform) {
				let byte = NODE_TYPE_TRANSFORM;
				node.translate && (byte |= TRANSFORM_FLAGS_TRANSLATE);
				node.euler && (byte |= TRANSFORM_FLAGS_ROTATE);
				dv?.setUint8(pos++, byte);

				if (node.translate) {
					const [x, y, z] = node.translate;
					dv?.setInt8(pos++, quantizePosition(x));
					dv?.setInt8(pos++, quantizePosition(y));
					dv?.setInt8(pos++, quantizePosition(z));
				}

				if (node.euler) {
					const [x, y, z] = node.euler;
					dv?.setUint8(pos++, quantizeAngle(x));
					dv?.setUint8(pos++, quantizeAngle(y));
					dv?.setUint8(pos++, quantizeAngle(z));
				}

				if (node.slotName) {
					(slotNames[obj.name] ??= {})[node.slotName] = transformSlotIndex;
				}
				transformSlotIndex++;
			}

			if (node.shape) {
				let byte = NODE_TYPE_SHAPE;
				if (node.shape == "box") byte |= SHAPE_TYPE_BOX;
				if (node.shape == "pill") byte |= SHAPE_TYPE_PILL;
				if (node.newObjectIndex) byte |= SHAPE_FLAGS_NEW_INDEX;
				if (node.collision) byte |= SHAPE_FLAGS_COLLISION;
				if (node.visible ?? true) byte |= SHAPE_FLAGS_VISIBLE;
				dv?.setUint8(pos++, byte);

				if (node.shape == "box") {
					const a1 = node.a1;
					const a2 = node.a2 ?? node.a1;
					const h = node.height ?? node.a1;
					const b1 = node.b1 ?? node.a1;
					const b2 = node.b2 ?? node.a2 ?? node.a1;

					dv?.setUint8(pos++, quantizeSize(a1 / 2));
					dv?.setUint8(pos++, quantizeSize(b1 / 2));
					dv?.setUint8(pos++, quantizeSize(h));
					dv?.setUint8(pos++, quantizeSize(a2 / 2));
					dv?.setUint8(pos++, quantizeSize(b2 / 2));
				}

				if (node.shape == "pill") {
					const r1 = node.bottomRadius;
					const r2 = node.topRadius ?? node.bottomRadius;
					const h = node.height ?? 0;

					dv?.setUint8(pos++, quantizeSize(r1));
					dv?.setUint8(pos++, quantizeSize(r2));
					dv?.setUint8(pos++, quantizeSize(h));
				}
			}

			node.children?.forEach(serializeNode);
			if (hasTransform) {
				dv?.setUint8(pos++, NODE_TYPE_TRANSFORM | TRANSFORM_FLAGS_POP);
			}
		};

		dv?.setUint8(pos++, NODE_TYPE_NEW_OBJECT);
		obj.nodes.forEach(serializeNode);
  }

  return {
    objectNames,
    slotNames,
    pos,
  }
}

export function serializeData(objectsData: ObjectDescriptor[], levelData: LevelDescriptor): {
	buffer: ArrayBuffer,
	names: string[],
	slotNames: Record<string, Record<string, number>>,
	sections: Map<string, number>,
	dialogue: string[],
} {
	const buffer = new ArrayBuffer(13 * 1024);
	const dv = new DataView(buffer);
	let pos = 0;
  const sections: Map<string, number> = new Map();

	// * Write palette
	for (let i = 0; i < COLOR_COUNT; i++) {
		const hex = palette[i]!;
		[hex >> 16, (hex & 0x00ff00) >> 8, hex & 0xff].forEach(
			colorComponent => dv.setUint8(pos++, colorComponent)
		);
	}

	sections.set("palette", pos);

	// * Write objects
  const serializedObjects = serializeObjects(objectsData, dv, pos);
  const { objectNames, slotNames} = serializedObjects;
  pos = serializedObjects.pos;

	sections.set("objectBank", pos);

	// * Write clouds
	const writeClouds = (safe: boolean) => {
		for (const node of levelData) {
			if (node[0] === CLOUD) {
				const [, y, a, b, isSafe] = node;
				if ((isSafe ?? false) != safe) continue;

				const xmin = Math.min(a[0], b[0]);
				const xmax = Math.max(a[0], b[0]);
				const ymin = Math.min(a[1], b[1]);
				const ymax = Math.max(a[1], b[1]);

				dv.setInt16(pos++, quantizeBigPosition(y));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(xmin));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(ymin));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(xmax));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(ymax));
				pos++;
			} else if (node[0] == CLOOD) {
				const [, y, p, s, isSafe] = node;
				if ((isSafe ?? false) != safe) continue;

				dv.setInt16(pos++, quantizeBigPosition(y));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(p[0] - s[0] * .5));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(p[1] - s[1] * .5));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(p[0] + s[0] * .5));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(p[1] + s[1] * .5));
				pos++;
			}
		}
	}

	writeClouds(true);
	sections.set("safeClouds", pos+1);
	writeClouds(false);
	sections.set("clouds", pos);

	// * Write NPCs
	const dialogue: string[] = [];
	for (const node of levelData) {
		if (node[0] === NPC) {
			const [, obj, translation, angle, say, minShards] = node;
			dv.setUint8(pos++, obj);
			dv.setInt16(pos++, quantizeBigPosition(translation[0]));
			pos++;
			dv.setInt16(pos++, quantizeBigPosition(translation[1]));
			pos++;
			dv.setInt16(pos++, quantizeBigPosition(translation[2]));
			pos++
			dv.setUint8(pos++, quantizeAngle(angle));
			dv.setInt8(pos++, minShards ?? 0);

			dialogue.push(say);
		}
	}
	sections.set("npcs", pos);

	// * Write shards
	for (const node of levelData) {
		if (node[0] === SHARD) {
			const [, color, locations] = node;
			dv.setUint8(pos++, color);
			const translations = Array.isArray(locations[0]) ? (locations as Vec3[]) : ([locations as Vec3]);
			dv.setUint8(pos++, translations.length);
			for (const translation of translations) {
				dv.setInt16(pos++, quantizeBigPosition(translation[0]));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(translation[1]));
				pos++;
				dv.setInt16(pos++, quantizeBigPosition(translation[2]));
				pos++
			}
		}
	}

	sections.set("shards", pos);

	// * Write balloons
	for (const node of levelData) {
		if (node[0] === BALLOON) {
			const translation = node[1];
			dv.setInt16(pos++, quantizeBigPosition(translation[0]));
			pos++;
			dv.setInt16(pos++, quantizeBigPosition(translation[1]));
			pos++;
			dv.setInt16(pos++, quantizeBigPosition(translation[2]));
			pos++
		}
	}

	sections.set("balloons", pos);

	// * Write level objects
	for (const node of levelData) {
		if (typeof node[0] === "number") {
			const [obj, translation, euler, color] = node;
			dv.setUint8(pos++, obj);
			dv.setInt16(pos++, quantizeBigPosition(translation[0]));
			pos++;
			dv.setInt16(pos++, quantizeBigPosition(translation[1]));
			pos++;
			dv.setInt16(pos++, quantizeBigPosition(translation[2]));
			pos++;
			dv.setUint8(pos++, quantizeAngle(euler?.[0] ?? 0));
			dv.setUint8(pos++, quantizeAngle(euler?.[1] ?? 0));
			dv.setUint8(pos++, quantizeAngle(euler?.[2] ?? 0));
			dv.setUint8(pos++, color ?? 0)
		}
	}

	sections.set("levelObjects", pos);

	return {
		buffer: buffer.slice(0, pos),
		names: objectNames,
		slotNames,
		sections,
		dialogue
	};
}
