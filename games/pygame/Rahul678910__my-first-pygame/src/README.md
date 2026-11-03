# 🗡️ Procedural Dungeon Crawler

A procedurally generated top-down rogue-lite dungeon crawler built in Python with **Pygame**.  
No external image or sound assets required — every room, entity, chest, and particle effect is dynamically rendered with Pygame shapes and colors.

![Gameplay GIF placeholder](docs/gameplay.gif)

---

## ✨ Features

| Category | Details |
|----------|---------|
| 🗺️ **Procedural Generation** | Randomized rooms connected by 2-tile wide corridors using Prim's MST + loop corridors. New layout every run with guaranteed full reachability. |
| 🧍 **Player Character** | Top-down WASD movement with smooth wall-sliding, facing direction reticle, health bar, melee cleave, and ranged magic shot. |
| 👾 **Enemy Types & AI** | 3 distinct monster types: **Chaser** (charges on sight), **Patroller** (waypoints → pursuit), and **Shooter** (standoff range + projectile attacks). |
| 💎 **Loot & Economy** | Health potions (restore HP), weapons (boost damage), and coins dropped from defeated foes and hidden dungeon chests. |
| 🧙 **Dungeon Merchant NPC** | Friendly Wandering Trader in the safe zone! Spend hard-earned coins on healing potions, weapons, dungeon keys, and permanent Max HP Heart Containers. |
| 📦 **Interactive World** | Contextual floating prompts appear over nearby objects (`[E] Open Chest`, `[E] Unlock Door`, `[E] Pray at Shrine`, `[E] Trade with Merchant`, `[E] Descend Stairs`). |
| 🗝️ **Locked Doors & Vaults** | Secret vault chambers sealed behind sturdy locked doors. Find the hidden Dungeon Key in outlying chests or from the Merchant to unlock high-tier gilded Vault Chests. |
| ⛩️ **Ancient Shrines** | Mystical altars placed across chambers; pray to heal wounds when hurt or empower your weapon with bonus attack damage. |
| 🎒 **Categorized Inventory** | 3 completely separated sections for **Weapons** (equipped card & weapon swapping), **Healing** (potion pouch & values), and **Keyring & Valuables** (keys & treasury). |
| ⚡ **Quick-Heal in Combat** | Press `Q` or `H` during active battle to instantly drink your best healing potion without opening menus. |
| 🔊 **Zero-Asset Procedural SFX** | 14 synthesized retro sound effects generated in memory using mathematical waveforms (`sfx.py`): melee whooshes, energy bolts, hit thuds, enemy death bursts, coin chimes, potion glugs, and chest jingles without requiring any external audio files. |
| 🗺️ **Minimap & Fog of War** | Fog-of-war system with 3 visual states (illuminated, previously explored, and pitch black). Toggleable minimap overlay (`M`) showing discovered rooms, stairs, and player. |
| 🪜 **Staircase Checkpoint** | Dedicated 3×3 platform housing the exit portal in the room furthest from the entrance. Press `E` to descend to the next floor. |
| 💥 **Visual Juice & Effects** | Directional screen shake on impacts, dynamic hit sparks, enemy death bursts, loot sparkles, and glowing stair portals. |
| 🎬 **Menus & Best Floor Record** | Retro main menu, interactive controls guide (`C`), game over summary with session stats, and persistent high score saved to `best_floor.txt`. |

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `WASD` / `↑↓←→` | Move adventurer (slides smoothly along walls) |
| `Space` | Melee swing (wide cleave arc in facing direction) |
| `F` | Ranged attack (fires a glowing energy bolt) |
| `Q` / `H` | **Quick-Heal** (instantly drinks best potion in combat) |
| `E` | **Contextual Interact** (trade with Merchant NPC, open chests, unlock doors, shrines, descend) |
| `I` | Toggle categorized inventory (press `1`–`9` to use potion or swap weapon) |
| `M` | Toggle exploration minimap (shows rooms, player, and Merchant NPC) |
| `C` | View controls and survival guide |
| `F11` / `Alt+Enter` | **Toggle fullscreen** (scales cleanly to any display) |
| `R` or `Space` | Restart / play again after game over |
| `ESC` | Close shop/inventory / Main menu / Back / Quit |

