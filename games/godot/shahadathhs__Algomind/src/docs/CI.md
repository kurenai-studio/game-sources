# CI/CD, tooling, and releases

> **Status: running.** The pipeline has run end to end on GitHub (see the status paragraph below). It follows the conventions of the DropGrid project. Update this file in the same change as any workflow or tooling change so it always matches the code.

## What runs today

`.github/workflows/ci.yml` is one pipeline. Pull requests run the gates; pushes to `main` continue through deploy, build, and release.

| Job          | Runs for             | What it does                                                                                                                                                                                         |
| ------------ | -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `quality`    | every push and PR    | Design-token drift check, generating the Prisma client and building `level-contract` (the type-aware lint needs both), oxlint (type-aware) and prettier, `tsc` type checks, and all TypeScript tests |
| `api`        | every push and PR    | Applies migrations to an empty PostgreSQL 17 service container, then builds the API                                                                                                                  |
| `web`        | every push and PR    | Production `next build`                                                                                                                                                                              |
| `game`       | every push and PR    | `gdlint` and `gdformat --check`, then headless Godot (in Docker) loads the project and runs the GUT tests, which include every level-contract fixture (copied in by `make game-fixtures`)            |
| `docker`     | every push and PR    | Builds the API and web images, starts the database, API, and web with Compose, checks `/v1/health/ready` and the landing page                                                                        |
| `deploy-api` | `main`               | Calls the Render deploy hook, then polls the Render API until the deploy is live (fails the run if it fails or times out)                                                                            |
| `apk`        | `main` and `v*` tags | Resolves the version, injects the version code and API URL, builds a debug APK in the Godot container, writes a SHA-256, uploads                                                                     |
| `release`    | `main` and `v*` tags | Refreshes the rolling **Latest build** release, calls the Vercel deploy hook, and publishes **Algomind vX.Y.Z** when `VERSION` is new                                                                |

**Status:** the pipeline has run end to end on GitHub. On the first merge to `main` all eight jobs passed, including the APK build and the release. At that time the Render, Vercel, signing-key, and API-URL settings were not configured, so the deploy job took its documented "skip" path and the first APK used a one-off signing key and had no API URL. They are configured now (see the table below), but the automated deploy through the Render and Vercel hooks has not run yet. `VERSION` is now 0.1.0 (loops ship in it), a version with no release, so the next merge to `main` publishes v0.1.0. The workflow passes `actionlint`.

**No credentials in the repository.** The local database password is generated into the git-ignored `.env` by `make env` (Compose refuses to start without it, and the database port is bound to `127.0.0.1`). The CI `api` job uses a throwaway Postgres service container with trust authentication and a passwordless URL; the `docker` job runs `make env` to generate a password. The API requires `DATABASE_URL` and has no default; `make env` also generates the JWT signing key and the seeded admin password into `.env` without printing them, and the CI `docker` job gets them that way. Android's public debug-keystore password (`android`) remains in the Godot container setup because the Android tooling expects it.

## Versions and releases

`VERSION` is the source of truth. Two make targets use `scripts/bump-version.sh`:

```sh
make version v=0.2.0    # write the version into VERSION, the API and web package.json, and the Android preset (no git)
make release v=0.2.0    # the same, then commit and push (you run this; nothing runs it automatically)
```

Both refuse the same version or a lower one. `release` also refuses to run with uncommitted changes, so the release commit contains only the bump. When that commit reaches `main`, the pipeline sees a `VERSION` with no matching release and publishes `v0.2.0` with the APK and its checksum. Rolling builds keep flowing and never take the "latest" flag.

## Principles

- **One command surface.** The `Makefile` is how you run everything locally. CI runs the same commands, so "passes locally" means "passes in CI".
- **Gates before deploys.** Pull requests and every push run the quality gates. Only `main` continues into deploy and release jobs.
- **Fail closed.** A deploy job fails the run if the deployment does not go live. Missing optional secrets produce a visible warning, never a silent skip of something critical.
- **Pinned and reproducible.** Lockfiles are frozen in CI (`pnpm install --frozen-lockfile`), tool versions are pinned, and Dependabot keeps actions and dependencies current.

## Local tooling

