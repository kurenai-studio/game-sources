# Controls

Every shortcut in Rhythm Fest is **rebindable** from the in-game **Settings** screen.
The tables below list the *default* bindings.

> **Heads-up:** **Boost** (gameplay) and **Editor Stop** both default to **Space**.
> They never fire on the same screen, so there's no conflict.

---

## Gameplay

| Action | Default key |
|---|---|
| Lane 1 | `D` |
| Lane 2 | `F` |
| Lane 3 | `J` |
| Lane 4 | `K` |
| Boost (spend charge) | `Space` |

- Press a lane key as its note crosses the hit line. Timing decides the rating
  (Perfect ≤ 45 ms · Great ≤ 90 ms · Good ≤ 140 ms · Miss beyond that).
- For a **hold note**, keep the key down across the note's length to keep earning points.
- Press **Boost** with at least 10 charge to double all points until the meter drains.

---

## Level editor

| Action | Default key |
|---|---|
| Lane 1–4 (place notes) | `D` `F` `J` `K` |
| Mark note as **boost** | hold `Ctrl` while pressing a lane |
| Stop & **save** | `Space` (Editor Stop) |
| Undo last note | `Backspace` |
| Cancel (discard everything) | `Esc` |

See the [Level Editor guide](LEVEL_EDITOR.md) for the full workflow.

---

## Menus & global

| Action | Default key |
|---|---|
| Move selection up / down | `↑` / `↓` |
| Move selection left / right | `←` / `→` |
| Confirm / select | `Enter` |
| Back / cancel (to main menu) | `Esc` |

---

## Rebinding keys

1. From the **Main Menu**, open **Settings**.
2. Click a keybind button — it waits for the next key press and captures it.
3. Use the **trash** button next to a binding to clear it.

A lane with **no** key simply can't be hit. Bindings are stored as readable key names in
`settings.json`, alongside music volume, scanlines, and particle toggles.
