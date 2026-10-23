# Contributing to Breakout

Thanks for contributing! Please keep the project small and readable — that is
its whole point.

## Branching model

```
main  ─────────────  protected; only maintainers push / merge
  └── dev ──────────  team integration branch
         └── feat/xyz ─  short-lived branch; merged via PR
```

- `main` is **protected**: no direct pushes (except maintainers). All changes
  land through a pull request.
- Create branches from `dev`, not from `main`.
- Branch names: `feat/<description>`, `fix/<description>`, `docs/<description>`.

## Workflow

1. Create a branch from `dev`:
   ```bash
   git checkout dev
   git pull
   git checkout -b feat/my-feature
   ```
2. Make your changes and commit with a clear message.
3. Push and open a pull request into `dev` (or `main` if you are a maintainer
   closing a release).
4. A maintainer reviews; address feedback; the maintainer merges.

## Commit conventions

Use the [Conventional Commits](https://www.conventionalcommits.org/) style:

```
feat: add ball speed scaling per level
fix: keep ball inside the right wall
docs: explain the state machine
refactor: extract collision helpers
```

## Code conventions

- One class per file, filename lowercase (`ball.lua`).
- Use the metatable OOP pattern documented in `docs/oop-in-lua.md`.
- All time-dependent logic receives `dt`; never hard-code per-frame values.
- Never put logic inside `draw()`.
- Run `luac -p` on every Lua file before committing.

## Before opening a PR

- [ ] `luac -p` passes on all `.lua` files.
- [ ] `love .` runs without errors.
- [ ] Code follows the conventions above.
- [ ] Docs are updated if behavior or structure changed.