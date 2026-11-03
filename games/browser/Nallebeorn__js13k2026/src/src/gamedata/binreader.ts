import { createMatrix, add } from "../core/math.ts";
import { srandf } from "../core/random.ts";
import { repeat } from "../core/util.ts";
import { createBalloon } from "../game/balloon.ts";
import { npcs } from "../game/npcs.ts";
import { shards } from "../game/rainbowShards.ts";
import type { BoxCollider, CapsuleCollider } from "../physics/collision.ts";
import { staticColliders } from "../physics/objectColliders.ts";
import type { DrawCommand } from "../rendering/drawCommand.ts";
import { drawMesh, drawObject, incrementObjectIndex } from "../rendering/renderer.ts";
import { createBox, createPill } from "../rendering/shapes.ts";
import { addVertexData, unitSphere } from "../rendering/vertexData.ts";
import {
	NODE_TYPE_MASK,
	NODE_TYPE_NEW_OBJECT,
	NODE_TYPE_COLOR,
	NODE_TYPE_TRANSFORM,
	TRANSFORM_FLAGS_TRANSLATE,
	TRANSFORM_FLAGS_ROTATE,
	NODE_TYPE_SHAPE,
	SHAPE_TYPE_MASK,
	SHAPE_TYPE_BOX,
	SHAPE_FLAGS_NEW_INDEX,
	COLOR_MASK,
	TRANSFORM_FLAGS_POP,
	SHAPE_FLAGS_COLLISION,
	SHAPE_FLAGS_VISIBLE,
	dequantizeBigPosition,
} from "./binformatHelpers.ts";
import { dequantizePosition, dequantizeAngle, dequantizeSize } from "./binformatHelpers.ts";
import { COLOR_WHITE, colors, type Color } from "./colors.ts";
import { dialogue } from "./dialogue.gen.ts";
import { objectsBank } from "./gamedata.ts";
import type { RenderObjectHandle } from "./objects.gen.ts";
import { section_balloonsEnd, section_cloudsEnd, section_levelObjectsEnd, section_npcsEnd, section_objectBankEnd, section_paletteEnd, section_safeCloudsEnd, section_shardsEnd } from "./sections.gen.ts";

