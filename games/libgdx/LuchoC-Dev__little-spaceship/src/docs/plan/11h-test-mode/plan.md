# Phase 11h — A test mode, so a wave can be looked at without playing to it

**Lane:** presentation + content · **Owner:** `game-presentation` for the build flavour and the menu, `level-designer` for the scenarios · **Depends on:** 11e (level 1 as it now stands) and 11g (the level signed off by playing)

**Not in `post-mvp-roadmap.md`.** Opened on 03/09/2026 by the project owner, as the first half of a decision taken in conversation the same day: level 1 gets more depth through movement and grouping, and **the tool comes first**, because every iteration of that work has to be judged by playing and today judging one wave costs playing the whole level up to it.

## Before you start

**Read, in this order:**

1. Your task's issue in full.
2. `docs/plan/11e-level-one-redesigned/status.md` and `docs/plan/11g-shield-and-test-harness/status.md` — level 1 as it is and why it is that way. It was signed off by the project owner across four play sessions on 01/09 and 02/09.
3. `docs/levels/level-01.md` — generated, and the most accurate picture of the level that exists.
4. `CLAUDE.md`, in particular **"Running the game is not playing it"** in [`../how-to-run-a-phase.md`](../how-to-run-a-phase.md). **This phase does not relax that rule, and it is the phase most likely to look as though it does.** Building a tool that makes a wave reachable in five seconds is not permission to go and play it. An agent writes the scenario; the project owner plays it.
5. Your agent memory.

## Goal

**The project owner can open one wave, or the boss, from the main menu — and the build that ships contains none of it.**

## The shape of the thing, as the project owner defined it

- A fourth entry, **TESTS**, in the main menu beside PLAY / OPTIONS / QUIT. It opens a submenu of named scenarios, and choosing one starts the game in that situation.
- **It is a build flavour, not a hidden entry.** `./gradlew :desktop:run -Ptests` has the menu; `./gradlew :desktop:run` does not, and neither does anything that reaches `main`. There is no secret combination to find, because there is nothing in the shipped build to find.
- **Desktop only in practice.** The web target is not excluded by a rule; nobody will run the test flavour against it.
- **What state the player starts in is the scenario's own decision.** Testing the boss and testing wave 4 do not want the same starting weapon.

## What a scenario already is

**A scenario is a level file, and the format needs nothing added.** `assets/data/level-01.json` is `{ "boss": {...}, "waves": [...] }` and nothing else — `game/adapter/content/JsonContentSource.java:349`, `requireOnlyKeys(root, "level file", "boss", "events", "waves")`. A file that lists one wave placement and no boss *is* "start at that wave"; a file with a boss block and `entersAt` near zero *is* "start at the boss".

Which level runs is `game/LittleSpaceshipGame.java:42`, `private static final String LEVEL_ID = "level-01"`, read through `levelId()` — which `game/screen/PlayScreen.java:111` and `:116` already call. **The seam is one field**, and its own javadoc says so: *"the day a level-select flow exists, this field is the one place that changes"*.

**Two precedents in this repository already do each half of this, and neither is being invented here:**

- **A source set the shipped build cannot see.** `game/build.gradle.kts` puts `tools.audio` in its own `tools` source set precisely because *"TeaVM compiles every class reachable from `main`"*. That comment is the argument for where the test-mode classes go.
- **A Gradle property selecting a build flavour.** `web/build.gradle.kts` reads `providers.gradleProperty("release")` to pick optimisation and obfuscation. `-Ptests` is the same mechanism.

Whether those are the right answers is task 1's to decide and argue. They are a starting opinion, written here so nobody re-derives them.

## Tasks

1. **The test flavour and the TESTS menu.** `game-presentation`.

   A Gradle property produces a desktop build with a TESTS entry in `MenuScreen`, opening a submenu that lists the scenarios and launches the chosen one. Without the property, `MenuScreen` is exactly what it is today.

   **The criterion that matters is not that the entry is hidden — it is that the code is absent.** A boolean checked at runtime leaves the test screens compiled into the shipped `app.js`, and that is the failure mode to design against. Say how you know, by observation: name the command and what it printed.

   Follow `MenuEntries`, `MenuNavigator` and `BaseUiScreen` as the existing screens do. This is one more menu, not a new UI framework.

