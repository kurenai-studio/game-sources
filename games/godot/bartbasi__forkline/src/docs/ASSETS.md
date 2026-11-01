# Forkline assets

Every visual, effect, sound and piece of music in Forkline is made in code. This file logs every asset and how it is made, plus the few approved third party files, which stay unmodified.

## Third party files (approved by Bart)

| File | What it is | License | Source | Notes |
|---|---|---|---|---|
| LICENSE | GNU General Public License, version 3 | (the license itself) | gnu.org, official text | Unmodified. MD5 `1ebbd3e34237af26da5dc08a4e440464`, checked by tests/project/test_project_rules.gd. |
| src/theme/fonts/Outfit[wght].ttf | Outfit font, variable weight, used everywhere (Bart, hard stop A) | SIL Open Font License 1.1 | Copied unmodified from SumUp's src/design/fonts/, originally from the Outfit project (Google Fonts). Playbook approved default. | MD5 `e31a3aa5fce3366bcadb8e9027f26178`, checked by tests/theme/test_ui_theme.gd. Ships in the game. |
| src/theme/fonts/OFL.txt | The font's license | (the license itself) | Same source, unmodified | MD5 `fc7bcc2f3d37195db3ea982ccfecd531`. Ships in the APK next to the font and is readable in About. |

## Made in code

| Asset | Made by | Notes |
|---|---|---|
| Color tokens | src/theme/palette.gd | Contrast checked by tests/theme/test_contrast.gd. |
| UI theme (buttons, panels, labels, fonts) | src/theme/ui_theme.gd | Built in code with StyleBoxFlat and the Outfit font. |
| Towers (6, each in 4 looks), creatures (11), bosses (4), status marks, HUD glyphs | src/theme/silhouettes.gd, with the src/theme/ink_pen.gd helper | Drawn with `_draw()` calls. Shape distinctness checked by tests/theme/test_silhouettes.gd. |
| Map ground, scenery, roads, spots, sockets, gates, base, entrance, route lines | src/theme/map_art.gd | Drawn in code on the level grid. |
| Wordmark | src/theme/wordmark.gd | Drawn in code. |
| Launcher icons: icons/icon_192.png, icon_foreground_432.png, icon_background_432.png, icon_monochrome_432.png | tools/icon/make_icon.gd drawing src/theme/icon_art.gd | Generated and committed. Rerun the tool after any change to the icon art. |
| Store icon: docs/store/graphics/icon_512.png | tools/store/make_graphics.gd drawing src/theme/icon_art.gd | Generated and committed. 512x512 for the Play listing. |
| Store feature graphic: docs/store/graphics/feature_1024x500.png | tools/store/make_graphics.gd, with the wordmark, palette and silhouettes from src/theme/ | Generated and committed. 1024x500 for the Play listing. |
| Store screenshots: docs/store/graphics/screen_1_front_door.png to screen_5_wave.png | tools/store/make_screenshots.gd running the real app at 1080x2160 | Generated and committed. The build and wave screens play 3 waves out of sight first. Retake after any visible UI change. |
| docs/art/ review images (silhouettes, tiers, grid maps, map pieces, gate looks, wordmark, icon preview) | tools/icon/art_review.gd | Review images, not shipped. |
| docs/art/*.png screenshots, icon idea and silhouette sheet | prototypes/theme/screenshots.sh running the slice (the slice was deleted on 2026-10-24) | Review images, not shipped. |
