# Plan: Keep Map (Chapter and Room Select)

Status: **Plan only. Not built yet.** Build is scheduled for Week 4 (23–29 Nov), see `DEVELOPMENT_ROADMAP.md`.
Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**

---

## 0. First version scope (drafted 2026-11-03, waiting for your approval)
Layout approved from the mockup: **Screen 1 = wing picker, Screen 2 = room picker** (one scene, two panels).
Built with plain buttons using the existing brown frames and Silkscreen font. No Keep drawing yet (§11 step 8).

| Item | First version |
|---|---|
| Entry | Name + Look "Start" and Title "Continue" both go to the Keep Map (replaces the "coming soon" placeholders) |
| Wings | 7 buttons. Vaults open, Gates locked until Ch 1 done, other 5 sealed ("Sealed, coming soon") |
| Rooms | Vaults shows 6 doors, Gates shows 4. Door states: locked / next / completed with stars |
| Room info | Click a door: title, type, concept, Enter room |
| Enter room | Only 1.1 will exist soon; until then Enter shows "Room coming soon" |
| Locked titles | Hidden as "???" until unlocked (the recommended answer in section 13) |
| Stars | Total shown at top (earned / possible) |
| Top bar | Player name, Look portrait, stars, Menu (Resume, Settings, Back to Title with confirm) |
| Tala line | One fixed line per state for now; story lines come later |
| Data | Chapters and rooms come from data (ScriptableObjects), no room names typed into UI scripts |
| Saving | Save file gets a progress list (room id, best stars); old saves without it load as "nothing completed" |
| Tests | `UnlockRules` (fresh game, mid-chapter, chapter complete, corrupted entry) written first |

Not in the first version: unlock animation, chapter-complete story moment, sounds beyond the click, real art.

### Result of first version (2026-11-03)
Built and play-tested; 103 edit-mode tests pass. Notes against the plan above:
- Catalog is a ScriptableObject at `Assets/_Project/Data/KeepCatalog.asset`, created from `KeepCatalogSeed` the first time the scene is built. It is never overwritten, so edit rooms in the asset.
- Names `KeepRoom` / `KeepChapter` are used so they do not clash with the future `RoomDefinition` in the Room 1.1 plan.
- Locked rooms hide title, type and concept as "???". Their Enter button is greyed.
- Added (not in plan): Esc on the wing picker opens the Keep menu; Esc elsewhere goes back one step; Settings opened from the Keep menu returns to it.
- Sealed and locked wings ignore clicks (no special "locked" sound yet).
- Checked by hand: fresh save, wing and room screens, locked-room details, Enter room placeholder, Keep menu, Settings return, title confirm, Continue, and a fake save with Chapter 1 done (Gates unlocked, 14 / 30 stars).
- Not checked by hand: clicking a sealed wing, 1280x720, keyboard-only navigation, completing a room in play (room completion does not exist yet; `UnlockRules.Record` is unit-tested).

## 1. Purpose
The hub between rooms. The player sees the Keep, their progress, and picks the next room. It must show **where they
are in the story**, make **locked vs open vs completed** obvious, and let them replay any finished room. It also shows
the examiners the bigger vision (sealed future wings).

## 2. Where it sits in the flow
```
Title → New Game → Name + Look → Prologue → KEEP MAP → Room → Debrief → KEEP MAP
              Continue ──────────────────────↗
```
Two levels: **Wing view** (the whole Keep) and **Room list** (the corridor of one wing).

## 3. Wing view (the Keep map) [RECOMMENDED]
A top-down pixel-art map of the Keep. The player does not walk. They click a wing.

```
┌──────────────────────────────────────────────────────┐
│  Warden <name>          ★ 14 / 30          [≡ Menu]  │
│                                                      │
│   [ The Vaults ★ ]───[ The Gates 🔒→ ]──[ Workshop ░ ]│
│         │                                            │
│   [ Archive ░ ]   [ Great Hall ░ ]   [ Towers ░ ]    │
│                       [ Architect's Chamber ░ ]      │
│                                                      │
│   ○ Tala: "Pick a wing, <name>."                     │
└──────────────────────────────────────────────────────┘
 ★ = open/completed   🔒 = locked (finish previous)   ░ = sealed (coming soon)
```
| Wing | MVP state |
|---|---|
| The Vaults (Ch 1) | Open from the start |
| The Gates (Ch 2) | Unlocks when Chapter 1 is completed |
| The Workshop, Archive, Great Hall, Towers, Architect's Chamber (Ch 3–7) | **Sealed**, shown dimmed with a chain/seal icon; tooltip: "Sealed — coming soon" |

Each wing node shows: name, a small progress bar (rooms completed / total), and total stars earned in that wing.
Hover highlights; click opens the Room list for that wing. Sealed wings do nothing except play a soft "locked" sound.

## 4. Room list (inside a wing)
A corridor with doors, one per room. Layout fits one screen; MVP wings have 6 and 4 doors.

```
 Chapter 1: The Vaults                       [← Back to Keep]
 ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐
 │1.1 │ │1.2 │ │1.3 │ │1.4 │ │1.5 │ │1.6 │
 │★★★ │ │★★  │ │ ▶  │ │ 🔒 │ │ 🔒 │ │ 🔒 │
 └────┘ └────┘ └────┘ └────┘ └────┘ └────┘
 "The Twin Guards"   Type: Predict    Concept: references
 [ Enter Room ]
```
- Selecting a door shows its **ticket title**, **room type**, **concept** and best stars so far at the bottom.
- **Enter Room** loads the room scene with that room's data.
- Door states: **Locked** (previous room not completed), **Open/next** (▶ highlighted), **Completed** (stars shown).
- Chapter 2 shows 4 doors (2.1, 2.2, 2.4, 2.5 from `LESSON_PLAN.md`); labels use the chapter-local order (2.1–2.4) in the UI.

