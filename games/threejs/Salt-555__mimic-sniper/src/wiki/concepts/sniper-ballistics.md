---
title: Sniper Ballistics
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [mechanic, physics, collision]
sources: []
---

# Sniper Ballistics

## Overview

Sniper shooting uses **instant raycasting** from camera center for hit detection. For MVP simplicity, bullets travel in straight lines — no bullet drop or wind drift initially (those are quality-of-life additions later). The Sniper has limited magazine ammo with a reload mechanic.

For a sniper game where the player is stationary at known distances, instant hitscan is actually more satisfying than simulated ballistics. Real bullet drop adds frustration without adding skill expression when you can't adjust elevation on the scope.

## Architecture

```
Shooting System:
├── Raycast from camera center (screen 0,0)
├── Hit detection against scene objects
├── Hit/miss feedback (visual + audio)
├── Ammo management (magazine-based)
└── Reload mechanic with cooldown
```

## Implementation

### Hitscan Shooting

```js
class SniperBallistics {
    constructor(camera, scene) {
        this.camera = camera;
        this.scene = scene;

        // Raycaster reused every frame (no allocation)
        this.raycaster = new THREE.Raycaster();
        this.center = new THREE.Vector2(0, 0); // screen center

        // Ammo system
        this.magazineSize = 5;
        this.ammoInMag = 5;
        this.reserveAmmo = 10; // total spare magazines worth
        this.isReloading = false;
        this.reloadTime = 2.0; // seconds for full reload
        this.reloadProgress = 0;

        // Fire rate
        this.fireCooldown = 0;
        this.minFireRate = 0.5; // seconds between shots (prevents spam)

        // Accuracy: slight random spread when scoped (tighter than unscoped)
        this.scopedSpread = 0.001;  // very tight at high zoom
        this.unscopedSpread = 0.02; // much wider without scope

        // Hit targets — objects the Sniper can shoot
        // These are registered by the game: Mimic body, disguised props, poof particles
        this.shootableObjects = [];

        // Callbacks (wired up by game)
        this.onHit = null;      // (hitObject, point, normal) => void
        this.onMiss = null;     // (point) => void
        this.onEmpty = null;    // () => void — click with no ammo
        this.onReloadStart = null;
        this.onReloadComplete = null;
    }

    /** Register an object as shootable */
    registerTarget(object) {
        if (!this.shootableObjects.includes(object)) {
            this.shootableObjects.push(object);
            object.userData.shootable = true;
        }
    }

    /** Unregister a target (e.g., Mimic eliminated) */
    unregisterTarget(object) {
        const idx = this.shootableObjects.indexOf(object);
        if (idx >= 0) {
            this.shootableObjects.splice(idx, 1);
            delete object.userData.shootable;
        }
    }

    /** Fire a shot. Returns hit result or null. */
    fire(isScoped) {
        // Check cooldowns
        if (this.fireCooldown > 0) return null;
        if (this.isReloading) return null;

        // Check ammo
        if (this.ammoInMag <= 0) {
            if (this.reserveAmmo > 0) {
                this.startReload();
            } else {
                if (this.onEmpty) this.onEmpty();
            }
            return null;
        }

        // Consume ammo
        this.ammoInMag--;
        this.fireCooldown = this.minFireRate;

        // Add slight spread to aim point
        const spread = isScoped ? this.scopedSpread : this.unscopedSpread;
        const aimX = (Math.random() - 0.5) * 2 * spread;
        const aimY = (Math.random() - 0.5) * 2 * spread;

        // Raycast from camera through slightly offset center
        this.raycaster.setFromCamera(
            new THREE.Vector2(aimX, aimY),
            this.camera
        );

        // Intersect against shootable objects only
        const hits = this.raycaster.intersectObjects(
            this.shootableObjects,
            true // recursive — check children groups
        );

        if (hits.length > 0) {
            const hit = hits[0];
            // Walk up to find the root shootable object (may have hit a child mesh)
            let target = hit.object;
            while (target.parent && !target.userData.shootable) {
                target = target.parent;
            }

            if (this.onHit) {
                this.onHit(target, hit.point, hit.face.normal);
            }

            return {
                hit: true,
                object: target,
                point: hit.point.clone(),
                normal: hit.face ? hit.face.normal.clone() : new THREE.Vector3(),
                distance: hit.distance,
            };
        } else {
            // Miss — ray goes to max distance
            const missPoint = this.raycaster.ray.at(500, new THREE.Vector3());
            if (this.onMiss) this.onMiss(missPoint);
            return { hit: false, point: missPoint };
        }
    }

    /** Start reload */
    startReload() {
        if (this.isReloading) return;
        if (this.ammoInMag === this.magazineSize) return; // already full
        if (this.reserveAmmo <= 0) return; // no reserve

        this.isReloading = true;
        this.reloadProgress = 0;
        if (this.onReloadStart) this.onReloadStart();
    }

    /** Update reload progress */
    updateReload(dt) {
        if (!this.isReloading) return false;

        this.reloadProgress += dt;

        if (this.reloadProgress >= this.reloadTime) {
            // Complete reload
            const needed = this.magazineSize - this.ammoInMag;
            const available = Math.min(needed, this.reserveAmmo);
            this.ammoInMag += available;
            this.reserveAmmo -= available;
            this.isReloading = false;
            this.reloadProgress = 0;
            if (this.onReloadComplete) this.onReloadComplete();
            return true;
        }

        return false; // still reloading
    }

    /** Update fire cooldown */
    updateCooldown(dt) {
        if (this.fireCooldown > 0) {
            this.fireCooldown = Math.max(0, this.fireCooldown - dt);
        }
    }

    /** Check if can fire right now */
    canFire() {
        return this.ammoInMag > 0 && !this.isReloading && this.fireCooldown <= 0;
    }

    /** Get ammo state for UI */
    getAmmoState() {
        return {
            inMag: this.ammoInMag,
            reserve: this.reserveAmmo,
            reloading: this.isReloading,
            reloadProgress: this.isReloading
                ? this.reloadProgress / this.reloadTime
                : 0,
            canFire: this.canFire(),
        };
    }

    /** Main update */
    update(dt) {
        this.updateCooldown(dt);
        this.updateReload(dt);
    }
}
```

