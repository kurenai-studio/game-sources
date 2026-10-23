import {
	DYNAMIC,
	b2Body_ApplyForceToCenter,
	b2Body_ApplyLinearImpulseToCenter,
	b2Body_GetAngularVelocity,
	b2Body_GetLinearVelocity,
	b2Body_GetMass,
	b2Body_GetRotation,
	b2Body_IsValid,
	b2Body_SetAngularVelocity,
	b2Body_SetLinearVelocity,
	b2Vec2,
	pxm
} from "phaser-box2d/dist/PhaserBox2D.js";
import { assignB2BodyBox } from "../modules/box2dUtils.js";
import { getTransmissionStats, getParKeyForDifficulty } from "./carParams.js";

const clampTransmission = (v) => Phaser.Math.Clamp(v, 0, 21);

// =============================================================================
// PHYSICS CONVERSION CONSTANTS
// =============================================================================
// Derived from original game measurements (see physicsMeasurements.md):
//   - At top speed, car travels ~2.306 * kph pixels per 30 frames at 60fps
//   - pxPerSec = 2.306 * kph * 2 = 4.612 * kph
//   - Box2D world uses PTM_RATIO = 30 (30 pixels = 1 meter)
//   - worldSpeed = pxPerSec / 30 = 0.1537 * kph
const KPH_TO_WORLD = 0.1537;
const WORLD_TO_KPH = 1 / KPH_TO_WORLD;
const MAX_REVERSE_KPH = 26;
const REVERSE_ACCEL = 5.0;
const MIN_STOP_VELOCITY = 0.5;
const TURN_ACCEL_DAMP = 0.8;

// Handbrake fine-tuning constants (matched to original TRABI2.EXE car_physicsUpdate @ 17ee:345c)
// Original game: handbrake kills throttle, disables steering self-centering, spins via car[0x13]
// formula: angVel += spinParam / (slipAngle + const). No direct forward brake force applied.
const HANDBRAKE_LATERAL_ACCEL_BASE = 6.0;       // Low base grip for pronounced slide/drift
const HANDBRAKE_LATERAL_ACCEL_TIRE_MULT = 6.0;  // Grip bonus per tiresVal (0-2) — bigger range so tires matter more
const HANDBRAKE_STEER_MULT_BASE = 3.5;          // Base steering speed multiplier during handbrake
const HANDBRAKE_STEER_TIRE_REDUCTION = 0.5;     // Less spin-out with better tires: mult = base - reduction*tiresVal
const HANDBRAKE_DECEL_FRACTION = 0.35;          // Fraction of normal brakeDecel applied (original has no direct brake force)

// Convert kph to Box2D world speed (meters/second)
const kphToWorldSpeed = (kph) => KPH_TO_WORLD * kph;

// Convert Box2D world speed to kph
const worldSpeedToKph = (worldSpeed) => WORLD_TO_KPH * worldSpeed;

// =============================================================================
// TRANSMISSION PROFILE
// =============================================================================

