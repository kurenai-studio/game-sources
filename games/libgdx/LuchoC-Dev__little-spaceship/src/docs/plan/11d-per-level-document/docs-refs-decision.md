# `docs-refs` (#56): measured, and it stays open

**Decides:** task 5 of [phase 11d](plan.md), [#187](https://github.com/LuchoC-Dev/little-spaceship/issues/187).
**Owner:** the coordinator. **Written:** 31/08/2026.

**Nothing here is built.** There is no `tools/docs-refs`, and `ls tools/` returns `agent-memory-path`,
`build-level-docs.js`, `commit-subject-ok`, `hooks`, `install-hooks`, `pre-pr-check` and
`status-fragments`. What follows is a measurement and a decision, not a description of behaviour.

## The decision

**[#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56) stays open, and it is a phase of its
own rather than a task of this one.**

Not because it is hard — the measurement below says the extraction is tractable and a good deal
cheaper than #56 assumed. Because **running it green today requires an audit pass over roughly fifteen
real findings**, and auditing `docs/` against the code is phase 10a's kind of work, not 11d's. Building
the check is an afternoon; the phase is what comes after it turns red.

## Why the question was worth asking rather than assuming

11d's own generator depends on `docs-refs` for its single known weak point. `tools/build-level-docs.js`
quotes constants that live in `core/` — the playfield dimensions, the enemy projectile radius, the six
drop kinds, the boss's velocity ratios — and **regenerating cannot catch a drift there**, because the
output is identical whether or not the Java still says it. Each quoted value names its file in
backticks, and `docs-refs` is what would make that naming load-bearing rather than decorative. So the
phase had a direct interest in the answer being "yes, now".

## The measurement

A prototype extractor was run over the 104 markdown files under `docs/` plus `README.md` and
`CLAUDE.md`, excluding `docs/sources/` — the scope #56 sets. Backticked spans only; fenced blocks were
not included, so these numbers are a lower bound on the work.

| | count |
|---|---|
| backticked spans in scope | 8,988 |
| shaped like a path | 1,937 (474 distinct) |
| shaped like a Java type | 2,218 (466 distinct) |
| neither | 4,833 |

**A naive extractor leaves 271 unresolved. A narrowed one leaves 122.** The difference is entirely in
the extractor, not in an allow-list, which is what #56 asked to be checked:

- resolve a relative link against the containing file's own directory;
- **resolve a path by suffix, not by prefix.** This repository names paths relative to the Java package
  — `core/port/WaveEndCondition.java`, not
  `core/src/main/java/dev/luchoc/littlespaceship/core/port/WaveEndCondition.java` — and that one rule
  alone took the unresolved paths from 155 to 50;
- skip a span containing a glob, a placeholder, whitespace or `...`, the last being this repository's
  own elision convention (`game/.../JsonContentSource.java`);
- skip a branch name by its `type/` prefix;
- require a name before a dot, so `.fnt` and `.atlas` used as nouns are not paths;
- take only `CamelCase` for a type, never `ALLCAPS`, which removes the HUD labels (`LIVES`, `SCORE`)
  and the palette ids (`N0`, `W3`, `C1`) at no cost.

### What the remaining 122 actually are

**72 unresolved types, and almost all of them are one class:** libGDX and JDK names — `Math`, `String`,
`List`, `Map`, `Optional`, `Gdx`, `Pixmap`, `SpriteBatch`, `Skin`, `Stage`, `Table`, `TextureAtlas`,
`BitmapFont`, `JsonReader`, `JsonValue`, `Thread`, `ConcurrentHashMap`, `NullPointerException`. That is
a list of about fifty names, written once. **This is the "short allow-list" #56 set as its bar**, and it
is a genuinely closed set rather than a growing one.

The handful that are not third-party are the interesting ones: `InputSystem`, `Composition`,
`PatternDefinition`, `PowerUpTaken`, `BombFired`, `BossPhaseStarted`, `LevelCleared`. **Those are
phase 10a's own class-A findings**, quoted inside
[`../10a-honest-documentation/audit.md`](../10a-honest-documentation/audit.md) precisely in order to
record that they do not exist.

**50 unresolved paths, in five classes:**

| Class | Examples | Treatment |
|---|---|---|
| extraction, still | `.fnt`, `.atlas`, `2/3`, `playerStartX/Y`, `fx-thrust-a/b`, `actions/checkout` | narrow further; no allow-list entry |
| deliberately naming something deleted | every `spikes/web-viability*`, `patterns.json`, `Composition.java`, `game/screens`, `core/src/test/resources/replays` | **the hard case — see below** |
| build output | `web/build/dist/js/webapp`, `app.js`, `index.html` | real paths that exist only after a build |
| branch names with an unlisted prefix | `content/level-01-waves`, `content/movement-shapes` | extend the prefix list |
| **genuinely stale** | `core-deferred-surface.md`, `content-pipeline-design.md`, `defect-patterns.md`, `review-tooling-and-memory-placement.md`, `boss-l1.json`, `specimen.png`, `game/ui/GameSkin`, `core/build.gradle`, `game/JsonContentSource.loadTrajectories` | **findings** |

That last row is the point: **`docs-refs` would find real rot in `docs/` today**, about fifteen items,
each needing to be chased and corrected one at a time. That is the work, and it is 10a's shape.

## The hard case, which #56 does not solve and should

`docs/plan/10a-honest-documentation/audit.md` and `mechanism.md` quote false references **on purpose**,
because their subject is false references. `docs/STATUS.md` does the same for `spikes/web-viability/`,
by a decision recorded in [`../10a-honest-documentation/decisions.md`](../10a-honest-documentation/decisions.md),
D1: the citations of a deleted directory *"are a dated record of a past phase and stay as written"*.

So the check's failure mode is not a missing name — it is **a document whose job is to name missing
things**. #56 proposes an allow-list file for this. An allow-list keyed on the name is the wrong key:
`Composition.java` is legitimately absent in `audit.md` and would be a genuine finding in
`12-architecture.md`, and one entry covers both. Whoever builds this should decide between a per-file
exemption and an inline marker before writing the extractor, not after.

## The interaction task 1 flagged, answered

[`document-contract.md`](document-contract.md) warned that the generated level documents are dense with
backticked content ids that look like repository references — `enemy-basic`, `l1-veteran-mix`,
`slow-descent`, `weapon-upgrade` — and would fire on every one.

**They do not, and the narrowed extraction is why.** All 25 ids in `assets/data/` were tested against
both shapes: **none matches.** They are lowercase and hyphenated, so they are neither `CamelCase` nor
path-shaped. `docs/levels/level-01.md` contributed exactly one unresolved span to the whole run —
`drops.json`, which the document names in order to say *"there is no `drops.json`"*, and which is
therefore the same hard case as the paragraph above rather than a new one.

The better form the contract suggested — a resolver that accepts an id `assets/data/` defines — remains
worth building, but it is now an improvement rather than a prerequisite.

## What the next person starts from

1. The extraction rules in "The measurement" above. They took the unresolved count from 271 to 122 and
   each one is a rule, not an exception.
2. The allow-list is about fifty third-party names, and it is closed.
3. **Decide the exemption key before writing the extractor** — per-file or inline marker, not per-name.
4. The roughly fifteen genuinely stale references above are the phase's actual content.
5. #56's acceptance test still stands: pointed at the repository as it stood on 26/08/2026 before
   [#51](https://github.com/LuchoC-Dev/little-spaceship/pull/51), it must fail on all eight class-A
   findings in [`../10a-honest-documentation/audit.md`](../10a-honest-documentation/audit.md). A
   worktree at that commit is how to check it, and **it was not run here** — no extractor exists to run.