| Tool                                  | Purpose                                                                                                                                                                         |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Husky                                 | Git hooks (`pre-commit`, `commit-msg`)                                                                                                                                          |
| lint-staged                           | Lint and format staged files only                                                                                                                                               |
| commitlint                            | Enforce Conventional Commits (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`, `wip`, `release`)                                   |
| commitizen + cz-git                   | Guided commits (`pnpm commit`)                                                                                                                                                  |
| prettier                              | Formatting for TypeScript, JSON, Markdown, YAML                                                                                                                                 |
| oxlint (type-aware)                   | TypeScript linting for every TypeScript app and package. There is no ESLint: TypeScript 7 has no JS compiler API, so typescript-eslint cannot parse it.                         |
| tsc                                   | Type checking in each TypeScript app and package                                                                                                                                |
| Vitest / Playwright                   | Vitest runs the API unit tests (publish gates, authorization, sessions, progress merge). The web app has no tests for now; add smoke tests (Playwright) when a flow needs them. |
| gdlint + gdformat (gdtoolkit, pinned) | GDScript style gate                                                                                                                                                             |
| GUT                                   | Game unit tests, run headless in Docker                                                                                                                                         |
| Prisma                                | Schema validation and migrations                                                                                                                                                |

Hooks live at the repository root and cover the whole repo. Typical `make` targets:

```sh
make lint            # all linters and format checks
make typecheck       # tsc across TypeScript apps/packages
make test            # contract, api, web, and game tests
make game-check      # load the Godot project headless
make api-run         # run the API locally (needs make db-up)
make web-dev         # run the web app
make apk             # export a debug Android build
make release v=0.2.0 # bump VERSION, commit, push
```

## Branching and commits

Work on `dev`, open a pull request into `main`, keep `dev` fast-forwarded to `main` after each merge. Commits follow Conventional Commits and are validated by the `commit-msg` hook.

## Pipeline

One workflow, `.github/workflows/ci.yml`, with `concurrency` per ref, least-privilege `permissions`, and current pinned action versions.

| Job          | Runs for                                                                                                                                                                            | What it does                                                                                                                                                                          |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tokens`     | every push and PR                                                                                                                                                                   | Regenerate the Godot palette and web CSS from `packages/design-tokens`; fail if the generated files differ from the committed ones; fail if a hand-defined color appears outside them |
| `contract`   | every push and PR                                                                                                                                                                   | Lint, typecheck, and test `packages/level-contract` (all fixtures)                                                                                                                    |
| `api`        | every push and PR                                                                                                                                                                   | Lint, typecheck, Prisma validate, migrate a PostgreSQL service container, build                                                                                                       |
| `web`        | every push and PR                                                                                                                                                                   | Lint, typecheck, tests, `next build`                                                                                                                                                  |
| `game`       | every push and PR                                                                                                                                                                   | `gdlint`, `gdformat --check`, headless project load, GUT tests (including every contract fixture)                                                                                     |
| `deploy-api` | `main`                                                                                                                                                                              | Triggers the Render deploy hook, then polls the Render API until live; fails the run on a failed or timed-out deploy                                                                  |
| `apk`        | `main`, `v*` tags                                                                                                                                                                   | Injects version and API URL, builds the Android package, uploads the artifact                                                                                                         |
| `web-export` | planned: PRs prove the web export still builds. Today the export runs inside the `apk` job (`main` and `v*` tags) and is attached to the release as `algomind-web-<version>.tar.gz` |
| `release`    | `main`                                                                                                                                                                              | Refreshes the rolling **Latest build**, triggers the Vercel rebuild hook, and publishes a versioned release when `VERSION` names a version without a release                          |

A normal push to `main`: gates, API deploy, Android and web exports, rolling Latest build, web rebuild. A version bump does all of that plus the versioned release.

## Releases

```sh
make release v=0.2.0   # writes VERSION, updates export presets, commits, pushes
```

When that reaches `main`, the pipeline publishes **Algomind v0.2.0** with the Android build, marked as the latest release. Rolling builds never take the "latest" flag. Releases are idempotent: a version is published once.

## Secrets and variables

| Name                            | Kind     | Used by                                                                                                   |
| ------------------------------- | -------- | --------------------------------------------------------------------------------------------------------- |
| `RENDER_DEPLOY_HOOK_URL`        | secret   | `deploy-api`                                                                                              |
| `RENDER_API_KEY`                | secret   | `deploy-api` (waits for the deploy to be live)                                                            |
| `VERCEL_DEPLOY_HOOK`            | secret   | `release` (rebuild the public site so the download page shows the new release; later also the web export) |
| `ANDROID_DEBUG_KEYSTORE_BASE64` | secret   | `apk` (fixed signing key so builds install over each other)                                               |
| `API_BASE_URL`                  | variable | `apk` (must be `https://…/v1`; the build fails otherwise)                                                 |

Create the signing key with `make -s android-key | gh secret set ANDROID_DEBUG_KEYSTORE_BASE64`: the target prints only the key on stdout (status messages go to stderr), so the pipe is clean. The `apk` job checks the secret before the long build and fails with a clear message if it is not a valid keystore; the decoder tolerates a status line or line endings in front of the key. Changing the secret changes the signing key.

Secrets are never committed. A Google Play release needs a separate upload keystore and an `.aab`; that is outside the initial MVP.

## Dependency updates

Dependabot runs weekly for GitHub Actions and the pnpm workspace. Group action bumps into one pull request.

## Known limits to revisit

- Each run may rebuild the Godot Docker image; add caching if it becomes slow.
- The Render deploy hook deploys the service's latest state; it does not pin a commit.
- The first deployment must verify these workflows; until then treat this document as the design, not a record.