### Hit Effect (Impact VFX)

Small burst of particles at the hit point to give visual feedback:

```js
class HitEffect {
    constructor(scene) {
        this.scene = scene;
        this.activeEffects = [];

        // Shared geometry for impact sparks
        const count = 12;
        this.geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(count * 3);
        const velocities = new Float32Array(count * 3);

        for (let i = 0; i < count; i++) {
            const theta = Math.random() * Math.PI * 2;
            const phi = Math.acos(2 * Math.random() - 1);
            const speed = 2 + Math.random() * 3;
            velocities[i * 3] = Math.sin(phi) * Math.cos(theta) * speed;
            velocities[i * 3 + 1] = Math.sin(phi) * Math.sin(theta) * speed;
            velocities[i * 3 + 2] = Math.cos(phi) * Math.speed;
        }

        this.geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        this.geometry.userData.velocities = velocities;

        this.material = new THREE.PointsMaterial({
            color: 0xff6644, // warm orange sparks
            size: 0.08,
            transparent: true,
            opacity: 1,
            depthWrite: false,
        });
    }

    play(point, normal) {
        const points = new THREE.Points(this.geometry.clone(), this.material);
        points.position.copy(point);

        // Orient sparks along hit surface normal
        const vel = this.geometry.userData.velocities;
        const cloneVel = new Float32Array(vel);
        for (let i = 0; i < cloneVel.length / 3; i++) {
            const v = new THREE.Vector3(cloneVel[i*3], cloneVel[i*3+1], cloneVel[i*3+2]);
            // Bias sparks to spray along the surface, not into it
            if (v.dot(normal) < 0) {
                v.reflect(normal);
            }
            vel[i*3] = v.x;
            vel[i*3+1] = v.y;
            vel[i*3+2] = v.z;
        }
        points.geometry.userData.velocities = cloneVel;

        // Reset positions
        const posAttr = points.geometry.getAttribute('position');
        for (let i = 0; i < posAttr.count * 3; i++) posAttr.array[i] = 0;
        posAttr.needsUpdate = true;

        points.userData.born = performance.now() / 1000;
        this.scene.add(points);
        this.activeEffects.push(points);
    }

    update() {
        const now = performance.now() / 1000;

        for (let i = this.activeEffects.length - 1; i >= 0; i--) {
            const p = this.activeEffects[i];
            const age = now - p.userData.born;
            const posAttr = p.geometry.getAttribute('position');
            const vel = p.geometry.userData.velocities;

            for (let j = 0; j < posAttr.count; j++) {
                posAttr.array[j * 3] += vel[j * 3] * 0.016;
                posAttr.array[j * 3 + 1] += vel[j * 3 + 1] * 0.016 - 5 * 0.016 * 0.016; // gravity
                posAttr.array[j * 3 + 2] += vel[j * 3 + 2] * 0.016;
            }
            posAttr.needsUpdate = true;

            p.material.opacity = Math.max(0, 1 - age / 0.4);

            if (age > 0.5) {
                this.scene.remove(p);
                p.geometry.dispose();
                this.activeEffects.splice(i, 1);
            }
        }
    }
}
```

