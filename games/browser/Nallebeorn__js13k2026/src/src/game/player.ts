import { rotateTowards, withLength, IDENTITY, add, type Vec3, normalize, length, sub, dot, clamp, spring, lerp, angleFromDirection, type Vec2 } from "../core/math.ts";
import { currentTime, deltaTime } from "../core/time.ts";
import { DEBUG, debugWatch } from "../debug.ts";
import { COLOR_CONSUMABLE_BLUE, COLOR_CONSUMABLE_CYAN, COLOR_CONSUMABLE_GREEN, COLOR_CONSUMABLE_ORANGE, COLOR_CONSUMABLE_RED, COLOR_CONSUMABLE_VIOLET, COLOR_CONSUMABLE_YELLOW, COLOR_OUTLINE, COLOR_RAINBOW, COLOR_RED, COLOR_VIOLET, colors, unlockedColors } from "../gamedata/colors.ts";
import {
	obj_unicorn,
	obj_unicorn_neckSlot,
	obj_unicorn_headSlot,
	obj_unicorn_tailSlot,
	obj_unicorn_hindLegRSlot,
	obj_unicorn_hindKneeRSlot,
	obj_unicorn_hindHeelRSlot,
	obj_unicorn_hindLegLSlot,
	obj_unicorn_hindKneeLSlot,
	obj_unicorn_hindHeelLSlot,
	obj_unicorn_foreLegRSlot,
	obj_unicorn_foreLegLSlot,
	obj_unicorn_foreLegBowRSlot,
	obj_unicorn_foreLegBowLSlot,
	obj_unicorn_bodySlot,
	obj_unicorn_tail2Slot,
	obj_unicorn_tail3Slot,
	obj_unicorn_hornPivotSlot,
	obj_gizmo,
} from "../gamedata/objects.gen.ts";
import { isKeyHeld, mouseDeltaX, mouseDeltaY, wasKeyJustPressed } from "../input/input.ts";
import type { KeyCode } from "../input/keycode.ts";
import { penetrateSphereGeneric, type BoxCollider, type CapsuleCollider, type Collision, type ConfirmedCollision } from "../physics/collision.ts";
import { staticColliders } from "../physics/objectColliders.ts";
import { cameraTransform, drawMesh, drawObject, ROOT_SLOT, updateCameraTransform, type SlotTransforms } from "../rendering/renderer.ts";
import { doScreenWipe, transitionProgress } from "../rendering/screenTransition.ts";
import { rainbowMesh } from "../rendering/vertexData.ts";
import { playBounce, playDie, playFling, playFlingCharge, playGrind, playJump, playLodge, playSpin, playStep } from "../sound/sound.ts";
import { bounce } from "./balloon.ts";
import { onPlayerDeath } from "./bus.ts";
import { shardCollectTimer, shardsCollected } from "./rainbowShards.ts";
import { inTitleScreen } from "./titleScreen.ts";

const SPEED = 20;
const BOOST_SPEED = 25;
const BOOST_DELAY = 1;
const ACCELERATION = 45;
const DECELERATION = 90;
const JUMP_SPEED = 35;
const WALL_JUMP_SPEED = 60;
const GRAVITY = 100;
const FALL_SPEED = 60;
const GRIND_LENGTH = 20;
const MAX_STEP = 0.25;

let x = 0;
let y = 1.5;
let z = 0;


let rotation = 0;
let dirx = 1;
let diry = 0;
let vx = 0;
let vy = 0;
let vz = 0;
let boostCharge = 0;
let wallJumping = false;
let grounded = true;
let groundedTimestamp = 0;

let springSpd = 0;
let springRot = 0;

let cameraYaw = 60;
let cameraPitch = 0;

let respawnPoint: [...Vec3, ...Vec2, ...Vec2] = [
	x,
	y,
	z,
	dirx,
	diry,
	cameraYaw,
	cameraPitch,
];

const enum PlayerState {
	MOVING,
	WALL_LODGE,
}

let state = PlayerState.MOVING;

let isGrinding = false;
let grindStart: Vec3;
let grindLength: number;
let grindUses = 0;
let completedGrindUses = 0;

let stepTimer = 0;
const stepTimings = [.25, .1, .1];
let stepIndex = 0;

export function getPlayerPos(): Vec3 {
	return [x, y, z];
}

