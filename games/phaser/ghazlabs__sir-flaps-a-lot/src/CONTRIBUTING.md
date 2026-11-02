# Contributing to Sir Flaps-a-Lot

Thanks for contributing. This project is intentionally structured as a small OSS exercise project, so clarity and focused PRs matter more than large feature drops.

## Prerequisites

- Node.js 20+ recommended
- npm 10+ recommended

## Local Setup

1. Fork the repository.
2. Clone your fork.
3. Install dependencies:

   ```bash
   npm install
   ```

4. Start the local dev server:

   ```bash
   npm run dev
   ```

## Development Commands

- `npm run dev` - start local development server
- `npm run build` - create production build
- `npm run lint` - run lint checks
- `npm run lint:fix` - auto-fix lint issues where possible
- `npm run format:check` - verify code formatting
- `npm run format` - format files
- `npm run test` - run tests

## Branch and Commit Guidelines

- Create branches from `main`.
- Use descriptive names, for example:
  - `fix/collision-bounds`
  - `feat/mute-toggle`
  - `docs/contributing-guide`
- Keep each PR focused on one problem.

## Pull Request Checklist

Before opening a PR, make sure:

- The project builds successfully with `npm run build`.
- Lint and formatting pass (`npm run lint`, `npm run format:check`).
- Tests pass (`npm run test`) for changes that affect tested code.
- README/docs are updated if behavior or workflows changed.
- The PR description clearly states the problem and solution.

## Picking Work

- Check open issues and labels.
- If an issue is not assigned, leave a comment before starting to avoid duplicate work.
- If your scope changes significantly, discuss it in the issue first.

## Triage Labels

- `bug` - something is broken or inconsistent
- `enhancement` - feature or improvement request
- `docs` - documentation-only change
- `good first issue` - beginner-friendly issue
- `help wanted` - maintainers are looking for contributors
- `ci` - automation and pipeline work
- `a11y` - accessibility-focused improvements

## Scope Discipline

- Avoid refactoring unrelated areas in the same PR.
- Keep gameplay changes measurable and easy to review.
- Prefer smaller PRs that can be reviewed quickly.