2. **The scenarios.** `level-designer`, on `assets/data/`.

   Four to start, chosen to exercise the mechanism rather than to enumerate the level:

   | Scenario | What it is | Why this one |
   |---|---|---|
   | Wave 4 | `l1-combined-formations`, 33.0–46.0 s | the first density spike, 1.77/s, and where the `shield` falls |
   | Wave 9 | `l1-high-pressure`, 88.0–99.0 s | 1.91/s with four archetypes at once |
   | Wave 12 | `l1-final-escalation`, 119.5–134.5 s | the escalation, 2.13/s, the only wave using all five archetypes |
   | The boss | `boss-l1` | the case the project owner named, and 134.5 s of level saved every time it is used |

   **Three waves and the boss on purpose.** The three waves prove the jump works across the level's range; the boss proves the starting state is configurable, which is the other half of the format and the half that can rot without anyone noticing.

   **A starting weapon level is a design decision per scenario, not a default.** Wave 12 played with the level-1 weapon is not the wave the project owner signed off. State what each scenario assumes and why. If the level format cannot express it, say so and say what it would take — **do not invent a key**; `JsonContentSource` rejects any key its schema does not name, so an invented one is a level that fails to load rather than a key quietly ignored.

3. **The record.** The coordinator's, at close.

   The decision — a test build flavour, scenarios as level files — goes into `docs/planning/08-decisions-and-open-items.md`, dated. It is a decision about how this project is worked on, and the next phase depends on it.

## Acceptance criteria

- **`./gradlew :desktop:run -Ptests` shows TESTS in the main menu**, and each of the four scenarios starts the game in its situation. **Verified by the project owner playing it** — that is what the phase is for, and no agent's claim substitutes for it.
- **`./gradlew build` is green**, and the ordinary desktop build shows no TESTS entry.
- **The shipped build does not contain the test-mode code.** Observed, not asserted: name the command and quote its output.
- **Each scenario says, in writing, what starting state it assumes and why**, in that task's status fragment.
- **`docs/levels/level-01.md` still regenerates identically** — `node tools/build-level-docs.js`, and the check in `.github/workflows/ci.yml`. If a test scenario is a level file under `assets/data/`, check what the generator does with it before assuming it ignores it.
- The decision is recorded in `docs/planning/08-decisions-and-open-items.md`.

## What is out of scope

- **Changing level 1.** Not one wave, not one number. The project owner signed it off on 01/09 and 02/09 across four sessions. **That is phase 11i's work**, and this phase exists to make it cheaper, not to start it.
- **The boss.** Explicitly the minimum the project owner will allow to move, decided 03/09/2026. A scenario that starts at the boss changes nothing about the boss.
- **New enemy archetypes.** Refused by the project owner on 03/09/2026; existing ones may be modified, in 11i.
- **Obstacles.** Postponed until the story and the final background exist. Decided 03/09/2026.
- **The web target.** Not a rule, a priority. If the flavour happens to work there, that is a note, not a deliverable.
- **A level-select flow for players.** This is a development tool. Level 2 does not exist.
- **Replays, or recording a session.** A different tool answering a different question.

## Risks

**Building a menu instead of a tool.** The measure of this phase is whether 11i's iterations get cheaper, and that is measured by the project owner using it, not by the entry existing.

**Test-mode code reaching the published build.** The whole reason for a flavour rather than a flag. The acceptance criterion asks for an observation because this is the one failure nobody would notice until a stranger found it.

**Scenarios that do not represent the level.** A wave played from a cold start, with the wrong weapon and no accumulated damage, is a *different* encounter from the same wave at minute two. That is acceptable and it is the point — as long as each scenario says what it assumes. A scenario that quietly lies is worse than no scenario.

**Touching level 1 in passing.** Four test level files land beside `level-01.json` in the same directory, owned by the same agent, in a phase whose successor rebalances the level. The diff is the guard: `assets/data/level-01.json`, `waves.json`, `formations.json` and `trajectories.json` are **not** this phase's to change.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a worktree per parallel worker created by the coordinator, a pull request against `phase/11h-test-mode`, and a status fragment in `status/` before review.

**Tasks 1 and 2 run in parallel.** The scenario format already exists, so `level-designer` does not wait for the menu.

## What comes after

**Phase 11i — movement and grouping.** More dynamism in how enemies enter, move and combine: trajectories, formations, entrances, simultaneous pressure. `docs/planning/01-vision-and-scope.md:89` names the axes, and this project has so far used density, speed and combinations; entrances barely, and space almost not at all. `docs/plan/11c-movement-shapes/shape-catalogue.md` refuses eight shapes with reasons, and one of those refusals — `sine` / weaving — is written with its own reopening condition already attached. **Read the refusals before proposing a ninth shape.**
