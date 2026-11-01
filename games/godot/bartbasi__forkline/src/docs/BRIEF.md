# Kickoff brief: Forkline, a Play, Inc. tower defense game

Bart Basi, 2026-10-23. Name: Forkline. Store title: "Forkline: Tower Defense". Folder: C:\bart\forkline. Repo: github.com/bartbasi/forkline.

## 0. Read this first

You are the main Claude Code session for this project and you are the Development Manager (DM) described in the playbook. Before planning anything:

1. Read C:\bart\playbook\PLAYINC_PLAYBOOK.md in full and follow it. This brief only adds what is specific to this game. Where the two disagree, stop and ask Bart.
2. Save this brief word for word as docs/BRIEF.md.
3. The playbook section 15 questions are already answered in sections 6 and 10. Don't ask them again. The only open one, the font, waits for hard stop A.
4. Write the project CLAUDE.md from playbook template 16.6, with the decisions in section 6 of this brief copied in and dated.
5. Create the agent files in section 7, then start phase 1 in section 8.

Stop and ask whenever something is unclear or would force a guess. Do not pick an interpretation silently.

## 1. What we are making

An original tower defense game for Android phones: simple to learn, easy to play, hard to figure out. Free, offline, no ads, no purchases, no accounts, under the playbook rules. Every visual, effect, sound and piece of music is made in code. It borrows the best proven mechanics of the genre but copies no existing game, and no other game's name appears anywhere players can see.

The hook that sets it apart: hand-built maps whose roads fork, plus a small number of gates the player places to close branches and steer enemies past their towers. Players solve each map like a puzzle, then watch it play out.

## 2. Why: the market findings behind this design

Research done 2026-10-23, from the point of view of a senior marketing analyst. Use these as design pillars. Do not cite or name the games below anywhere in the product.

- **Tower defense retains well when choices are real.** Top games in the genre keep about 40% of players on day 1 and 15% on day 7. The retention comes from many meaningful choices and the moment a player discovers that two towers work well together.
- **The genre's biggest complaint is money, not gameplay.** Mobile TD reviews praise the core loop and complain about ads and pay to win. Our free, no-ads stance is a selling point. Say so in the store listing.
- **Hand-built levels beat generated ones** for the campaign. One leading studio builds every level by hand because players learn the patterns of generated levels quickly.
- **Clarity over count.** Strong TD design gives the player the information to make calculated decisions, not guesses, and forces a mix of tower types with no single super tower.
- **No ambushes.** A well-reviewed minimalist TD was criticized for surprise enemy types that felt like ambushes and for a loop that went stale. Show what is coming, and keep adding small new ideas.
- **Short sessions win on phones.** Players love games they can save and leave after any round, in 10 to 30 minute sittings.
- **Path control is an underserved niche** that strategy players miss. Full maze building is fiddly on a phone, so we use gates on hand-built forks instead.
- **Roguelite runs drive replay.** Easy to learn, hard to master, short runs, pause any time.
- **Cozy and bright widen the audience.** Cozy games are a mainstream force and draw players who don't usually play games. Bright styles read as "for everyone", strategy players skew older, and cute art is the norm on mobile.

## 3. Game design requirements

The game designer turns these into docs/design/RULES.md with exact numbers. Numbers below are starting targets, not limits. Anything beyond this list goes to Bart as a suggestion, not into the game.

### 3.1 Core loop

- Waves come down roads toward the player's base. Each enemy that reaches it costs lives. Run out and the level is lost.
- Between waves there is a build phase with no time pressure. During waves the game runs in real time.
- The player can pause at any moment and still build, upgrade, sell and inspect while paused.
- Speed controls: 1x, 2x, 3x.
- Calling the next wave early pays a small gold bonus, so skilled players can push the pace.
- Gold comes from kills and wave clears. Selling during the same build phase refunds in full; after that it refunds part of the cost.

### 3.2 Towers

