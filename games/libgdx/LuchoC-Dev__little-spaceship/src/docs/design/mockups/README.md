# Mockups

Three pages that draw the visual direction instead of describing it, at the resolution the game
actually runs at.

| Page | Shows | Answers |
|---|---|---|
| [`combat.html`](combat.html) | the level 1 combat screen, three moments of it | does the direction survive a real frame |
| [`screens.html`](screens.html) | six of the MVP's seven screens — credits is not drawn | is every screen reachable, legible and free of what the spec excludes |
| [`reference.html`](reference.html) | palette, sizes, colliders, silhouettes, both fonts | what do I need open while drawing |

They are pixel-exact: the framebuffer holds **palette indices**, not colours, and it is blown up to
the canvas at an integer factor with smoothing off. That is what lets a page prove no pixel escaped
`ls32`, colour every pixel by the set it belongs to, and say out loud when the browser is scaling
it fractionally.

## Running them

Open any of the three `.html` files in a browser. They are self-contained — no server, no build
step to view them.

## Changing them

The `.html` files are **generated**. Edit `src/`, then:

```
python docs/design/mockups/build.py
node docs/design/mockups/check.js
```

Each page has to be one self-contained file to be publishable, but three copies of the rasteriser
would rot the moment a sprite changed, so the copying happens in `build.py` rather than by hand.

| In `src/` | Is |
|---|---|
| `NN-*.js` | the engine, concatenated in numeric order, shared by every page |
| `<page>.page.html` | that page's title and markup |
| `<page>.ui.js` | that page's own interface code |
| `shared.css` | the stylesheet every page uses |
| `<page>.css` | optional, appended after `shared.css` for one page |

`build.py` picks pages up by looking for `*.page.html`, so a fourth page needs no change to it.

The engine never touches the DOM, which is why `check.js` can run it — and each page's interface —
in node with a stub document.

## Adding a sprite

This is the loop art production runs in. Do it **before** drawing the final art, not after.

1. Add the entry to `SPRITES` in [`src/01-sprites.js`](src/01-sprites.js): the declared `w`, `h`,
   the collider `r`, and the character art. The character-to-colour map is at the top of
   [`src/00-palette.js`](src/00-palette.js).
2. Place it in a scene in [`src/03-scenes.js`](src/03-scenes.js), or in the sheet in
   `src/reference.ui.js`, or both.
3. Run `build.py`, then `check.js`.

`check.js` fails if the art does not match its declared size, if a character is not a palette
colour, if a dimension is even, if a gameplay sprite reaches for a background colour, or if enemy
fire uses anything outside the reserved band. Those are the failures that are otherwise invisible
until the level is running.

Then look at it at ×1 next to the others. A silhouette that reads on its own and disappears in a
crowd is the normal failure, and this is the cheap place to find it.

## What these are not

Silhouettes stand in for art that has not been drawn. What is exact here is the **footprint**, the
**palette**, the **HUD geometry** and the **font metrics** — not the craft. Two places where the
mock stands in for something the real renderer does differently, both marked in the source:

- the invulnerability blink is a checker, because an indexed framebuffer has no alpha and the real
  renderer uses a batch tint;
- the carrier and the boss are drawn from primitives rather than character art, because at 39×31
  and 119×87 a hand-typed grid is a transcription error waiting to happen.
