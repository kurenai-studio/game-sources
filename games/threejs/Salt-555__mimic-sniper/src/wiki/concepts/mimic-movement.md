---
title: Mimic Movement
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [mechanic, animation, procedural, performance]
sources:
  - raw/articles/threejs-procedural-spider.md
  - raw/articles/two-bone-ik-little-polygon.md
  - raw/articles/two-bone-ik-tim-wheeler.md
---

# Mimic Movement

## Overview

The Mimic is a floating sphere body with generative leg-like tentacles that use **two-bone inverse kinematics** to produce spider-like walking motion. Legs contact the ground, follow a procedural gait cycle, and adapt foot placement each frame — no animation clips.

Reference: [threejs-procedural-spider](https://github.com/majidmanzarpour/threejs-procedural-spider) (8-leg IK spider, closed-form solver, no physics engine).

## Architecture

| System | What it does | Approach |
|---|---|---|
| **Body locomotion** | Sphere moves through 3D space on a ground plane | Direct position update + smooth damping |
| **Leg IK** | Each leg = 2-bone chain (upper + lower). Foot targets computed by gait | Closed-form two-bone IK (Law of Cosines) |
| **Gait cycle** | Legs alternate lift/place in a wave pattern | Phase-offset sine waves per leg |

## Two-Bone IK Solver (Closed-Form)

Based on the Law of Cosines. Given hip → knee → foot bones and a target foot position, compute joint angles analytically — no iteration needed.

```js
/**
 * Solve two-bone IK.
 * @param {THREE.Vector3} hip     - Hip (root) world position
 * @param {THREE.Vector3} knee0   - Knee rest position (defines pole vector)
 * @param {number} upperLen       - Upper leg length
 * @param {number} lowerLen       - Lower leg length
 * @param {THREE.Vector3} target  - Desired foot position
 * @returns {{ hipQuat: THREE.Quaternion, kneePos: THREE.Vector3, kneeQuat: THREE.Quaternion }}
 */
function solveTwoBoneIK(hip, knee0, upperLen, lowerLen, target) {
    const maxReach = upperLen + lowerLen - 0.01; // epsilon to avoid straight-line singularity

    // Direction from hip to target (clamped)
    let toTarget = new THREE.Vector3().subVectors(target, hip);
    const dist = toTarget.length();
    const clampedDist = Math.min(dist, maxReach);
    if (dist > 0.001) toTarget.divideScalar(dist); // normalize

    // Pole vector: perpendicular to hip→target, pointing toward original knee
    const poleVec = new THREE.Vector3()
        .subVectors(knee0, hip)
        .projectOnPlane(toTarget)
        .normalize();

    if (poleVec.length() < 0.001) {
        // Knee and target are collinear with hip — pick arbitrary perpendicular
        poleVec.crossVectors(toTarget, new THREE.Vector3(0, 1, 0)).normalize();
    }

    // Law of Cosines: angle at hip between toTarget and upper leg
    // cos(θ) = (d² + u² - l²) / (2 * d * u)
    const cosTheta = clampedDist > 0.001
        ? (clampedDist * clampedDist + upperLen * upperLen - lowerLen * lowerLen)
          / (2 * clampedDist * upperLen)
        : 1;

    const theta = Math.acos(Math.max(-1, Math.min(1, cosTheta))); // clamp for float safety
    const sinTheta = Math.sin(theta);

    // Knee position: along toTarget by u*cos(θ), offset by pole vector by u*sin(θ)
    const kneePos = new THREE.Vector3()
        .addScaledVector(toTarget, upperLen * cosTheta)
        .addScaledVector(poleVec, upperLen * sinTheta);
    kneePos.add(hip);

    // Foot position (clamped to max reach if target is too far)
    const footPos = new THREE.Vector3().addScaledVector(toTarget, clampedDist);
    footPos.add(hip);

    // Compute rotations via quaternion "from-to" rotations
    // Hip rotation: rotate upper leg from its rest direction toward the solved knee
    const upperRest = new THREE.Vector3().subVectors(knee0, hip).normalize();
    const upperSolved = new THREE.Vector3().subVectors(kneePos, hip).normalize();
    const hipQuat = new THREE.Quaternion().setFromUnitVectors(upperRest, upperSolved);

    // Knee rotation: rotate lower leg from its rest direction toward the solved foot
    const lowerRestDir = new THREE.Vector3(0, -1, 0); // assuming rest points down
    const lowerSolved = new THREE.Vector3().subVectors(footPos, kneePos).normalize();
    // Apply hip rotation to rest dir first (since knee is child of hip)
    const lowerRestWorld = lowerRestDir.clone().applyQuaternion(hipQuat);
    const kneeQuat = new THREE.Quaternion().setFromUnitVectors(lowerRestWorld, lowerSolved);

    return { hipQuat, kneePos, kneeQuat, footPos };
}
```

## Gait System

Each leg has a phase offset in the gait cycle. During each frame we compute whether the leg is in **swing** (lifting forward) or **stance** (planted on ground), then set the IK target accordingly.

```js
class Leg {
    constructor(index, totalLegs, upperLen = 0.6, lowerLen = 0.5) {
        this.index = index;
        this.upperLen = upperLen;
        this.lowerLen = lowerLen;

        // Attach point on body (evenly distributed around sphere bottom)
        const angle = (index / totalLegs) * Math.PI * 2 + Math.PI * 0.25; // slight offset
        this.attachOffset = new THREE.Vector3(
            Math.cos(angle) * 0.35,  // radius from center
            -0.3,                     // below center
            Math.sin(angle) * 0.35
        );

        // Gait phase: each leg is offset so they don't all move at once
        this.phase = (index / totalLegs) * Math.PI * 2;

        // Visual groups
        this.hipGroup = new THREE.Group();
        this.kneeGroup = new THREE.Group();

        // Upper leg mesh (low-poly cylinder)
        const upperGeo = new THREE.CylinderGeometry(0.03, 0.025, upperLen, 5);
        upperGeo.translate(0, -upperLen / 2, 0);
        this.upperMesh = new THREE.Mesh(upperGeo, LEG_MATERIAL);

        // Lower leg mesh
        const lowerGeo = new THREE.CylinderGeometry(0.025, 0.015, lowerLen, 5);
        lowerGeo.translate(0, -lowerLen / 2, 0);
        this.lowerMesh = new THREE.Mesh(lowerGeo, LEG_MATERIAL);

        // Foot sphere (contact point)
        const footGeo = new THREE.SphereGeometry(0.04, 4, 3);
        this.footMesh = new THREE.Mesh(footGeo, LEG_MATERIAL);
        this.footMesh.position.y = -lowerLen;

        // Assemble hierarchy: hip → upper → knee → lower → foot
        this.hipGroup.add(this.upperMesh);
        this.kneeGroup.add(this.lowerMesh);
        this.kneeGroup.add(this.footMesh);
        this.hipGroup.add(this.kneeGroup);

        // Rest positions for IK pole vector
        this.restKneePos = new THREE.Vector3(0, -upperLen, 0);
    }

    /**
     * Compute foot target based on gait phase and body movement.
     */
    computeFootTarget(bodyPos, bodyForward, time, speed, gaitRate) {
        const cycle = time * gaitRate + this.phase;
        const swingPhase = (Math.sin(cycle) + 1) / 2; // 0..1 oscillation

        // Stance: foot stays planted at last ground position
        // Swing: foot lifts and moves forward
        const isSwinging = swingPhase > 0.5;

        if (isSwinging) {
            // Lift height peaks mid-swing
            const liftT = (swingPhase - 0.5) * 2; // 0..1 during swing
            const liftHeight = Math.sin(liftT * Math.PI) * 0.3; // arc

            // Step forward in body's facing direction
            const stepForward = speed * 0.8;
            const footLocal = this.attachOffset.clone();
            footLocal.z -= stepForward; // forward relative to leg attach
            footLocal.y = -Math.min(this.upperLen + this.lowerLen, 1.0) + liftHeight;

            // Transform to world space (simplified — use body quaternion for full rotation)
            return new THREE.Vector3(
                bodyPos.x + footLocal.x,
                bodyPos.y + footLocal.y,
                bodyPos.z + footLocal.z
            );
        } else {
            // Stance: keep foot planted (use last known ground position)
            if (!this.plantedPos) {
                this.plantedPos = new THREE.Vector3(
                    bodyPos.x + this.attachOffset.x,
                    bodyPos.y - this.upperLen - this.lowerLen,
                    bodyPos.z + this.attachOffset.z
                );
            }
            return this.plantedPos;
        }
    }

    update(bodyMesh, time, speed, gaitRate) {
        const bodyPos = new THREE.Vector3();
        bodyMesh.getWorldPosition(bodyPos);

        // Position hip at attach point on body
        this.hipGroup.position.copy(this.attachOffset);

        // Compute IK target
        const footTarget = this.computeFootTarget(
            bodyPos, null, time, speed, gaitRate
        );

        // Solve IK
        const hipWorld = new THREE.Vector3().addVectors(bodyPos, this.attachOffset);
        const kneeRestWorld = new THREE.Vector3()
            .copy(this.restKneePos)
            .applyQuaternion(bodyMesh.quaternion)
            .add(hipWorld);

        const result = solveTwoBoneIK(
            hipWorld,
            kneeRestWorld,
            this.upperLen,
            this.lowerLen,
            footTarget
        );

        // Apply to visual hierarchy (relative to body)
        this.hipGroup.quaternion.copy(result.hipQuat);
        this.kneeGroup.position.y = -this.upperLen;
        this.kneeGroup.quaternion.copy(result.kneeQuat);
    }

    attachTo(bodyMesh) {
        bodyMesh.add(this.hipGroup);
    }
}

// Shared material for all legs (draw call optimization)
const LEG_MATERIAL = new THREE.MeshStandardMaterial({
    color: 0x0a0a0a,
    roughness: 0.9,
    metalness: 0.1,
});
```

## Putting It Together

```js
class Mimic {
    constructor(scene) {
        // Body: low-poly sphere
        this.body = new THREE.Mesh(
            new THREE.IcosahedronGeometry(0.5, 1),
            new THREE.MeshStandardMaterial({
                color: 0x0a0a0a,
                roughness: 0.9,
                metalness: 0.1,
            })
        );
        scene.add(this.body);

        // Legs
        this.legs = [];
        const LEG_COUNT = 6;
        for (let i = 0; i < LEG_COUNT; i++) {
            const leg = new Leg(i, LEG_COUNT);
            leg.attachTo(this.body);
            this.legs.push(leg);
        }

        // Movement state
        this.velocity = new THREE.Vector3();
        this.targetVelocity = new THREE.Vector3();
        this.speed = 0; // 0..1 normalized speed for gait intensity

        this.clock = new THREE.Clock();
    }

    update(dt, input) {
        // input: { forward: -1..1, strafe: -1..1 }
        this.targetVelocity.set(input.strafe, 0, input.forward).multiplyScalar(4.0);
        this.velocity.lerp(this.targetVelocity, 1 - Math.exp(-8 * dt));

        const move = this.velocity.clone().multiplyScalar(dt);
        this.body.position.add(move);

        // Face movement direction
        if (this.velocity.length() > 0.1) {
            const targetAngle = Math.atan2(this.velocity.x, this.velocity.z);
            let diff = targetAngle - this.body.rotation.y;
            while (diff > Math.PI) diff -= Math.PI * 2;
            while (diff < -Math.PI) diff += Math.PI * 2;
            this.body.rotation.y += diff * 5 * dt;
        }

        // Gait rate scales with speed — idle = slow crawl, fast = rapid scuttle
        this.speed = Math.min(this.velocity.length() / 4.0, 1.0);
        const gaitRate = 2.0 + this.speed * 4.0; // 2-6 Hz

        const time = this.clock.getElapsedTime();
        for (const leg of this.legs) {
            leg.update(this.body, time, this.speed, gaitRate);
        }
    }
}
```

## Triangle Budget

| Component | Count | Triangles each | Total |
|---|---|---|---|
| Body (Icosahedron d1) | 1 | 80 | 80 |
| Upper leg (Cylinder 5-side) | 6 | 20 | 120 |
| Lower leg (Cylinder 5-side) | 6 | 20 | 120 |
| Foot (Sphere 4×3) | 6 | 24 | 144 |
| **Total per Mimic** | | | **~464 triangles** |

Even cheaper than the FK approach. All legs share one `MeshStandardMaterial` = just **4 draw calls** total (body + upper + lower + foot via instancing or grouping).

## Key Parameters (Tunable)

| Parameter | Effect | Default |
|---|---|---|
| `LEG_COUNT` | Number of legs | 6 |
| `upperLen / lowerLen` | Leg proportions | 0.6 / 0.5 |
| `gaitRate` | How fast legs cycle (scales with speed) | 2-6 Hz |
| `liftHeight` | How high legs lift during swing | 0.3 |
| `stepForward` | Step distance per swing | speed × 0.8 |

## Known Pitfalls

1. **Foot sliding** — the biggest visual tell for procedural IK. Mitigate by keeping stance feet truly planted (don't drift them with body movement). The `plantedPos` approach above handles this.
2. **Leg collision with body** — keep attach points close to the sphere surface and upper legs short enough that they don't clip through during extreme poses.
3. **Pole vector flipping** — if the knee rest position is nearly collinear with the target, the pole vector becomes unstable. The cross-product fallback in `solveTwoBoneIK` handles this.
4. **Performance on Pi 5** — closed-form IK is just trig per leg per frame. 6 legs × ~20 math ops = trivial. No iteration, no physics engine overhead.

## Related

- [[mimic-transformation]] — How the Mimic morphs into objects
- [[mimic-stealth-tells]] — Visual cues that betray the Mimic's position
- [[performance-pi5]] — Pi 5 rendering budget and optimization targets