- Six towers in version 1, each with one clear job. Starting archetypes: rapid single target, splash, slow, long range armor piercing, anti air, support (boosts neighbors).
- Three tiers per tower. At tier 3 the player picks one of two specializations for that tower. The choice is permanent for that tower.
- No tower is best everywhere. Every tower must be the right answer somewhere.
- Towers sit on build spots marked on each map. Limited spots are part of the puzzle.

### 3.3 Enemies

- About ten enemy types plus one boss per region. Starting set: basic, fast, armored, swarm, flyer, shielded, splitter, healer, and one that can force a gate open after a delay.
- Flyers ignore roads and gates, so gates are never a complete answer.
- Each new enemy appears alone first, with a short info card the first time it shows up. Never introduce two new things in the same wave.

### 3.4 Gates, the hook

- Maps are hand-built road networks with forks. Some road cells are gate sockets.
- Each level gives the player a set number of gates (0 to 3 in the campaign). A gate closes the road at its socket.
- Ground enemies always take the shortest open route to the base.
- A gate placement that would seal every route is refused with clear feedback.
- While the player places or moves a gate, a route line on the map shows exactly where enemies will go.
- Gates can be placed, moved and removed during build phases. They are locked during waves. The game designer may propose a limited mid-wave switch for later levels; Bart decides.

### 3.5 Information and control

- Before every wave, a preview shows which enemies are coming, how many, and from which entrance.
- Tapping a tower or enemy shows its real numbers: damage, rate, range, health, armor, speed, special rules.
- Placing a tower shows its range. Upgrades show before and after numbers.
- Color is never the only signal. Every tower and enemy reads by silhouette alone.
- Touch only. Every control works with one thumb in portrait. Touch targets at least 48 dp.

### 3.6 Campaign

- About 24 hand-built levels in 4 regions of 6. Each region introduces one or two towers and two or three enemies and ends with a boss level.
- Levels take 5 to 10 minutes at 1x.
- Three stars per level. One star for winning. The designer defines the second and third stars (for example lives kept, or a level-specific challenge) and states them on the level card before play.
- The first levels each teach one idea with a one-line hint and a highlighted spot. No long tutorial and no text walls. The Info screen holds the full rules.
- After a level is cleared with three stars, a Twist version of it unlocks: the same map with one rule changed (for example a tower banned, gates fixed in place, or a double-strength final wave). The designer proposes the twist list.

### 3.7 Roguelite mode (in version 1)

- A run is a single session of about 15 to 20 waves, 15 to 25 minutes, ending in a boss.
- Run maps are assembled from hand-built segments (forks, gate sockets, entrances), never fully random, so they keep the hand-made feel.
- After each wave the player picks one of three cards: a tower for this run, a tower perk, an extra gate, an economy perk, or a risk card that trades a harder wave for a reward.
- Losing ends the run. A run can be left and resumed at any wave.
- Playing unlocks new cards into the pool. Unlocks add variety, never raw power, so skill decides runs. Nothing is bought.

### 3.8 Daily challenge

- One seeded roguelite run per day, seed taken from the phone's local date. Same seed on every phone, no network.
- Saves the player's best result for the day and a play streak, both on the phone only.

### 3.9 Progression

- Stars unlock regions and the roguelite mode. New towers unlock as the campaign introduces them.
- Everything is earned by playing. No grind walls: a player who clears levels at one or two stars must still be able to reach the end of the campaign.

### 3.9a Difficulty

- Two difficulties: Normal and Relaxed. The player picks per level or per run, and can switch before starting. Normal is the default.
- Relaxed gives more lives and more starting gold. The game designer sets the numbers. Nothing else changes: same maps, waves and rules.
- A Relaxed win earns one star, which is enough to keep going through the campaign. The second and third stars need Normal.
- The daily challenge is always Normal, so every player faces the same run.

### 3.10 Sessions and saving

