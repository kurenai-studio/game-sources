# Neon Snake — open-source HTML5 snake by PlayFennec

A glowing take on the arcade classic. Guide the snake with arrow keys or WASD, eat the apples, and do not bite yourself. Speed ramps up as you score. Best score lives in your browser. No download, no signup.

Play it free on the web: https://playfennec.com/game/neon-snake/
More free browser games: https://playfennec.com

## Play locally

Just open index.html in any modern browser — no build step, no dependencies.

## Controls

- Arrow keys / WASD to steer
- Swipe on touch screens
- Eat apples to grow and score; avoid walls and your own tail

## Tech notes

- Single-file Canvas game (24x18 grid, 720x540), under 300 lines of vanilla JS
- Speed curve: tick drops 8ms every 5 points, floored at 70ms
- Best score persisted in localStorage (wg_best_snake)
- Extracted from the PlayFennec site build (Astro + Tailwind); site-only bits (layout, analytics, 8-language i18n) were stripped. The full 8-language version lives at the link above.

## License

MIT — fork it, jam with it, ship it. If you reuse the code, a link back to https://playfennec.com is appreciated but not required.