if (DEBUG) {
	const data = JSON.parse(localStorage.getItem("UNIFROST_DEBUG_SAVE")!);
	x = data?.x ?? x;
	y = data?.y ?? y;
	z = data?.z ?? z;
	respawnPoint = data?.respawnPoint ?? respawnPoint;
	cameraYaw = data?.cameraYaw ?? cameraYaw;
	cameraPitch = data?.cameraPitch ?? cameraPitch;
}

function saveDebugState() {
	if (DEBUG) {
		localStorage.setItem(
			"UNIFROST_DEBUG_SAVE",
			JSON.stringify({ x, y, z, respawnPoint, cameraYaw, cameraPitch }),
		);

		if (wasKeyJustPressed("KeyT" as KeyCode)) {
			localStorage.removeItem("UNIFROST_DEBUG_SAVE");
			location.reload();
		}
	}
}

export function processPlayer() {
	debugWatch("pos", [x, y, z].map(n => n.toFixed(1)));

	const t0 = performance.now();
	if (state == PlayerState.MOVING && !shardCollectTimer && !inTitleScreen) {
		processMovingState();
	}
	if (state == PlayerState.WALL_LODGE && !shardCollectTimer && !inTitleScreen) {
		processWallLodgedState();
	}

	if (!isGrinding) {
		completedGrindUses = grindUses;
	}

	let spentColors = 0;
	for (let c = COLOR_RED; c <= COLOR_VIOLET; c++) {
		const available = !!unlockedColors[c] && ++spentColors > completedGrindUses;
		for (let i = 0; i < 3; i++) {
			colors[c * 4 + 17 * 4 + i] = +available && colors[c * 4 + i]!;
		}
	}

	// debugWatch("vx", vx.toFixed(3));
	// debugWatch("vz", vz.toFixed(3));
	debugWatch("vy", vy);

	// ? Draw unicorn
	drawObject(obj_unicorn, {
		[ROOT_SLOT]: {
			translation: [x, y, z],
			euler: [0, rotation, 0],
		},
		[obj_unicorn_hornPivotSlot]: {
			euler: [springRot, 0, 0],
		},
		...getAnimation()
	});

	if (isGrinding) {
		drawMesh(
			rainbowMesh,
			COLOR_RAINBOW,
			IDENTITY
				.translate(...grindStart)
				.rotate(0, -angleFromDirection(diry, dirx) + 90, 0),
			grindLength * 2,
			GRIND_LENGTH - 5
		);
	}

	if (DEBUG) {
		// drawObject(obj_gizmo, { _: { translation: [x, y, z] } });
	}

	// ? Camera controls
	if (!inTitleScreen) {
		const moveYaw = mouseDeltaX * .1;
		const movePitch = mouseDeltaY * .1;
		cameraYaw += -moveYaw * 100 * deltaTime;
		cameraPitch = clamp(cameraPitch - movePitch * 100 * deltaTime, -80, 30)
		updateCameraTransform(
			IDENTITY
				.translate(x, y, z)
				.rotate(cameraPitch, cameraYaw, 0)
				.translate(0, 3, 18)
		);
	}

	debugWatch("player", performance.now() - t0);
}

