---
title: Sniper UI
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [mechanic, ui]
sources: []
---

# Sniper UI

## Overview

Minimal HUD elements for the Sniper. Most UI lives inside the CSS scope overlay (already defined in [[sniper-camera]]). This page covers the dynamic updates: ammo counter, reload progress, hit/miss feedback, and round-end screens.

All UI is **CSS overlays** — no Three.js rendering overhead. Consistent with Chromium kiosk constraints on Pi 5.

## HUD Elements

### Ammo Counter (In-Scope)

Already in the scope overlay HTML from [[sniper-camera]]. Updated each frame:

```js
function updateAmmoUI(ballistics) {
    const ammoEl = document.getElementById('ammoCounter');
    if (!ammoEl) return;

    const state = ballistics.getAmmoState();

    if (state.reloading) {
        ammoEl.textContent = `RELOADING ${Math.floor(state.reloadProgress * 100)}%`;
        ammoEl.style.color = 'rgba(255, 200, 100, 0.8)';
    } else if (state.inMag === 0) {
        ammoEl.textContent = 'EMPTY — PRESS R';
        ammoEl.style.color = 'rgba(255, 80, 80, 0.9)';
    } else {
        ammoEl.textContent = `${state.inMag} / ${state.reserve}`;
        ammoEl.style.color = state.inMag <= 2
            ? 'rgba(255, 160, 80, 0.8)'  // low ammo warning
            : 'rgba(255, 255, 255, 0.6)';
    }
}
```

### Hit Feedback

Three visual signals when the Sniper fires:

| Signal | On Hit | On Miss |
|---|---|---|
| **Scope flash** | White brightness pulse (CSS animation) | None |
| **Crosshair color** | Brief red flash | Stays seafoam green |
| **Impact sparks** | Orange particle burst at hit point (see [[sniper-ballistics]]) | None |

```js
function showHitFeedback() {
    const scope = document.getElementById('scopeOverlay');
    if (!scope) return;

    // Trigger CSS hit flash animation
    scope.classList.add('hit');
    setTimeout(() => scope.classList.remove('hit'), 150);

    // Flash crosshair red
    const crossH = scope.querySelector('.cross-h');
    if (crossH) {
        crossH.style.background = 'linear-gradient(to right, transparent 15%, rgba(255,80,80,0.9) 50%, transparent 85%)';
        setTimeout(() => {
            crossH.style.background = ''; // revert to CSS default
        }, 200);
    }
}

function showMissFeedback() {
    // Subtle screen edge darkening — "you missed" signal
    const scope = document.getElementById('scopeOverlay');
    if (!scope) return;
    // Could add a subtle vignette pulse here
}
```

### Reload Progress Bar

The breath bar doubles as a reload indicator. When reloading, it fills from 0→100%:

```js
function updateReloadUI(ballistics) {
    const breathFill = document.getElementById('breathBarFill');
    if (!breathFill) return;

    const state = ballistics.getAmmoState();

    if (state.reloading) {
        // Show reload progress
        breathFill.style.width = (state.reloadProgress * 100) + '%';
        breathFill.style.background = 'rgba(255, 200, 100, 0.7)'; // amber for reload
    } else {
        // Show breath meter (from camera system)
        const breathData = sniperCamera?.update?.(0); // or pass from main loop
        breathFill.style.background = 'rgba(127, 179, 168, 0.7)'; // seafoam default
    }
}
```

### Round End Screen

Full-screen overlay shown when a round ends:

```css
/* round-end.css */
.round-end {
    position: fixed;
    top: 0; left: 0;
    width: 100vw; height: 100vh;
    display: none;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    background: rgba(0, 0, 0, 0.85);
    z-index: 200;
    pointer-events: auto;
}

.round-end.visible {
    display: flex;
}

.round-end h1 {
    font-family: monospace;
    font-size: 48px;
    letter-spacing: 8px;
    margin-bottom: 20px;
}

.round-end .sniper-win h1 {
    color: #7FB3A8; /* seafoam green */
}

.round-end .mimic-win h1 {
    color: #1a1a2e;
    text-shadow: 0 0 20px rgba(26, 26, 46, 0.8);
}

.round-end .stats {
    font-family: monospace;
    font-size: 16px;
    color: rgba(255, 255, 255, 0.6);
    text-align: center;
    line-height: 2;
}

.round-end .next-btn {
    margin-top: 30px;
    padding: 12px 32px;
    font-family: monospace;
    font-size: 18px;
    letter-spacing: 4px;
    background: transparent;
    color: #7FB3A8;
    border: 1px solid #7FB3A8;
    cursor: pointer;
    transition: all 0.2s;
}

.round-end .next-btn:hover {
    background: #7FB3A8;
    color: #0a0a0a;
}
```

