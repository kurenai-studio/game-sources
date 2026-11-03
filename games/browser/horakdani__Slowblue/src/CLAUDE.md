# Slowblue — working notes for Claude

A finished mobile-first Canvas 2D game: seven acts, forty-two authored stations, one
sentence holding all of them — *you do not control the fish, you control the ocean.*
[README.md](README.md) is the pitch, [docs/GAME.md](docs/GAME.md) the design and
[docs/DEVELOPING.md](docs/DEVELOPING.md) the way in; this file is how to work on it without
breaking things that were already decided or re-learning things that were already measured.

**Talk to Daniel in Hungarian. Write code, comments and commit messages in English.**

## Shape of the thing

TypeScript + Vite, no framework. Canvas 2D (`src/render/`, no WebGL), procedural Web Audio
(`src/audio/`), Pointer Events, fixed 1/60 s simulation step (`src/core/GameLoop.ts`),
53k lines in `src/`, 788 unit tests, PWA with an offline service worker.

**The campaign has been rebuilt: 432 sections and 144 authored minutes, from 182 and 72.**
Six acts of about twenty-two minutes and act I frozen at ten, because it is the metronome
the other six are heard against. Read [docs/DESIGN-LENGTH.md](docs/DESIGN-LENGTH.md) before
touching any level file: it is the measurement, the three passes act V went through as the
pilot, what the phone said about each of them, and the three instruments that keep this
honest —
`tools/stations.sweep.ts` (what a station is made of, arithmetic, instant),
`tools/length.sweep.ts` (how hard an act is, by flying it, half an hour) and
`tools/rush.sweep.ts` (how much faster than the world a hand can go, and what that costs;
`SLOWBLUE_ACT=reentry` for one act in two minutes). Do not hand-maintain a table of act
lengths again; all three print one.

**Nobody has played any of it.** Six of the seven acts were rebuilt in one afternoon and
verified by tests, and tests answer *can this be flown* and *does it obey the rules* - not
whether act III still feels like patience or whether act II is still the act this repo is
proudest of. `docs/DESIGN-LENGTH.md` §12 is the watch list, in the order a playthrough
meets it.

**The rules a station obeys are `tests/stations.test.ts` now**, campaign-wide. They were
measured on act V and lived in `tests/reentry.test.ts`, where they guarded one act; six acts
are built to them, so a rule that only holds act V is a rule five acts can break silently.
Act I is exempt from two of them **on purpose** - it is 1.4-to-2.0-minute stations where a
rebuilt one is 2.5 to 5.5, and a rule learned at one scale is not automatically true at the
other.

**Every bot in this repo was a *careful* hand until 2026-08-14, and it made the whole suite
blind.** Each one gated its forward stroke on `behindFraction > 0.5..0.62` — it stopped
pushing at the camera's anchor — and `World.step`'s camera follow pins the swarm at exactly
that anchor for anyone who pushes, so the gate was unconditionally true and had never once
fired. A player reported descending far faster than the world and never being able to die;
nothing in 800 tests could see it. `makeAimBot({ rush: true })` and `{ brake: true }` exist
now. **When a report cannot be reproduced by any probe here, suspect the probe.**

**There is no network code in this project, and there never will be.** Nothing is uploaded,
nothing is fetched. `package.json` has **zero runtime dependencies**, and that is a rule
rather than an accident: adding one is a decision to argue for, not a convenience.

## Commands

```bash
npm run dev        # dev server on all interfaces — reachable from a phone on the LAN
npm run verify     # lint + typecheck + unit + build + e2e — the project's gate
npm test           # unit only, fast
npm run screens    # the eleven documentation frames
npm run sweep      # balance sweeps; the only thing that may justify a tuning number
```

## Traps — measured, not guessed

**The e2e port.** 4173 is occupied on Daniel's machine. Always
`SLOWBLUE_E2E_PORT=4271 npm run e2e`, and build first — without it the suite silently runs
against whatever was already on the port and dies in five-minute timeouts.