function processMovingState() {
	if (isGrinding) {
		vx += dirx * ACCELERATION * deltaTime;
		vz += diry * ACCELERATION * deltaTime;
		boostCharge += deltaTime * 4;
	} else {
		const [movex, movey] = withLength(
			[isKeyHeld("KeyD") - isKeyHeld("KeyA"), isKeyHeld("KeyS") - isKeyHeld("KeyW")],
			ACCELERATION * deltaTime
		)
		const move = (cameraTransform.transformPoint(new DOMPoint(movex, 0, movey, 0)));
		const movedir = normalize([move.x, move.z] as Vec2);
		vx += movedir[0] || 0;
		vz += movedir[1] || 0;

		if (movex || movey) {
			[dirx, diry] = movedir;
			const turnBoost = -dot([dirx, 0, diry], normalize([vx, 0, vz])) * .5 + .5;
			[vx,, vz] = add([vx, 0, vz], withLength([dirx, 0, diry], DECELERATION * turnBoost * deltaTime));
		} else {
			const decel = withLength(
				[vx, 0, vz],
				Math.min(length([vx, 0, vz]), DECELERATION * deltaTime),
			);
			[vx, , vz] = sub([vx, 0, vz], decel);
		}

		vy = Math.max(vy - GRAVITY * deltaTime, -FALL_SPEED);
	}

	const speed = length([vx, 0, vz]);
	[vx, , vz] = withLength([vx, 0, vz], Math.min(boostCharge > BOOST_DELAY || isGrinding ? BOOST_SPEED : SPEED, speed));
	debugWatch("speed", speed.toFixed(3));
	rotation = rotateTowards(rotation, angleFromDirection(dirx, diry), deltaTime * 720)

	if (isGrinding) {
		grindLength = grindLength + speed * deltaTime;
		debugWatch("grind length", grindLength);
		if (grindLength > GRIND_LENGTH) {
			isGrinding = false;
			boostCharge = 0;
		}
	}

	debugWatch("colliders", staticColliders.length);

function* enumerateCollisions() {
		for (const levelCollider of staticColliders) {
			const pos =
				(levelCollider as CapsuleCollider).pos ??
				(levelCollider as BoxCollider).min;
			if (length(sub(pos, [x, y, z])) < 100) {
				for (const playerCollider of [
					[dirx/2, 0, diry/2],
					[dirx/2, -1, diry/2],
					[-dirx/2, 0, -diry/2],
					[-dirx/2, -1, -diry/2],
				] satisfies Vec3[]) {
					const collision = penetrateSphereGeneric(
						add(playerCollider, [x, y, z]),
						0.5,
						levelCollider,
					);

					if (collision.depenetration) {
						yield collision as ConfirmedCollision;
					}
				}
			}
		}
	}

	x += vx * deltaTime;
	z += vz * deltaTime;

	const t1 = performance.now();

	// * Horizontal collisions
	for (const {depenetration, balloon} of enumerateCollisions()) {
		x += depenetration[0];
		if (vx) {
			vx += depenetration[0] / deltaTime;
		}
		z += depenetration[2];
		if (vz) {
			vz += depenetration[2] / deltaTime;
		}
		if (!grounded && dot(normalize(depenetration), [-dirx, 0, -diry]) > 0.3) {
			if (isGrinding) {
				isGrinding = false;
				boostCharge = 0;
				vx = 0;
				vz = 0;
			} else if (boostCharge > BOOST_DELAY && !balloon) {
				// ? activate wall lodge
				state = PlayerState.WALL_LODGE;
				x -= dirx * .8;
				z -= diry * .8;
				boostCharge = 0;
				springRot = 45;
				vx = 0;
				vz = 0;
				isGrinding = false;
				playLodge();
			}
		}
	}

	// * Vertical movement
	let prevGrounded = grounded;
	grounded = false;
	let yMovement = Math.abs(vy * deltaTime);
	while (yMovement > 0) {
		y += Math.min(yMovement, MAX_STEP) * Math.sign(vy);
		yMovement -= MAX_STEP;

		for (const { depenetration, safePoint, balloon } of enumerateCollisions()) {
			y += depenetration[1];
			if (Math.abs(normalize(depenetration)[1]) > 0.5) {
				vy += depenetration[1] / deltaTime;
				if (depenetration[1] > 0) {
					if (safePoint) {
						respawnPoint = [...safePoint, dirx, diry, cameraYaw, cameraPitch];
					}
					if (balloon) {
						if (vy < 0) {
							vy = JUMP_SPEED;
							bounce(balloon);
							playBounce();
						}
					} else {
						grounded = true;
						grindUses = 0;
					}
				}
			}
		}
	}

	debugWatch("playercoll", performance.now() - t1);

	if (y < -25 && !transitionProgress) {
		// * Die and respawn
		playDie();
		doScreenWipe(COLOR_OUTLINE, () => {
			[x, y, z, dirx, diry, cameraYaw, cameraPitch] = respawnPoint;
			vx = 0;
			vy = 0;
			vz = 0;
			boostCharge = 0;
			onPlayerDeath.forEach(fn => fn());
			grounded = true;
		});
	}

	debugWatch("grounded", grounded ? 1 : 0);

	if (grounded) {
		if (!prevGrounded) {
			playStep();
		}
		vy = 0;
		wallJumping = false;
		groundedTimestamp = currentTime;

		if (speed >= SPEED) {
			boostCharge += deltaTime;
		} else {
			boostCharge = 0;
		}
	} else {
		if (speed < SPEED) {
			boostCharge = Math.max(boostCharge - deltaTime, 0);
		}
	}

	if (grounded && speed > 0) {
		stepTimer += boostCharge >= BOOST_DELAY ? deltaTime * 1.25 : deltaTime;
		if (stepTimer > stepTimings[stepIndex]!) {
			playStep();
			stepTimer = 0;
			stepIndex = (stepIndex + 1) % stepTimings.length;
		}
	} else {
		stepTimer = 0;
		stepIndex = 0;
	}

	if (wasKeyJustPressed("Space")) {
		if ((currentTime - groundedTimestamp < .2) || isGrinding) {
			vy = JUMP_SPEED;
			isGrinding = false;
			groundedTimestamp = 0;
			if (boostCharge >= BOOST_DELAY) {
				playSpin();
			} else {
				playJump();
			}
		} else if (!grounded && grindUses < shardsCollected) {
			// ? activate grinding
			isGrinding = true;
			boostCharge = 0;
			vy = 0;
			vx = dirx * SPEED;
			vz = diry * SPEED;
			grindStart = [x, y - 1.4, z];
			grindLength = 0;
			wallJumping = false;
			grindUses++;
			playGrind();
		}
	}

	debugWatch("boost", boostCharge.toFixed(2));

	saveDebugState();
	prevGrounded = grounded;
}