## 5. Unlock rules [RECOMMENDED]
- Rooms unlock **in order** within a chapter: completing room N unlocks room N+1.
- **Completed** = the room's fix passes its test (at least ★). Stars never gate progress.
- Completed rooms can be replayed any time; stars only go up (keep the best).
- Chapter 2 unlocks when all Chapter 1 rooms are completed.
- Replay does not erase progress. Prediction can be skipped on replay (see `GAMEPLAY_SYSTEMS.md`).

## 6. Persistent info on screen
- Player name and look portrait (top left).
- Total stars (earned / possible).
- Menu button: Resume, Settings, Credits, Back to Title (with confirm).
- Tala line at the bottom (context-sensitive, see §8).

## 7. States the screen must handle
| State | Behaviour |
|---|---|
| Fresh start (first visit) | Only The Vaults open; room 1.1 is the highlighted next step; Tala points to it |
| Mid-chapter | Next room highlighted; locked rooms greyed |
| Chapter complete | Short celebration effect; next wing unlocks with an animation; Tala line |
| MVP complete (all 10 rooms) | Final message: "The Keep isn't fixed yet..." with a teaser of the sealed wings |
| Missing or corrupted save entry | Treat that room as not completed; never crash |

## 8. Story touches (short, optional skip)
- **First arrival:** Bato: "Welcome, <name>. Everything is on fire. Mostly figuratively. Start at the Vaults."
- **Chapter 1 complete:** Tala shows the first Architect note: "Used one master key for all vaults. Temporary. Will
  fix." Then the Gates unlock (the "to be continued" hook).
- **Returning:** a random short Tala line (tip or joke).
- Lines come from the dialogue table and use the player's name only, no he/she.

## 9. Assets needed (see `ASSET_REQUIREMENTS.md`)
Keep overview background (assembled from Kenney Tiny Dungeon tiles), 7 wing icons or silhouettes (reuse tiles +
tint), door sprites (locked/open/completed), star icons (empty/filled), lock and seal icons, progress bar frame, Tala
sprite, Bato and Warden portraits, panel/button sprites, click/hover/locked sounds, a short unlock jingle.

## 10. Technical plan (design only)
- **Scene:** `KeepMap` (or a panel set inside a shared `Hub` scene).
- **Data:** `ChapterDefinition` (id, name, ordered list of `RoomDefinition`, sealed flag) as ScriptableObjects.
- **Progress:** `SaveService` returns `PlayerProgress` (completed rooms, best stars). A small pure-C# `UnlockRules`
  class decides state per room and wing: `GetRoomState(roomId, progress)` → Locked/Open/Completed.
- **UI scripts (small, separate):**
  - `KeepMapController`: builds wing nodes from `ChapterDefinition` data, handles clicks.
  - `WingNodeView`, `RoomDoorView`: show state, stars, hover.
  - `RoomInfoPanel`: shows title, type, concept, Enter button.
- **Navigation:** `SceneLoader.LoadRoom(roomId)` stores the chosen room in a small `GameSession` object that the room
  scene reads.
- **No hard-coded room lists in UI scripts.** Everything comes from chapter and room data, so adding a room needs only
  new data.
- **Tests (edit-mode):** `UnlockRules` (fresh game, mid-chapter, chapter complete, corrupted entry).

## 11. Build steps (for when it is time)
1. Write `UnlockRules` and its tests (no Unity UI yet).
2. Create `ChapterDefinition` data for Chapter 1 and 2 (rooms may be stubs).
3. Build the wing view with placeholder rectangles; wire click navigation.
4. Build the room list and info panel; wire Enter Room to the room scene.
5. Hook up the save progress and star display.
6. Add sealed-wing behaviour and the unlock animation.
7. Add Tala/Bato lines for the three story moments.
8. Swap placeholders for real art; add sounds.
9. Test at 1280×720, 1920×1080, 2560×1440.

## 12. Acceptance checklist
- [ ] Fresh save: only Vaults open; room 1.1 is highlighted as next.
- [ ] Completing a room unlocks the next one; stars display correctly.
- [ ] Completing Chapter 1 unlocks the Gates with the story moment.
- [ ] Sealed wings are visible but cannot be entered; tooltip says coming soon.
- [ ] Replaying a room never lowers stars or locks later rooms.
- [ ] Back to Title asks for confirmation; progress is not lost.
- [ ] Missing or corrupted progress entries do not crash the screen.
- [ ] All lists come from data (no hard-coded rooms in UI scripts).
- [ ] Readable at 1280×720 and 2560×1440; mouse and keyboard both work.

## 13. Open questions
- One scene with two panels (wing view + room list) or two scenes? **[RECOMMENDED]** one scene, two panels.
- Show locked-room ticket titles, or hide as "???" to avoid spoilers? **[RECOMMENDED]** show the chapter concept
  only, hide the title until the room is unlocked. **[OPEN]**
- Show a dedicated "Stars" total, or keep it per wing only? **[OPEN]**
- Let the player jump to any completed chapter's rooms from the Menu? **[RECOMMENDED]** yes, via the same map.