const buildTransmissionProfile = (stats, transmissionVal) => {
	const T = clampTransmission(transmissionVal);

	const topKph = stats.finalSpeed;
	const maxSpeedWorld = kphToWorldSpeed(topKph);

	// 3-phase acceleration model (simulates gear behavior from original game):
	// These base values were tuned for Medium difficulty (diff=1).
	let a1_kph = 30;
	let a2_kph = 54 - 0.83 * T;
	let a3_kph = 26 - 0.64 * T;

	// Scale accelerations based on the ratio of target zeroTo60 time.
	// We need a reference Medium 0-60 time for this transmission.
	// We can use a dummy 25-byte buffer where r2=baseF2 (0.142)
	const dummyBytes = new Uint8Array(25);
	dummyBytes[6] = 0x84; // Real48 exponent 132 for 0.142... approx
	// In carParams.js, for diff=1: par1_60 = 4 + Number(T >= 3) + Number(T >= 11) + Number(T >= 16) + Number(T >= 20);
	const ref_par1_60 = 4 + Number(T >= 3) + Number(T >= 11) + Number(T >= 16) + Number(T >= 20);
	
	const accelScale = ref_par1_60 / stats.finalAccelTime;
	
	a1_kph *= accelScale;
	a2_kph *= accelScale;
	a3_kph *= accelScale;

	// Convert accelerations to world units (m/s²)
	const a1_world = KPH_TO_WORLD * a1_kph;
	const a2_world = KPH_TO_WORLD * a2_kph;
	const a3_world = KPH_TO_WORLD * a3_kph;

	// Speed thresholds in world units
	const v1_world = kphToWorldSpeed(20);
	const v2_world = kphToWorldSpeed(40);

	const accelAtWorldSpeed = (worldSpeed) => {
		if (worldSpeed <= 0) return a1_world;
		if (worldSpeed >= maxSpeedWorld) return 0;

		if (worldSpeed < v1_world) {
			// Phase 1: constant acceleration
			return a1_world;
		} else if (worldSpeed < v2_world) {
			// Phase 2: higher constant acceleration
			return a2_world;
		} else {
			// Phase 3: constant acceleration until top speed
			// Stop just before top speed to avoid overshoot
			const remaining = maxSpeedWorld - worldSpeed;
			if (remaining < 0.5) {
				return a3_world * (remaining / 0.5);
			}
			return a3_world;
		}
	};

	return {
		T,
		topKph,
		maxSpeedWorld,
		accelAtWorldSpeed
	};
};

