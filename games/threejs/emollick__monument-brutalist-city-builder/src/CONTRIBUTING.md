# Contributing to Monument

Thanks for helping make Monument a richer architectural toy. Contributions should preserve the balance between immediate play, architectural depth, visual character, and reliable performance.

## Before starting

1. Search existing issues and pull requests.
2. For a large new composition, rendering system, or state migration, open an issue describing the architectural intent and performance implications first.
3. Keep a pull request focused on one coherent outcome.

## Development workflow

```bash
git clone https://github.com/emollick/monument-brutalist-city-builder.git
cd monument-brutalist-city-builder
npm ci
npm run dev
```

Create a descriptive branch, make the change, and run:

```bash
npm run check
```

Do not commit `node_modules/`, `dist/`, `.netlify/`, logs, or TypeScript build-info files.

## Pull request expectations

Include:

- What changed and why.
- The architectural or player-facing intent.
- Tests added or updated.
- Manual viewport and mood checks performed.
- Before/after images or short recordings for visual changes.
- Any expected GPU, bundle-size, or loading impact.
- Save-compatibility notes when changing `Building` or `GameSnapshot`.

## Design principles

- Make simple actions delightful before exposing expert depth.
- Prefer controls with a visible architectural consequence.
- Keep presets suggestive rather than restrictive.
- Keep buildings grounded and structurally legible.
- Let moods alter space, infrastructure, and atmosphere—not just colors.
- Preserve the toy-city character: growth guidance is expressive, not economic punishment.
- Do not remove desktop capability to simplify mobile; adapt the interaction instead.

## Code expectations

- Keep TypeScript strict and avoid `any` except at narrow third-party boundaries.
- Keep authoritative city state in `App` and rendering state in `CityScene`.
- Reuse shared types and control-applicability rules.
- Add safe defaults for old saves when introducing required fields.
- Prefer instancing or shared materials for repeated scene geometry.
- Avoid per-building real lights unless gated by quality and occupancy.
- Provide accessible names, focus states, and keyboard behavior for interactive controls.
- Keep compact touch targets at least 40–44 CSS pixels where practical.

## Tests

Add or update tests when changing:

- Building defaults or the parcel grid.
- Template generation or save migration.
- Control applicability.
- Any new pure calculation extracted from UI or rendering code.

WebGL appearance and pointer behavior still require manual QA. Follow [docs/TESTING.md](docs/TESTING.md).

## Documentation

Update documentation in the same pull request when changing controls, architecture, setup, persistence, performance behavior, templates, or deployment.

Useful references:

- [Architecture](docs/ARCHITECTURE.md)
- [Controls](docs/CONTROLS.md)
- [Development](docs/DEVELOPMENT.md)
- [Testing](docs/TESTING.md)

## Licensing

By submitting a contribution, you agree that it may be distributed under the repository's [MIT License](LICENSE).
