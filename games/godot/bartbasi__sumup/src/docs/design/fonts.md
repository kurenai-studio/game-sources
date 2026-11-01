# Font comparison for Hard Stop 1

> Bart's decision at Hard Stop 1: Gumdrop and Nova use Outfit, Slate uses the system font. See docs/DESIGN_SYSTEM.md and docs/ASSETS.md.

Bart's question: ship with the device's system font, or bundle one free open-license font? Every other visual in the game is made in code, and a font file would be the one exception.

## What you are looking at

- **The twelve main screens** (`<direction>-<screen>.png`) use the system font. The token files ask for Roboto first, then Segoe UI, then sans-serif. On this Windows machine that resolves to **Segoe UI**, the weights from Light (300) to Black (900).
- **On Android** the same list resolves to **Roboto**, which every Android phone carries, so the game looks the same on all phones. Roboto is a little more neutral and geometric than Segoe UI, with slightly taller digits (cap height 0.711 of the size against Segoe UI's 0.700), so the label sizes that pass here pass on Android too. If we listed sans-serif first instead, phones would use the maker's own font (Samsung One UI, for example), which we could not test against.
- **The Outfit captures** (`-outfit.png`) are the same screens with every role in Outfit at the same weights: all four Slate screens, plus the Gumdrop and Nova board screens so the font can be judged whichever direction Bart picks.

## What Outfit adds

- **What it is:** Outfit, by Rodrigo Fuenzalida, SIL Open Font License 1.1. One variable file holds every weight from 100 to 900.
- **Numerals with character.** The forms are rounder and more geometric, with an open 4 and a flagged 1, so the score and the tile numbers look designed rather than default.
- **The same on every device.** The captures would be exactly what ships, and the label check measures the real font: `godot --headless --path . --script res://tools/label_check.gd -- --font <path>` passes all 24 checks with Outfit. 4 character digits measure 12.3 to 12.4 dp on a 56 dp tile.
- **Gumdrop** gains the most. Outfit Black turns the numbers into round, toy-like shapes that match the candy tiles.
- **Nova** looks refined in Outfit Light. It is a small step up from the system font.
- **Slate** softens. Outfit's geometric shapes pull against Slate's editorial grotesk feel, and Slate's tight display tracking (-6, tuned for Segoe UI) would need retuning to about -2, because Outfit's digits already sit close.

## What shipping it would mean

- **Two files in the repo:** `Outfit[wght].ttf` (110,884 bytes) and its license text `OFL.txt` (4,389 bytes), kept side by side.
- **A log entry:** both are recorded in docs/ASSETS.md as the only third party files in the game. It needs Bart's explicit approval, because it relaxes the "nothing third party" rule in CLAUDE.md.
- **License terms:** the OFL lets us bundle the font with the app for free; we would use it unmodified. It requires shipping the license text with the font, and it forbids selling the font on its own.
- **Cost:** the APK grows by about 110 KB. Runtime cost is the same as the system font.

## Recommendation

- **With Slate, my first pick:** keep the system font. Roboto's neutral grotesk is what Slate's editorial design wants, and the repo stays free of third party files.
- **If Bart picks Gumdrop:** bundle Outfit. It is a visible upgrade worth one file.
- **If Bart picks Nova:** either works, and Outfit is slightly better.