export function deserializeBinaryGameData(buffer: ArrayBuffer) {
	const dv = new DataView(buffer);
	let pos = 0;

	// * Read palette
	while (pos < section_paletteEnd) {
		colors.push(dv.getUint8(pos++) / 0xff);
		colors.push(dv.getUint8(pos++) / 0xff);
		colors.push(dv.getUint8(pos++) / 0xff);
		colors.push(1);
	}

	// * Read objects
	let obj!: DrawCommand[];
	while (pos < section_objectBankEnd) {
		const header = dv.getUint8(pos++);

		const type = header & NODE_TYPE_MASK;

		if (type == NODE_TYPE_NEW_OBJECT) {
			objectsBank.push(obj = []);
		}

		if (type == NODE_TYPE_COLOR) {
			obj.push({ colour: (header & COLOR_MASK) as Color});
		}

		if (type == NODE_TYPE_TRANSFORM) {
			if (header & TRANSFORM_FLAGS_POP) {
				obj.push({ popTransform: 1 });
			} else {
				obj.push({
					pushTransform: {
						translation: (header & TRANSFORM_FLAGS_TRANSLATE) && [
							dequantizePosition(dv.getInt8(pos++)),
							dequantizePosition(dv.getInt8(pos++)),
							dequantizePosition(dv.getInt8(pos++))
						],
						euler: (header & TRANSFORM_FLAGS_ROTATE) && [
							dequantizeAngle(dv.getUint8(pos++)),
							dequantizeAngle(dv.getUint8(pos++)),
							dequantizeAngle(dv.getUint8(pos++)),
						]
					}
				});
			}
		}

		if (type == NODE_TYPE_SHAPE) {
			if ((header & SHAPE_TYPE_MASK) == SHAPE_TYPE_BOX) {
				const a1 = dequantizeSize(dv.getUint8(pos++))
				const b1 = dequantizeSize(dv.getUint8(pos++))
				const h = dequantizeSize(dv.getUint8(pos++))
				const a2 = dequantizeSize(dv.getUint8(pos++))
				const b2 = dequantizeSize(dv.getUint8(pos++))

				obj.push({
					drawShape: (header & SHAPE_FLAGS_VISIBLE) && addVertexData(createBox(a1, b1, h, a2, b2)),
					incrementSurfaceIndex: header & SHAPE_FLAGS_NEW_INDEX,
					collider: (header & SHAPE_FLAGS_COLLISION) && {
						min: [Math.min(-a1, -a2), 0, Math.min(-b1, -b2)],
						max: [Math.max(a1, a2), h, Math.max(b1, b2)]
					} satisfies BoxCollider
				});
			} else { // SHAPE_TYPE_PILL
				const r1 = dequantizeSize(dv.getUint8(pos++));
				const r2 = dequantizeSize(dv.getUint8(pos++));
				const h = dequantizeSize(dv.getUint8(pos++));

				obj.push({
					drawShape: (header & SHAPE_FLAGS_VISIBLE) && addVertexData(createPill(r1, r2, h)),
					incrementSurfaceIndex: header & SHAPE_FLAGS_NEW_INDEX,
					collider: (header & SHAPE_FLAGS_COLLISION) && {
						pos: [0, 0, 0],
						r: Math.max(r1, r2),
						vector: [0, h, 0],
					} satisfies CapsuleCollider
				});
			}
		}
	}

	// * Read clouds
	let seed = 0;
	while (pos < section_cloudsEnd) {
		const y = dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1)));
		const xmin = dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1)));
		const zmin = dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1)));
		const xmax = dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1)));
		const zmax = dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1)));

		for (let z = zmin; z <= zmax; z += 0.75) {
			for (let x = xmin; x <= xmax; x += 0.75) {
				drawMesh(
					unitSphere,
					COLOR_WHITE,
					createMatrix({
						translation: add(
							[x, y - .5, z],
							[0.2 * srandf(seed++), 0.2 * srandf(seed++), 0.2 * srandf(seed++)],
						),
						scale: 0.75 + srandf(seed++) * .25
					}),
					1,
					0,
					true,
				);
			}
		}

		staticColliders.push({
			min: [xmin, y - 1, zmin],
			max: [xmax, y, zmax],
			safePoint: pos < section_safeCloudsEnd && [xmin * 0.5 + xmax * 0.5, y+1.5, zmin * 0.5 + zmax * 0.5],
		});
		incrementObjectIndex();
	}

	// * Read NPCs
	let npcIndex = 0;
	while (pos < section_npcsEnd) {
		npcs.push({
			obj: dv.getUint8(pos++) as RenderObjectHandle,
			pos: [
				dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
				dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
				dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
			],
			angle: dequantizeAngle(dv.getUint8(pos++)),
			dialogue: dialogue[npcIndex++]!,
			minShards: dv.getInt8(pos++),
		})
	}

	// * Read shards
	while (pos < section_shardsEnd) {
		shards.push([
			dv.getUint8(pos++),
			repeat(dv.getUint8(pos++)).map(() => [
				dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
				dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
				dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
			]),
			0,
		]);
	}

	// * Read balloons
	while (pos < section_balloonsEnd) {
		createBalloon([
			dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
			dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
			dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
		]);
	}

	// * Read level objects
	while (pos < section_levelObjectsEnd) {
		drawObject(
			dv.getUint8(pos++) as RenderObjectHandle,
			{
				_: {
					translation: [
						dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
						dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
						dequantizeBigPosition(dv.getInt16((pos++, pos++ - 1))),
					],
					euler: [
						dequantizeAngle(dv.getUint8(pos++)),
						dequantizeAngle(dv.getUint8(pos++)),
						dequantizeAngle(dv.getUint8(pos++)),
					],
				}
			},
			dv.getUint8(pos++) || undefined,
			true
		);
	}
}
