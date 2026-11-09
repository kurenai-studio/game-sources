# Plan: Assets Phase 1 (import pipeline + main menu skin)

Status: **DRAFT, waiting for your check. No downloads, no code yet.**

## 1. Goal
Get real art, fonts and sound into the project the *right way once*, so every later room just drops assets in.
Prove it on the screens we already have (title, settings, credits, name+look) before Room 1.1 needs it.

Not in this phase: Keep scene art, guards, chests, threads (those come with Room 1.1, Phase A).

## 2. Decisions I need from you (D-06 is still open)
| # | Question | My recommendation |
|---|---|---|
| A | Tile size | **16x16.** Kenney Tiny Dungeon is 16x16, small enough for you to draw/recolour alone. |
| B | Core pack | **Kenney Tiny Dungeon** (CC0) for characters/props/tiles. |
| C | UI pack | **Kenney UI Pack - Pixel Adventure** (CC0) for buttons/panels. |
| D | Pixel UI font | A free pixel font under **SIL OFL** (e.g. Pixelify Sans or Silkscreen from Google Fonts). |
| E | Code font | **JetBrains Mono** (OFL). Readability over pixel style, per the asset doc. |
| F | Audio | Defer. Only UI click + one menu loop now (Kenney UI Audio, CC0). Chapter music later. |

## 3. What YOU download (you said you want to do this)
Put each in `F:\UnityGames\CODEBOUND\_AssetDrop\` (I will add this folder to `.gitignore`, so raw zips never get committed).
1. Kenney **Tiny Dungeon** zip: https://kenney.nl/assets/tiny-dungeon
2. Kenney **UI Pack - Pixel Adventure**: https://kenney.nl/assets/ui-pack-pixel-adventure
3. Kenney **UI Audio**: https://kenney.nl/assets/ui-audio
4. Pixel font `.ttf` + its OFL licence text (Google Fonts download).
5. JetBrains Mono `.ttf` + licence text.

I check each licence file myself before importing anything. Anything unclear stays out.

## 4. What I do (after you drop the files)
1. **Folders:** `Assets/_Project/Art/{Characters,Tiles,UI,Icons}`, `Fonts`, `Audio/{Sfx,Music}`.
2. **Import settings script** (Editor `AssetPostprocessor`): anything under `Art/` imports as Sprite, **Point filter, no compression, PPU 16**. Done by code so settings never drift. Includes a small test that checks the rules.
3. **TMP font assets** generated from the two fonts; set the pixel font as TMP default.
4. **CREDITS.md** at repo root listing every asset: name, author, licence, URL. The Credits screen shows it (replaces the placeholder text).
5. **Re-skin the main menu** through `MainMenuSceneBuilder` (rebuilt, not hand-edited): panel and button sprites, pixel font, UI click sound on buttons, Look 1 / Look 2 buttons show real character sprites instead of grey squares.
6. **Project setting:** Game view reference resolution 1920x1080 with integer scaling checked at 1280x720 and 2560x1440.

## 5. Acceptance checklist
- [ ] Every file in `Art/` imports with point filter, no compression, PPU 16 (test passes).
- [ ] No font or asset in the project without a line in `CREDITS.md`.
- [ ] Main menu, Settings, Credits, Name+Look all show the new look with no pink/missing sprites, 0 console errors.
- [ ] Look 1 and Look 2 show distinct character sprites; selection highlight still readable.
- [ ] Code font is NOT used anywhere yet except a test label (so we know it loads); it is for Room 1.1.
- [ ] Button click plays a sound; music/sfx sliders still change volume.
- [ ] Looks crisp (no blur, no shimmering) at 1280x720 and 2560x1440.
- [ ] All tests green.

## 6. Risks
- **Look 1 / Look 2 sprites:** Tiny Dungeon has several heroes, so we pick two. If neither reads as "Warden", you recolour later; the plan does not depend on it.
- **Licence surprise:** font sites sometimes bundle a different licence than the page says; I read the file, not the page.
- **Time:** about one session. If audio import misbehaves, I drop audio and ship visuals only.

## 6b. Result (2026-11-03)
Approved with **Silkscreen** instead of Pixelify Sans (D). Built and play-tested. Deviations from the plan above:
- **Music:** Kenney UI Audio has no music, so the menu loop is deferred. Only the button click was added.
- **Scaling:** the UI uses the existing 1920x1080 CanvasScaler. Integer scaling and the 1280x720 / 2560x1440 crispness check were **not** done; 2560x1440 looked fine in the Game view.
- **Look sprites:** Look 1 = `tile_0085` (man), Look 2 = `tile_0099` (woman); both are stand-ins you can recolour later.
- **Credits:** the Credits screen reads `CREDITS.md` at scene-build time (single source of truth). Rebuild the scene after editing it.
- **Licences:** full texts are in `/Licenses`, outside `Assets/`.
- **Tiles:** all 132 Tiny Dungeon tiles are imported under `Art/Tiles/Dungeon` for Room 1.1; the menu does not use them yet.
- **Not checked by ear:** the click sound plays without errors, but I could not hear it.

## 7. Order of work
Your check on this plan -> you download -> I import + script + tests -> skin menu -> play-test vs checklist -> check code vs this plan -> you commit.
