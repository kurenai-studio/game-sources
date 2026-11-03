import { degtorad, IDENTITY } from "../core/math.ts";
import { currentTime, deltaTime } from "../core/time.ts";
import { COLOR_OUTLINE } from "../gamedata/colors.ts";
import { updateCameraTransform } from "../rendering/renderer.ts";
import { doScreenWipe, transitionProgress } from "../rendering/screenTransition.ts";
import { playStart } from "../sound/sound.ts";
import { onClick } from "./bus.ts";

export let inTitleScreen = true;

let cameraYaw = 0;

onClick.push(() => {
	if (!transitionProgress && inTitleScreen) {
		playStart();
		doScreenWipe(COLOR_OUTLINE, () => {
			inTitleScreen = false;
		});
	}
});

export function processTitleScreen() {
	playTxt.hidden = !inTitleScreen || (currentTime % 1 > 0.66);
	logo.hidden = !inTitleScreen || (transitionProgress as unknown as boolean);
	if (inTitleScreen) {
		cameraYaw += deltaTime * 30;

		updateCameraTransform(
			IDENTITY
				.rotate(0, cameraYaw, 0)
				.translate(0, 110, 100)
				.rotate(-30, 0, 0)
		);
	}
}