### Wiring to Input

```js
const ballistics = new SniperBallistics(camera, scene);
const hitEffect = new HitEffect(scene);

// Left-click to fire
window.addEventListener('mousedown', (e) => {
    if (e.button === 0 && sniperCamera.controls.isLocked) { // left click
        const result = ballistics.fire(sniperCamera.isScoped);

        if (result && result.hit) {
            // Play hit VFX
            hitEffect.play(result.point, result.normal);

            // Trigger recoil on camera
            sniperCamera.addRecoil(0.04, 0.015);

            // Check if Mimic was hit
            handleMimicHit(result.object);
        }
    }
});

// R to reload
window.addEventListener('keydown', (e) => {
    if (e.key.toLowerCase() === 'r') {
        ballistics.startReload();
    }
});

function handleMimicHit(hitObject) {
    // Walk up to find if this is the Mimic or a disguised prop
    let target = hitObject;
    while (target.parent && target !== scene) {
        if (target === mimic.body || target === transformer.currentDisguise?.mesh) {
            // HIT THE MIMIC!
            onMimicEliminated();
            return;
        }
        target = target.parent;
    }
}
```

### Bullet Tracer (Optional Visual)

A thin line from camera to hit point that fades quickly:

```js
function showTracer(start, end) {
    const points = [start.clone(), end.clone()];
    const geo = new THREE.BufferGeometry().setFromPoints(points);
    const mat = new THREE.LineBasicMaterial({
        color: 0xffffcc,
        transparent: true,
        opacity: 0.6,
    });
    const line = new THREE.Line(geo, mat);
    scene.add(line);

    // Fade and remove after brief flash
    const startTime = performance.now() / 1000;
    function fadeTracer() {
        const age = performance.now() / 1000 - startTime;
        mat.opacity = Math.max(0, 0.6 - age * 3);
        if (mat.opacity <= 0) {
            scene.remove(line);
            geo.dispose();
            mat.dispose();
        } else {
            requestAnimationFrame(fadeTracer);
        }
    }
    fadeTracer();
}
```

## Ammo Tuning

| Parameter | Default | Rationale |
|---|---|---|
| `magazineSize` | 5 | Forces thoughtful shots, not spray |
| `reserveAmmo` | 10 | 2 extra magazines — running out is a loss condition for Mimic win |
| `reloadTime` | 2.0s | Long enough to be tense, short enough to not be frustrating |
| `minFireRate` | 0.5s | Prevents instant double-tap spam |
| `scopedSpread` | 0.001 | Nearly pixel-perfect when scoped and holding breath |
| `unscopedSpread` | 0.02 | Very inaccurate without scope — encourages scoping in |

## Design Notes

### Why Hitscan Over Simulated Bullets?

For this game specifically:
- Sniper is **stationary** at a fixed vantage point
- Distances are known and consistent within a level
- Bullet drop would require the Sniper to lead targets and adjust for distance — adds complexity without adding fun when you can't move to reposition
- Hitscan feels snappy and responsive, which matters more for a browser game

If we add bullet drop later, it's a simple modification: instead of raycasting, spawn a projectile mesh with velocity + gravity and check collisions per frame. But for MVP, hitscan is the right call.

### Wrong Target Penalty

When the Sniper shoots a non-Mimic prop:
- The prop could briefly "shake" or show impact marks (cheap visual feedback)
- No penalty beyond wasted ammo — keeping it simple
- In future iterations: wrong shots could alert the Mimic to the Sniper's attention direction

## Related

- [[sniper-camera]] — Camera system that provides aim ray and recoil integration
- [[sniper-ui]] — Ammo counter display, reload indicator, hit feedback UI
- [[game-state-machine]] — Round resolution on Mimic elimination
