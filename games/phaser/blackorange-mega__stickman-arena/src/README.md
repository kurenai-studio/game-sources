# Stickman Arena

A stage-based Stickman fighting game. You play a customizable hero and fight a
progressively stronger opponent each stage until you've cleared them all.

Built with **Phaser 3 + TypeScript + Vite**, wrapped for mobile with
**Capacitor** so the same codebase runs on **Web, Android, and iOS**.

---

## Quick start

```bash
npm install      # install dependencies
npm run dev      # play in the browser at http://localhost:5173
npm run build    # type-check + produce a production build in dist/
```

Open the dev URL on your phone (same Wi-Fi) to test touch controls — the server
is exposed on your LAN.

### Controls

| Action  | Keyboard (web)     | Touch (mobile) |
| ------- | ------------------ | -------------- |
| Move    | `A`/`D` or `←`/`→` | ◀ ▶ buttons    |
| Jump    | `W` / `Space`      | JUMP           |
| Guard   | `S` / `↓` (hold)   | GRD (hold)     |
| Light   | `J`                | A              |
| Heavy   | `K`                | B              |
| Special | `L`                | SP             |

Guarding cuts incoming damage by ~70% but steadily drains stamina, and you
can't move or attack while blocking — time it around the enemy's swings.

---

## Project structure

```
Beheshti/
├── index.html              # page shell, mobile viewport + safe-area handling
├── package.json            # scripts & dependencies
├── vite.config.ts          # bundler config (relative base for Capacitor)
├── capacitor.config.ts     # native app id / name / web dir
├── tsconfig.json
│
├── public/                 # static files copied as-is into the build
│   └── content/            # ★ ALL game content lives here (no rebuild to edit)
│       ├── stages.json     #   the campaign: which hero, which stages, order
│       ├── characters/     #   one JSON per character (hero + enemies/bosses)
│       │   ├── hero.json
│       │   ├── thug.json
│       │   ├── ninja.json
│       │   └── titan.json
│       └── sprites/        #   character images (SVG/PNG)
│           └── stickman.svg
│
└── src/                    # game code
    ├── main.ts             # Phaser game config + scene list (entry point)
    ├── config.ts           # tunable constants (size, gravity, ground)
    ├── types.ts            # TypeScript shapes for the JSON content
    ├── ContentLoader.ts    # fetches & validates JSON + loads sprites
    ├── InputManager.ts     # keyboard + on-screen touch buttons
    ├── Fighter.ts          # a combatant: HP, stamina, attacks, damage
    ├── ui/
    │   └── StatusBars.ts   # HP + stamina HUD bars
    └── scenes/
        ├── BootScene.ts    # loads content, then → Menu
        ├── MenuScene.ts    # title screen
        ├── FightScene.ts   # the actual fight (one per stage)
        └── ResultScene.ts  # win / lose screen
```

**The golden rule:** game *content* (characters, stats, stages, art) lives in
`public/content/`. Game *behaviour* lives in `src/`. You can build an entire new
roster and campaign without touching the code in `src/`.

---

## Adding a custom character or boss

1. **Add the art.** Drop an image into `public/content/sprites/`, e.g.
   `dragon.png`. SVG or PNG both work. (The included stickman is white so the
   per-character `tint` can recolor it; for your own colored art, omit `tint`.)

2. **Create the character file.** Add `public/content/characters/dragon.json`:

   ```json
   {
     "id": "dragon",
     "name": "Fire Dragon",
     "description": "Breathes fire. Hits like a truck.",
     "sprite": "content/sprites/dragon.png",
     "tint": "#ff7043",
     "stats": {
       "maxHp": 160,
       "maxStamina": 110,
       "staminaRegen": 14,
       "moveSpeed": 190,
       "jumpVelocity": 500
     },
     "attacks": {
       "light": { "name": "Claw", "damage": 12, "staminaCost": 10, "range": 85, "cooldown": 500 },
       "heavy": { "name": "Tail Whip", "damage": 22, "staminaCost": 28, "range": 95, "cooldown": 1000 }
     },
     "special": { "name": "Fire Breath", "damage": 40, "staminaCost": 50, "range": 140, "cooldown": 4000 }
   }
   ```

   > `id` **must** match the filename (`dragon.json` → `"id": "dragon"`).

3. **Use it.** Reference the `id` in `public/content/stages.json` — either as the
   `player`, or as a stage's `enemy`:

   ```json
   { "id": 6, "name": "Dragon's Lair", "enemy": "dragon", "difficulty": 1.2, "background": "#2b1212" }
   ```

That's it — no code changes. Every field is documented in
[`src/types.ts`](src/types.ts).

### Stage fields

| Field        | Meaning                                                            |
| ------------ | ----------------------------------------------------------------- |
| `id`         | Stage number (display only).                                       |
| `name`       | Shown on the stage banner.                                         |
| `enemy`      | `id` of the character to fight.                                    |
| `difficulty` | Stat multiplier. `1` = base; `1.4` = +40% HP and faster, etc.      |
| `background` | Arena fill color (hex).                                            |
| `intro`      | Optional flavor text on the banner.                               |

Reuse one character at rising `difficulty` to make it a tougher rematch, or
introduce brand-new characters as bosses. Stages are fought in array order.

---

## Shipping to mobile (Capacitor)

After `npm install`, add whichever native platforms you need (run once):

```bash
npm run cap:add:android     # requires Android Studio + JDK
npm run cap:add:ios         # requires a Mac with Xcode
```

Then build the web bundle and open the native project:

```bash
npm run cap:android         # builds, syncs, opens Android Studio → Run
npm run cap:ios             # builds, syncs, opens Xcode → Run
```

`cap:sync` re-copies the latest `dist/` into the native shells; re-run it after
any change. The `android/` and `ios/` folders are generated and git-ignored.

For a plain **web deploy**, just `npm run build` and host the `dist/` folder on
any static host.

---

## Balancing & feel

Global feel (game size, gravity, ground height) is in
[`src/config.ts`](src/config.ts). Per-character power is in the JSON files.
Enemy AI aggressiveness scales with a stage's `difficulty` — see
`updateEnemyAI` in [`src/scenes/FightScene.ts`](src/scenes/FightScene.ts).
