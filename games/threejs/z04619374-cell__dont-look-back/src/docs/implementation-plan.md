# 回头 Implementation Plan

> **For agentic workers:** Execute natively with superpowers:executing-plans, test-driven-development and verification-before-completion. One final independent review per that skill.

**Goal:** Ship the user's playable dual-view horror game as an open-source-ready static repository and a private Sites deployment.
**Architecture:** DOM UI over a single Three.js renderer with two cameras; deterministic browser-independent GameModel. Static dist contains all runtime dependencies. Node built-ins run tests, preview and packaging.
**Tech Stack:** JavaScript ESM, Three.js 0.180.0, PointerLockControls, Web Audio, node:test.
**Spec:** docs/design.md

## Global constraints
Left A / right B, low 3-point damage, hold A 2 s triggers inevitable rear turn, 90 s demo, no edits to sources, no secrets committed. All audio/meshes original; Three.js MIT notice retained.

## Review focus
Pointer unlock/focus loss must pause and clear input; repeat keydown must not refresh guard; resistance cannot defeat held-key forced turn; dynamic viewport reaches zero without invalid aspect; retry clears run state.

## Task 1 — Simulation and reproducible project
Files: dist/js/config.js, dist/js/model.js, tests/model.test.mjs, package.json, scripts/serve.mjs.
Interface: GameModel.start(), pause(), resume(), setGuard(boolean), tap(), look(dx,dy), step(dt), drainEvents(); fields status, reason, time, health, yaw, pitch, contact, monsters.
- [ ] Write and run failing rule tests.
- [ ] Implement deterministic simulation and pass all tests, including paused timers and reset.
- [ ] Add Node-only static server, vendored dependencies with provenance.

## Task 2 — Render, input, UI and sound
Files: dist/index.html, dist/style.css, dist/js/{main,world,splitView,input,sound,ui}.js.
Consumes model from Task 1. World.update(model, dt); SplitView.render(model); Input binds semantic events; UI updates HUD and overlays.
- [ ] Implement image-concept visual tokens and primary screen, start/pause/failure/win overlays.
- [ ] Implement road travel, avatar/hand pose, monster visibility, original synthetic effects.
- [ ] Verify browser load, start/pause/retry, view shrink and long-hold failure, desktop/narrow screen, console and screenshot.

## Task 3 — Open-source handoff and publication
Files: LICENSE, THIRD_PARTY_NOTICES.md, README.md, .gitignore, .github/workflows/pages.yml, scripts/package.mjs, docs/verification.md.
- [ ] Run tests and syntax checks; review independently; fix material findings.
- [ ] Package public-ready source (exclude private Site identity and local QA files).
- [ ] Sites source helper commits/pushes/packages exact source state; deploy its exact commit/archive; confirm terminal result.
- [ ] Deliver game URL, source ZIP, test evidence and known platform limitations.