function processWallLodgedState() {
	if (wasKeyJustPressed("Space")) {
		playFlingCharge();
	}
	if (isKeyHeld("Space")) {
		springSpd = 0;
		springRot = lerp(springRot, -60, 0.08);
	} else {
		if (springRot < -55) {
			state = PlayerState.MOVING;
			vy = WALL_JUMP_SPEED;
			wallJumping = true;
			springRot = 0;
			springSpd = 0;
			playFling();
		} else {
			springSpd = spring(springRot, springSpd);
			springRot += springSpd;
		}
	}
}

function getAnimation(): Partial<SlotTransforms> {
	// return grindAnimation();
	if (isGrinding) return grindAnimation();
	if (state == PlayerState.WALL_LODGE) return wallLodgedAnimation();
	if (!grounded && wallJumping) return wallJumpAnimation();
	if (!grounded && boostCharge > BOOST_DELAY) return boostJumpAnimation();
	if (vy > 0) return jumpAnimation();
	if (vy < 0) return fallAnimation();
	if ((vx || vz) && !shardCollectTimer) return runAnimation();
	return idleAnimation();
}

function runAnimation(): Partial<SlotTransforms> {
	const runAnimationTime = boostCharge > BOOST_DELAY ? currentTime * 30 : currentTime * 19;
	return {
		[obj_unicorn_bodySlot]: {
			translation: [0, Math.cos(runAnimationTime) * .1, 0],
		},
		[obj_unicorn_tailSlot]: {
			euler: [Math.sin(runAnimationTime) * 45 + 60, 0, 0],
		},
		[obj_unicorn_tail2Slot]: {
			euler: [Math.sin(runAnimationTime - 1) * 45, 0, 0],
		},
		[obj_unicorn_tail3Slot]: {
			euler: [Math.sin(runAnimationTime - 2) * 45, 0, 0],
		},
		[obj_unicorn_neckSlot]: {
			euler: [Math.sin(runAnimationTime) * 15, 0, 0],
		},
		[obj_unicorn_headSlot]: {
			euler: [Math.sin(runAnimationTime) * -10, 0, 0],
		},


		[obj_unicorn_hindLegRSlot]: {
			euler: [Math.cos(runAnimationTime) * 45, 0, 0],
		},
		[obj_unicorn_hindKneeRSlot]: {
			euler: [Math.sin(runAnimationTime) * 60 + 60, 0, 0],
		},
		[obj_unicorn_hindHeelRSlot]: {
			euler: [Math.sin(runAnimationTime) * -90, 0, 0],
		},

		[obj_unicorn_hindLegLSlot]: {
			euler: [Math.cos(runAnimationTime + 2) * 45, 0, 0],
		},
		[obj_unicorn_hindKneeLSlot]: {
			euler: [Math.sin(runAnimationTime + 2) * 60 + 60, 0, 0],
		},
		[obj_unicorn_hindHeelLSlot]: {
			euler: [Math.sin(runAnimationTime + 2) * -90 - 45, 0, 0],
		},

		[obj_unicorn_foreLegRSlot]: {
			euler: [Math.cos(runAnimationTime + Math.PI) * 30 - 30, 0, 0],
		},
		[obj_unicorn_foreLegBowRSlot]: {
			euler: [Math.sin(runAnimationTime + Math.PI) * -45 + 30, 0, 0]
		},

		[obj_unicorn_foreLegLSlot]: {
			euler: [Math.cos(runAnimationTime + Math.PI + 1) * 30 - 45, 0, 0],
		},
		[obj_unicorn_foreLegBowLSlot]: {
			euler: [Math.sin(runAnimationTime + Math.PI + 1) * -45 + 30, 0, 0]
		},
	};
}

