import { spring, type Vec3 } from "../core/math.ts";
import { DEBUG, debugWatch } from "../debug.ts";
import { objectsBank } from "../gamedata/gamedata.ts";
import { obj_balloon, obj_balloon_balloonSlot } from "../gamedata/objects.gen.ts";
import { staticColliders } from "../physics/objectColliders.ts";
import { drawObject } from "../rendering/renderer.ts";

const balloons: [pos: Vec3, scale: number, spring: number][] = [];

export function createBalloon(pos: Vec3) {
	balloons.push([pos, 0, 0]);
	const collider = objectsBank[obj_balloon]![2]?.collider;
	if (DEBUG) {
		if (!collider) {
			console.error("Didn't find balloon collider");
		}
	}
	staticColliders.push({
		pos,
		r: 2.5,
		vector: [0, 0.25, 0],
		balloon: balloons.length,
	});
}

export function bounce(balloon: number) {
	balloons[balloon - 1]![1] = 1;
}

export function processBalloons() {
	const t0 = performance.now();
	for (let i = 0; i < balloons.length; i++) {
		balloons[i]![2] = spring(balloons[i]![1], balloons[i]![2]);
		balloons[i]![1] += balloons[i]![2];
		drawObject(obj_balloon, { _: { translation: balloons[i]![0] }, [obj_balloon_balloonSlot]: {yscale: 1 - balloons[i]![1]} });
	}
	debugWatch("balloons", performance.now() - t0);
}