- Leaving the app at any point, including killing it mid-wave, and coming back resumes the game. The architect proposes whether that is the exact moment or the start of the current wave, and Bart decides.
- Saves follow the playbook security rules exactly.

### 3.11 Simulation rules

- The game rules run in plain classes with no UI or Node dependencies, on a fixed timestep with seeded randomness, so the same inputs always give the same result. This is what makes the balance bots, the daily seed and the tests possible.

## 4. Theme, look and sound

The theme matters as much as the rules. Bart chose **cozy storybook fantasy**: a warm hillside village at dusk; towers as lantern-lit watch posts and cottages; enemies as mischievous night creatures that puff into sparkles, no blood. Why: fantasy is the look players expect from the strategy category, and cozy plus bright widens it to people who skip darker strategy games. Forkline fits it: the village roads fork, and the player decides which way the night creatures go.

The art director builds the theme as a playable slice of an early level, on Bart's phone, in both orientations, so Bart judges it in his hand rather than from mockups. The slice shows the map, all six tower silhouettes at tier 1, the first four enemies walking the route, one gate, the HUD, a short music loop and a few sound effects.

The look is original: no borrowed characters, layouts, palettes or tower designs from any existing game. The art director writes one page in docs/art/: the idea, palette tokens with contrast checks, silhouette sheet, how it looks as a 512 x 512 store icon and as the first store screenshot, and the risks. The test for the icon and first screenshot: a stranger can tell at a glance it is a tower defense game.

It stays non-gory so the content rating stays Everyone.

## 5. Screens and orientation

- Portrait is the default, for one-handed play on normal phones and the Fold5 cover screen.
- On a foldable's inner screen, or any window that is close to square or wider than tall, the game switches to a landscape layout on its own. No setting.
- Lay out by window size, not by an orientation lock. The architect checks current Android large-screen behavior for Godot 4.7.2 (newer Android versions can override orientation locks on large screens) and writes the approach into docs/ARCHITECTURE.md before UI work starts.
- Both layouts are tested on both Fold5 screens, including folding and unfolding mid-wave without losing state.
- The front door, Info, About, Settings and Pause screens follow playbook section 6, with one change Bart made for this game: "Play" opens a mode screen with Campaign, Roguelite and Daily. When a level or run is saved, a Continue card sits at the top of that screen and resumes it in one tap.
- About has a tappable source code link and a "Send feedback" button (playbook 6.3). Pause has a quiet Buy me a coffee row (playbook section 5 rules). The privacy policy names all three.

## 6. Decisions already made (Bart, 2026-10-23)

- Path design: hybrid. Hand-built maps with forks plus player-placed gates.
- Version 1 includes the campaign with stars, Twist versions, the roguelite mode and the daily challenge. No networking of any kind.
- Portrait by default, landscape automatically on foldable inner screens.
- Theme: cozy storybook fantasy (section 4).
- Name: Forkline. Store title "Forkline: Tower Defense". Package name: io.github.bartbasi.forkline.
- "Play" opens a mode screen (Campaign, Roguelite, Daily) with a Continue card on top when something is saved.
- Optional Relaxed difficulty (section 3.9a).
- About has a tappable source link and a Send feedback button. Pause has a quiet Buy me a coffee row.
- Models: Claude Opus 5.5 and Claude Sonnet 5.5 only. Effort levels high and max only.
- Everything else follows the playbook defaults: Godot 4.7.2, GDScript statically typed, Android first, assets made in code, GPL v3 with the Play, Inc. terms.

## 7. The team: agents, models and effort

### 7.1 Who does what

