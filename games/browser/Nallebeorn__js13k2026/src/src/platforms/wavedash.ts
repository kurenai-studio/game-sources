import type { Id, WavedashSDK } from "@wvdsh/sdk-js";

declare global {
	const Wavedash: WavedashSDK;
}

export const WAVEDASH = import.meta.env.MODE === "wavedash";

let leaderboardId: Id<"leaderboards"> | undefined;

export function initWavedash() {
	if (WAVEDASH) {
		Wavedash.init();
		initLeaderboard();
	}
}


export async function submitTime(time: number) {
	if (WAVEDASH) {
		if (!leaderboardId) {
			await initLeaderboard();
		}
		await Wavedash.uploadLeaderboardScore(leaderboardId!, time, true);
	}
}

export async function unlockAchievement(achievement: string) {
	if (WAVEDASH) {
		Wavedash.setAchievement(achievement, true);
	}
}

async function initLeaderboard() {
	return Wavedash.getLeaderboard("time").then(leaderboard => {
		if (leaderboard.success) leaderboardId = leaderboard.data.id;
		console.log("leaderboard", leaderboardId);
	});
}
