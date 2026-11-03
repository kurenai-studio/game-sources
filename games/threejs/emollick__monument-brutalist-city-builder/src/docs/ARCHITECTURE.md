# Architecture

This document explains how Monument turns application state into a procedural city. It is intended for contributors who need to change behavior without accidentally breaking the architectural grammar, responsive editor, persistence, or adaptive renderer.

## System overview

```text
main.tsx
  └─ App.tsx
      ├─ city and interface state
      ├─ analysis, growth choices, undo/redo
      ├─ cityLibrary.ts ── localStorage
      ├─ data.ts / types.ts / controlApplicability.ts
      └─ CityScene.tsx
          ├─ CameraRig and adaptive quality
          ├─ CityWorld
          │   ├─ atmosphere, streets, skyline, waterfront
          │   ├─ lots, plazas, people, and traffic
          │   └─ BrutalistBuilding[]
          │       ├─ structuralBodies()
          │       ├─ ConcreteBody + structure
          │       ├─ FacadeLayer + roof/detail systems
          │       └─ MassingGizmo when selected
          └─ post-processing
```

There is no backend, network API, ECS, or global state library. React state in `App.tsx` is the source of truth; the Three.js scene is a visual and interactive projection of that state.

## Source responsibilities

### `src/App.tsx`

`App` owns:

- Buildings, plazas, time, pause/speed, active tool, selection, lens, camera, and mood.
- The three `DistrictCharter` growth choices and their visible city signals.
- UI panels, welcome screen, Focus mode, mobile Direct Edit, and display settings.
- Building and city analysis used by the inspector and score ribbon.
- In-memory undo/redo history.
- Named city saves and template switching.

The scene receives serializable city data plus callbacks. Scene components do not own authoritative building state.

### `src/CityScene.tsx`

`CityScene` owns rendering concerns:

- React Three Fiber `Canvas` creation and device-pixel-ratio limits.
- Automatic quality selection and performance monitoring.
- Camera positioning, orbit controls, cinematic movement, and street movement.
- Procedural building bodies, facades, structure, roofscape, lighting, and architectural character.
- Streets, background city, public realm, vehicles, people, mood-specific details, atmosphere, and post-processing.
- 3D manipulation handles. Handle changes are throttled through animation frames before being sent to `App`.

Keep long-lived product state out of this module. A scene-only animation phase, hover state, or pointer-drag state belongs here; the resulting building dimensions belong in `App`.

### `src/data.ts`

This is the architectural catalog:

- `PROGRAMS` and `TONES` define use and material presentation.
- `TYPOLOGIES` provide initial dimensions and construction defaults.
- `DESIGN_LANGUAGES` apply coherent multi-property presets.
- `COMPOSITIONS` and `PROFILES` expose the generative form families.
- `ARCHITECTURAL_TRAJECTORIES` provide recognizable starting propositions.
- `makeBuilding`, `initialBuildings`, and `lots` create base state.

Presets are starting points, not locked subclasses. Every building ultimately remains one `Building` record.

### `src/controlApplicability.ts`

Some numeric properties cannot visibly affect every composition. This module is the shared contract between the inspector and direct manipulation:

- `controlDisabledReason` explains when a control must be disabled.
- `controlContextNote` explains values that affect analysis without changing the current shell.
- `isVillageCluster` identifies the special low-rise cluster grammar.

When a composition changes, update these rules and their tests before exposing a control.

### `src/cityLibrary.ts`

This module contains the four starting-city definitions and all browser persistence. It deliberately has no React dependency, making its template and migration behavior testable in Node.

### `src/types.ts`

The `Building`, `Plaza`, `GameSnapshot`, and UI union types are the shared schema. Changing these types affects templates, old saves, inspector controls, scene geometry, and tests.

## Building generation pipeline

A building is data, not a stored mesh. Its visible form is rebuilt from the `Building` record on render:

1. `structuralBodies(building)` converts composition, profile, module density, articulation, branches, taper, dimensions, and other form values into an array of internal bodies.
2. `ConcreteBody` renders the primary mass for each body.
3. Composition-specific systems add pilotis, cores, transfer structures, capsules, megaframe members, cantilever support, and forum geometry.
4. `FacadeLayer` applies the selected facade strategy on all relevant elevations.
5. Roof plant, gardens, balconies, material weathering, charter evidence, and mood details attach to the generated bodies.
6. When selected, `MassingGizmo` positions controls in world space and sends patches back to `App`.

The key invariant is that every form control must have a legible geometric or analytical effect, or be disabled with a player-facing reason.

## State and event flow

```text
pointer / keyboard / inspector input
  → App callback or MassingGizmo
  → Partial<Building> / city-state update
  → React render
  → CityScene regenerates affected geometry
  → analysis and city metrics recompute
```

`selectedId` connects the DOM interface and Three.js scene. On desktop, selection also opens the inspector. On compact mobile layouts, selection first switches to orbit, focuses the building, and leaves `MassingGizmo` visible; the inspector opens only after the player chooses **Design**.

## Undo and snapshots

Before a destructive or continuous edit begins, `capture()` stores a structured clone of the current `GameSnapshot`. History is held in memory and capped at 60 snapshots. Undo moves the current snapshot to the future stack; a new edit clears that future stack.

The saved snapshot contains:

- Buildings and plazas.
- Day and time.
- Growth-sketch stage.
- Mood.
- District charter choices and decision history.

UI state such as the selected building, open panel, camera position, and active lens is intentionally not persisted.

## Persistence

`readCityLibrary` and `writeCityLibrary` use browser local storage:

- `monument-city-library-v1`: up to 30 named `CitySaveRecord` objects.
- `monument-city-v2`: legacy single-city input, migrated on read.
- `monument-graphics-v2`: display settings, managed by `App`.

The current validation is intentionally permissive: a snapshot must contain building and plaza arrays. When adding required schema fields, supply defaults during restore so old cities remain usable.

## Growth choices

The city has no currency or economy. Progress is expressed through three growth sketches. Each resolves one `DistrictCharter` field:

- Ground-level access: open or quiet.
- Commons: shared rooms or specialist growth.
- Aggregate: reuse or formal standards.

`App` turns these choices into `CitySignals`. Scene components then add visible evidence such as shared rooms, workshops, night stalls, gardens, reclaimed panels, or formal language.

## Rendering and performance

Rendering quality is split into named profiles (`low`, `balanced`, and `high`) and an `auto` setting:

- Profiles control DPR, shadow maps, facade density, detail, and real accent lights.
- Auto begins conservatively and uses `PerformanceMonitor` to move between profiles.
- Cyberpunk and Totalitarian are protected from the most expensive high-quality combination.
- Compact viewports are capped conservatively.
- The welcome preview keeps architectural detail but omits expensive simulation elements; compact previews remove additional effects.
- A pixel budget limits DPR independently of the device-reported pixel ratio.

Performance changes must be checked in Default, Cyberpunk, and Totalitarian moods, at day and night, and on a compact viewport. See [Testing](TESTING.md).

## Responsive interface boundary

Desktop and mobile share the same city and building state. Responsiveness changes presentation and selection flow, not capability:

- Desktop opens a persistent inspector beside the city.
- Portrait phones use bottom control rails and a handle-first Direct Edit mode.
- Landscape phones use a shallow, horizontally constrained layout.
- Touch pointers receive larger controls and range thumbs.
- Safe-area insets and dynamic viewport units protect controls from browser chrome and notches.

Keep compact-layout media queries aligned with `COMPACT_EDITOR_MEDIA` in `App.tsx`.

## Deliberate constraints

- Saves are local-only; there is no account or cloud synchronization.
- Street-camera movement currently expects a keyboard for translation.
- WebGL output is not snapshot-tested; visual regressions require browser QA.
- `App.tsx`, `CityScene.tsx`, and `styles.css` are large. Prefer extracting a subsystem when a change creates a clear reusable boundary, but avoid broad refactors mixed with visual feature work.
