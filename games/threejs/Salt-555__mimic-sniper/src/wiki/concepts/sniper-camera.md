---
title: Sniper Camera
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [mechanic, camera, input, ui]
sources: []
---

# Sniper Camera

## Overview

The Sniper uses a stationary first-person camera at a fixed vantage point. Mouse controls aim via `PointerLockControls`. Right-click or mouse wheel toggles scope zoom. The scope view includes breathing sway (camera micro-movement) and an optional wind indicator.

Key constraint: the Sniper is **stationary** — no WASD movement, just mouse look + shoot. This simplifies everything and focuses tension on spotting the Mimic.

## Architecture

```
Sniper Camera System:
├── PointerLockControls (mouse → camera rotation)
├── Scope zoom (FOV animation: 75° → 15°)
├── Breathing sway (sinusoidal micro-offsets on pitch/yaw)
├── Hold breath (shift key reduces sway, depletes meter)
└── CSS scope overlay (crosshair + vignette via HTML/CSS)
```

## Implementation

### Camera Setup with PointerLock

```js
import { PointerLockControls } from 'three/addons/controls/PointerLockControls.js';

class SniperCamera {
    constructor(camera, domElement) {
        this.camera = camera;
        this.domElement = domElement; // canvas element

        // Position at vantage point (set by level design)
        this.vantagePoint = new THREE.Vector3(0, 8, -15); // rooftop example
        this.lookDirection = new THREE.Vector3(0, -0.2, 1); // slightly downward
        camera.position.copy(this.vantagePoint);
        camera.lookAt(this.vantagePoint.clone().add(this.lookDirection));

        // Pointer lock for mouse look
        this.controls = new PointerLockControls(camera, domElement);

        // Click canvas to lock pointer
        domElement.addEventListener('click', () => {
            if (!this.isScoped) {
                this.controls.lock();
            }
        });

        // Default FOV (unscoped)
        this.defaultFOV = 75;
        this.scopedFOV = 12; // tight zoom for sniper scope
        camera.fov = this.defaultFOV;
        camera.updateProjectionMatrix();

        // Zoom state
        this.isScoped = false;
        this.currentFOV = this.defaultFOV;
        this.zoomSpeed = 30; // FOV units per second during transition

        // Breathing sway
        this.breathTime = 0;
        this.swayAmplitude = 0.003; // radians — subtle but noticeable at high zoom
        this.swayFrequency = 1.5;   // breaths per second (~90 BPM)

        // Hold breath
        this.isHoldingBreath = false;
        this.breathMeter = 100;     // percentage
        this.breathDrainRate = 15;  // % per second
        this.breathRecoveryRate = 8; // % per second when not holding
        this.maxHoldTime = this.breathMeter / this.breathDrainRate; // ~6.7s

        // Recoil (from shooting — linked to [[sniper-ballistics]])
        this.recoilPitch = 0;
        this.recoilYaw = 0;
        this.recoilRecovery = 5; // radians per second recovery

        // Bind right-click for scope toggle
        domElement.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            this.toggleScope();
        });

        // Mouse wheel for scope zoom levels
        domElement.addEventListener('wheel', (e) => {
            if (!this.controls.isLocked) return;
            // Scroll up = zoom in, scroll down = zoom out
            if (e.deltaY < 0 && !this.isScoped) this.toggleScope(true);
            if (e.deltaY > 0 && this.isScoped) this.toggleScope(false);
        });

        // Keyboard: shift to hold breath
        this.keys = {};
        window.addEventListener('keydown', (e) => {
            if (e.key === 'Shift') this.keys.Shift = true;
        });
        window.addEventListener('keyup', (e) => {
            if (e.key === 'Shift') this.keys.Shift = false;
        });

        // CSS scope overlay
        this.scopeOverlay = null; // created in createScopeOverlay()
    }

    /** Toggle or set scope state */
    toggleScope(forceState) {
        if (typeof forceState === 'boolean') {
            this.isScoped = forceState;
        } else {
            this.isScoped = !this.isScoped;
        }

        // Show/hide CSS overlay
        if (this.scopeOverlay) {
            this.scopeOverlay.style.display = this.isScoped ? 'block' : 'none';
        }

        // Lock pointer when scoping in
        if (this.isScoped && !this.controls.isLocked) {
            this.controls.lock();
        }
    }

    /** Smooth FOV transition */
    updateZoom(dt) {
        const targetFOV = this.isScoped ? this.scopedFOV : this.defaultFOV;
        const diff = targetFOV - this.currentFOV;

        if (Math.abs(diff) > 0.1) {
            this.currentFOV += Math.sign(diff) * Math.min(Math.abs(diff), this.zoomSpeed * dt);
            this.camera.fov = this.currentFOV;
            this.camera.updateProjectionMatrix();
        } else {
            this.currentFOV = targetFOV;
        }
    }

    /** Breathing sway — sinusoidal micro-movements */
    updateBreathing(dt) {
        this.breathTime += dt;

        // Hold breath logic
        if (this.keys.Shift && this.isScoped && this.breathMeter > 0) {
            this.isHoldingBreath = true;
            this.breathMeter = Math.max(0, this.breathMeter - this.breathDrainRate * dt);
        } else {
            this.isHoldingBreath = false;
            this.breathMeter = Math.min(100, this.breathMeter + this.breathRecoveryRate * dt);
        }

        // Sway amplitude: reduced when holding breath, zero when meter empty
        let effectiveAmplitude = this.swayAmplitude;
        if (this.isHoldingBreath) {
            effectiveAmplitude *= Math.max(0, this.breathMeter / 100);
        }

        // When not scoped, sway is barely noticeable (low zoom)
        if (!this.isScoped) {
            effectiveAmplitude *= 0.1;
        }

        // Dual-frequency breathing: slow vertical + faster horizontal
        const pitchSway = Math.sin(this.breathTime * this.swayFrequency) * effectiveAmplitude;
        const yawSway = Math.cos(this.breathTime * this.swayFrequency * 0.7 + 1.3) * effectiveAmplitude * 0.6;

        // Apply as additional rotation on top of PointerLockControls
        // We rotate the camera slightly around its local axes
        const euler = new THREE.Euler(pitchSway, yawSway, 0, 'YXZ');
        const swayQuat = new THREE.Quaternion().setFromEuler(euler);

        // Combine with existing camera rotation
        const currentQuat = this.camera.quaternion.clone();
        this.camera.quaternion.premultiply(swayQuat);

        return { pitchSway, yawSway, breathMeter: this.breathMeter };
    }

    /** Recoil recovery */
    updateRecoil(dt) {
        // Recover toward zero
        this.recoilPitch *= Math.exp(-this.recoilRecovery * dt);
        this.recoilYaw *= Math.exp(-this.recoilRecovery * dt);

        if (Math.abs(this.recoilPitch) > 0.0001 || Math.abs(this.recoilYaw) > 0.0001) {
            const euler = new THREE.Euler(this.recoilPitch, this.recoilYaw, 0, 'YXZ');
            const recoilQuat = new THREE.Quaternion().setFromEuler(euler);
            const currentQuat = this.camera.quaternion.clone();
            this.camera.quaternion.premultiply(recoilQuat);
        }

        return { pitch: this.recoilPitch, yaw: this.recoilYaw };
    }

    /** Add recoil impulse (called by ballistics on shoot) */
    addRecoil(pitch = 0.04, yaw = 0.015) {
        this.recoilPitch += pitch; // kick up
        this.recoilYaw += (Math.random() - 0.5) * yaw * 2; // random left/right
    }

    /** Main update */
    update(dt) {
        if (!this.controls.isLocked) return null;

        this.updateZoom(dt);
        const breath = this.updateBreathing(dt);
        const recoil = this.updateRecoil(dt);

        return { ...breath, ...recoil };
    }

    /** Get world-space ray from camera center (for shooting) */
    getAimRay() {
        const raycaster = new THREE.Raycaster();
        raycaster.setFromCamera(new THREE.Vector2(0, 0), this.camera); // screen center
        return raycaster;
    }
}
```

