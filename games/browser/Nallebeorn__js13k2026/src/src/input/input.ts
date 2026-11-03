import { currentTime } from "../core/time.ts";
import { DEBUG } from "../debug.ts";
import { onClick } from "../game/bus.ts";
import type { KeyCode } from "./keycode.ts";

let pressedTimestamp: Record<string, number> = {};

export let mouseDeltaX = 0, mouseDeltaY = 0;

onkeydown = (event: KeyboardEvent) => {
	if (!event.repeat) {
		pressedTimestamp[event.code] = currentTime;
	}
	if (event.code == "Space") {
		event.preventDefault();
	}
};

onkeyup = (event: KeyboardEvent) => {
	pressedTimestamp[event.code] = 0;
};

document.onpointerlockchange = () => {
	pressedTimestamp = {};
}

document.body.onclick = () => {
	if (document.pointerLockElement != document.body) {
		/*
		`unadjustedMovement` seems to be needed on some systems to get consistent
		movement values without weird spikes. But Chromium doesn't support it on
		Linux and will throw and fail the locking :/
	 */
		document.body
			.requestPointerLock({ unadjustedMovement: true })
			.catch(() => document.body.requestPointerLock());
	}
	onClick.forEach(fn => fn());
};

document.body.onmousemove = (event: MouseEvent) => {
	if (document.pointerLockElement == document.body) {
		mouseDeltaX += event.movementX;
		mouseDeltaY += event.movementY;
	}
};

export function clearFrameInputs() {
	mouseDeltaX = mouseDeltaY = 0;
}

export function isKeyHeld(code: KeyCode): (0 | 1) {
	return pressedTimestamp[code] ? 1 : 0;
}

export function wasKeyJustPressed(code: KeyCode) {
	return pressedTimestamp[code] == currentTime;
}
