export const deltaTime = 1 / 60;
export let currentTime = 0;

export function advanceTime() {
	currentTime += deltaTime;
}
