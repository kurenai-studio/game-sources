# Plan: Main Menu / Title Screen

Status: **Plan only. Not built yet.** Build is scheduled for Week 4 (23–29 Nov), see `DEVELOPMENT_ROADMAP.md`.
Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**

---

## 1. Purpose
First screen the player sees. It sets the mood (warm, funny, a little mysterious), lets the player start or continue,
and leads to the name and look screen. It must be quick to build and clear for first-time players.

## 2. Where it sits in the flow
```
Boot → TITLE SCREEN → New Game → Name + Look → Prologue → Keep Map → Room → Debrief → Keep Map
                  ↘ Continue ─────────────────────────────────────↗
                  ↘ Settings (panel) · Credits (panel) · Quit
```

## 3. Visual concept [RECOMMENDED]
The **gate of the Keep at night**, top-down pixel art feel but framed as a still scene:
- Dark stone gate in the lower half; torches on both sides with flickering light.
- **Game logo** "CODEBOUND" centred in the upper area, subtitle "The Programming Dungeon" below it.
- **Tala** (lantern spirit) floating gently near the logo (idle bob animation).
- A few faint lines of C# code slowly drifting up like dust or embers (very low opacity, decorative).
- Menu buttons in a vertical stack, centred below the logo.

```
┌──────────────────────────────────────────────┐
│   ✦ torch                          torch ✦   │
│                                              │
│            C O D E B O U N D                 │
│        The Programming Dungeon               │
│                                   ○ Tala     │
│              [ New Game ]                    │
│              [ Continue ]                    │
│              [ Settings ]                    │
│              [ Credits  ]                    │
│              [ Quit     ]                    │
│  ▓▓▓▓▓▓▓▓▓▓▓ keep gate (pixel art) ▓▓▓▓▓▓▓▓  │
└──────────────────────────────────────────────┘
```
Version label ("v0.1 · build date") small in a corner.

## 4. Buttons and behaviour
| Button | Behaviour |
|---|---|
| **New Game** | If a save exists: confirm dialog ("Starting a new game replaces your saved progress. Continue?"). Then go to Name + Look screen. |
| **Continue** | Loads the save and goes to the Keep Map. **Disabled (greyed, tooltip "No saved game yet")** when no save exists. |
| **Settings** | Opens a panel: music volume, effects volume (sliders), Back. Saved to the settings file. |
| **Credits** | Opens a panel listing assets, authors, licences (from `CREDITS.md`), team, and "Built with Unity." Back button. |
| **Quit** | Confirm dialog, then `Application.Quit()`. (No effect in the editor; log a message instead.) |

Keyboard: Up/Down to move focus, Enter to select, Esc closes a panel or opens Quit confirm. Mouse hover highlights.

## 5. Name and Look screen (next screen after New Game)
- **Name field** (max ~16 characters, trimmed). Empty → fallback name "Apprentice". Letters, numbers, spaces and basic
  punctuation only; no profanity filtering required for the MVP.
- **Look picker [CONFIRMED B]:** two Warden looks shown as portraits, labelled "Look 1" and "Look 2" (no gender labels).
  Writing uses the player's name only, no he/she, so every look works.
- **Start** button → saves name and look → Prologue.
- Save fields: `playerName`, `lookId`.

## 6. States the screen must handle
| State | Behaviour |
|---|---|
| First launch, no save | Continue disabled |
| Save exists | Continue enabled; shows small text "Welcome back, <name>" under Continue (optional) |
| Corrupted/unreadable save | Treat as no save; show a short message; do not crash; keep a backup copy of the bad file |
| Settings changed | Applied immediately, saved on Back |

## 7. Audio
- One calm looping title track (dungeon-ambient, low intensity), fades in.
- UI sounds: hover tick, click, back.
- Torch crackle ambience (optional, low volume).
- Volume sliders control the Music and SFX groups.

## 8. Assets needed (see `ASSET_REQUIREMENTS.md`)
Keep gate background (can be built from Kenney Tiny Dungeon tiles), torch sprite (2–4 frame flicker), Tala sprite
and glow, logo (pixel font text, can be made in Unity with a pixel font first), panel and button sprites (Kenney
UI Pack Pixel Adventure), pixel UI font, title music loop, UI sounds, two Warden portraits (for the next screen).

