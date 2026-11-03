import { angleFromDirection, length, rotateTowards, sub, type Vec3 } from "../core/math.ts";
import { currentTime, deltaTime } from "../core/time.ts";
import { debugWatch } from "../debug.ts";
import { obj_npc1_bodySlot, obj_npc1_headSlot, obj_npc1_lowerArmLSlot, obj_npc1_lowerArmRSlot, obj_npc1_lowerLegLSlot, obj_npc1_lowerLegRSlot, obj_npc1_upperArmLSlot, obj_npc1_upperArmRSlot, obj_npc1_upperLegLSlot, obj_npc1_upperLegRSlot, type RenderObjectHandle } from "../gamedata/objects.gen.ts";
import { drawObject, type SlotTransforms } from "../rendering/renderer.ts";
import { playTalk } from "../sound/sound.ts";
import { say } from "./dialogue.ts";
import { getPlayerPos } from "./player.ts";
import { shardsCollected } from "./rainbowShards.ts";

export interface Npc {
	obj: RenderObjectHandle,
	pos: Vec3,
	angle: number,
	dialogue: string,
	minShards: number
}
export const npcs: Npc[] = [];

let prevDialogue = "";

export function processNpcs() {
	const t0 = performance.now();
	let dialogue = "";
	for (const npc of npcs) {
		if (shardsCollected >= npc.minShards && 7 + npc.minShards >= shardsCollected) {
			const toPlayer = sub(npc.pos, getPlayerPos());
			if (length(toPlayer) < 7) {
				dialogue =
					shardsCollected >= 7
						? "You did it great Neighdall! You saved us all!"
						: npc.dialogue;
				npc.angle = rotateTowards(npc.angle, angleFromDirection(toPlayer[0], toPlayer[2]), deltaTime * 720)
			}

			const getAnimation = (): Partial<SlotTransforms> => {
				if (length(toPlayer) < 7) {
					return {
						[obj_npc1_upperArmLSlot]: {
							euler: [
								-80 + Math.sin(currentTime * 20) * 20,
								0,
								Math.sin(currentTime * 10) * 30,
							],
						},
						[obj_npc1_lowerArmLSlot]: {
							euler: [
								Math.sin(currentTime * 22) * 15 - 10,
								0,
								Math.sin(currentTime * 12) * 15 + 5,
							],
						},
						[obj_npc1_upperArmRSlot]: {
							euler: [
								-80 + Math.sin(currentTime * 20) * 10,
								0,
								-Math.sin(currentTime * 10 + 1) * 30,
							],
						},
						[obj_npc1_lowerArmRSlot]: {
							euler: [
								Math.sin(currentTime * 22) * 15,
								0 - 10,
								-Math.sin(currentTime * 12 + 1) * 15 - 5,
							],
						},
						[obj_npc1_headSlot]: {
							euler: [Math.sin(currentTime * 20) * 5, 0, 0],
						},
					};
				}

				if (shardsCollected >= 7) {
					return {
						[obj_npc1_upperArmLSlot]: {
							euler: [0, 0, Math.sin(currentTime * 15) * 20 + 20],
						},
						[obj_npc1_lowerArmLSlot]: {
							euler: [0, 0, Math.sin(currentTime * 15 + 3) * 30 + 20],
						},
						[obj_npc1_upperArmRSlot]: {
							euler: [0, 0, -Math.sin(currentTime * 15 + .5) * 20 - 20],
						},
						[obj_npc1_lowerArmRSlot]: {
							euler: [0, 0, -Math.sin(currentTime * 15 + 3 + .5) * 30 - 20],
						}
					};
				}

				return {
					[obj_npc1_upperArmLSlot]: {
						euler: [0, 0, Math.sin(currentTime * 10) * 20 + 20],
					},
					[obj_npc1_lowerArmLSlot]: {
						euler: [0, 0, Math.sin(currentTime * 10) * 20 + 20],
					},
					[obj_npc1_upperArmRSlot]: {
						euler: [0, 0, Math.sin(currentTime * 3) * 5 + 50],
					},
					[obj_npc1_lowerArmRSlot]: {
						euler: [0, 0, Math.sin(currentTime * 3) * 10 + 10],
					},
				};
			};

			drawObject(npc.obj, {
				_: { translation: npc.pos, euler: [0, npc.angle, 0] },
				[obj_npc1_bodySlot]: { translation: [0, Math.sin(currentTime * 3) * 0.1, 0] },
				[obj_npc1_lowerLegLSlot]: {euler: [Math.sin(currentTime * 3) * 15 - 15, 0, 0]},
				[obj_npc1_upperLegLSlot]: {euler: [-Math.sin(currentTime * 3) * 30 + 30, 0, 0]},
				[obj_npc1_lowerLegRSlot]: {euler: [Math.sin(currentTime * 3) * 15 - 15, 0, 0]},
				[obj_npc1_upperLegRSlot]: {euler: [-Math.sin(currentTime * 3) * 30 + 30, 0, 0]},
				...getAnimation(),
			});
		}
	}

	if (dialogue && dialogue != prevDialogue) {
		playTalk();
	}
	prevDialogue = dialogue;
	say(dialogue);

	debugWatch("npcs", performance.now() - t0);
}