---

## 📦 Project Structure

```
dungeon-crawler/
├── main.py              # Entry point: game states, HUD, Merchant shop modal, combat loops
├── dungeon.py           # Procedural generation: rooms, corridors, MST connectivity, stair platforms, merchant spawn
├── entities.py          # Player, Enemy AI, Projectiles, MerchantNPC, Chests, Locked Doors, Shrines
├── inventory.py         # Categorized inventory: Weapons, Healing Potions, Keyring & Valuables
├── sfx.py               # Zero-asset procedural sound effects generator (14 synthesized sounds)
├── minimap.py           # Explored-tile tracking, minimap rendering, player, exit, and NPC markers
├── settings.py          # Tunable gameplay constants, color palette, enemy stats, file paths
├── tests/
│   ├── test_dungeon.py   # Tests: room overlap, reachability, vaults, Merchant NPC, stairs
│   └── test_inventory.py # Tests: separate sections, quick-heal, weapon swap, coin purchases
├── best_floor.txt       # Auto-created high score save file
├── requirements.txt     # Python dependencies (pygame, pytest)
├── .gitignore           # Git ignore rules
└── LICENSE              # MIT License
```

---

## 👾 Enemy AI Behaviors

| Type | Visual | Behavior & Attack Pattern |
|------|--------|---------------------------|
| **Chaser** | 🔴 Crimson Square | Sprints directly towards the player upon entering sight range; executes rapid melee bites at close quarters. |
| **Patroller** | 🟠 Amber Square | Patrols waypoint markers throughout its spawn chamber; breaks patrol into full pursuit when the player is spotted. |
| **Shooter** | 🟣 Violet Square | Backs away or keeps a 5-tile standoff distance; periodically fires magical energy bolts at the player. |

*Difficulty scaling:* Monster HP, speed, and spawn counts scale automatically as you delve into deeper floors (+15% HP / +5% Speed / +20% enemy density per floor).

---

## 🚀 Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/dungeon-crawler.git
   cd dungeon-crawler
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the game:**
   ```bash
   python main.py
   ```

*Prerequisites: Python 3.9+ and Pygame 2.1+*

---

## 🧪 Running Automated Tests

Run the test suite using `pytest` or directly with standard `python`:

```bash
# Using pytest
pytest tests/ -v

# Or using standard Python
python tests/test_dungeon.py
python tests/test_inventory.py
```

### Test Coverage
- **Dungeon Generation & Vaults:**
  - Rooms do not overlap (`margin=0` check)
  - Always generates at least 2 connected rooms
  - BFS flood reachability from player start to every room center and exit stairs
  - Exit tile is correctly formatted as `T_STAIRS`
  - Player start position is placed on a walkable floor tile
  - Room geometry and inner boundary calculation
  - Vault room and locked doorway generation (`T_DOOR` and `locked_doors` set)
  - Exit stairs platform is never locked behind a vault door
  - Interactive door locking and unlocking mechanics with Dungeon Key
  - Gilded Vault Chest high-tier loot generation
- **Inventory, Loot & Keys:**
  - Inventory capacity and overflow rejection
  - Auto-tallying of gold/coins without consuming item slots
  - Potions heal HP accurately and respect `max_hp`
  - Weapons equip and grant attack damage bonuses
  - Dropping and removing items
  - Chest loot generation & guaranteed key drops
  - Key item management, slot usage, and door consumption (`consume_key`)

---

## 🗺️ Development Roadmap

- [x] **Phase 1** — Procedural dungeon generation, tile renderer, camera viewport, test suite
- [x] **Phase 2** — Player movement, melee cleave, ranged shot, 3 enemy AI types, projectiles, follow camera
- [x] **Phase 3** — Inventory system (use/equip), loot drops, chest interactions, minimap overlay, 3-state fog of war, message log
- [x] **Phase 4** — Main menu, controls modal, game-over screen, screen shake, particle effects, floor scaling, best-floor persistence

---

## 📄 License

Distributed under the [MIT License](LICENSE).
