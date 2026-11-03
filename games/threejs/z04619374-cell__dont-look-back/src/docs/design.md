# 回头 — Demo design

The user authorized implementation from the in-chat plan on 2026-10-15, including their revisions: vertical divider (left A / right B), low monster damage with strong feedback, and inevitable failure when A is continuously held. Work lives in a new isolated subdirectory; synced sources stay read-only.

## Play
- One player, two simultaneous cameras, automatic forward movement at 1.35 m/s. B follows A by 1.5 m. Mouse changes A's look direction only; road travel is independent of look direction.
- Desktop mouse/keyboard, left/right 50:50 start. Only B sees A's body and B hands. Only A sees monsters. B disappears through a shrinking right viewport; camera aspect follows its viewport.
- Left click taps A's shoulder, restores B width, and turns A toward the rear by 0.82 rad through a resistible impulse. Cooldown 1.2 s. Begin-game click must not also tap.
- No B interaction for 4 s starts shrink; at 12 s B is gone and the run ends. A can reverse the impulse using the mouse; facing within 10 degrees of the rear for 0.2 s ends the run.
- A press starts a 0.5 s guard, cooldown 0.9 s. Holding for 2 s latches an irreversible forced turn, ending at the rear even if the player moves the mouse. Releasing earlier clears continuous hold, but cannot cancel a latched forced turn. Ignore repeated keydown. Only sufficiently front-facing guard blocks attacks.
- Health 100, hit damage 3; clear non-gory red edge, shake, sound. Monster type has approach, warning, strike, fade. Health zero also ends the run. Survive 90 s to reach the exit.
- Escape, focus loss, visibility loss, or pointer unlock pause. Clear inputs on pause. No timers run in pause; resume requires intentional user activation. Retry reconstructs the model and clears monsters/feedback.

## Visual direction
User revision during implementation: **no art assets; pure whitebox only**. Charcoal-blue near-black #0c1012, off-white #d7d9d0, cool gray #889394, muted red #b64b40. Slim top and bottom rails, spacious serif Chinese title, no cards/marketing page. Live 3D geometry behind start/pause/result overlay. Road, railings, pillars, road markers, A and B bodies, hands and monsters all use BoxGeometry with plain gray materials. No models, images, textures or recorded sounds. Browser-local sound synthesis and procedural geometry are original MIT work. UI text/control overlays stay HTML/CSS. Reduced-motion option and volume/sensitivity controls. Narrow/touch devices get a clear desktop requirement, not pretend touch support.

## Boundaries
Static buildless JS modules, vendored Three.js 0.180.0 and PointerLockControls, no external runtime/CDN requirements. Single renderer, two viewport/scissor render passes, camera layer visibility. GameModel owns rules independent of DOM/WebGL. World owns meshes; sound owns Web Audio; UI owns text and controls; main coordinates.

## Release
MIT source, third-party MIT notices, README (Chinese + concise English), Node-built-in preview/test scripts, GitHub Pages workflow, source ZIP, Sites static dist publication (new Site remains private). No GitHub public repository creation without account/target details; deliver a ready-to-publish repository.

## Verification
Node tests: B decay/recovery/cooldown, tap turn, long-held A despite mouse resistance, release, guard direction/damage, rear dwell, frame-rate invariance, paused timers, reset, win. Browser: nonblank live views, controls, start/resume/pause/retry, shrinking width and forced-turn outcomes, console, narrow layout. Check source licensing, local dependency integrity, serve path traversal prevention, and packaged source excludes credentials and Site identity.