```html
<div class="round-end" id="roundEnd">
    <h1 id="roundResult">SNIPER WINS</h1>
    <div class="stats" id="roundStats">
        Shots fired: 3<br>
        Accuracy: 33%<br>
        Time: 45s
    </div>
    <button class="next-btn" id="nextRoundBtn">NEXT ROUND</button>
</div>
```

```js
function showRoundEnd(sniperWon, stats) {
    const overlay = document.getElementById('roundEnd');
    const resultEl = document.getElementById('roundResult');
    const statsEl = document.getElementById('roundStats');

    overlay.className = 'round-end visible ' + (sniperWon ? 'sniper-win' : 'mimic-win');
    resultEl.textContent = sniperWon ? 'MIMIC ELIMINATED' : 'MIMIC ESCAPED';

    statsEl.innerHTML = `
        Shots fired: ${stats.shotsFired}<br>
        Hits: ${stats.hits}<br>
        Accuracy: ${stats.shotsFired > 0 ? Math.round(stats.hits / stats.shotsFired * 100) : 0}%<br>
        Time: ${Math.floor(stats.time)}s
    `;

    // Unlock pointer so user can click the button
    sniperCamera.controls.unlock();
}

document.getElementById('nextRoundBtn').addEventListener('click', () => {
    document.getElementById('roundEnd').className = 'round-end';
    startNewRound();
});
```

### In-Game Timer

Simple countdown timer visible in scope view:

```css
.sniper-scope .timer {
    position: absolute;
    top: 20%; left: 50%;
    transform: translateX(-50%);
    font-family: monospace;
    font-size: 18px;
    color: rgba(255, 255, 255, 0.4);
    letter-spacing: 3px;
}
```

Updated from the game state machine (see [[game-state-machine]]):

```js
function updateTimerUI(secondsRemaining) {
    const timerEl = document.querySelector('.sniper-scope .timer');
    if (!timerEl) return;

    const mins = Math.floor(secondsRemaining / 60);
    const secs = Math.floor(secondsRemaining % 60);
    timerEl.textContent = `${mins}:${secs.toString().padStart(2, '0')}`;

    // Flash red when time is running low
    if (secondsRemaining < 10) {
        timerEl.style.color = `rgba(255, ${Math.floor(80 + Math.sin(Date.now()/200)*40)}, 80, 0.9)`;
    } else {
        timerEl.style.color = 'rgba(255, 255, 255, 0.4)';
    }
}
```

## Complete Scope Overlay HTML

Combining everything:

```html
<div class="sniper-scope" id="scopeOverlay">
    <!-- Crosshair -->
    <div class="cross-h"></div>

    <!-- Range marks -->
    <div class="range-marks">
        <div class="range-mark" style="top: 20%"></div>
        <div class="range-mark" style="top: 40%"></div>
        <div class="range-mark" style="top: 60%"></div>
        <div class="range-mark" style="top: 80%"></div>
    </div>

    <!-- Timer -->
    <div class="timer" id="scopeTimer">2:00</div>

    <!-- Breath/Reload bar -->
    <div class="breath-bar-bg">
        <div class="breath-bar-fill" id="breathBarFill"></div>
    </div>

    <!-- Ammo counter -->
    <div class="ammo" id="ammoCounter">5 / 10</div>
</div>

<!-- Round end screen -->
<div class="round-end" id="roundEnd">
    <h1 id="roundResult">MIMIC ELIMINATED</h1>
    <div class="stats" id="roundStats"></div>
    <button class="next-btn" id="nextRoundBtn">NEXT ROUND</button>
</div>
```

## Main Loop UI Updates

```js
function animate() {
    requestAnimationFrame(animate);
    const dt = clock.getDelta();

    // ... game logic ...

    // UI updates (only when scoped for performance)
    if (sniperCamera.isScoped) {
        updateAmmoUI(ballistics);
        updateTimerUI(roundTimer);
    }

    renderer.render(scene, camera);
}
```

## Related

- [[sniper-camera]] — Scope overlay CSS foundation
- [[sniper-ballistics]] — Ammo state data source
- [[game-state-machine]] — Round timer and end-screen triggers