### CSS Scope Overlay

Since Chromium kiosk silently skips `<script>` tags in injected HTML, we use **CSS-only** for the scope overlay — no JS needed in the overlay itself:

```css
/* scope-overlay.css */
.sniper-scope {
    position: fixed;
    top: 0; left: 0;
    width: 100vw; height: 100vh;
    pointer-events: none;
    display: none; /* toggled by JS */
    z-index: 100;
}

/* Circular vignette — black everything outside scope circle */
.sniper-scope::before {
    content: '';
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: radial-gradient(
        circle at center,
        transparent 30%,     /* clear scope view */
        rgba(0, 0, 0, 0.4) 32%,
        rgba(0, 0, 0, 0.95) 35%,
        black 100%
    );
}

/* Crosshair — vertical line */
.sniper-scope::after {
    content: '';
    position: absolute;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    width: 2px; height: 60%;
    background: linear-gradient(
        to bottom,
        transparent 15%,
        rgba(127, 179, 168, 0.8) 20%, /* seafoam green — ALLMIND brand */
        rgba(127, 179, 168, 0.9) 50%,
        rgba(127, 179, 168, 0.8) 80%,
        transparent 85%
    );
}

/* Horizontal crosshair line */
.sniper-scope .cross-h {
    position: absolute;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    width: 60%; height: 2px;
    background: linear-gradient(
        to right,
        transparent 15%,
        rgba(127, 179, 168, 0.8) 20%,
        rgba(127, 179, 168, 0.9) 50%,
        rgba(127, 179, 168, 0.8) 80%,
        transparent 85%
    );
}

/* Range marks (hash marks on vertical line) */
.sniper-scope .range-marks {
    position: absolute;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    width: 2px; height: 60%;
}

.sniper-scope .range-mark {
    position: absolute;
    left: -4px;
    width: 10px; height: 1px;
    background: rgba(127, 179, 168, 0.5);
}

/* Breath meter bar (bottom of scope) */
.sniper-scope .breath-bar-bg {
    position: absolute;
    bottom: 30%; left: 50%;
    transform: translateX(-50%);
    width: 120px; height: 4px;
    background: rgba(255, 255, 255, 0.15);
    border-radius: 2px;
}

.sniper-scope .breath-bar-fill {
    height: 100%;
    width: 100%;
    background: rgba(127, 179, 168, 0.7);
    border-radius: 2px;
    transition: width 0.1s linear;
}

/* Ammo counter */
.sniper-scope .ammo {
    position: absolute;
    bottom: 25%; left: 50%;
    transform: translateX(-50%);
    color: rgba(255, 255, 255, 0.6);
    font-family: monospace;
    font-size: 14px;
    letter-spacing: 2px;
}

/* Hit flash */
.sniper-scope.hit::before {
    animation: hitFlash 0.15s ease-out;
}

@keyframes hitFlash {
    0% { filter: brightness(2); }
    100% { filter: brightness(1); }
}
```