## 9. Technical plan (design only)
- **Scene:** `MainMenu` (Boot loads it first).
- **UI:** one Canvas (Screen Space - Overlay, Canvas Scaler 1920×1080) with child panels: `TitlePanel`, `SettingsPanel`,
  `CreditsPanel`, `ConfirmDialog`, and later the `NameLookPanel` (or its own scene).
- **Scripts (small and separate):**
  - `MainMenuController`: wires buttons to actions, shows/hides panels.
  - `SaveService` (shared, plain C# class): `HasSave()`, `Load()`, `Save()`, `DeleteSave()`.
  - `SettingsService`: volume values, saved and applied.
  - `AudioService`: plays music and SFX by id.
  - `MenuButton` (optional): hover/click effects and sounds.
- **Data flow:** `MainMenuController` asks `SaveService.HasSave()` to enable/disable Continue. It never reads files
  itself. Scene changes go through one `SceneLoader`.
- **Animations:** torch flicker and Tala bob via simple sprite animation or tweens; drifting code text via a few
  `TextMeshPro` objects moving upward on a loop (or a particle system).
- **No game logic** lives in menu scripts. Menus only call services.

## 9b. Scope of the FIRST coding pass (added after plan check)
**In:** `MainMenu` scene with placeholder art (coloured rectangles, default font); Title panel with the 5 buttons;
Continue enable/disable from `SaveService`; New Game confirm dialog; Settings panel (two sliders, values saved and
loaded, not yet wired to sound); Credits panel (static text for now); Quit confirm; keyboard and mouse navigation;
`SaveService` and `SettingsService` as plain C# with edit-mode tests; corrupted-save handling.
**Out (later):** real art, torches/Tala animation, drifting code text, music and UI sounds, `AudioService`, the Name +
Look screen (New Game goes to a placeholder "Name + Look coming" screen that returns to the title), Welcome-back text.
**Input:** the template uses the legacy Input Manager, so the scene uses the standard `EventSystem` with
`StandaloneInputModule`. Revisit only if we adopt the new Input System (D-11).

## 9c. How the scene is built (changed at the project lead's request)
Instead of clicking the scene together by hand, an editor script (`Assets/_Project/Scripts/Editor/MainMenuSceneBuilder.cs`,
menu **Codebound → Build Main Menu Scene**) creates the whole placeholder scene and wires every Inspector field of
`MainMenuController`. Re-running it replaces `MainMenu.unity` (it asks first). Real art later replaces the placeholder
visuals; the structure and names stay.

## 10. Build steps (for when it is time)
1. Create `MainMenu` scene with Canvas and placeholder panels (coloured rectangles).
2. Add buttons, wire navigation and focus, Esc handling.
3. Add `SaveService` with `HasSave` and test it (edit-mode tests).
4. Wire Continue enable/disable, New Game confirm.
5. Add Settings panel with sliders; connect to `AudioService`.
6. Add Credits panel (scrollable text).
7. Swap placeholders for real art: gate, torches, Tala, logo, buttons.
8. Add drifting code effect, music and UI sounds.
9. Test at 1280×720, 1920×1080, 2560×1440.

## 11. Acceptance checklist
- [ ] Game starts on the title screen; no errors in the Console.
- [ ] Continue is disabled with no save and enabled with a save.
- [ ] New Game with an existing save asks for confirmation.
- [ ] Settings volume values persist after restarting. (Hearing the change is tested later, once audio files exist.)
- [ ] Credits lists every asset used in the game.
- [ ] Quit confirms and exits the built game.
- [ ] Works with mouse and keyboard; Esc behaviour is consistent.
- [ ] Readable at 1280×720 and 2560×1440.
- [ ] A corrupted save does not crash the game.

## 12. Open questions
- Logo: text in a pixel font (cheap) or a drawn logo? **[RECOMMENDED]** pixel-font text first.
- Show "Welcome back, <name>" on the title screen? **[OPEN]**, optional.
- Name and Look as a panel on the same scene or its own scene? **[RECOMMENDED]** panel on the same scene.
- Should Tala say a short line on the title screen (for example, a random tip)? **[OPEN]** nice-to-have.
