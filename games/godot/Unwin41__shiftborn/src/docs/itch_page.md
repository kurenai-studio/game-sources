# itch.io page kit

Everything needed to fill in the Shiftborn page on itch.io. The images are
in `docs/media/`.

## Settings

- **Title:** Shiftborn
- **Short description / tagline:** Shift between warrior and mage to survive the horde.
- **Classification:** Game
- **Kind of project:** HTML (upload the web build zip, or let the CI job push it with butler) plus downloadable Windows, macOS and Linux builds.
- **Viewport:** 1280 × 720, with "Click to launch in fullscreen" off and the fullscreen button on.
- **Genre:** Action. **Tags:** survivors-like, roguelite, pixel-art, bullet-heaven, godot, game-off, shapeshifting.
- **Cover image (630 × 500):** `docs/media/itch_cover.png`
- **Screenshots:** `horde.png`, `perfect_shift.png`, `evolution_cards.png`, `boss.png`, `results.png`, `title.png`
- **Gameplay GIF:** `gameplay.gif`
- **Source code:** https://github.com/Unwin41/shiftborn

## Description

**Shiftborn** is a five-minute survivors-like built around one button: **shift**.

You are two people at once. The **warrior** is slow and spins a heavy axe around himself. The **mage** is fast and snipes the nearest enemy with bolts. Press Space (or A) to swap between them at any moment, and keep swapping, because the horde is built to punish whoever stays the same:

- **Immunities.** Skulls are immune to magic, spirits to the axe. The diamond above an enemy shows the only form that hurts it.
- **Energy.** The form you are using tires out and its damage drops; the resting form recovers.
- **Perfect shift.** Shift just as something is about to hit you: time slows, you cannot be hurt for a moment and the new form gets a burst of energy.
- **Evolutions.** Max out one warrior and one mage upgrade and they fuse into a hybrid power that works in both forms: Arcane Orbit, Storm Cleaver, Blood Pact and Twin Soul.

Two mini-bosses arrive at 1:45 and 3:15. At 4:30 the waves stop and **The Shifting Demon** appears. It keeps swapping the form it resists, so you have to keep shifting too.

The first run opens with a short guided tutorial.

### Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD / arrow keys | Left stick / D-pad |
| Shift | Space / Shift | A / RB |
| Pause | Esc / P | Start |
| Mute | M | |

Attacks are automatic.

### Credits

Made for GitHub Game Off 2026 (theme: SHIFT) with Godot 4.7. Art and font: Ninja Adventure Asset Pack by Pixel-boy and AAA (CC0). Music: pmiller, Zane Little Music and XCVG (CC0, via OpenGameArt). Sound effects generated in code. Full list in [CREDITS.md](https://github.com/Unwin41/shiftborn/blob/main/CREDITS.md).

## Publishing from CI

The release workflow pushes builds to itch.io on every `v*` tag once these exist:

```sh
gh secret set BUTLER_API_KEY            # from https://itch.io/user/settings/api-keys
gh variable set ITCH_GAME --body "<your-itch-username>/shiftborn"
```

Channels: `web`, `windows`, `linux`, `mac`.