| Agent | Model | Effort | Owns | Job |
|---|---|---|---|---|
| DM (main session) | claude-opus-5-5 | high | CLAUDE.md, project.godot, LICENSE, NOTICE, README, tests/run_tests.gd, tests/base_test.gd, git | Plans, launches every agent, integrates, commits, the only one who talks to Bart |
| game-designer | claude-opus-5-5 | max | docs/design/ | Rules, towers, enemies, gates, economy, campaign outline, roguelite and daily design, star rules, twists; reviews fun and can send work back |
| architect | claude-opus-5-5 | max | docs/ARCHITECTURE.md | The contract: data model, every public class and signal, save format, simulation timestep and seeding, orientation approach, performance budget |
| art-director | claude-opus-5-5 | high | docs/art/, src/theme/, prototypes/theme/ | The theme slice, then the design system: tokens, silhouettes, wordmark, contrast script |
| sim-engineer | claude-opus-5-5 | high | src/sim/, tests/sim/ | The pure rules engine: roads, gates, routing, waves, targeting, damage, economy, save and load of sim state |
| level-designer | claude-opus-5-5 | high | data/levels/, data/segments/, tests/levels/ | Hand-built campaign levels and roguelite map segments as data, star targets, first-sight hints |
| balance-analyst | claude-sonnet-5-5 | high | tools/balance/, docs/balance/ | Headless bots that play every level and run; reports win rates, star reachability, dominant towers and dead towers to the game designer |
| roguelite-engineer | claude-sonnet-5-5 | high | src/run/, data/cards/, tests/run/ | Run structure, card drafts, unlock pool, daily seed |
| ui-engineer | claude-sonnet-5-5 | high | src/ui/, scenes/ui/, tests/ui/ | Every screen and the HUD, touch input, portrait and landscape layouts, safe areas, playbook standard screens and the coffee button |
| render-engineer | claude-sonnet-5-5 | high | src/render/, shaders/ | Maps, towers, enemies, projectiles, particles and effects drawn in code in the storybook theme, at 60 fps |
| audio-engineer | claude-sonnet-5-5 | high | src/audio/ | Synthesized sound effects and music, mixing, the sound toggle |
| release-engineer | claude-sonnet-5-5 | high | scripts/, export_presets.cfg, tools/store/, docs/store/, docs/release.md | Build and install scripts, export preset, license and APK contents check, store graphics from code, listing and privacy policy drafts |
| qa-reviewer | claude-opus-5-5 | high | docs/reviews/qa-*.md | Finds bugs on Windows and on the phone. Never fixes code |
| security-reviewer | claude-opus-5-5 | max | docs/reviews/security-*.md | Checks the playbook section 11 baseline every round. Never fixes code |

Why these choices:

- **Opus on judgment, Sonnet on volume.** Design, architecture, the rules engine, level design and reviews decide whether the game is fun and safe. Those get Opus. Level design gets Opus because the puzzle in each map is the product; the bots only check it. Well-specified build work with clear tests gets Sonnet.
- **Max only where depth pays.** Max goes to the game designer, architect and security reviewer, where one wrong call is expensive. Max can overthink and over-build. If a max agent stalls, sprawls or adds unrequested features, the DM drops it to high for that task and tells Bart.
- **The DM stays on high.** It runs the longest session, and high keeps it responsive.

Cost note for Bart: Opus at max uses plan limits fastest. The DM runs at most four agents at once and works phase by phase. Never launch the whole team together.

### 7.2 Setting the agents up

Create one file per agent in .claude/agents/, with the full model ID and effort in the frontmatter so nothing drifts if aliases change. Leave the Agent tool out of every agent's tools so no agent can spawn its own agents. Example:

```markdown
---
name: game-designer
description: Owns the rules, towers, enemies, gates, economy, campaign, roguelite and daily design, and fun reviews. Use for any design or balance decision.
tools: Read, Write, Edit, Glob, Grep, Bash
model: claude-opus-5-5
effort: max
---

You are the game designer for Forkline, a Play, Inc. tower defense game.
Read docs/BRIEF.md, CLAUDE.md and docs/ARCHITECTURE.md before any task.
You may edit only docs/design/. Ask the DM for anything outside it.
[Role details from section 7.1, plus the rules in 7.3.]
```

Launch the main session from C:\bart\forkline:

```bash
claude --model claude-opus-5-5 --effort high
```

### 7.3 Rules every agent follows

- Read docs/BRIEF.md, CLAUDE.md and docs/ARCHITECTURE.md before starting any task.
- Edit only the paths you own. Contract changes and changes to anyone else's area go through the DM.
- Never commit or push. Only the DM commits.
- Keep it simple. No features, settings or abstractions beyond the task. Ideas go in your report as suggestions.
- Security and bugs first, then fun and polish.
- Writing style from the playbook: plain, short sentences, no em dashes, no double hyphens in prose.
- End every task with the playbook report: files changed, how it was proven (command and result, test names, screenshot path), open questions, contract change requests.

## 8. Phases and hard stops

1. **Kickoff.** Section 0 steps. Write CLAUDE.md and the agent files.
2. **Scaffold.** DM and release-engineer: playbook checklist step 3, plus build and install scripts. Done when the empty project opens headless, the test runner exits 0 and a debug APK installs on the Fold5.
3. **Design.** In parallel: the game designer writes docs/design/RULES.md; the architect writes the first docs/ARCHITECTURE.md; the art director builds the cozy storybook slice on the phone.
   - **Hard stop A.** Bart approves the rules and the look, and picks the font. Delete the slice from prototypes/ once its parts are carried into the real code.
4. **Contract and design system.** The architect finalizes the contract. The art director turns the theme into tokens and a silhouette sheet.
5. **Build region 1.** Sim, render, UI (including front door, Info, About, Settings, Pause and the coffee button), audio, the first six levels and the balance bots, in parallel, each against the contract.
6. **Integration.** Region 1 playable on Windows, then on the Fold5, both screens, both orientations. The game designer does a fun review and the balance analyst reports bot results first.
   - **Hard stop B, playtest.** Bart plays region 1 on his phone. Fix what he flags before any more content.
7. **Content.** Regions 2 to 4, bosses, Twists, the roguelite mode and the daily challenge, with balance passes after each region.
8. **Reviews.** QA and security reviews per the playbook. Fix every Critical and High and review again. Bart decides on Medium and Low.
   - **Hard stop C.** Ask before creating the GitHub repo and the first push.
9. **Store and release.** Store material and privacy policy per the playbook. Ask first before turning on Pages, before any signing, and before any Play Console work. Play Console waits for Play, Inc.'s DUNS number.

End every phase with a short status for Bart: done, verified, next, blocking. Keep the task list current.

## 9. Name

The name is **Forkline** (Bart, 2026-10-23). A fork in the road is the game's hook. The store title is "Forkline: Tower Defense" (23 of 30 characters), so a new publisher's game says what it is.

The name was checked only with web searches on 2026-10-23, which found no game with that title. Before the first GitHub push, remind Bart to search "Forkline" in Google Play on his phone and run a quick trademark search. If anything looks close, it's a question for a lawyer, and the name can still change before anything is public.

## 10. Questions still open for kickoff (playbook section 15)

Bart settled the rest on 2026-10-23 (section 6). One question remains, and it waits for hard stop A, when Bart sees the storybook look:

1. Font: Outfit, the system font, or both depending on where it shows?

## 11. Done means

- All headless tests pass, exit code 0.
- The balance bots confirm, for every campaign level: it can be won, three stars can be reached, no single tower type gets three stars alone, and every tower type appears in at least one winning three-star solution somewhere in the campaign.
- The bots confirm roguelite runs and the daily seed are winnable and that the same seed always plays the same.
- 60 fps on the Fold5 during the largest wave in the game, on both screens.
- Killing the app mid-wave and mid-run, then reopening, resumes as Bart decided in 3.10.
- Folding and unfolding mid-wave switches layout without losing state.
- The release APK requests no permissions, and its bundled parts all appear in NOTICE, README and About (playbook section 3 check).
- Every playbook Always item checked off, and every Critical and High review finding fixed.
