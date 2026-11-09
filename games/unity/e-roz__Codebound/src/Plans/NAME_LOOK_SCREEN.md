# Plan: Name and Look Screen (character selection)

Status: **PLAN, awaiting your check. No code written yet.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**

---

## 1. Purpose
Let the player enter their name and choose a Warden look before the story starts. It creates the player's first
save file. Decisions already made: the player types their own name; empty falls back to "Apprentice"; two looks with
no gender labels; dialogue uses the name only, never he/she (`STORY.md`, `MAIN_MENU_TITLE_SCREEN.md` §5). **[CONFIRMED]**

## 2. Where it sits in the flow
```
Title → New Game ──(save exists? confirm)──► NAME + LOOK ──Start──► Prologue (placeholder for now) → Keep Map (later)
                                                  └──Back / Esc──► Title
```
The old save is only replaced when the player presses **Start** here (as decided in the main menu pass).

## 3. Layout [RECOMMENDED]
```
┌──────────────────────────────────────────────────────┐
│                  Who are you, Warden?                │
│                                                      │
│     ┌────────┐            ┌────────┐                 │
│     │ Look 1 │            │ Look 2 │                 │
│     │  [  ]  │            │  [  ]  │                 │
│     └────────┘            └────────┘                 │
│       ● selected            ○                        │
│                                                      │
│     Name:  [ Apprentice________ ]   0/16             │
│     "Welcome, Jean. Everything is on fire.           │
│      Mostly figuratively."   (live preview)          │
│                                                      │
│          [ Start ]            [ Back ]               │
└──────────────────────────────────────────────────────┘
```
- Two selectable look cards. The selected one has a visible highlight **and** the word "Selected" (not colour only).
- Name field with greyed hint text "Apprentice" and a character counter.
- A live preview line shows Bato's first greeting with the typed name. Cheap, and it shows the player their name will matter.
- **Start** is always enabled, because an empty name is allowed (falls back to "Apprentice").
- Placeholder art for now: coloured squares labelled "Look 1" and "Look 2". Real portraits (for example from Kenney Tiny
  Dungeon characters) come with the art pass.

## 4. Name rules [RECOMMENDED]
| Rule | Value |
|---|---|
| Max length | 16 characters |
| Allowed characters | letters (including ñ and Ñ), digits, space, hyphen `-`, apostrophe `'`, period `.` |
| Cleanup on Start | trim leading/trailing spaces; collapse repeated spaces to one; drop disallowed characters |
| Empty after cleanup | use "Apprentice" |
| Offensive-word filter | not in the MVP |
Emojis and symbols are not allowed because the font may not draw them. Rules live in one pure-C# class so they can be tested.

## 5. Looks [RECOMMENDED]
Two looks with ids `0` and `1`, labelled "Look 1" and "Look 2". Default selected: Look 1 (id 0). A small catalog class holds
ids and labels so adding a third look later is a data change. The chosen id is saved in `PlayerSave.lookId`.

## 6. What Start does
1. Clean the name with the name rules.
2. Build `PlayerSave { playerName, lookId }` and call `SaveService.Save` (overwrites any old save).
3. Show the prologue placeholder: "Welcome, <name>. The prologue is coming soon." with a Back to Title button.
4. The Continue button on the title screen will now be enabled with this name.

## 7. Input and keyboard
- Click or Left/Right arrows to switch look; Enter in the name field = Start; Esc = Back to Title (typed name is discarded).
- Name field is focused when the screen opens.
- Tab order: name → looks → Start → Back.

## 8. Technical plan (design only)
- **Core (plain C#, tested):**
  - `PlayerNameRules`: `MaxLength`, `FallbackName`, `Clean(string) → string`.
  - `LookCatalog`: look ids and labels.
  - `MenuScreen` gets a new value `NameLook`; `MenuNavigator` handles Back from it like other panels.
- **UI (scene scripts):**
  - `NameLookPanelController` on its own panel: owns the name field, look cards, preview text, Start/Back. It raises two C# events: `Started(PlayerSave)` and `Cancelled`. It does **not** touch `SaveService` directly.
  - `MainMenuController` subscribes: on `Started` it saves via `GameServices.Save`, then shows the prologue placeholder; on `Cancelled` it goes back to Title. (Keeps the controller small and the panel reusable.)
  - The editor builder (`MainMenuSceneBuilder`) creates the new panel and wires its fields, so you don't build it by hand.
- **Tests (edit-mode):** name cleaning cases, look catalog, navigator Back from `NameLook`.
- **Not changed:** `SaveService`, `SettingsService`.

## 9. Build order
1. `PlayerNameRules` + `LookCatalog` + tests (no scene).
2. `MenuScreen.NameLook` + navigator test.
3. `NameLookPanelController` and the panel in the builder script.
4. Wire into `MainMenuController` (New Game → NameLook; Started → save → prologue placeholder).
5. Rebuild the scene, play-test, compare against the checklist.

## 10. Acceptance checklist
- [ ] New Game (no save) opens the Name + Look screen with the name field focused.
- [ ] New Game with an existing save still asks for confirmation first; Yes opens the Name + Look screen.
- [ ] Switching looks by click and by Left/Right works; the selected look is clearly marked.
- [ ] Typing shows the counter and the live preview; names longer than 16 are blocked.
- [ ] `  jean   cruz  ` is saved as `jean cruz`; `Ñoel` is kept; `Jean😀` becomes `Jean`; empty or spaces only becomes `Apprentice`.
- [ ] Start writes `save.json` with the cleaned name and the chosen look id, and shows the prologue placeholder.
- [ ] Back or Esc returns to the title **without** touching the old save.
- [ ] After Start, restarting the game shows Continue enabled and "Welcome back, <name>".
- [ ] All new unit tests pass; no Console errors.

## 11. Open questions for you to check
1. Is "Look 1 / Look 2" with no gender labels what you meant by choosing a character? **[CONFIRMED earlier, check again]**
2. Name length 16: enough, or do you want 20?
3. Do you want the live Bato greeting preview, or should it be dropped?
4. Do you want the look cards to show a name label ("Look 1") or later a short title (for example "Apprentice A" / "Apprentice B")?
