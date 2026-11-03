# Development guide

## Prerequisites

- Node.js 20 or newer. Node.js 22 is used in CI.
- npm, using the committed `package-lock.json`.
- A browser with WebGL support.

## Setup

```bash
git clone https://github.com/emollick/monument-brutalist-city-builder.git
cd monument-brutalist-city-builder
npm ci
npm run dev
```

Use `npm ci`, not `npm install`, when validating a clean checkout. It enforces the committed dependency graph.

Before opening a pull request:

```bash
npm run check
```

This runs TypeScript, Vitest, and a production Vite build.

## Working conventions

- Keep `Building` and `GameSnapshot` serializable. Do not store Three.js classes, DOM nodes, functions, or React state in them.
- Capture history before the first change in a continuous edit, not on every pointer frame.
- Send scene edits to `App`; do not create a competing authoritative copy in `CityScene`.
- Reuse `controlApplicability.ts` when a control cannot affect every grammar.
- Use player-facing architectural language in the UI and implementation language in documentation.
- Preserve desktop behavior when adding compact-layout behavior.
- Use `apply_patch`-sized focused changes and avoid mixing a renderer refactor with a visual feature.

## Adding a typology

1. Add the literal to `Typology` in `src/types.ts`.
2. Add dimensions, construction defaults, composition, and profile to `TYPOLOGIES` in `src/data.ts`.
3. Add or update the inspector's typology presentation in `App.tsx`.
4. Confirm `makeBuilding` produces a complete building.
5. Add a data test and manually place the typology in Default and Structure lenses.

A typology is a starting configuration. It should not create a separate runtime class.

## Adding a composition

1. Extend `Composition` in `src/types.ts`.
2. Add its public label to `COMPOSITIONS` in `src/data.ts`.
3. Implement its body generation in `structuralBodies` in `CityScene.tsx`.
4. Add any necessary support, core, facade, roof, lighting, and selection geometry.
5. Update `controlDisabledReason` and `controlContextNote` for every control whose meaning changes.
6. Add tests for those rules.
7. Check low/high module density, all six profiles, minimum/maximum dimensions, and Structure view.

The composition must remain grounded and structurally legible. Floating masses need visible cores, frames, transfer members, or pilotis.

## Adding a growth profile

1. Extend `Profile` in `src/types.ts`.
2. Add its label to `PROFILES` in `src/data.ts`.
3. Teach each relevant composition how the profile changes its tiers or modules.
4. Update taper applicability.
5. Test minimum and maximum taper values with short and tall buildings.

## Adding a design language or trajectory

Design languages and trajectories are coherent patches over `Building`:

- A language should coordinate composition, profile, material, structure, facade, porosity, vegetation, and detail.
- A trajectory should make a strong, legible proposition without locking later controls.

Update the catalog in `data.ts`, the UI labels in `App.tsx` if needed, and at least one template or test fixture that exercises it.

## Adding a mood

Mood work crosses rendering and UI boundaries:

1. Extend `DistrictMood` in `types.ts`.
2. Add the UI entry and representative hour in `App.tsx`.
3. Add light, sky, fog, ground, road, window, lamp, accent, and bloom values to `MOOD_SCENES`.
4. Extend atmosphere, street language, district details, building details, and post-processing as appropriate.
5. Add any CSS grade or overlay in `styles.css`.
6. Verify day and night on `low`, `balanced`, and `high`/auto rendering.
7. Check real-light counts and console errors before increasing bloom or accent lights.

A mood should change the city, not merely recolor windows.

## Adding a building control

1. Add the field to `Building` and defaults to `makeBuilding`.
2. Supply restore defaults for old snapshots in `App.tsx`.
3. Add the inspector control and analysis impact.
4. Use the field in `structuralBodies`, facade, detail, or analysis code.
5. Add a `MassingGizmo` handle when direct manipulation is meaningful.
6. Add applicability rules and player-facing reasons.
7. Test representative supported and unsupported compositions.

If the control affects only analysis, label that context explicitly. Do not imply a visible shell change.

## Adding a starting city

1. Extend the `CityTemplate['id']` union in `cityLibrary.ts`.
2. Build the district from deterministic seeds with instance-prefixed IDs.
3. Add plazas and a representative mood/hour.
4. Add the template to `CITY_TEMPLATES`.
5. Extend the template-order test.
6. Check the welcome preview at desktop, phone, and tablet widths.

Template creation must return fresh objects on every call.

## Save compatibility

Existing saves may omit newly introduced fields. When a new field becomes required:

- Add a safe default during `restore`.
- Keep old mood/value aliases normalized.
- Do not rename the local-storage key without a migration.
- Add a migration test.

Never assume a browser save contains the latest complete TypeScript shape.

## Styling and responsive behavior

The interface uses one CSS file with breakpoint sections at the end. Keep these coordinated:

- Base desktop rules.
- Tablet control stacking.
- Portrait phone rules at 720 px and below.
- Landscape-phone rules for short viewports up to 900 px wide.
- Coarse-pointer target sizing.

`COMPACT_EDITOR_MEDIA` in `App.tsx` must describe the same compact layouts as CSS. Test notches/safe areas conceptually by retaining `env(safe-area-inset-*)` in bottom and top calculations.

## Performance guardrails

- Prefer instancing for repeated, materially identical geometry.
- Avoid adding a point or spot light to every building.
- Keep expensive mood details behind render-quality checks.
- Do not make the welcome screen compile the most expensive mood shaders.
- Preserve the DPR pixel budget and compact-viewport cap.
- Test Cyberpunk and Totalitarian separately; they have the densest mood-specific geometry and lighting.
- Inspect browser console warnings and test automatic quality after changing render cost.

## Dependencies

Keep dependencies minimal. Before adding one, confirm that the capability cannot be expressed with React, Three.js, the existing Drei/post-processing stack, or a small local helper. Commit both `package.json` and `package-lock.json` changes.

## Deployment

Netlify reads `netlify.toml`, runs `npm run build`, and publishes `dist/`. `dist/` is intentionally ignored and should not be committed.

After a production deploy, verify:

- Welcome preview.
- Starting a city.
- Direct building manipulation.
- Save/open cycle.
- Default, Cyberpunk, and Totalitarian moods.
- Phone selection and Design-panel flow.

See [Testing](TESTING.md) for the complete matrix.