function idleAnimation(): Partial<SlotTransforms> {
	const t = ((currentTime * 10 / Math.PI) % 14) <= 4 ? currentTime * 10 : 0;

	return {
		[obj_unicorn_neckSlot]: {
			euler: [
				Math.sin(t) * 15,
				Math.sin(t * 2) * 20,
				0,
			],
		},
		[obj_unicorn_headSlot]: {
			euler: [Math.sin(t) * 10, 0, 0],
		},
		[obj_unicorn_tailSlot]: {
			euler: [0, 0, Math.sin(currentTime * 8) * 15],
		},
		[obj_unicorn_tail2Slot]: {
			euler: [0, 0, Math.sin(currentTime * 8) * 15],
		},
		[obj_unicorn_tail3Slot]: {
			euler: [0, 0, Math.sin(currentTime * 8) * 15],
		},
	};
}

function jumpAnimation(): Partial<SlotTransforms> {
	return {
		[obj_unicorn_bodySlot]: {
			euler: [-15, 0, 0],
		},
		[obj_unicorn_headSlot]: {
			euler: [10, 0, 0],
		},

		[obj_unicorn_foreLegRSlot]: {
			euler: [-60, 0, 0]
		},
		[obj_unicorn_foreLegBowRSlot]: {
			euler: [120, 0, 0],
		},
		[obj_unicorn_foreLegLSlot]: {
			euler: [-60, 0, 0]
		},
		[obj_unicorn_foreLegBowLSlot]: {
			euler: [120, 0, 0],
		},

		[obj_unicorn_hindLegRSlot]: {
			euler: [45, 0, 0]
		},
		[obj_unicorn_hindLegLSlot]: {
			euler: [45, 0, 0]
		},

		[obj_unicorn_tailSlot]: {
			euler: [Math.sin(currentTime * 19) * 45 + 60, 0, 0],
		},
		[obj_unicorn_tail2Slot]: {
			euler: [Math.sin(currentTime * 19 - 1) * 45, 0, 0],
		},
		[obj_unicorn_tail3Slot]: {
			euler: [Math.sin(currentTime * 19 - 2) * 45, 0, 0],
		},
	}
}

function fallAnimation(): Partial<SlotTransforms> {
	return {
		[obj_unicorn_bodySlot]: {
			euler: [15, 0, 0],
		},
		[obj_unicorn_headSlot]: {
			euler: [-10, 0, 0],
		},

		[obj_unicorn_foreLegRSlot]: {
			euler: [-45, 0, 0]
		},

		[obj_unicorn_foreLegLSlot]: {
			euler: [-60, 0, 0]
		},
		[obj_unicorn_foreLegBowLSlot]: {
			euler: [15, 0, 0],
		},

		[obj_unicorn_hindLegRSlot]: {
			euler: [-45, 0, 0]
		},
		[obj_unicorn_hindKneeRSlot]: {
			euler: [90, 0, 0],
		},
		[obj_unicorn_hindHeelRSlot]: {
			euler: [-90, 0, 0],
		},

		[obj_unicorn_hindLegLSlot]: {
			euler: [-45, 0, 0]
		},
		[obj_unicorn_hindKneeLSlot]: {
			euler: [90, 0, 0],
		},
		[obj_unicorn_hindHeelLSlot]: {
			euler: [-90, 0, 0],
		},

		[obj_unicorn_tailSlot]: {
			euler: [Math.sin(currentTime * 19) * 45 + 120, 0, 0],
		},
		[obj_unicorn_tail2Slot]: {
			euler: [Math.sin(currentTime * 19 - 1) * 45, 0, 0],
		},
		[obj_unicorn_tail3Slot]: {
			euler: [Math.sin(currentTime * 19 - 2) * 45, 0, 0],
		},
	}
}

