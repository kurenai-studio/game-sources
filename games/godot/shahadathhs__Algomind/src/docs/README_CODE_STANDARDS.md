# Algomind — Code Standards

> **Goal:** Keep every hand-written source file small, single-purpose, and reusable. This document is the source of truth for file size, module structure, and extraction rules across `apps/web`, `apps/api`, `apps/game`, and `packages/*`. It exists because the codebase already drifted: the worst file holds eleven React components in 955 lines.
> **Status:** Enforced from now on. New code must comply immediately; existing violations are a refactor backlog (section 9). Reviewers and AI tools should reject changes that break these rules.

## 1. Principles

- **One file, one job.** A file is a component, a hook, a pure module, a schema, or a screen section — never several.
- **Prefer deleting to adding.** Extraction is not free; extract when the rules below trigger, not to look tidy.
- **Pure logic never lives in UI.** Anything testable without a renderer belongs in `lib/` (web), a service (API), or `scripts/logic/` (game). This is the same rule as "simulation is separate from animation and UI", applied at file level.
- **The second copy is the bug.** The same helper twice in two files means a shared module is missing.
- **Size is a proxy, not the goal.** A 290-line file with one purpose beats a 120-line file with three.

## 2. Hard limits

| Limit                                           | Soft (refactor when touching) | Hard ceiling (reject in review) |
| ----------------------------------------------- | ----------------------------- | ------------------------------- |
| Hand-written source file (`.ts`, `.tsx`, `.gd`) | 300 lines                     | 450 lines                       |
| Exported React components per `.tsx` file       | 1                             | 1                               |
| Function length                                 | 40 lines                      | 80 lines                        |
| Function nesting depth                          | 3                             | 4                               |
| Controller/route-handler logic                  | parse + delegate only         | —                               |
| Function parameters                             | 4                             | 5 (use an object)               |

Measure with:

```sh
find apps/web/src apps/api/src apps/game/scripts packages/*/src -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.gd' \) -exec wc -l {} + | sort -rn | grep -v ' total ' | head -20
```

Exemptions are listed in section 8. Files over the soft limit that cannot be split (see exemptions) need a one-line `// Why large:` comment at the top stating the reason.

## 3. React: one component per file

- **One exported component per `.tsx` file.** The file name is the component name: `PreviewPanel.tsx`, not `editor-panels.tsx`.
- Allowed in the same file: unexported render helpers under 20 lines that only that component uses (a row, an icon wrapper). Anything else moves out.
- A subcomponent moves to its own file as soon as **any** of these trigger:
  - it has its own state or effects;
  - it is used by more than one component;
  - it exceeds 40 lines;
  - the parent file crosses the soft limit.
