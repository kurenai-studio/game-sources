import { IDENTITY } from "../core/math.ts";
import { COLOR_BLACK, COLOR_RAINBOW } from "../gamedata/colors.ts";
import { processPlayer } from "./player.ts";
import { processNpcs } from "./npcs.ts";
import { processRainbowShards, shardsCollected } from "./rainbowShards.ts";
import { doScreenWipe, processScreenTransition, transitionProgress } from "../rendering/screenTransition.ts";
import { processBalloons } from "./balloon.ts";
import { processSpeedrunTimer } from "../core/speedrunTimer.ts";
import { drawMesh, drawObject } from "../rendering/renderer.ts";
import { rainbowMesh } from "../rendering/vertexData.ts";
import { currentTime } from "../core/time.ts";
import { wasKeyJustPressed } from "../input/input.ts";
import { inTitleScreen, processTitleScreen } from "./titleScreen.ts";

export function processFrame() {
	processScreenTransition();
	processNpcs();
	processRainbowShards();
	processBalloons();
	processPlayer();
	processSpeedrunTimer();
	processTitleScreen();

	if (shardsCollected >= 7) {
		drawMesh(
			rainbowMesh,
			COLOR_RAINBOW,
			IDENTITY
				.scale(5, 5, 5)
				.rotate(-90,currentTime * 180, 0)
				.translate(0, 3, Math.sin(currentTime * 2)),
			7,
			1,
		);

		if (wasKeyJustPressed("KeyR") && !transitionProgress) {
			doScreenWipe(COLOR_BLACK, () => {
				location.reload();
			});
		}
	}

	victoryTxt.hidden = shardsCollected < 7;
	creditsTxt.hidden = !inTitleScreen && shardsCollected < 7;
}
