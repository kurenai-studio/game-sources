---
title: Game State Machine
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [mechanic, state-machine, game-loop]
sources: []
---

# Game State Machine

## Overview

Finite state machine driving round flow: spawn → play → resolve → score → repeat. Manages timer, win conditions, and transitions between states. Both players share the same state — no desync possible in local mode.

## States

```
                    ┌─────────────┐
                    │   ROUND_END  │ ← show results, wait for input
                    └──────┬──────┘
                           │ "Next Round" / auto-advance
                    ┌──────▼──────┐
            ┌───────│    SETUP     │───────────────┐
            │       └─────────────┘                │
            │  - position Mimic                    │
            │  - reset Sniper ammo                  │
            │  - hide all props                     │
            │  - start countdown (3,2,1)            │
            │                                       │
            ▼                                       │
    ┌──────────────┐                                │
    │   COUNTDOWN   │                                │
    │  (3 seconds)  │                                │
    └───────┬───────┘                                │
            │ timer expires                           │
            ▼                                         │
    ┌──────────────┐    Mimic eliminated     ┌───────▼────────┐
    │     PLAYING   │◄──────────────────────│      SNIPER_    │
    │               │                        │      WINS       │
    │ - timer runs  │   Sniper out of ammo   └────────────────┘
    │ - both active │─────────────────────►  ┌────────────────┐
    │ - shooting ok │                        │     MIMIC_     │
    └───────┬───────┘                        │     WINS       │
            │ timer expires                  └───────┬────────┘
            │ Mimic still alive                            │
            ▼                                              │
    ┌──────────────┐                                       │
    │     TIME_     │◄─────────────────────────────────────┤
    │     UP        │  (Mimic survived or Sniper out of ammo)
    │   MIMIC_WINS  │
    └──────────────┘
```

## Implementation

```js
const GameState = {
    SETUP: 'setup',           // Position entities, reset state
    COUNTDOWN: 'countdown',   // 3-2-1 before round starts
    PLAYING: 'playing',       // Active gameplay
    SNIPER_WINS: 'sniper_wins',
    MIMIC_WINS: 'mimic_wins',
    ROUND_END: 'round_end',   // Show results, wait for next
};

class GameStateMachine {
    constructor() {
        this.state = GameState.SETUP;
        this.roundNumber = 0;
        this.scores = { sniper: 0, mimic: 0 };

        // Round config
        this.roundDuration = 120; // seconds (2 minutes per round)
        this.countdownDuration = 3; // seconds
        this.autoAdvanceDelay = 4; // seconds before auto-advancing from ROUND_END

        // Timer state
        this.timer = 0;
        this.countdownTimer = 0;
        this.endTimer = 0;

        // Round stats (tracked during PLAYING)
        this.stats = {
            shotsFired: 0,
            hits: 0,
            startTime: 0,
        };

        // Callbacks
        this.onStateChange = null;   // (oldState, newState) => void
        this.onRoundStart = null;    // () => void
        this.onRoundEnd = null;      // (winner, stats) => void
        this.onCountdownTick = null; // (secondsRemaining) => void
    }

    /** Transition to a new state */
    transition(newState) {
        const oldState = this.state;
        if (oldState === newState) return;

        this.state = newState;

        switch (newState) {
            case GameState.SETUP:
                this.enterSetup();
                break;
            case GameState.COUNTDOWN:
                this.enterCountdown();
                break;
            case GameState.PLAYING:
                this.enterPlaying();
                break;
            case GameState.SNIPER_WINS:
                this.enterRoundEnd('sniper');
                break;
            case GameState.MIMIC_WINS:
                this.enterRoundEnd('mimic');
                break;
            case GameState.ROUND_END:
                // Already handled by enterRoundEnd
                break;
        }

        if (this.onStateChange) {
            this.onStateChange(oldState, newState);
        }
    }

    enterSetup() {
        this.roundNumber++;
        this.stats = { shotsFired: 0, hits: 0, startTime: 0 };

        // Reset entities (called by game via callback)
        if (this.onRoundStart) this.onRoundStart();
    }

    enterCountdown() {
        this.countdownTimer = this.countdownDuration;
    }

    enterPlaying() {
        this.timer = this.roundDuration;
        this.stats.startTime = performance.now() / 1000;
    }

    enterRoundEnd(winner) {
        this.scores[winner]++;
        const elapsed = (performance.now() / 1000) - this.stats.startTime;
        this.stats.time = Math.floor(elapsed);

        if (this.onRoundEnd) {
            this.onRoundEnd(winner, { ...this.stats });
        }

        // Auto-advance after delay
        this.endTimer = this.autoAdvanceDelay;
    }

    /** Called when Sniper hits the Mimic */
    sniperHitMimic() {
        if (this.state !== GameState.PLAYING) return;
        this.transition(GameState.SNIPER_WINS);
    }

    /** Called when Sniper runs out of all ammo */
    sniperOutOfAmmo() {
        if (this.state !== GameState.PLAYING) return;
        this.transition(GameState.MIMIC_WINS);
    }

    /** Main update — called every frame */
    update(dt) {
        switch (this.state) {
            case GameState.SETUP:
                // Auto-transition to countdown after a brief pause
                // (or wait for "Start" button press)
                this.transition(GameState.COUNTDOWN);
                break;

            case GameState.COUNTDOWN:
                this.countdownTimer -= dt;
                if (this.onCountdownTick) {
                    this.onCountdownTick(Math.ceil(this.countdownTimer));
                }
                if (this.countdownTimer <= 0) {
                    this.transition(GameState.PLAYING);
                }
                break;

            case GameState.PLAYING:
                this.timer -= dt;
                if (this.timer <= 0) {
                    this.timer = 0;
                    this.transition(GameState.MIMIC_WINS); // Mimic survived
                }
                break;

            case GameState.SNIPER_WINS:
            case GameState.MIMIC_WINS:
                this.transition(GameState.ROUND_END);
                break;

            case GameState.ROUND_END:
                this.endTimer -= dt;
                if (this.endTimer <= 0) {
                    this.transition(GameState.SETUP); // auto-next round
                }
                break;
        }
    }

    /** Force advance to next round (manual trigger from UI button) */
    nextRound() {
        if (this.state === GameState.ROUND_END) {
            this.transition(GameState.SETUP);
        }
    }

    /** Get timer display value */
    getTimerDisplay() {
        switch (this.state) {
            case GameState.COUNTDOWN:
                return Math.ceil(this.countdownTimer);
            case GameState.PLAYING:
                return Math.ceil(this.timer);
            default:
                return 0;
        }
    }

    /** Check if gameplay is active */
    get isPlaying() {
        return this.state === GameState.PLAYING;
    }

    /** Get current scores */
    getScores() {
        return { ...this.scores, round: this.roundNumber };
    }
}
```

