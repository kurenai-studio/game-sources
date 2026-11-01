# Phase 10a — the documentation audit

Run on 26/08/2026 by the coordinator session that owns the 10 group. This is the record task 1 and
task 2 of [`plan.md`](plan.md) ask for: **which documents were checked, against what, and what was
found — including the ones that were fine.**

Everything below was checked against the repository at commit `c4b8c70`, with `./gradlew core:test`
run to confirm the one measurement several documents assert (289 tests, 0 failures).

## How a document was judged

Three kinds of statement live in `docs/`, and only one of them can be false in the way this phase
cares about.

| Kind | Example | Can it be false? |
|---|---|---|
| **Descriptive** — says what the code does | "`SystemOrder` holds the ten stages" | **Yes.** This is the phase's subject. |
| **Prescriptive** — says what should be drawn or built | `08-background.md`'s four parallax layers | No. Unbuilt is a gap, not a lie. |
| **Dated record** — says what was true on a date | a phase's "verified, measured" block | Only if it was false when written. |

The distinction matters because without it a status file from August becomes a "finding" every time
the code moves, and the audit produces noise instead of defects.

**One exception, and it is the exception that produced [#5](https://github.com/LuchoC-Dev/little-spaceship/issues/5):**
a dated record that makes a *forward-looking* claim — "this can be re-run whenever the algorithm is
touched", "this remains to be done" — is read by the next person as current. Those are audited as
descriptive, because that is how they are used.

## Coverage

Every markdown file under `docs/`, plus `README.md`, was read. `docs/sources/` is out of scope by the
plan: it is a verbatim transcript kept as evidence.

### `docs/STATUS.md`

| Document | Verdict |
|---|---|
| `STATUS.md` | **F13, F33, F34, F35.** The document a newcomer is told to read first, and the one carrying the most live claims. Most reproduce — the 289 tests, the served byte counts, the phase table, the whole post-MVP backlog. Four do not. |

### `docs/design/` — the visual direction

| Document | Verdict |
|---|---|
| `00-visual-direction.md` | **Fine.** Index and tone. Its one checkable claim — the L\* 44.9 / 48.1 gap — reproduces from `01-palette.md`'s table. |
| `01-palette.md` | **Fine.** All 32 hex values, and the 15 of them declared in `game/.../ui/Palette.java`, agree exactly. |
| `02-sprite-sizes.md` | **F1, F2.** Radii for all six archetypes match `assets/data/enemies.json` exactly. The boss section does not match `BossSystem`. |
| `03-typography.md` | **F3, F4.** Both sheet dimensions verified against the PNGs (96×60, 128×78). Two statements about the loader are false. |
| `04-hud-layout.md` | **F5, F6, F7.** Remarkably accurate: every coordinate, tick count and colour in the plate tables is reproduced literally in `HudRenderer`, and the three invulnerability states in `WorldRenderer`. Three claims do not hold. |
| `05-legibility-rules.md` | **F8.** R1–R3 are enforced by the palette and hold. R11 and R13 describe behaviour that does not exist. |
| `06-boss-presentation.md` | **F2, F9.** The tell — three beats of 0.25 s, which parts charge, the core never charging — is implemented exactly. The collider map and the mock instruction are stale. |
| `07-skin.md` | **F10.** The worst case in the repository, and worse than `STATUS.md` recorded. |
| `08-background.md` | **Fine, and entirely unbuilt.** Prescriptive throughout; `CheckerboardBackground` is still the diagnostic backdrop from the spike. One cross-reference (F11) is wrong. |
| `mockups/README.md` | **F12.** Accurate about the build pipeline. One count is wrong. |

### `docs/planning/` — the design record

| Document | Verdict |
|---|---|
| `00-master-context.md` | **Fine.** Reading order matches the files that exist. |
| `01-vision-and-scope.md` | **F13.** Vision, not code. One statement overtaken by events. |
| `02-mvp-functional-spec.md` | **Fine.** Prescriptive. Every rule spot-checked against code held: the defensive chain, fragile-vs-resistant crash, the additive input scheme, pause as an overlay, the HUD's required items. |
| `03-game-systems.md` | **Fine.** Prescriptive and mostly post-MVP. Its one MVP rule — invulnerability → shield → attachment → life — is `DamageSystem.resolvePlayerHit` line for line. |
| `04-campaign-and-levels.md` | **Fine.** The level 1 provisional sequence has **fourteen** bullets; see F14, which is a defect in a document that quotes it. |
| `05-progression-modes-and-saving.md` | **Fine.** Entirely post-MVP. |
| `06-platform-and-technical-validation.md` | **F13.** A record of pre-measurement reasoning, correctly labelled as such. |
| `07-references-and-asset-constraints.md` | **Fine.** Historical, plus an asset policy the MIT `LICENSE` and the in-house art satisfy. |
| `08-decisions-and-open-items.md` | **F13, F15, F16.** The single most load-bearing document in the repository and it is mostly correct. Three entries have been overtaken. |
| `09-source-map.md` | **Fine.** Traceability into `docs/sources/`. |
| `10-mvp-initial-values.md` | **F17, F18.** Its own rule is "when a value changes after playtesting, it is updated here", and that rule was broken once. Four "exists only in test fixtures" notes are stale. |
| `11-technical-prototype-results.md` | **F19.** A dated measurement record, correct as such. Its "What remains pending" list is forward-looking and stale. |
| `12-architecture.md` | **F20–F26. The largest concentration of drift in the repository**, and the most dangerous, because it is the document a new agent reads to learn the shape of the code. |
| `13-working-with-agents.md` | **F27.** Accurate about cost and session policy. Its roster is wrong, and one of its rationales has been contradicted by the project. |

### `docs/plan/` — the master plan

| Document | Verdict |
|---|---|
| `00-overview.md` | **Fine.** Phase table, lanes and the 10 group all match. |
| `how-to-run-a-phase.md` | **Fine**, and F28 is a gap it leaves rather than a falsehood. |
| `agent-prompts.md` | **Fine.** A template. |
| `beyond-mvp.md` | **Fine.** Sketch. Carries a lost decision — see L2. |
| `post-mvp-roadmap.md` | **F14.** Written yesterday and already misquotes its own source. |
| `01`–`09` `plan.md` | **Fine.** Prescriptive task lists, frozen by design ("the `plan.md` next to it says what to do and does not change to reflect progress"). |
| `01`–`09` `status.md` | **F29, F30.** Dated records, and correct as history. Four of the nine claim a state that is not the state. |
| `10a`/`10b`/`10c` `status.md` | **Fine.** Templates, "not started". |

### Outside `docs/`

| File | Verdict |
|---|---|
| `README.md` | **F31.** Its measurable claims reproduce: 289 tests, the module graph, the build commands, the MIT licence. One caveat is obsolete. |
| `CLAUDE.md` | **F32.** Out of scope to edit here (10b owns it). One claim recorded for that phase. |

---

## Findings

Severity is what a reader loses by believing the document.

- **High** — a reader acts on it and does the wrong work. This is the shape that already cost this project a phase-09 false warning.
- **Medium** — a reader forms a wrong picture of the code.
- **Low** — stale, visibly so, corrected by a glance at the repository.

Disposition is where it gets fixed: **10a** here, **11** the code group, **10b** the agents phase.

### F1 — `02-sprite-sizes.md` says the boss is five entities. It is six. · High · 10a

> "It is built from **five entities** on the `ENEMY` layer, moved together" — and a table giving the
> arms at offset `-44, -18` and `+44, -18`.

`BossSystem` builds **six** parts. `core-keel`, radius 13.0 at offset `0, -27`, closes the 25 px gap
under the core, and the arms moved to `-22`. Both changes are exactly the proposal
`06-boss-presentation.md` made and phase 07 accepted.

This matters more than an arithmetic slip: the document declares itself the frozen footprint that art
is drawn against ("If phase 07 needs different parts it should change them here first, because the
art is drawn against this map"). Phase 07 did the work and did not come back to the map.

### F2 — `06-boss-presentation.md` still presents an accepted change as a proposal · High · 10a

Its "The five colliders do not cover the drawn boss" section ends with **"Proposed, for phase 07 to
accept or replace"**, listing `core-keel` at 13.0 / `0, -27` and the arm move to `-22`. Phase 07
accepted both, verbatim, and `BossSystem`'s class javadoc explains them. The document reads as an
open question that was answered nine days ago, and its own part table above still carries the
pre-decision offsets.

### F3 — `03-typography.md`: "the loader uppercases before drawing" · Medium · 10a

> "A string with lowercase in it is a mistake in the caller, not in the font — the loader uppercases
> before drawing rather than showing a gap."

Nothing uppercases. The only `toUpperCase` in the whole codebase is `HudRenderer.attachmentLabel`,
turning a content id into a plate label. A lowercase string handed to `font-title` draws gaps, which
is precisely the failure mode the sentence claims is prevented.

### F4 — `03-typography.md`: the shadow rule, and the wrong build script · Medium · 10a

> "**Text over the playfield carries a shadow.** One pixel of `N0` at offset `+1, +1`, drawn as a
> second pass before the glyph."

There is no second pass anywhere. Stated as a fact about how text is drawn; it is a rule nobody
implemented.

Separately, the document names `fonts/build-fonts.py` as what produces the fonts. That script exists
and writes `docs/design/fonts/*.png`, but what puts the fonts **into the game** is
`docs/design/fonts/build-fnt.js`, added on 25/08, which emits `assets/fonts/*.fnt` and its page. The
document does not mention it, so following the document produces sheets the game cannot load — the
exact gap that made every screen render in Arial until 25/08.

### F5 — `04-hud-layout.md`'s slot artwork does not exist · Medium · 10a

"What each slot looks like" specifies a ship silhouette with a `C1` engine for a life, a `W4` core
inside an `N6` ring for a bomb, an arc for the shield, a burst for invulnerability. `HudRenderer`
draws flat rectangles with outlines for all four, and inverts the bomb's two colours. The five
`icon-*` sprites are in `assets/atlas/sprites.atlas` and nothing references them.

`STATUS.md` already records the gap, but describes the HUD as "still text-only", which is not right
either: it is rectangles, at the right coordinates, in the right colours.

### F6 — `04-hud-layout.md` asserts a feedback case the renderer deliberately does not build · Medium · 10a

The "Feedback" table lists "Pickup collected at maximum → the score value flashes `W4` for 6 ticks".
`HudRenderer`'s class javadoc explains at length why it is not built: `enemy-tank`'s kill score and
`maxedPickupBonus` are both 500, so the case cannot be told from a kill by diffing `PlayerStatus`.

The code documented the gap honestly. The design document did not, and the table is offered as "the
acceptance criterion … made checkable".

### F7 — `04-hud-layout.md`: "the five screens of the flow", and a parallax that does not exist · Low · 10a

There are seven screens (`MenuScreen`, `ShipSelectScreen`, `OptionsScreen`, `PlayScreen` with its
pause overlay, `VictoryScreen`, `DefeatScreen`, `CreditsScreen`). The same table specifies "the
level's parallax at 30% behind the menu"; there is no parallax anywhere in the project.

### F8 — `05-legibility-rules.md` R11 and R13 describe behaviour that does not exist · Medium · 10a

- **R11.** "Every enemy shot is preceded by a muzzle flash on the shooter, at least 2 ticks before
  the projectile exists." No muzzle flash exists in `core` or `game`. `EnemyWeaponSystem` creates the
  projectile the tick the cooldown reaches zero.
- **R13.** "Projectiles removed by a bomb play a 3-frame dissipation rather than vanishing."
  `BombSystem` marks them for destruction and `CleanupSystem` removes them the same tick.

Both are written in the same present tense as R1–R3, which *are* enforced. A reader has no way to
tell the three that hold from the two that do not.

### F9 — `06-boss-presentation.md` tells the mock to do something it never did · Low · 10a

> "`drawBoss` in `src/03-scenes.js` becomes five `blit` calls at the offsets above instead of the
> primitive stack it holds today."

`boss-core`, `boss-pod` and `boss-arm` were subsequently drawn into `mockups/src/01-sprites.js` — the
same document's "Open, for whoever draws it" section records that correctly — but `drawBoss` is still
the ellipse stack. The combat mock draws a boss that is not the boss that was drawn.

### F10 — `07-skin.md` describes a Skin the game does not use · High · 10a

This is the case `STATUS.md` and the plan both name, and the audit found it is larger than either
recorded.

The document is written as a delivery note — "**What ships**" — for three files under
`docs/design/skin/`. Those three files exist. **Nothing loads them.** `GameSkin.build()` constructs
the whole skin in code from `Pixmap`/`NinePatch`/style objects.

Concretely, none of this is in the game:

- the fourteen drawables (`panel`, `plate`, `button-up`/`over`/`down`/`disabled`, `bar-back`,
  `bar-fill`, `bar-fill-low`, `check-off`, `check-on`, `cursor`, `focus`). `GameSkin` registers
  three: `white`, `n2-panel`, `n1-panel`;
- the five named colours (`label`, `value`, `disabled`, `selected`, `warning`). None is registered;
- the `skin.load(...)` snippet, which is the false warning that reached `docs/STATUS.md` and told
  phase 09 to prepare TeaVM reflection declarations for a call that does not exist;
- "**Keyboard focus is drawn, not implied**" — the `focus` nine-patch. Focus is carried by a `>`
  marker and a 6 px width change, per `STATUS.md`'s UI-pass entry.

**This is the fourth instance of the pattern `STATUS.md` warns about** — art produced under
`docs/design/`, never packaged into `assets/`, with a document saying it shipped. The sprites, the
fonts, the boss art, and now the skin. Unlike the first three it is not a defect to fix: the
in-code skin is a deliberate choice with a written justification in `GameSkin`'s javadoc. What is
wrong is only the document.

The document's own internal numbers also disagree: it says `skin.png` is 128 × 19 (which the file
is), while `build-skin.py`'s docstring says 128 × 64.

### F11 — the "fourteen-beat sequence" cross-reference · Low · 10a

`08-background.md` attributes the fourteen-beat sequence to `04-campaign-and-levels.md`, which is
right, and then maps it onto four background sections that do not exist. The count is correct; see
F14 for the document that gets it wrong.

### F12 — `mockups/README.md`: "the six screens of the MVP flow" · Low · 10a

`screens.html` draws six (menu, ship, options, pause, victory, defeat). The MVP flow has seven —
credits, which `10-mvp-initial-values.md` requires and `CreditsScreen` implements, is missing from
the mock. The sentence is accurate about the page and wrong about the flow.

### F13 — "the repository will be private" · Medium · 10a

Four documents say it and the repository has been **public** since 25/08 (`gh repo view`:
`"visibility": "PUBLIC"`).

| Where | What it says |
|---|---|
| `docs/STATUS.md` | "Repository: … — private." — flatly false, in the document a newcomer reads first |
| `08-decisions-and-open-items.md` | "The repository stays private initially" — listed under **Confirmed decisions**, with no resolution |
| `01-vision-and-scope.md` | "The repository will be private during the initial stage" |
| `06-platform-and-technical-validation.md` | "The repository will be private during initial development" |

The last two are dated plans and only need the outcome recorded. `STATUS.md` is a live description
and is simply wrong.

### F14 — `post-mvp-roadmap.md` misquotes the sequence it is built on · Medium · 10a

The roadmap quotes `04-campaign-and-levels.md` as listing "level 1 as **thirteen** beats" and then
prints thirteen. The source lists **fourteen**; the roadmap dropped "Audiovisual introduction".

Written on 25/08, wrong on 26/08. It matters because phase 11's first task is to rebuild level 1's
92 rows into waves *from this list*, and `08-decisions-and-open-items.md` and `08-background.md`
both say fourteen. Two counts of the same sequence is how the flattening happened the first time.

### F15 — `08-decisions-and-open-items.md`: "nothing but the boss shoots today" · Low · 10a

The 22/08 decision entry describes the state that motivated the decision, and that state is gone:
four archetypes carry a `weapon` component and `enemy-shooter` no longer "reads as a larger, slower
basic". As a dated entry it is defensible; as the paragraph a reader lands on when checking whether
enemies shoot, it is not.

### F16 — `08-decisions-and-open-items.md`: two resolved items still open · Low · 10a

- "**Technical items to verify:** Real compatibility in Firefox, Edge and Safari; Chrome already
  verified." Firefox was verified by hand on 25/08 and Edge was dropped by the player's decision.
- The completion-bonus entry ends "a pure function with no caller yet … (phase 07)". Phase 07
  happened; `WorldView.completionBonus()` is part of the read-only contract.

### F17 — `10-mvp-initial-values.md` records a boss value that changed · Medium · 10a

It lists `patternCooldown 1.3`. `level-01.json` carries **0.7**, changed on 25/08 to make the boss's
attack cycle 1.45 s against its fixed 0.75 s tell — recorded in `STATUS.md` and nowhere here.

The document opens with "When a value changes after playtesting, it is updated here." This is the
one value that changed after playtesting, and it is the one that was not updated.

### F18 — `10-mvp-initial-values.md`: "exists only in test fixtures", four times · Medium · 10a

Four separate "Open, not decided" notes say a placeholder "exists only in test fixtures — there is no
production `BalanceValues` implementation yet for them to live in instead". `JsonBalanceValues` and
`assets/data/balance.json` have existed since phase 05 and carry every one of them: `playerSpeed`
140, `playerSlowFactor` 0.45, `playerStartX/Y` 104/30, `weaponProjectileDamage` 10, `bombDamage` 50,
plus the four weapon and pickup values.

The values are still open, which is the point the notes are making. The reason given for them being
open is no longer true, and it is the half a reader would act on.

### F19 — `11-technical-prototype-results.md`: "What remains pending" · Low · 10a

Three of its four items are closed: Firefox verified and Edge dropped (25/08); audio under the
browser's interaction policy confirmed by the shipped build; measurement with real assets done in
phase 09 (2.5 MB artifact, ~298 KB gzipped `app.js`). Only pointer capture remains, and it is now
[#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41) — a defect, not an unknown.

### F20 — `12-architecture.md` lists the wrong system order · **High** · 10a

The document prints ten systems in a numbered list. `SystemOrder` declares **fourteen** stages, in a
different order:

| `12-architecture.md` | `SystemOrder` |
|---|---|
| 1 InputSystem · 2 MotionSystem · 3 WeaponSystem · 4 SpawnSystem · 5 LifetimeSystem · 6 CollisionSystem · 7 DamageSystem · 8 PickupSystem · 9 ScoreSystem · 10 CleanupSystem | INPUT · MOTION · WEAPON · **BOMB** · SPAWN · **SPAWNER** · **ENEMY_WEAPON** · **BOSS** · LIFETIME · COLLISION · DAMAGE · PICKUP · SCORE · CLEANUP |

Four stages are missing, and `LIFETIME` has moved from fifth to ninth.

**This is the highest-severity finding in the audit.** Invariant 5 of `CLAUDE.md` says the execution
order *is a game rule*. `SystemOrder`'s own javadoc explains, at length, why `BOMB` must run before
`COLLISION` and what breaks if it does not. A reader who takes the architecture document as the order
has been handed a wrong game rule by the document whose job is to teach the architecture.

(`InputSystem` is also not a class; `INPUT` is a declared stage with no system in it, which
`SystemOrder` says is intentional — "Stages with no system yet are simply skipped".)

### F21 — `12-architecture.md` names six events that do not exist · Medium · 10a

> "core emits: `EnemyDestroyed`, `PlayerHit`, `PowerUpTaken`, `BombFired`, `AttachmentLost`,
> `BossPhaseStarted`, `LevelCleared`"

`core/domain/event/` contains `GameEvent`, `GameEventQueue` and `EnemyDestroyed`. The other six were
never built, deliberately — `docs/plan/01-foundations/status.md` records the decision ("Inventing
their fields before a system emits them would be guessing"). The architecture document was never
updated to match, so it advertises an event API six-sevenths of which is fiction.

### F22 — `12-architecture.md`'s component table is wrong in three ways · Medium · 10a

It lists `Lifetime` ("remaining duration, for projectiles"), which does not exist — `LifetimeSystem`
expires projectiles by position, not by a component. It omits `BombState` and `EnemyWeapon`, both
real. `Collider` is described as "radius and collision layer"; it also carries `fragile`, which is
what decides whether ramming destroys an enemy — a game rule from `02-mvp-functional-spec.md`.

### F23 — `12-architecture.md` points at files that are not there · Medium · 10a

- `assets/data/patterns.json` — never created. Shot patterns are a field on the weapon component.
  `attachments.json`, which does exist, is missing from the same list.
- `game/…/Composition.java`, "composition root" — no such file. Composition happens in
  `LittleSpaceshipGame` and `PlayScreen`.
- `game/screens/` — the package is `game/screen/`, singular. Repeated in "Conventions".

### F24 — `12-architecture.md` describes a replay format that was never built · Medium · 10a

> ```
> core/src/test/resources/replays/
>   level-01-victory.replay
>   level-01-defeat.replay
>   attachment-absorbs.replay
> ```

`core/src/test/resources/` does not exist. Replays are Java tests (`BombReplayTest`,
`BossReplayTest`, `DamageReplayTest`, `LevelScoreReplayTest`, `SpawnerReplayTest`) that build their
input in code.

Worth flagging beyond the file paths: the document says a replay "compares the final state against
the expected one", and [#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44) exists because
most of them compare a run against *itself*. The description is of the thing the 11 group is going to
have to build.

### F25 — `12-architecture.md`'s port signatures are out of date · Low · 10a

`ContentSource` is shown with three methods; it has eight (`trajectory`, `formation`, `attachment`,
`hasBoss`, `boss` were added by phases 04 and 07). `WorldView` is shown with `boss()`; the method is
`bossStatus()`, and `outcome()` and `completionBonus()` are missing. `SpriteVisitor.accept` is
reproduced exactly.

### F26 — `12-architecture.md`'s enemy JSON example never matched · Low · 10a

The illustrative archetype uses `"id": "tank"`, `"motion": {"speed": 18, …}` and
`"collider": {"radius": 7, "layer": "enemy"}`. The real file uses `enemy-tank`, a motion component
carrying only a trajectory, radius 10.5 and no `layer` key. Illustrative, but it is the only JSON
schema in the documentation and it does not load.

### F27 — `13-working-with-agents.md`'s roster is missing an agent, and denies it exists · Medium · 10b

The roster table lists five agents plus the boss. `.claude/agents/` holds **six**: `level-designer`
is absent from the table, while `CLAUDE.md` lists it and gives it `assets/data/level-*.json`.

The same document then explains, under "**Why there is no content agent**", that one was "considered
and discarded" because content "is touched rarely and with small changes … it is done by whoever is
working at the time". A content agent was subsequently created and wrote level 1.

Recorded for 10b rather than fixed here: 10b owns the agent definitions, and the right correction
depends on what that phase decides about the roster.

### F28 — `how-to-run-a-phase.md` never says to close the status file · Medium · 10a

The cycle is `issue → branch → work → PR → reviewer → merge → status`, and "Status" means *update it
on the branch, before the PR is reviewed*. Then: "**Afterwards**, update the phase table in
`docs/STATUS.md`."

So the last write to a phase's `status.md` happens **before** the merge, and the only post-merge step
touches `STATUS.md`. That is not a slip in any one phase — it is the process guaranteeing the two
stores diverge, and F29 is the result.

### F29 — four phase status files claim a state that is not the state · **High** · 10a

`STATUS.md`'s phase table says 01–09 are all done or merged. `CLAUDE.md` says a phase's `status.md`
is where the work stands. They disagree:

| Phase | `status.md` says | Reality |
|---|---|---|
| 02 | `in review` | merged in #10 |
| 05 | `implemented, pending re-review` | merged in #22 |
| 08 | `tasks 1-4 done, task 5 partially done (see Blocked)` | merged in #31 |
| 09 | **`in progress`** | done; the MVP shipped and the game is live |

Phase 09's is the one that would mislead. Its "In progress", "Notes for whoever comes next" and
"Tasks 4-6 remain" sections are all written as live instructions, and they include:

- "the link itself is still a 404 as of this writing" — it returns 200 and has since 25/08;
- "Whoever merges PR #38 should confirm … serves a 200 afterwards" — done, and recorded in
  `STATUS.md`;
- "task 8 needs the merge-time check above before it can be called done" — it passed.

### F30 — `07-boss/status.md`: "**`enemy-shooter` does not shoot**" · Medium · 10a

Under "A gap this lane did not close": "no archetype in `enemies.json` declares a `"weapon"`
component, so the behaviour is still absent from the game", and beat 9 of the sequence "currently
reads as a larger, slower basic worth more points".

All four intended archetypes have carried a `weapon` component since 25/08. The stretch this note
says "will need rewriting" is the same stretch the 11 group is about to rewrite, so the note will be
read.

### F31 — `README.md`'s deploy caveat · Low · 10a

> "The deploy is the last step of the current milestone. If the link does not resolve yet, the game
> still builds and runs locally."

The deploy happened. Everything else in the README reproduces: 289 tests (run, 0 failures), the
module graph, both Gradle commands, the MIT licence, the browser matrix.

### F32 — `CLAUDE.md`: "each with persistent memory under `.claude/agent-memory/`" · Low · 10b

Six agent definitions, five memory directories. `test-engineer` has none. Recorded for 10b, which
owns that file.

### F33 — `docs/STATUS.md` says `core` carries 236 tests · Low · 10a

It says 289 in one place, in the phase-09 section, and 236 in the repository inventory eight lines
from the top. `./gradlew core:test` on 26/08: **289 tests, 0 failures**. The inventory line is the
one a newcomer reads.

### F34 — `docs/STATUS.md` miscounts the content · Low · 10a

"six archetypes, four trajectories, **three** formations and one timeline". `formations.json` holds
**eight** (`single`, `line-3`, `line-5`, `column-3`, `diagonal`, `diagonal-mirror`, `vee-5`, `pair`),
and the list omits `attachments.json` and the boss carried inside `level-01.json`. Six archetypes and
four trajectories are right.

### F35 — `docs/STATUS.md`: "`web/` is still an empty skeleton; phase 09 owns it" · Medium · 10a

`web/` carries `WebLauncher` and the TeaVM build that produces the site the same document links to
twice. The same sentence describes `game/` as carrying "placeholder art at the sizes the visual
direction fixed", which stopped being true on 25/08 when the real atlas and the real bitmap fonts
landed.

---

## Findings for the 11 group

The plan says: where a document is right and the code is wrong, that is a finding for the 11 group.
Three came out of this audit, none of them new work this phase may do.

| # | What | Where |
|---|---|---|
| C1 | The five `icon-*` sprites exist in the atlas and `HudRenderer` draws rectangles instead (F5). `STATUS.md` already carries it; recorded here with the correction that the HUD is not "text-only". | `game/adapter/render/HudRenderer.java` |
| C2 | `WorldRenderer`'s class javadoc says the real boss art "lives on `feat/sprite-production`, not merged here". That branch merged as #30 on 25/08. A comment, so out of scope for a documentation phase and out of scope for the 10 group entirely. | `game/adapter/render/WorldRenderer.java` |
| C3 | R11 (muzzle flash) and R13 (bomb dissipation) from `05-legibility-rules.md` are unbuilt (F8). Whether to build them or demote them to "not in the MVP" is a design call the 11 group makes with the game in hand. | `05-legibility-rules.md`, `core`, `game` |

---

## Task 2 — decisions that got lost

A decision is *lost* here if it was made, is still valid, and is not visible from the place the work
that depends on it happens. The plan names four; the audit found a fifth and demoted one.

### L1 — level 1's fourteen designed beats, flattened into 92 anonymous rows

**Decided** in `04-campaign-and-levels.md` ("Provisional sequence"), with progression, a deliberate
rest before the climax, and a reward tied to a specific encounter. **Where the work happens:**
`assets/data/level-01.json`, 92 spawn events each carrying an absolute time, an archetype, a
formation and an x. Nothing in the file names a beat.

Not entirely lost — `docs/plan/07-boss/status.md` records the per-stretch intention in prose, and
`10-mvp-initial-values.md` maps the pacing table onto real timestamps. But neither is reachable from
the file being edited, and the roadmap already miscounted the beats (F14) while planning the work
that depends on them.

**Surfaced by:** correcting F14 so the roadmap and its source agree, and a header comment is not
available in JSON. The durable fix is the 11 group's wave format, which is exactly the task this
decision was lost from.

### L2 — "if a new level is mostly JSON, the architecture worked"

**Decided** in `beyond-mvp.md`, as the acceptance test for the whole content pipeline. **Where the
work happens:** phase 12 builds levels 2 and 3.

Already recovered: `post-mvp-roadmap.md`'s phase 12 section now states it as "an acceptance criterion
rather than a hope". Recorded here as resolved, not as an open finding.

### L3 — the campaign's five stages, nearly re-planned from scratch

**Decided** in `04-campaign-and-levels.md`, with each stage's narrative function, setting and
escalation. `01-palette.md` and `00-visual-direction.md` both build on it — the palette was
deliberately sized for five stages and Level 1 uses less than half of it.

Already recovered: `post-mvp-roadmap.md` opens with "Scope: stage 1 only" and points at the document.
Recorded as resolved.

### L4 — the intensity curve, and the tool for it

**Decided** as a design method in `03-game-systems.md` ("Each level should be designed with a
relative curve of pressure over time") and carried as a non-blocking open item in `STATUS.md` and
`08-decisions-and-open-items.md` since planning. **Where the work happens:** the 11 group's wave
work and phase 12's two new levels.

Still open, and correctly so — but it is carried as an *open item* in two places rather than as an
input to the phase that will need it. `post-mvp-roadmap.md` mentions it in one line at the end of the
phase-11 section ("Also open from before"). That is the right place; nothing more is needed.

### L5 — the boss footprint contract, lost in the other direction · **new**

`02-sprite-sizes.md` says, in bold: "If phase 07 needs different parts it should change them here
first, because the art is drawn against this map." Phase 07 needed different parts, changed them in
the code, and left the map behind (F1, F2).

This is a decision about *process* that was made, is still valid, and got lost the first time it was
tested. It is the same shape as the documentation drift this phase exists to fix, and it is the
strongest single argument for the mechanism task 5 chooses: the contract was written in prose, in a
document nobody had to open to do the work.

**Surfaced by:** correcting F1 and F2, and by the mechanism in
[`mechanism.md`](mechanism.md), whose whole point is to make a document naming code fail loudly when
that code moves.