function boostJumpAnimation(): Partial<SlotTransforms> {
	return {
		[obj_unicorn_bodySlot]: {
			euler: [0, 0, currentTime * 1666]
		},
		[obj_unicorn_neckSlot]: {
			euler: [45, 0, 0],
		},
		[obj_unicorn_foreLegBowRSlot]: {
			euler: [120, 0, 0],
		},
		[obj_unicorn_foreLegBowLSlot]: {
			euler: [120, 0, 0],
		},

		[obj_unicorn_hindLegRSlot]: {
			euler: [45, 0, 0]
		},
		[obj_unicorn_hindLegLSlot]: {
			euler: [45, 0, 0]
		},

		[obj_unicorn_tailSlot]: {
			euler: [45, 0, 0]
		},
		[obj_unicorn_tail2Slot]: {
			euler: [0, 0, 60]
		},
		[obj_unicorn_tail3Slot]: {
			euler: [0, 0, 60]
		}
	}
}

function wallLodgedAnimation(): Partial<SlotTransforms> {
	return {
		[obj_unicorn_neckSlot]: {
			euler: [45, 0, 0],
		},

		[obj_unicorn_foreLegLSlot]: {
			euler: [0, 0, Math.sin(currentTime * 4) * 15],
		},
		[obj_unicorn_foreLegRSlot]: {
			euler: [0, 0, Math.sin(currentTime * 4 + 1) * 15],
		},
		[obj_unicorn_hindLegLSlot]: {
			euler: [0, 0, Math.sin(currentTime * 4 + 2) * 15],
		},
		[obj_unicorn_hindLegRSlot]: {
			euler: [0, 0, Math.sin(currentTime * 4 + 3) * 15],
		},

		[obj_unicorn_tailSlot]: {
			euler: [0, 0, Math.sin(currentTime * 8) * 15],
		},
		[obj_unicorn_tail2Slot]: {
			euler: [0, 0, Math.sin(currentTime * 8) * 15],
		},
		[obj_unicorn_tail3Slot]: {
			euler: [0, 0, Math.sin(currentTime * 8) * 15],
		},
	}
}

function wallJumpAnimation(): Partial<SlotTransforms> {
	return {
		[obj_unicorn_bodySlot]: {
			euler: [currentTime * 1666, 0, 0],
		}
	}
}

function grindAnimation(): Partial<SlotTransforms> {
	return {
		[obj_unicorn_bodySlot]: {
			euler: [-15, Math.min(boostCharge * 2 * 360, 360), 0],
		},
		[obj_unicorn_neckSlot]: {
			euler: [
				Math.sin(currentTime * 22) * 16,
				0,
				Math.sin(currentTime * 8) * 16,
			],
		},
		[obj_unicorn_headSlot]: {
			euler: [Math.sin(currentTime * 22 - 1) * 16, 0, 0],
		},

		[obj_unicorn_tailSlot]: {
			euler: [
				Math.sin(currentTime * 22) * 15 + 100,
				0,
				Math.sin(currentTime * 22) * 15,
			],
		},
		[obj_unicorn_tail2Slot]: {
			euler: [
				Math.sin(currentTime * 22 - 1) * 45,
				0,
				Math.sin(currentTime * 22) * 15,
			],
		},
		[obj_unicorn_tail3Slot]: {
			euler: [
				Math.sin(currentTime * 22 - 2) * 45,
				0,
				Math.sin(currentTime * 22) * 15,
			],
		},

		[obj_unicorn_hindLegLSlot]: {
			euler: [-15, 0, 5],
		},
		[obj_unicorn_hindLegRSlot]: {
			euler: [-15, 0, -5],
		},

		[obj_unicorn_foreLegLSlot]: {
			euler: [15, 0, 5],
		},
		[obj_unicorn_foreLegRSlot]: {
			euler: [15, 0, -5],
		},
	};
}
