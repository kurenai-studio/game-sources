import { easeInBack, IDENTITY, length, lerpv, sub, type Vec3 } from "../core/math.ts";
import { saveBestTime, speedrunTimer } from "../core/speedrunTimer.ts";
import { currentTime, deltaTime } from "../core/time.ts";
import { DEBUG, debugWatch } from "../debug.ts";
import { COLOR_GREEN, COLOR_VIOLET, unlockColor, type Color } from "../gamedata/colors.ts";
import { wasKeyJustPressed } from "../input/input.ts";
import type { KeyCode } from "../input/keycode.ts";
import { unlockAchievement } from "../platforms/wavedash.ts";
import { drawMesh } from "../rendering/renderer.ts";
import { doScreenWipe, transitionProgress } from "../rendering/screenTransition.ts";
import { rainbowMesh } from "../rendering/vertexData.ts";
import { playCollect, playCollect2, playFlee } from "../sound/sound.ts";
import { onPlayerDeath } from "./bus.ts";
import { getPlayerPos } from "./player.ts";

export const shards: [color: Color, pos: Vec3[], currentPosIndex: number][] = [];

export let shardsCollected = 0;

let collectingShard: number;
export let shardCollectTimer = 0;

let movingShard: number;
let shardMovement = 0;
let distanceToNextPos = 1;

let hasFoundVioletShard: boolean | undefined;

onPlayerDeath.push(() => {
	movingShard = -1;
	shardMovement = 0;
	for (let i = 0; i < shards.length; i++) {
		shards[i]![2] = (hasFoundVioletShard && shards[i]![0] == COLOR_VIOLET) ? 1 : 0;
	}
});

export function processRainbowShards() {
	const t0 = performance.now();

	for (let i = 0; i < shards.length; i++) {
		const [color, positions, posIndex] = shards[i]!;

		const scale = 0.75 * (1 - (+(collectingShard == i) && easeInBack(Math.min(1, shardCollectTimer += deltaTime * .8))));
		drawMesh(
			rainbowMesh,
			color + 10,
			IDENTITY.translate(
				...lerpv(
					positions[posIndex]!,
					positions[posIndex + 1],
					movingShard == i ? shardMovement : 0,
				),
			)
				.scale(scale, scale, scale)
				.rotate(
					-90,
					currentTime * (collectingShard == i || movingShard == i ? 1200 : 360),
					0
				)
				.translate(
					0,
					3,
					Math.sin(currentTime * 3)
					+ shardCollectTimer * 7,
				),
			7,
			1,
		);

		if (movingShard == i) {
			shardMovement += deltaTime / (distanceToNextPos * 0.025);
			if (shardMovement > 1) {
				shardMovement = 0;
				movingShard = -1;
				shards[i]![2]++;
			}
		} else {
			if (length(sub(positions[posIndex]!, getPlayerPos())) < 3 && !shardCollectTimer) {
				if (posIndex >= positions.length - 1) {
					collectingShard = i;
					playCollect();
				} else {
					playFlee();
					movingShard = i;
					distanceToNextPos = length(
						sub(positions[posIndex + 1]!, positions[posIndex]!),
					);
					if (color == COLOR_VIOLET) {
						hasFoundVioletShard = true;
					}
				}
			}
		}

		if (DEBUG && wasKeyJustPressed(`Digit${i + 1}` as KeyCode)) {
			unlockColor(color);
			shardsCollected++;
			setTimeout(() => shards.splice(i, 1), 0);
		}
	}

	if (shardCollectTimer > 1 && !transitionProgress) {
		doScreenWipe(shards[collectingShard]![0] + 10, () => {
			unlockColor(shards[collectingShard]![0]);
			unlockAchievement("shard" + shardsCollected);
			if (shardsCollected == 0 && speedrunTimer < 10) {
				unlockAchievement("gallop");
			}
			shardsCollected++;
			shards.splice(collectingShard, 1);
			collectingShard = -1;
			shardCollectTimer = 0;
			playCollect2();

			if (shardsCollected >= 7) {
				saveBestTime();
			}
		});
	}

	debugWatch("shards", performance.now() - t0);
}