**`npm run verify` is not green on `main`.** Three e2e tests fail at baseline, measured
2026-08-11 against `899b187` in a clean detached worktree with no session work in it:
`chrome.spec.ts:603`, `chrome.spec.ts:962`, `measure.spec.ts:213`. 66 pass; unit, lint,
typecheck and build are fully green. **A red e2e run is not by itself evidence that you
broke something** — check the failing set against those three first. All three are
DOM/shell/ident tests; none of them touches the renderer or the simulation. The baseline
was written before the act I visual merge and asked to be re-confirmed after it; that is
done — re-measured 2026-08-11 on `feat/ios` (66 passed, 12.9 min), same three, same lines.

**Check them by name, not by line.** Re-measured 2026-08-14 after the act V rebuild: same
three, 72 pass, 12.5 min — but the second one had moved to `chrome.spec.ts:1020` as the
file grew, which for a minute looked like a different failure. The names are `every
screen: what can be read, and what can be hit`, `the pinned primary clears the cutout and
lets go at the end of the column`, and `startup › reports what the first launch costs
before the title screen`. Re-measured again 2026-08-14 after act V's second pass: same
three, same names, 74 pass, 12.7 min. Re-measured a last time 2026-11-02, after the dev toolchain moved to vitest 5 and the
admin surface was translated: same three, same names, 74 pass, 13.3 min, and again the same day once the output
level had its own spec: 75 pass, 13.4 min.

**The screenshots are not deterministic.** `npm run screens` rewrites all eleven PNGs on
every run, so a dirty `git status` proves nothing. Commit them only when you meant to.

**Another Claude may be on this tree.** Sessions run in parallel here. Check a file's mtime
before writing it if you were not the last one to touch it.

**This is a public repository.** Nothing that reaches a commit here is private, and git
history is hard to scrub — so no keys, no personal identifiers, no paths out of someone's
home directory. There is nothing to sign and no secret the build needs: the deploy is a
static `dist/` pushed to a branch, and it asks for nothing but a push.

**`main` is the only branch** that holds work, and it is the default branch. `gh-pages`
is build output and nothing else: `npm run deploy` replaces it with one orphan commit, so
never commit to it and never merge it anywhere.

## Decided — do not reopen these

* **No post-processing.** Bloom, glow and grain were built, hated and reverted. Fix a
  picture with composition, not a filter.
* **The visual language:** hard flat vector, discrete depth planes (not a continuum, not
  haze), outline only on large silhouettes, teal plus **one** warm second colour per
  station, and no fast foreground plane — that was built and rejected.
* **The failure system stays** as it is: the hunter, the 40 % swarm floor, the Game Over
  screen. The cozy criterion is read on the mood, not on the mechanics.
* **`blue-rise` is never regenerated.** It is the one signed picture; the other forty-one
  stations are measured against it.
* **`touch-action: none` is deliberately absent from `<body>`** — it intersects on the
  ancestor chain and killed scrolling in the shell. The canvas declares it itself.
* **The `tide.*` storage prefix stays**, even though the game is called Slowblue. Renaming
  it silently discards every existing player profile.
* **The web is the only target, decided 2026-10-26.** The Capacitor/iOS shell that was
  built in August is gone from this repo, along with the three runtime dependencies it
  needed and the store copy written for it. What replaces it is the thing that was
  underneath all along: an installable PWA, open source under MIT, served by GitHub
  Pages from the `gh-pages` branch. There is no deploy workflow and no CI, because
  pushing anything under `.github/workflows/` needs an OAuth scope this repo was created
  without; `npm run deploy` (`tools/deploy.sh`) is the deploy, run by hand, so a change
  to `main` is not live until someone runs it. Two consequences worth keeping in
  mind - the build must survive being served under a path (see `vite.config.ts`), and
  the haptics driver seam in `platform/Haptics.ts` now has exactly one driver behind it.
  The seam stays: it is what keeps the cue table the only way the game buzzes.

## House style

Comments here explain **why**, and often name the wrong solution that was already tried —
that is what makes them worth reading twice. Write that kind, not the kind that restates
the line below it.

Where a measurement can decide instead of taste, **measure**. That is the habit of this
repo, and `e2e/measure.spec.ts` exists to hold the numbers.

The hot path allocates nothing: no `new`, no `.map()`, no `.filter()` inside `tick` or
`render`. Pool instead.

Commit subjects are English sentences that name one concrete thing, in the repo's own
voice — read `git log` before writing one. Commit only when asked, and never push.