- **No component named after a screen holding six unrelated panels.** Panel families (the editor's preview, playtest, hints, walls panels) are siblings: one folder, one file each, composed by a thin parent.
- Pages and layouts stay thin: data fetching plus composition. A `page.tsx` over ~120 lines is a smell; the content is components.
- Do not seed state from props and then let the prop change (the stale-state bug class). Either derive during render, sync in an effect, or key the child on the value.

## 4. Reuse and extraction triggers

Extract into a shared module when **any** trigger fires — do not copy:

| Signal                                                                                  | Extract to                                                                                |
| --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| The same helper appears in a second file                                                | `apps/web/src/lib/…` or `components/admin/shared.tsx` (one shared module per route group) |
| The same UI fragment appears twice                                                      | `components/ui/` (shared by public + admin) or `components/admin/`                        |
| A stateful `useEffect` + `useState` cluster over ~30 lines, or reused across components | a custom hook in `components/<area>/use-*.ts` or `lib/`                                   |
| Pure logic in a component (parsing, formatting, geometry, merges)                       | `lib/` (web), a service or module-level function (API), `scripts/logic/` (game)           |
| The same API call shape in two components                                               | one typed client function in `lib/admin/admin-api.ts`                                     |
| Message/error mapping repeated per file                                                 | one `messages.ts` helper                                                                  |

Duplications found in review and since removed (do not re-copy): `TextAction` and `swap`/`move` now live in `components/admin/text-action.tsx` and `lib/admin/list-ops.ts`; the per-file `messageOf` helpers are one `apiMessage` in `lib/admin/messages.ts`.

## 5. Naming and placement

- Web: `components/<area>/<Name>.tsx` for React, one concern per file; `lib/<domain>.ts` for logic; kebab-case file names, PascalCase component names.
- API: one folder per module (`modules/<domain>/`); `*.controller.ts` stays thin, `*.service.ts` holds the domain logic, `*.schemas.ts` the zod schemas; split a service by use case (`levels-publish.service.ts`) when it crosses the limit, never by technical layer.
- Game: `scripts/logic/` is pure and headless-tested; `scripts/ui/` holds reusable controls; `scripts/screens/` orchestrates. A screen over the limit splits by overlay or section (`play_tape.gd`, `play_result.gd`), not by utility functions.
- A file's name must let you guess its single responsibility without opening it.

## 6. Functions and state

- One function, one job. If the docstring needs "and", split it.
- No boolean parameters that select unrelated behavior — two functions beat one `mode` flag.
- Return values a caller ignores (a `save()` result) are either checked or explicitly `-> void`-documented as best-effort.
- Avoid parallel mutable copies of the same source of truth (props-into-state, server state mirrored locally without sync-back).

## 7. Per-area layout rules

- **Web (`apps/web`)**: `(public)` components must stay independent from `(admin)` components; shared pieces live in `components/ui/`. Route handlers under `app/…/api/` delegate to `lib/` and contain no business logic beyond request shaping.
- **API (`apps/api`)**: guards, filters, and DTO parsing are the only things allowed in controllers. Every service method that mutates money-equivalent state (publish, sync, delete) stays transactional and takes the lock it needs — do not extract across that boundary.
- **Game (`apps/game`)**: `screens/*.gd` may contain layout building and signal wiring; game rules, storage, and networking never do. UI scripts read the generated palette; they never compute colors.

## 8. Exemptions

| Path                                                                                                                                            | Reason                                                                                 |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `apps/api/src/generated/**`                                                                                                                     | Prisma output                                                                          |
| `apps/game/addons/**`                                                                                                                           | Vendored GUT                                                                           |
| Generated token outputs (`token-colors.generated.ts`, `scripts/generated/palette.gd`, `tokens.css`)                                             | Produced by `make tokens`                                                              |
| Pure data modules (`starter-campaign.data.ts`, `daily-pool.data.ts`, fixture JSON, seed catalogs)                                               | Data, not logic; keep entries one per level                                            |
| Contract mirrors: `packages/level-contract/src/validate.ts`, `apps/game/scripts/contract/level_validator.gd` (and their simulator/solver twins) | Rule parity outranks size; if they are ever split, split both sides in the same change |

## 9. Refactor backlog (current state, measured 2026-10-19)

The splits listed in the first review are done: the editor panels, campaign manager, level list, level editor and game screen on the web; `levels.service.ts` in the API (reads, drafts, publishing, playtests, transfer); `play.gd` in the game. Behavior was unchanged: tests stayed green and the 102 debug screenshots were byte-identical before and after.

Files still over the soft limit (300), all under the ceiling. Split the part you touch when you next edit them:

| File                                                     | Lines | Note                                                     |
| -------------------------------------------------------- | ----- | -------------------------------------------------------- |
| `apps/game/scripts/screens/play.gd`                      | 408   | state-to-view and player actions; split on the next edit |
| `apps/web/src/lib/admin/session-manager.ts`              | 366   | refresh, locks and broadcast; split by concern           |
| `apps/api/src/modules/campaign/campaign.service.ts`      | 350   | worlds, chapters and order                               |
| `apps/api/src/modules/levels/admin-levels.controller.ts` | 326   | route declarations with Swagger metadata                 |
| `apps/api/src/modules/levels/levels.service.ts`          | 320   | drafts                                                   |
| `apps/web/src/lib/admin/bff.ts`                          | 306   | proxy request shaping                                    |

Exempt (section 8): `starter-campaign.data.ts`, `daily-pool.data.ts`, `level_validator.gd`, `validate.ts`.

## 10. Enforcement

- Review-time until automated: reject new files over the hard ceiling and new multi-component `.tsx` files. AI agents must run the measurement command before claiming a file is small.
- The boy-scout rule applies: any edit to a file over the soft limit splits or extracts at least the part being touched. Do not grow an oversized file.
- `make size-check` (`scripts/check-file-size.mjs`, run by `make check` and CI) fails a file over 450 lines and lists files over 300. Exemptions live in that script and in section 8; keep the two in step.
- Extraction must not change behavior: move code, keep the tests green (`make test`, `make game-test`), and update `docs/` only if a documented contract changed.
