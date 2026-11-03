---
title: Multiplayer Architecture
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [mechanic, networking, architecture]
sources: []
---

# Multiplayer Architecture

## Overview

**MVP: Local single-machine multiplayer.** Both players share one screen and one keyboard. The Sniper controls the camera via mouse (PointerLock), the Mimic moves via WASD + E to transform. No split screen — both players see the same view (Sniper's POV). The Mimic player navigates blind, relying on spatial memory and audio cues (future).

This is intentionally simple: zero networking code, zero server infrastructure, runs on a single Pi 5 in kiosk mode. Two people at one keyboard — couch co-op style.

Networked multiplayer is a V2 feature. This page covers both approaches so the architecture doesn't block it later.

## V1: Local Multiplayer (MVP)

### Input Separation

| Player | Controls | Device |
|---|---|---|
| **Sniper** | Mouse aim, left-click fire, right-click scope, scroll zoom, shift hold breath, R reload | Mouse + keyboard |
| **Mimic** | WASD move, E transform/reveal | Keyboard only |

No input conflict — Sniper never uses WASD, Mimic never uses mouse. PointerLock captures the mouse for Sniper; keyboard events are shared but keys don't overlap.

### Shared Scene, Single Camera

Both players share one Three.js scene and one camera (Sniper's POV). The Mimic player cannot see their own character on screen — they navigate by:
- Spatial memory of the level layout
- Knowing where transformable props are placed
- Feeling out movement (like a blindfolded player)

This is actually **a feature, not a bug** — it adds tension. The Mimic player has to memorize the map and trust their instincts about where the Sniper is looking.

```js
// Input handling — no conflict between players
const keys = {};
window.addEventListener('keydown', (e) => {
    keys[e.key.toLowerCase()] = true;

    // Mimic: E to transform/reveal
    if (e.key.toLowerCase() === 'e' && stateMachine.isPlaying) {
        if (transformer.currentDisguise) {
            transformer.reveal();
        } else {
            transformer.transform();
        }
    }

    // Sniper: R to reload
    if (e.key.toLowerCase() === 'r') {
        ballistics.startReload();
    }
});

window.addEventListener('keyup', (e) => {
    keys[e.key.toLowerCase()] = false;
});

// Mimic input from keyboard
function getMimicInput() {
    return {
        forward: (keys['w'] ? 1 : 0) - (keys['s'] ? 1 : 0),
        strafe: (keys['a'] ? 1 : 0) - (keys['d'] ? 1 : 0),
    };
}

// Sniper input from mouse (handled by PointerLockControls + event listeners)
window.addEventListener('mousedown', (e) => {
    if (e.button === 0 && sniperCamera.controls.isLocked && stateMachine.isPlaying) {
        ballistics.fire(sniperCamera.isScoped);
    }
});
```

### Why This Works for MVP

1. **Zero networking** — no server, no latency, no sync bugs
2. **Single render pass** — one camera, one scene, maximum Pi 5 performance
3. **Social gameplay** — two people at one keyboard is inherently fun and chaotic
4. **No split screen needed** — the asymmetry IS the game. Mimic playing blind is part of the tension

## V2: Networked Multiplayer (Future)

When ready to go online, the architecture supports two paths:

### Option A: WebSocket + Authoritative Server

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  Sniper     │◄───────►│              │◄───────►│   Mimic     │
│  (browser)  │ WebSocket│  Node.js    │ WebSocket│  (browser)  │
│             │          │  Server     │          │             │
└─────────────┘         └──────────────┘         └─────────────┘
                              │
                         Authoritative
                         game state
```

**Pros:**
- Server is source of truth — no cheating
- Easy to add spectating, matchmaking, leaderboards
- Works behind NATs/firewalls (server-initiated connections)

**Cons:**
- Requires a server to run and maintain
- Adds latency (round-trip time for every action)
- More complex state sync logic

**Protocol design:**
```js
// Client → Server messages
{ type: 'mimic_move', forward: 1, strafe: 0 }
{ type: 'mimic_transform' }
{ type: 'sniper_shoot', aimX: 0.001, aimY: -0.002 }
{ type: 'sniper_scope', scoped: true }

// Server → Client messages (authoritative state)
{ type: 'state_update', mimicPos: [x,y,z], disguised: bool, ammo: 3, timer: 45 }
{ type: 'hit', target: 'mimic', point: [x,y,z] }
{ type: 'round_end', winner: 'sniper' }
```

**Tick rate:** 20Hz (50ms) is sufficient for this game — no fast reflex combat.

### Option B: WebRTC Peer-to-Peer

```
┌─────────────┐  ───────────────────►  ┌─────────────┐
│  Sniper     │   WebRTC DataChannel   │   Mimic     │
│  (browser)  │  ════════════════════  │  (browser)  │
└─────────────┘                        └─────────────┘
       │                                    │
       └──────── Signaling Server ──────────┘
       (only for handshake, then disconnected)
```

**Pros:**
- Lower latency (direct peer-to-peer)
- No game server to maintain — just a lightweight signaling server
- Mimic is source of truth for their own position (no prediction needed)

**Cons:**
- NAT traversal can fail (needs TURN server fallback)
- One player has authority — potential cheating
- Harder to add spectating or more than 2 players

### Recommendation: Start with WebSocket

For V2, WebSocket + Node.js server is the cleaner path. Reasons:
1. The game doesn't need sub-50ms latency (it's not a twitch shooter)
2. Authoritative server prevents cheating (Sniper can't fake shots, Mimic can't teleport)
3. Easier to extend to matchmaking, lobbies, leaderboards later
4. Cheap hosting — a $5/mo VPS handles hundreds of concurrent games

### State Sync Strategy

For networked play, the server runs the authoritative game loop:

```js
// Server-side (Node.js + ws)
class GameServer {
    constructor() {
        this.state = {
            mimicPos: new Vector3(),
            mimicDisguised: false,
            mimicDisguiseType: null,
            sniperAmmo: 5,
            sniperReloading: false,
            timer: 120,
            roundActive: false,
        };

        this.tickRate = 20; // Hz
        this.lastTick = 0;
    }

    tick() {
        if (!this.state.roundActive) return;

        // Process queued inputs from both players
        this.processMimicInputs();
        this.processSniperInputs();

        // Update timer
        this.state.timer -= 1 / this.tickRate;

        // Check win conditions
        if (this.state.timer <= 0) {
            this.endRound('mimic');
        }

        // Broadcast state to both clients (delta compression)
        this.broadcastState();
    }

    processSniperInputs() {
        for (const shot of this.pendingShots) {
            const hit = this.raycast(shot);
            if (hit && hit.target === 'mimic') {
                this.endRound('sniper');
            }
            this.state.sniperAmmo--;
        }
        this.pendingShots = [];
    }

    broadcastState() {
        const delta = this.computeDelta(this.lastState, this.state);
        this.sendToAll(JSON.stringify({ type: 'state', delta }));
        this.lastState = { ...this.state };
    }
}
```

**Client-side prediction:** Mimic predicts their own movement locally (no lag feel). Sniper predicts nothing — they just aim and shoot, server resolves.

## Architecture Decision Summary

| Factor | V1 Local | V2 Networked |
|---|---|---|
| **Players** | 2 at one keyboard | 2 over network |
| **Rendering** | Single camera, single pass | Each client renders full scene |
| **Authority** | Client (no server) | Server authoritative |
| **Latency** | Zero | ~50-100ms |
| **Complexity** | Minimal | Moderate (server + sync) |
| **Hosting** | None needed | $5/mo VPS |

## Related

- [[game-state-machine]] — Round flow logic (runs on server in V2)
- [[performance-pi5]] — Pi 5 rendering constraints for local mode
- [[sniper-camera]] — PointerLock input handling