## Integration with Game Loop

```js
const stateMachine = new GameStateMachine();

// Wire callbacks
stateMachine.onRoundStart = () => {
    // Reset Mimic position
    mimic.body.position.copy(spawnPoints.mimic);
    mimic.body.visible = true;
    mimic.legs.forEach(l => l.hipGroup.visible = true);

    // Reset transformation
    transformer.reveal();

    // Reset Sniper ammo
    ballistics.ammoInMag = ballistics.magazineSize;
    ballistics.reserveAmmo = 20;
    ballistics.isReloading = false;

    // Hide all props
    transformables.forEach(t => t.deactivate());

    // Register Mimic as shootable target
    ballistics.registerTarget(mimic.body);

    // Unlock pointer for Sniper
    sniperCamera.controls.lock();
};

stateMachine.onRoundEnd = (winner, stats) => {
    // Unregister targets
    ballistics.unregisterTarget(mimic.body);

    // Show round end screen
    showRoundEnd(winner === 'sniper', stats);

    // Update score display
    updateScoreDisplay(stateMachine.getScores());
};

stateMachine.onCountdownTick = (seconds) => {
    // Update countdown UI
    const timerEl = document.getElementById('scopeTimer');
    if (timerEl) {
        timerEl.textContent = seconds > 0 ? `${seconds}` : 'GO!';
        timerEl.style.color = seconds === 1
            ? 'rgba(127, 179, 168, 1)' // seafoam flash on GO
            : 'rgba(255, 255, 255, 0.6)';
    }
};

// Track shots for stats
ballistics.onHit = (target, point, normal) => {
    stateMachine.stats.hits++;
    // Check if Mimic was hit
    if (isMimicTarget(target)) {
        stateMachine.sniperHitMimic();
    }
};

// Track shots fired
const originalFire = ballistics.fire.bind(ballistics);
ballistics.fire = (...args) => {
    if (stateMachine.state === GameState.PLAYING) {
        stateMachine.stats.shotsFired++;
    }
    return originalFire(...args);
};

// Main loop
function animate() {
    requestAnimationFrame(animate);
    const dt = clock.getDelta();

    // State machine drives everything
    stateMachine.update(dt);

    // Only allow gameplay actions during PLAYING state
    if (stateMachine.isPlaying) {
        mimic.update(dt, mimicInput);
        transformer.update(dt, mimicInput);
        ballistics.update(dt);
    }

    // Always update camera and VFX
    sniperCamera.update(dt);
    poofEffect.update();
    hitEffect.update();

    // Update timer UI
    if (sniperCamera.isScoped) {
        const timeDisplay = stateMachine.getTimerDisplay();
        updateTimerUI(timeDisplay);
    }

    renderer.render(scene, camera);
}
```

## Win Conditions Summary

| Condition | Winner | Trigger |
|---|---|---|
| Sniper shoots Mimic (blob or disguised) | **Sniper** | `sniperHitMimic()` |
| Round timer expires, Mimic alive | **Mimic** | Timer → 0 in PLAYING state |
| Sniper runs out of all ammo | **Mimic** | `sniperOutOfAmmo()` |

## Best-of Series

For a full match, track best-of-N rounds:

```js
const BEST_OF = 5; // first to 3 wins

function checkMatchWinner() {
    const scores = stateMachine.getScores();
    if (scores.sniper >= Math.ceil(BEST_OF / 2)) {
        showMatchWinner('sniper');
    } else if (scores.mimic >= Math.ceil(BEST_OF / 2)) {
        showMatchWinner('mimic');
    }
}
```

## Related

- [[sniper-ui]] — Round-end screen and timer display
- [[multiplayer-architecture]] — State sync for networked play
- [[level-design]] — Spawn point placement per round
