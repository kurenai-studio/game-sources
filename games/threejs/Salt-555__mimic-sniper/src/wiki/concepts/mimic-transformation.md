---
title: Mimic Transformation
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [mechanic, animation, shader, ui]
sources: []
---

# Mimic Transformation

## Overview

The Mimic transforms into nearby objects via **instant asset swap + particle VFX**. No mesh morphing — the Mimic mesh hides, a pre-placed prop mesh shows, and a "poof" cloud effect plays at the transformation point. Simple, performant, visually clear.

Same approach as Garry's Mod Prop Hunt, Wizards N' Skulls, and every successful prop hunt clone.

## Architecture

```
Scene contains:
  - Mimic mesh (visible when untransformed)
  - Prop objects (always in scene, invisible or "inactive")

On transform:
  1. Find nearest eligible prop within range
  2. Hide Mimic mesh (visible = false)
  3. Show prop mesh at Mimic's position
  4. Play particle poof VFX
  5. Link prop movement → Mimic movement
```

## Implementation

### Transformable Object Registry

Each transformable object sits in the scene as a normal mesh, but starts with `visible = false` or is tracked separately:

```js
class TransformableObject {
    constructor(mesh, type) {
        this.mesh = mesh;
        this.type = type; // 'crate', 'barrel', 'rock', etc.
        this.homePosition = mesh.position.clone(); // where it sits in the level
        this.isOccupied = false; // is the Mimic currently disguised as this?

        // Start invisible — they're "ghost" props until the Mimic uses them
        mesh.visible = false;
        mesh.userData.transformable = true;
    }

    /** Activate: show at Mimic's position */
    activateAt(position) {
        this.mesh.position.copy(position);
        this.mesh.visible = true;
        this.isOccupied = true;
    }

    /** Deactivate: hide and return to home position */
    deactivate() {
        this.mesh.visible = false;
        this.mesh.position.copy(this.homePosition);
        this.isOccupied = false;
    }
}

// Registry of all transformable objects in the scene
const transformables = [];

function registerTransformableObject(mesh, type) {
    const obj = new TransformableObject(mesh, type);
    transformables.push(obj);
    return obj;
}
```

### Transformation Logic

```js
class MimicTransformer {
    constructor(mimic, scene) {
        this.mimic = mimic; // the Mimic instance (has .body mesh)
        this.scene = scene;
        this.currentDisguise = null; // currently occupied TransformableObject
        this.transformRange = 3.0;   // max distance to transform into a prop

        // Poof VFX system
        this.poofSystem = new PoofEffect(scene);
    }

    /**
     * Find nearest eligible transformable object within range.
     * Returns the TransformableObject or null.
     */
    findNearestTarget() {
        const mimicPos = this.mimic.body.position;
        let closest = null;
        let closestDist = this.transformRange;

        for (const obj of transformables) {
            if (obj === this.currentDisguise) continue; // can't re-transform to same one
            if (obj.isOccupied) continue; // another Mimic is using it (multiplayer)

            const dist = mimicPos.distanceTo(obj.homePosition);
            if (dist < closestDist) {
                closest = obj;
                closestDist = dist;
            }
        }

        return closest;
    }

    /** Transform INTO a prop */
    transform() {
        const target = this.currentDisguise
            ? null // already disguised — find new one or refuse
            : this.findNearestTarget();

        if (!target) return false;

        // Hide Mimic body + legs
        this.mimic.body.visible = false;
        if (this.mimic.legs) {
            for (const leg of this.mimic.legs) {
                leg.hipGroup.visible = false;
            }
        }

        // Show prop at Mimic's position
        target.activateAt(this.mimic.body.position);
        this.currentDisguise = target;

        // Play poof VFX
        this.poofSystem.play(this.mimic.body.position);

        return true;
    }

    /** Transform BACK to blob form */
    reveal() {
        if (!this.currentDisguise) return false;

        // Hide prop
        this.currentDisguise.deactivate();

        // Show Mimic at the prop's current position
        this.mimic.body.position.copy(this.currentDisguise.mesh.position);
        this.mimic.body.visible = true;
        if (this.mimic.legs) {
            for (const leg of this.mimic.legs) {
                leg.hipGroup.visible = true;
            }
        }

        // Play poof VFX
        this.poofSystem.play(this.currentDisguise.mesh.position);

        this.currentDisguise = null;
        return true;
    }

    /** Update: move the disguised prop with Mimic movement */
    update(dt, input) {
        if (!this.currentDisguise) return;

        // Move the disguise mesh with Mimic's movement logic
        // (reuse the same velocity calculation from Mimic.update)
        const velocity = this.mimic.velocity || new THREE.Vector3();
        const move = velocity.clone().multiplyScalar(dt);
        this.currentDisguise.mesh.position.add(move);

        // Optional: slight rotation to face movement direction
        if (velocity.length() > 0.1) {
            const targetAngle = Math.atan2(velocity.x, velocity.z);
            let diff = targetAngle - this.currentDisguise.mesh.rotation.y;
            while (diff > Math.PI) diff -= Math.PI * 2;
            while (diff < -Math.PI) diff += Math.PI * 2;
            this.currentDisguise.mesh.rotation.y += diff * 3 * dt; // slower turn = more suspicious
        }
    }
}
```

### Poof Particle Effect

Simple expanding ring of particles that fade out over ~0.5s:

```js
class PoofEffect {
    constructor(scene) {
        this.scene = scene;
        this.activeParticles = [];

        // Shared geometry + material for all poofs (draw call optimization)
        const particleCount = 40;
        this.geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);
        const velocities = new Float32Array(particleCount * 3);
        const lifetimes = new Float32Array(particleCount);

        for (let i = 0; i < particleCount; i++) {
            positions[i * 3] = 0;
            positions[i * 3 + 1] = 0;
            positions[i * 3 + 2] = 0;

            // Random spherical velocity
            const theta = Math.random() * Math.PI * 2;
            const phi = Math.acos(2 * Math.random() - 1);
            const speed = 1.5 + Math.random() * 2.0;
            velocities[i * 3] = Math.sin(phi) * Math.cos(theta) * speed;
            velocities[i * 3 + 1] = Math.sin(phi) * Math.sin(theta) * speed;
            velocities[i * 3 + 2] = Math.cos(phi) * speed;

            lifetimes[i] = 0.4 + Math.random() * 0.3; // 0.4-0.7s lifetime
        }

        this.geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        this.geometry.userData.velocities = velocities;
        this.geometry.userData.lifetimes = lifetimes;

        // Dark void-like particles (matching Mimic aesthetic)
        this.material = new THREE.PointsMaterial({
            color: 0x1a1a2e,
            size: 0.15,
            transparent: true,
            opacity: 0.8,
            sizeAttenuation: true,
            depthWrite: false,
        });
    }

    play(position) {
        const points = new THREE.Points(this.geometry.clone(), this.material);
        points.position.copy(position);

        // Clone per-instance data so each poof is independent
        const origVel = this.geometry.userData.velocities;
        const origLife = this.geometry.userData.lifetimes;
        points.geometry.userData.velocities = new Float32Array(origVel);
        points.geometry.userData.lifetimes = new Float32Array(origLife);

        // Reset positions to origin for this instance
        const posAttr = points.geometry.getAttribute('position');
        for (let i = 0; i < posAttr.count * 3; i++) {
            posAttr.array[i] = 0;
        }
        posAttr.needsUpdate = true;

        points.userData.born = performance.now();
        this.scene.add(points);
        this.activeParticles.push(points);
    }

    update() {
        const now = performance.now() / 1000;

        for (let i = this.activeParticles.length - 1; i >= 0; i--) {
            const p = this.activeParticles[i];
            const age = now - p.userData.born;
            const posAttr = p.geometry.getAttribute('position');
            const vel = p.geometry.userData.velocities;
            const life = p.geometry.userData.lifetimes;

            let allDead = true;
            for (let j = 0; j < posAttr.count; j++) {
                if (age < life[j]) {
                    allDead = false;
                    // Update particle position
                    posAttr.array[j * 3] += vel[j * 3] * 0.016;
                    posAttr.array[j * 3 + 1] += vel[j * 3 + 1] * 0.016;
                    posAttr.array[j * 3 + 2] += vel[j * 3 + 2] * 0.016;

                    // Gravity pull down
                    posAttr.array[j * 3 + 1] -= 0.5 * 0.016;
                } else {
                    // Hide dead particles by pushing them far away
                    posAttr.array[j * 3 + 1] = -9999;
                }
            }

            posAttr.needsUpdate = true;

            // Fade out overall opacity
            const maxLife = Math.max(...life);
            p.material.opacity = Math.max(0, 1 - age / maxLife) * 0.8;

            if (allDead || age > maxLife + 0.1) {
                this.scene.remove(p);
                p.geometry.dispose();
                this.activeParticles.splice(i, 1);
            }
        }
    }
}
```

### Input Binding

```js
// Local multiplayer: Mimic player presses 'E' to transform/reveal
const keys = {};
window.addEventListener('keydown', (e) => {
    keys[e.key.toLowerCase()] = true;

    if (e.key.toLowerCase() === 'e') {
        if (transformer.currentDisguise) {
            transformer.reveal(); // pop back to blob form
        } else {
            transformer.transform(); // disguise as nearest prop
        }
    }
});
window.addEventListener('keyup', (e) => {
    keys[e.key.toLowerCase()] = false;
});
```

## Triangle Budget

| Component | Triangles | Notes |
|---|---|---|
| Poof particles | 0 | Points, not triangles |
| Prop meshes | varies | Crate: 12, Barrel: ~60, Rock: ~40 (low-poly) |
| **Overhead** | **+0** | No additional geometry — props already exist in scene |

The poof effect uses `THREE.Points` — zero triangle cost. Props are already loaded in the scene as invisible objects, so transformation is just toggling visibility + moving a mesh.

## Design Considerations

### Transform Range
- **3 units** is a good starting range — Mimic needs to be close but not touching
- Visual feedback: highlight nearby transformable props when Mimic is within range (emissive glow or outline)
- Prevents spam-transforming across the map

### Cooldown
Consider a brief cooldown after transforming (0.5-1s) to prevent rapid flicker between forms that breaks immersion and makes the mechanic trivial.

```js
this.lastTransformTime = 0;
this.transformCooldown = 0.7; // seconds

transform() {
    if (performance.now()/1000 - this.lastTransformTime < this.transformCooldown) return false;
    this.lastTransformTime = performance.now()/1000;
    // ... rest of transform logic
}
```

### Visual Feedback for Sniper
The poof effect itself is a **tell** — the Sniper can see where a transformation happened. This is intentional and creates gameplay tension:
- Poof appears → Sniper knows something transformed there
- But was it transforming INTO a prop or OUT of one?
- The dark particle color matches Mimic's void aesthetic

## Related

- [[mimic-stealth-tells]] — Visual cues that betray the Mimic (poof is one)
- [[object-library]] — Catalog of transformable objects with triangle counts
- [[level-design]] — Placement strategy for transformable props in levels