HTML structure (injected once at game init):

```html
<div class="sniper-scope" id="scopeOverlay">
    <div class="cross-h"></div>
    <div class="range-marks">
        <div class="range-mark" style="top: 20%"></div>
        <div class="range-mark" style="top: 40%"></div>
        <div class="range-mark" style="top: 60%"></div>
        <div class="range-mark" style="top: 80%"></div>
    </div>
    <div class="breath-bar-bg">
        <div class="breath-bar-fill" id="breathBarFill"></div>
    </div>
    <div class="ammo" id="ammoCounter">5 / ∞</div>
</div>
```

### Integrating with Game Loop

```js
// In main game loop:
const sniperCamera = new SniperCamera(camera, renderer.domElement);

function animate() {
    requestAnimationFrame(animate);

    const dt = clock.getDelta();
    const cameraState = sniperCamera.update(dt);

    // Update breath bar UI
    if (cameraState && sniperCamera.scopeOverlay) {
        const breathFill = document.getElementById('breathBarFill');
        if (breathFill) {
            breathFill.style.width = cameraState.breathMeter + '%';
        }
    }

    renderer.render(scene, camera);
}
```

## Control Scheme

| Input | Action |
|---|---|
| **Mouse move** | Aim (PointerLockControls) |
| **Right-click** | Toggle scope in/out |
| **Scroll wheel** | Zoom in (up) / out (down) |
| **Left-click** | Fire (see [[sniper-ballistics]]) |
| **Shift** | Hold breath (reduces sway, drains meter) |
| **R** | Reload (see [[sniper-ui]]) |

## Tuning Parameters

| Parameter | Default | Effect |
|---|---|---|
| `scopedFOV` | 12° | Tighter = harder to track moving targets |
| `swayAmplitude` | 0.003 rad | Higher = more difficult precision aiming |
| `swayFrequency` | 1.5 Hz | ~90 BPM breathing rhythm |
| `breathDrainRate` | 15%/s | How fast hold-breath meter depletes |
| `breathRecoveryRate` | 8%/s | Recovery speed after releasing shift |
| `recoilPitch` | 0.04 rad | Vertical kick per shot |
| `zoomSpeed` | 30 FOV/s | How fast scope zooms in/out |

## Known Pitfalls

1. **PointerLock + Chromium kiosk** — Pointer Lock requires user gesture to activate. In kiosk mode, the first click on canvas triggers it. After that it stays locked until Escape is pressed. Test this flow carefully on Pi 5.
2. **Sway feels wrong at low zoom** — breathing sway is barely visible at 75° FOV but very obvious at 12°. The `effectiveAmplitude *= 0.1` when unscoped handles this, but tune to taste.
3. **CSS overlay + Three.js rendering order** — the scope overlay sits on top via `z-index: 100` and `pointer-events: none`. This means clicks pass through to the canvas. Critical for shooting to work while scoped.
4. **FOV transition jitter** — always use smooth interpolation, never snap FOV. The `zoomSpeed` clamp prevents popping.

## Related

- [[sniper-ballistics]] — Raycasting, hit detection, bullet drop
- [[sniper-ui]] — Ammo counter, reload animation, hit feedback
- [[game-state-machine]] — Round flow and win/lose conditions
