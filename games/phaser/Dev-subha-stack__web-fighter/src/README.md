# web-fighter

A small 2D browser fighting prototype built with Phaser 3 (player vs CPU).

Controls
- Left / Right arrows: move
- Up arrow: jump
- Z: light attack
- X: heavy attack
- C: special attack
- R: restart round after win

How to run locally
- Option A: Python (quick)
  - python3 -m http.server 8000
  - Open http://localhost:8000 in your browser

- Option B: Node (serve)
  - npx serve .
  - Open the URL printed by the tool

What I committed
- index.html
- src/main.js (Phaser game code)
- README.md

Next steps you can ask for
- Add sprite animations / real sprite sheets (I can integrate Kenney or OpenGameArt sprites)
- Add combo buffering, blocking, hitstun and knockback
- Add mobile touch controls or 2-player local support
- Build and publish to GitHub Pages (I can create a branch or guide you)

License: MIT
