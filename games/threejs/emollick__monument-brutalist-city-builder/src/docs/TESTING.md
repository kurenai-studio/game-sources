# Testing

Monument combines deterministic city data with a GPU-rendered, interaction-heavy scene. Automated tests protect the pure rules; browser QA protects visual composition, input behavior, and performance.

## Automated commands

```bash
npm run typecheck
npm test
npm run build
```

Run all three in CI order with:

```bash
npm run check
```

GitHub Actions runs `npm run check` on pull requests and pushes to `main`.

## Current automated coverage

### `data.test.ts`

- Parcel grid size, centering, and coordinate uniqueness.
- Typology defaults copied into new buildings.
- Starter-district count, IDs, sites, and positive dimensions.

### `controlApplicability.test.ts`

- Capsule taper remains available.
- Ring-only control constraints.
- Village-cluster grammar and disabled controls.
- Analytical context for controls that do not directly alter the current facade.

### `cityLibrary.test.ts`

- Starting-template order and instance-prefixed IDs.
- Fresh template snapshots without shared mutation.
- Thirty-save limit and round-trip reading.
- Malformed-record filtering.
- Legacy single-city migration and mood normalization.

## What is not automated yet

- Pixel-level WebGL output.
- Pointer dragging in world space.
- Orbit/pan/zoom behavior.
- Mobile safe-area rendering.
- Mood lighting and post-processing appearance.
- Automatic-quality frame-rate transitions.
- Browser local-storage quota behavior.

These areas require the manual matrix below. A future visual regression system should use deterministic camera/time/mood fixtures and tolerate GPU differences rather than comparing arbitrary live frames.

## Manual smoke test

Run `npm run dev` or `npm run preview`, then check:

1. The welcome preview contains detailed buildings, facades, roofscape, public ground, and a reachable start action.
2. Open each starting city and Open Ground.
3. Place one building of each program and one public space.
4. Select a building, drag Move/Height/Span/Depth, then try its composition-specific controls.
5. Change composition among bar, cluster, ring, capsule, and megaframe.
6. Change profiles and confirm disabled controls explain themselves.
7. Grow a sibling, undo it, and redo it.
8. Rename and save the city, return to Menu, and reopen it.
9. Move time from day to night and confirm inhabited buildings light up.
10. Enter and leave Focus mode.

## Responsive matrix

| Viewport | Required checks |
| --- | --- |
| 1440 × 900 desktop | Inspector beside city, full top ribbon, dock/time controls, orbit/pan/zoom |
| 768 × 1024 tablet | No bottom-control overlap, usable toolrail, inspector remains readable |
| 390 × 844 phone | Objectives start collapsed, scrollable lens/mood dock, safe bottom controls |
| 844 × 390 landscape phone | Compact top bar, shallow panels, no clipped build rail |

### Mobile building flow

At 390 × 844:

1. Tap a building.
2. Confirm the inspector does **not** open.
3. Confirm the camera focuses the building and all applicable handles are present.
4. Drag a handle and verify the building changes continuously.
5. Tap **Design** and confirm the inspector opens.
6. Close the inspector and confirm Direct Edit returns.
7. Tap **Done** and confirm the lens, mood, and time controls return.

## Mood matrix

Check each mood at its representative hour and once in daylight:

| Mood | Visual and stability checks |
| --- | --- |
| Default | Warm windows, civic lamps, neutral street material |
| Cyberpunk | Neon/glyph signage, service detail, dark streets, controlled bloom, no crash |
| Green | Planting and ecological street language remain legible without oversaturation |
| Totalitarian | Searchlights, severe underlighting, banners/checkpoints, no crash |
| University | Warm academic lighting, campus signage and public detail |

For Cyberpunk and Totalitarian, switch into and out of the mood repeatedly and inspect the console for WebGL errors.

## Architecture matrix

For a representative building, inspect these combinations:

- Minimum and maximum height, width, and depth.
- Module density 1 and 5.
- Articulation 0 and 100.
- Branches 0 and maximum.
- Crown 0 and 100.
- Each composition with a compatible and incompatible taper profile.
- Structure lens for visible supports and load paths.
- Night mode for facade lighting on ring, capsule, and megaframe forms.

No generated mass should float without a visible architectural connection to the ground or another supported body.

## Performance check

1. Leave graphics on **Auto**.
2. Reload a ready city and observe startup responsiveness.
3. Orbit through the densest view for at least 15 seconds.
4. Switch Default → Cyberpunk → Totalitarian → Default.
5. Enter cinematic camera and advance to night.
6. Confirm interaction remains responsive and the browser console stays free of WebGL/context errors.
7. Repeat at 390 × 844 or on a physical phone.

When a visual improvement adds significant geometry or lighting, document the expected cost in the pull request and identify the quality gate that limits it.

## Before release

- `npm ci` succeeds from a clean checkout.
- `npm run check` passes.
- CI is green.
- The live Netlify URL serves the intended commit.
- The manual smoke, mobile flow, and mood stability checks pass.
- Git status is clean and generated directories remain untracked.
