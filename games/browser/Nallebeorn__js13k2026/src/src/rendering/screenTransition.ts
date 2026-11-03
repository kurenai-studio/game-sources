import { deltaTime } from "../core/time.ts";
import { type Color } from "../gamedata/colors.ts";

export let transitionProgress = 0;
export let transitionColor!: Color;

let transitionCallback: (() => void) | undefined;

export function doScreenWipe(color: Color, callback: () => void) {
	transitionColor = color;
	transitionProgress = 1;
	transitionCallback = callback;
}

export function processScreenTransition() {
	if (transitionProgress) {
		transitionProgress = Math.max(transitionProgress - deltaTime * .9, 0);
		if (transitionProgress < .5 && transitionCallback) {
			transitionCallback();
			transitionCallback = undefined;
		}
	}
}