export const createCar = (scene, x, y, team = 0, isPlayer = false) => {
	const car = scene.add.container(x+55, y+53);
	car.name = `car${team}`;

	const hudScene = scene.scene.get("hud");

	const sides = [
		"topLeft",
		"topRight",
		"bottomLeft",
		"bottomRight"
	];
	sides.forEach((side, index) => {
		const frame = team * 4 + index;
		const carPart = scene.add.image(0, 0, "TRABANT.FSF", frame).setOrigin(0.5, 0.5);
		// Add ~1px overlap on the right and bottom seams to avoid gaps
		switch (side) {
			case "topLeft":
				carPart.setCrop(0, 0, 42, 42);
				break;
			case "topRight":
				carPart.setCrop(40, 0, 40, 42);
				break;
			case "bottomLeft":
				carPart.setCrop(0, 40, 42, 40);
				break;
			case "bottomRight":
				carPart.setCrop(40, 40, 40, 40);
				break;
		}
		car.add(carPart);
		car[side] = carPart;
	});
	car.team = team;
	car.damage = [0, 0, 0, 0]; // topLeft, topRight, bottomLeft, bottomRight
	const dmgToFrame = (n) => {
		const clamped = Math.max(0, Math.min(100, n));
		return Math.min(3, Math.floor(clamped / 25));
	};

	car.updateDamage = function () {
		// damage values are percentages (0-100). Map them to 4 frames (0..3)
		this.topLeft.setFrame(this.team * 4 + dmgToFrame(this.damage[0]));
		this.topRight.setFrame(this.team * 4 + dmgToFrame(this.damage[1]));
		this.bottomLeft.setFrame(this.team * 4 + dmgToFrame(this.damage[2]));
		this.bottomRight.setFrame(this.team * 4 + dmgToFrame(this.damage[3]));
		if (hudScene && isPlayer) {
			hudScene.events.emit("carDamage", { damageState: this.damage });
		}
	};
	car.updateDamage();

	car.setRotation(Phaser.Math.DegToRad(-90)).setDepth(10);

	// Controls & physics params
	car.width = 32;
	car.height = 72;

	// linearDamping: 0 so we can manually control top speed with dynamic drag
	assignB2BodyBox(car, {
		type: DYNAMIC,
		fixedRotation: false,
		linearDamping: 0,
		angularDamping: 3.0
	});

	const cursors = scene.input.keyboard.createCursorKeys();
	const keys = scene.input.keyboard.addKeys({
		W: Phaser.Input.Keyboard.KeyCodes.W,
		A: Phaser.Input.Keyboard.KeyCodes.A,
		S: Phaser.Input.Keyboard.KeyCodes.S,
		D: Phaser.Input.Keyboard.KeyCodes.D,
		SPACE: Phaser.Input.Keyboard.KeyCodes.SPACE
	});

	// Load variables from registry with defaults
	const difficulty = scene.registry.get("difficulty") ?? 1;
	const transmission = scene.registry.get("transmissionVal") ?? 0; // 0-21; 0 means fast accel and lowest top speed and vice versa
	const brakesVal = scene.registry.get("brakesVal") ?? 0; // 0-21; 0 means strong brakes with short stopping distance and vice versa
	const tiresVal = scene.registry.get("tiresVal") ?? 0; // 0-2; tires only seem to affect handbrake turns - 2 has best grip, spins out the least

	// All cars use the same PAR file based on difficulty (Easy→PAR1, Medium→PAR3, Hard→PAR5).
	// Car type modifiers (hardcoded in the original EXE) differentiate opponent stats.
	// Player is car type 4 (all modifiers zero). Opponent types map from team index.
	const parKey = getParKeyForDifficulty(difficulty);
	const carType = isPlayer ? 4 : team;
	const parData = scene.cache.binary.get(parKey);
	const stats = getTransmissionStats(parData, difficulty, transmission, carType);

	const transmissionProfile = buildTransmissionProfile(stats, transmission);
	const maxSpeedKph = transmissionProfile.topKph;
	const maxSpeedWorld = transmissionProfile.maxSpeedWorld;

	const brakeDecelMs2 = (10 + (brakesVal / 21) * 15) * 2.0;
	const maxLateralAccel = 25 * 2.0;

	// Vehicle Control Update loop
	car.updateRef = (time, delta) => {
		if (!car.body || !b2Body_IsValid(car.body.bodyId)) return;
		const bodyId = car.body.bodyId;
		const dt = Math.min(delta / 1000, 0.1);
		if (dt === 0) return;

		const velocity = b2Body_GetLinearVelocity(bodyId);
		const rot = b2Body_GetRotation(bodyId);

		const forward = { x: -rot.s, y: rot.c };
		const right = { x: rot.c, y: rot.s };

		const mass = b2Body_GetMass(bodyId);

		const forwardVelocityMag = velocity.x * forward.x + velocity.y * forward.y;
		const lateralVelocityMag = velocity.x * right.x + velocity.y * right.y;

		// Input evaluation
		let isAccelerating = cursors.up.isDown || keys.W.isDown;
		const isBraking = cursors.down.isDown || keys.S.isDown;
		const steerInput = (cursors.left.isDown || keys.A.isDown ? 1 : 0) + (cursors.right.isDown || keys.D.isDown ? -1 : 0);
		const isHandbraking = cursors.space.isDown || keys.SPACE.isDown;

		if (isHandbraking) {
			isAccelerating = false; // Completely kill gas/throttle
		}
		
		const currentSpeedWorld = Math.sqrt(velocity.x ** 2 + velocity.y ** 2);
		
		const carWorldX = car.x;
		const carWorldY = car.y;
		let isOffroad = false;
		if (window.SYNQuery && scene.tilemap) {
			isOffroad = window.SYNQuery.isOffroad("POZ.SYN", scene.tilemap, carWorldX, carWorldY);
		}

		// Lateral Friction (Tire Grip & Handbrake drifting)
		let currentMaxLateralAccel = maxLateralAccel;
		if (isHandbraking) {
			// Handbrake drift logic - scales with tiresVal to affect grip and spin outs
			currentMaxLateralAccel = HANDBRAKE_LATERAL_ACCEL_BASE + (HANDBRAKE_LATERAL_ACCEL_TIRE_MULT * tiresVal);
		}
		const maxImpulse = mass * currentMaxLateralAccel * dt;
		let lateralImpulseMag = -mass * lateralVelocityMag;
		lateralImpulseMag = Math.max(-maxImpulse, Math.min(maxImpulse, lateralImpulseMag)); // Clamp exactly to grip limit

		const lateralImpulse = new b2Vec2(right.x * lateralImpulseMag, right.y * lateralImpulseMag);
		b2Body_ApplyLinearImpulseToCenter(bodyId, lateralImpulse, true);

		// Engine Force (Forward/Reverse/Brake)
		const vWorld = Math.abs(forwardVelocityMag);
		let throttleAccel = transmissionProfile.accelAtWorldSpeed(vWorld);
		
		if (isOffroad) {
			throttleAccel *= 0.3; // Much slower acceleration
		}
		const driveForceMag = mass * throttleAccel;

		let forceMag = 0;
		const brakeForceMag = mass * brakeDecelMs2;

		if (isHandbraking) {
			if (vWorld > 0.1) {
				// Original game: handbrake has NO direct forward brake force; car slows via lateral drift friction.
				// We apply a fraction of normal brake decel to approximate that friction-based slowdown.
				const handbrakeDecel = brakeDecelMs2 * HANDBRAKE_DECEL_FRACTION;
				const combinedDecel = isBraking ? Math.max(handbrakeDecel, brakeDecelMs2) : handbrakeDecel;
				forceMag = -mass * combinedDecel * Math.sign(forwardVelocityMag);
				// Prevent force from pushing the car in the opposite direction (overshoot)
				if (Math.abs(forceMag * dt / mass) > vWorld) {
					forceMag = -mass * forwardVelocityMag / dt;
				}
			} else {
				// Snap completely to prevent jitter or turning in place
				forceMag = -mass * forwardVelocityMag / dt;
			}
		} else if (isAccelerating) {
			if (forwardVelocityMag < -1) {
				forceMag = brakeForceMag;
			} else {
				// Reduce acceleration when turning. Scale by steer input magnitude and current turning factor
				// turningFactor is computed below; replicate minimal form here (clamped by speed)
				const steerMagnitude = Math.min(Math.abs(steerInput), 1);
				// turningFactor previously is Math.min(Math.abs(forwardVelocityMag) / 2, 1)
				const localTurningFactor = Math.min(Math.abs(forwardVelocityMag) / 2, 1);
				const damp = 1 - Math.min(1, TURN_ACCEL_DAMP * steerMagnitude * localTurningFactor);
				forceMag = driveForceMag * damp;
			}
		} else if (isBraking) {
			if (forwardVelocityMag > 1) {
				forceMag = -brakeForceMag;
			} else {
				
				const maxReverseSpeed = kphToWorldSpeed(MAX_REVERSE_KPH);
				let reverseForce = -mass * REVERSE_ACCEL;

				if (vWorld > maxReverseSpeed - 0.5) {
					const drop = Math.max(0, (maxReverseSpeed - vWorld) / 0.5);
					reverseForce *= drop;
				}
				if (vWorld >= maxReverseSpeed) {
					reverseForce = 0;
				}
				forceMag = reverseForce;
			}
		} else {
			// coast / engine braking
			if (Math.abs(forwardVelocityMag) > 0.5) {
				forceMag = -mass * Math.sign(forwardVelocityMag);
			}
		}

		// Optional overspeed pullback if collision/downhill pushes past top speed while throttling
		const overspeed = Math.max(0, vWorld - transmissionProfile.maxSpeedWorld);
		if (overspeed > 0) {
			forceMag -= mass * Math.min(overspeed * 8.0, 20.0) * Math.sign(forwardVelocityMag || 1);
		}

		const forwardForce = new b2Vec2(forward.x * forceMag, forward.y * forceMag);
		b2Body_ApplyForceToCenter(bodyId, forwardForce, true);

		// Steering & Angular Torque
		const currentAngularVel = b2Body_GetAngularVelocity(bodyId);

		// Use total speed during handbrake so the spin doesn't halt abruptly when passing 90 degrees
		const velocityMagForSteering = isHandbraking ? currentSpeedWorld : Math.abs(forwardVelocityMag);
		const turningFactor = Math.min(velocityMagForSteering / 2, 1); // Limits static turning

		const baseSteerSpeed = 2.1; // rad/s - seems to match pretty wall with transmissionVal 0
		// Original game: spin-out scales inversely with tire quality (car[0x13] parameter)
		const handbrakeSteerMult = HANDBRAKE_STEER_MULT_BASE - (HANDBRAKE_STEER_TIRE_REDUCTION * tiresVal);
		const steerSpeed = isHandbraking ? baseSteerSpeed * handbrakeSteerMult : baseSteerSpeed;

		// Invert steering visually when moving backwards, but not while predominantly sliding sideways
		let directionSign = 1;
		if (forwardVelocityMag < -0.1 && Math.abs(forwardVelocityMag) > Math.abs(lateralVelocityMag)) {
			directionSign = -1;
		}

		// Prevent turning in place completely if stopped
		let desiredAngularVel = 0;
		if (currentSpeedWorld > 0.5) {
			desiredAngularVel = steerInput * steerSpeed * turningFactor * directionSign;
		}

		// Blend safely to the desired angle over time to prevent unnatural snapping
		const angularVelDiff = desiredAngularVel - currentAngularVel;
		let newAngularVel = currentAngularVel + angularVelDiff * 10 * dt;
		
		if (isOffroad && vWorld > 0.5) {
			// Apply a sine wave based on time to make it wiggle quickly and smoothly
			const wiggleForce = Math.sin(time / 20) * 0.8;
			newAngularVel += wiggleForce;
			
			// Also cap speed to simulate heavy friction/drag
			if (currentSpeedWorld > transmissionProfile.maxSpeedWorld * 0.2) {
				const drag = new b2Vec2(-velocity.x * mass * 2, -velocity.y * mass * 2);
				b2Body_ApplyForceToCenter(bodyId, drag, true);
			}
		}

		b2Body_SetAngularVelocity(bodyId, newAngularVel);

		// Damage calculation based on sudden velocity changes (impacts)
		const lastVel = car.lastVelocity || { x: velocity.x, y: velocity.y };
		const dvx = velocity.x - lastVel.x;
		const dvy = velocity.y - lastVel.y;
		const impactMag = Math.sqrt(dvx * dvx + dvy * dvy);

		// Threshold for taking damage
		if (impactMag > 2) {
			// The change in velocity is away from the impact point, so the hit directed -dv
			const hitDirX = -dvx;
			const hitDirY = -dvy;

			// Localize the hit direction using the forward and right vectors
			const localHitX = hitDirX * right.x + hitDirY * right.y;
			const localHitY = hitDirX * forward.x + hitDirY * forward.y;

			// Determine quadrant
			let quadIndex = 0;
			if (localHitX < 0 && localHitY > 0) quadIndex = 0; // topLeft
			else if (localHitX >= 0 && localHitY > 0) quadIndex = 1; // topRight
			else if (localHitX < 0 && localHitY <= 0) quadIndex = 2; // bottomLeft
			else if (localHitX >= 0 && localHitY <= 0) quadIndex = 3; // bottomRight

			// Apply damage based on impact magnitude
			car.damage[quadIndex] += impactMag * 2; // Adjust multiplier as needed
			if (car.damage[quadIndex] > 100) car.damage[quadIndex] = 100;
			car.updateDamage();
		}

		if (((!isAccelerating && !isBraking && steerInput === 0) || isHandbraking) && currentSpeedWorld < MIN_STOP_VELOCITY) {
			b2Body_SetLinearVelocity(bodyId, new b2Vec2(0, 0));
			b2Body_SetAngularVelocity(bodyId, 0);
		}

		if (hudScene && isPlayer) {
			const kph = worldSpeedToKph(currentSpeedWorld);
			hudScene.events.emit("playerCarUpdate", { speedKPH: Math.round(kph) });
		}

		car.lastVelocity = { x: velocity.x, y: velocity.y };
	};

	scene.events.on("update", car.updateRef);
	car.on("destroy", () => {
		scene.events.off("update", car.updateRef);
	});

	if (isPlayer) {
		const dynamic = scene.registry.get("dynamicScreenEnabled");
		const lerpX = dynamic ? 0.1 : 1;
		const lerpY = dynamic ? 0.1 : 1;
		scene.cameras.main.startFollow(car, false, lerpX, lerpY);
	}
	return car;
}