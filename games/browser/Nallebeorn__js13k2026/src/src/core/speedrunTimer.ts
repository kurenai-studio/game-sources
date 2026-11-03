import { shardsCollected } from "../game/rainbowShards.ts";
import { inTitleScreen } from "../game/titleScreen.ts";
import { submitTime, unlockAchievement } from "../platforms/wavedash.ts";
import { deltaTime } from "./time.ts";

export let speedrunTimer = 0;
let bestTime = +localStorage.getItem("unifrostBest")!;

export function processSpeedrunTimer() {
	timers.hidden = !bestTime;
	if (shardsCollected < 7 && !inTitleScreen) {
		speedrunTimer += deltaTime;
	}
	curTimer.innerText = formatTime(speedrunTimer);
	bestTimer.innerText = formatTime(bestTime);
}

export function saveBestTime() {
	bestTime = bestTime ? Math.min(bestTime, speedrunTimer) : speedrunTimer;
	localStorage.setItem("unifrostBest", bestTime as unknown as string);
	submitTime(bestTime);
	if (speedrunTimer < 13 * 60) {
		unlockAchievement("speed");
	}
	if (speedrunTimer < 3 * 60 + 47.583) {
		unlockAchievement("par");
	}
}

function formatTime(seconds: number) {
  const mins = (seconds / 60) | 0;
  const secs = seconds % 60;

  return `${(""+mins).padStart(2, '0')}:${secs.toFixed(3).padStart(6, '0')}`;
}


//
