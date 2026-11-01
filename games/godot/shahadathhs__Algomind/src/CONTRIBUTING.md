# Contributing to Algomind

Algomind is a programming puzzle game for Android (Godot) with a NestJS API and a Next.js web app that holds the public site and the admin dashboard. Read [docs/README_PROJECT_OVERVIEW.md](docs/README_PROJECT_OVERVIEW.md) first: it defines what is in scope and, just as important, what is not.

## Setup

You need Node 22+, [pnpm](https://pnpm.io) (the version is pinned in `package.json`), Docker, and `make`. For the game you also need Godot 4.7 and [uv](https://docs.astral.sh/uv/) (GDScript lint), or you can use the `game-docker-*` targets instead of a host Godot.

```sh
make setup       # .env (generated local database password), dependencies and git hooks, database, migrations, Godot cache
make help        # lists every command
make up          # or run the database, API, and web in containers
```

## Before you open a PR

`make` is the command surface and CI runs the same commands. Run the ones that cover your change:

| Changed                  | Run                                        |
| ------------------------ | ------------------------------------------ |
| any TypeScript or docs   | `make lint`, `make typecheck`, `make test` |
| `packages/design-tokens` | `make tokens`, then `make tokens-check`    |
| anything                 | keep `docs/` matching the code             |

A PR that fails these will not be reviewed in detail.

## House rules

- **Docs are the spec.** If behavior changes, update the relevant file in `docs/` in the same change.
- **Rules live in one place.** Gameplay rules: [docs/README_GAME_RULES.md](docs/README_GAME_RULES.md). Visual rules: [docs/README_VISUAL_DESIGN.md](docs/README_VISUAL_DESIGN.md). Do not restate or contradict them in code comments.
- **Colors come from design tokens.** Define colors only in `packages/design-tokens`; never hand-write a hex value or `Color(...)` in an app.
- **The simulation is shared.** The TypeScript reference simulator and the GDScript simulator must agree on every fixture in `packages/level-contract/fixtures`.
- **No scope creep.** Do not add features from the overview's "not included" list; propose them in an issue first.
- **Never claim you ran, built, or tested something you did not.** Say what you verified and how.

## Branching, commits, and PRs

- Work on `dev` and open a pull request into `main`. Keep `dev` fast-forwarded to `main` after each merge.
- Commits follow **Conventional Commits**, enforced by a `commit-msg` hook (commitlint): `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `ci:`, and so on, with an optional scope, for example `feat(web): add the download page`. Use `pnpm commit` for a guided prompt. Keep the subject imperative and under about 72 characters.
- A `pre-commit` hook runs lint-staged (oxlint and prettier on staged files). If it fails, fix the problem and stage again.
- One logical change per commit. Keep PRs reviewable and describe how you tested them.

## Reporting issues

Use the issue templates. For security problems, do not open a public issue; see [SECURITY.md](SECURITY.md). Everyone is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
