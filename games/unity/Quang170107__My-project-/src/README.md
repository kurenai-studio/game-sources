# Geometric Dungeon: 2D Roguelike RPG

Welcome to **Geometric Dungeon**, a fast-paced 2D Roguelike Action RPG built natively in Unity 6!

---

## 🎮 How to Play

### Option 1: ⚡ Run the Standalone EXE (No Unity Required!)
Just double-click **`GeometricDungeon.exe`** to play instantly!
- Make sure `libraylib.dll` and `libwinpthread-1.dll` are in the same folder as the `.exe`.
- The standalone version is a complete C++ port using [raylib](https://www.raylib.com/) — no Unity installation needed.

### Option 2: Just Hit Play! (Unity Editor)
Simply click the **Play** button (`▶`) at the top of the Unity Editor in `SampleScene`.
The game automatically bootstraps the camera, player, audio, dungeon room, UI, shop, inventory, and monsters!

### Option 3: Pre-populate Scene in Edit Mode
In Unity's top menu bar, click:
> **RPG Game** -> **Setup Playable Scene**

This places all Managers, UI, and Player directly into the hierarchy for Edit Mode inspection.

### 🔨 Building the EXE from Source
If you want to rebuild the standalone executable yourself:
1. Install [MSYS2](https://www.msys2.org/) and raylib: `pacman -S mingw-w64-ucrt-x86_64-raylib`
2. Run `build_game.bat` (CMD) or `build_game.ps1` (PowerShell)
3. The script compiles `StandaloneApp/main.cpp` and copies all required DLLs automatically.

---

## 🕹️ Controls

| Action | Primary Input | Secondary / Alternative | Description |
| :--- | :--- | :--- | :--- |
| **Move** | `W` `A` `S` `D` | Arrow Keys / Left Gamepad Stick | Smooth 8-directional movement with walk squash |
| **Aim** | Mouse Cursor | Facing Direction | Weapon rotates towards aim, knight flips facing direction |
| **Melee Attack** | Left Mouse Button (`LMB`) | `Space` / `J` | 120° slash arc, knocks back enemies |
| **Dash / Dodge Roll** | Right Mouse Button (`RMB`) | `Left Shift` / `K` | Speed burst + Invulnerability Frames + Ghost trail |
| **Special Skill (Nova)** | `Q` or `E` | `U` | 360° radial pulse pushing & damaging all nearby foes |
| **Inventory (Kho đồ)** | `I` | `Esc` to close | View 4 equipped slots, stats breakdown & pause game |
| **Settings (Cài đặt)** | `Esc` (Settings Button in UI) | - | Resolution, VSync, Screen Shake toggle, Window mode |
| **Open Chest / Collect** | Walk near / Touch | - | XP gems & coins are magnetically drawn to you |
| **Restart Game** | `R` (on Game Over screen) | Click "Play Again" / Click anywhere | Restarts a fresh dungeon run |

---

## ⚔️ Gameplay Mechanics

### 1. Floor Progression & The Portal
- You start in a fortified chamber on **Floor 1**.
- Each room contains waves of monsters, obstacles for tactical cover, and treasure chests.
- Defeat all monsters in the chamber to **open the Exit Portal**.
- Stepping onto the glowing portal teleports you deeper into the dungeon!

### 2. Monsters & Archetypes
- 🟢 **Slime Chaser** (lime slime): Bouncy, fast, lunges when in striking distance.
- 🔴 **Crimson Spitter** (horned red slime): Kites away, keeps distance, and fires aimed energy darts.
- 🟣 **Armored Slime** (purple slime with rock plates): High health, slow march, telegraphs a massive AOE ground stomp!
- 👑 **The Void Sovereign** (crowned boss slime on Floor 5, 10...): Giant slime that unleashes 10-way bullet spirals, charging rushes, and leaves behind massive loot chests!

### 3. Equipment & Inventory System (Kho đồ)
- **4 Equipment Slots**: Weapon, Armor, Boots, Ring.
- **4 Rarity Tiers**: Common (White), Rare (Blue), Epic (Purple), Legendary (Orange).
- **Dynamic Weapons**: Equipping Swords, Blades, Axes, or Spears dynamically updates the weapon sprite and scale held in the player's hands!
- **Auto-Equip & Auto-Sell**: Walking over equipment drops automatically equips them if they are stronger than your current gear, or sells them for bonus gold if weaker!

### 4. Merchant Shop (Cửa hàng Thương nhân)
- Spawns every 3 floors (Floors 3, 6, 9...).
- Rest area with a floating Merchant NPC.
- Sells 4 level-scaled equipment pieces + instant Health Potions.
- Spend your accumulated Gold to power up before upcoming Boss floors!

### 5. Level-Up Upgrade Cards
Every time you level up, the game pauses and presents **3 random upgrade cards**:
- **Titan's Heart**: +25 Max Health & instant heal
- **Sharpened Edge**: +8 Sword Damage
- **Swift Wind**: +15% Move Speed
- **Flurry**: +30% Attack Speed
- **Blink Step**: -0.2s Dash Cooldown
- **Vampiric Touch**: +8% Lifesteal on all melee attacks
- **Iron Aegis**: +2 Flat Damage Reduction Armor

### 6. Audiovisual Juice & Polish
- Procedural retro sound effects synthesized directly in code (zero missing audio files!).
- Floating damage numbers with color coding (white for enemy hit, red for player hurt, green for healing, yellow for gold).
- Hit flashes, camera screen shake, and squash-and-stretch walk bobbing.
- Dash afterimages / ghost trail effects.

---

## 📁 Project Architecture

- `Assets/Scripts/Player/`: `PlayerController.cs`, `CameraFollow.cs`, `InputHelper.cs`
- `Assets/Scripts/`: `EquipmentItem.cs`, `EquipmentManager.cs`, `EquipmentIcons.cs`, `EquipmentPickup.cs`, `InventoryUI.cs`, `PlayerWeaponVisual.cs`
- `Assets/Scripts/Combat/`: `CombatStats.cs`, `Projectile.cs`
- `Assets/Scripts/Enemies/`: `EnemyBase.cs`, `ChaserEnemy.cs`, `RangerEnemy.cs`, `BruteEnemy.cs`, `BossEnemy.cs`
- `Assets/Scripts/Loot/`: `LootItem.cs`, `LootManager.cs`
- `Assets/Scripts/Dungeon/`: `DungeonManager.cs`, `DungeonObstacle.cs`, `ExitPortal.cs`, `ShopManager.cs`, `SpriteFactory.cs`, `EnemySpriteBytes.cs`, `GameBootstrap.cs`
- `Assets/Scripts/UI/`: `GameUI.cs`, `DamageNumberManager.cs`, `SettingsManager.cs`
- `Assets/Scripts/Editor/`: `RPGEditorSetup.cs`

## 🆕 Changelog (balance & polish pass)

- **Fix:** Boss floors (5, 10, 15, 30...) are no longer replaced by the Merchant Shop when they coincide with a shop floor.
- **Balance:** Armor is now a percentage reduction with diminishing returns (armor 10 = -50% damage) instead of a flat reduction that made enemies deal 1 damage.
- **Balance:** Lifesteal is capped at 30% and heals once per swing instead of once per enemy hit.
- **Balance:** Enemy counts per floor are capped (10 Chasers / 8 Spitters / 5 Armored Slimes) so late floors stay readable.
- **Fix:** Gaining several levels at once (e.g. from a boss kill) now queues the upgrade cards instead of overwriting them.
- **New:** Cover pillars are randomised every floor (4-7 pillars), keeping spawn, portal and chest areas clear. Enemies no longer spawn inside pillars.
- **New:** Boss enrages below 50% HP (faster movement, shorter attack cycle, 16-way bullet ring).
- **New:** Best floor is saved (PlayerPrefs) and shown on the Game Over screen, with a NEW RECORD marker.
- **Fix:** The shop no longer lets you buy a potion at full HP or gear that is not an upgrade (previously the gold was spent and only partly refunded).
- **Repo:** Added MIT license.

## 🗺️ Level variety update

- **4 biomes** that change every 3 floors (Ancient Crypt, Overgrown Ruins, Molten Depths, Frozen Halls): different colour palette and a different enemy mix (e.g. Ruins = more Chasers, Molten = more Spitters, Frozen = more Armored Slimes).
- **5 room layouts**, never repeated twice in a row: Scattered pillars, Pillar Ring, 2x2 Blocks, Bastion walls and an Open arena. Boss and shop floors avoid layouts that block them.
- **Floor modifiers** on normal floors: Swarm, Elite Hunt, Sniper Nest, and an enemy-free Treasure Vault with extra chests.
- Checkerboard floor shading for a bit more depth.


## 🎯 Combat depth update (crits & combos)

Inspired by Hades, Dead Cells and Soul Knight:

- **Critical hits:** every melee swing and Nova rolls a crit (base 5%, x2 damage). Crits show a yellow `!` damage number, hit harder knockback and a little extra screen shake.
- **2 new upgrade cards:** **Eagle Eye** (+8% crit chance, capped at 60%) and **Arcane Focus** (-0.8s Nova cooldown, min 2.5s). The Nova cooldown ring in the HUD follows the new value.
- **Kill combo:** killing enemies within 3 seconds of each other builds a combo shown on the right side of the screen (colour heats up at x10 and x20). Every 5th kill pays out bonus gold that scales with the combo. Taking damage or dying breaks the combo.
- New file: `Assets/Scripts/Combat/ComboSystem.cs` (creates itself on the first kill, no scene setup needed).


## ⚡ High-Performance Multi-Language Core & Relic System Update

### 🚀 1. Multi-Language High-Performance Architecture (C++ / C# / Python)
- **Native C++ Engine Plugin (`NativeRoguelikeCore.dll`)**:
  - Compiled with GCC 16 `-O3` native SIMD optimizations into `Assets/Plugins/x86_64/NativeRoguelikeCore.dll`.
  - **Spatial Hash Grid (2D Partitioning)**: Accelerated $O(1)$ spatial queries for entity detection, range lookups, and projectile checks. Benchmarked at **17.6x faster** than managed $O(N^2)$ brute-force queries!
  - **Swarm Boids & Steering**: Vectorized separation and attraction calculations preventing monster clustering.
  - **Procedural Cellular Automata**: Native generator for cave layout and hazard map carving.
  - **Universal C# Fallback**: Seamless managed C# implementation so the project runs on any platform even without the native binary.
  - One-click build scripts provided: `build_native.bat` & `build_native.ps1`.
- **Zero-GC Object Pooling (`ObjectPoolManager.cs`)**:
  - Pre-warmed zero-allocation pooling for `DamageNumberManager`, `Projectile`, and visual effects. Eliminates GC allocation spikes and prevents framerate stutter during intense battles.
- **Python Monte-Carlo Balance & Benchmark Suite**:
  - `tools/balance_simulator.py`: Monte-Carlo combat simulation modeling player DPS, floor scaling, and survival rates across Floors 1–50.
  - `tools/benchmark_native.py`: Ctypes-based benchmark suite measuring native spatial hash grid performance vs managed calculations.

### 🏺 2. Ancient Relic Synergy System (Hệ thống Cổ vật & Hiệu ứng)
- Defeating dungeon bosses awards ancient relics with passive synergies:
  - ⚡ **Thunder Conduit**: Melee and skills zap chain lightning across up to 3 nearby enemies.
  - 🧪 **Toxic Fang**: Attacks inflict corrosive poison dealing damage over 3 seconds.
  - ❄️ **Frost Core**: Critical hits freeze/chill foes, cutting their movement speed by 50%.
  - 🛡️ **Divine Aegis**: Recharges a sacred barrier every 12 seconds that negates an incoming hit.
  - 🩸 **Blood Chalice**: Slain enemies have a 25% chance to drop blood healing orbs.
  - 💥 **Combustion Sigil**: Defeated monsters detonate in a fiery shockwave.
- Active relics are dynamically displayed in the Top-Left HUD.

### 🧭 3. Tactical Radar Mini-Map (`MiniMapUI.cs`)
- Real-time top-down radar in the top-right HUD:
  - Green pulsing dot: Player position.
  - Red dots: Standard monsters.
  - Golden/large skull marker: Boss slime.
  - Cyan glowing star: Exit portal.
  - Press `M` key to toggle the mini-map on/off anytime.

### 👹 4. Elite Monster Encounters
- Starting from Floor 3, monsters have a 20% chance to mutate into **Elite Slimes**:
  - Larger scale, 1.8x HP, 1.3x contact damage, golden glowing aura.
  - Guarantees 100% coin drop and 2x experience gems.

---

## Combat depth update (crits, combos, status effects)

### 💣 New enemy: Bomber Slime (floor 4+)

- Rushes you, then stops and blinks for 0.75s with a red warning circle before exploding (20 damage in a 2.2m radius).
- The blast also hurts other enemies (40 damage), so lead it into a crowd. Kills caused that way still count for your combo.
- Kill it before the fuse ends and it never explodes. A self-destruct drops no loot and does not count for the combo.
- 1 Bomber on floor 4, +1 every 2 floors, max 4. Not present on Swarm floors.

### 🗡️ Crit on gear & stats

- Weapons can now roll a **crit chance** affix (+2% × rarity/floor scaling, max +20% per weapon). It shows in the shop, the inventory item rows and the new fourth line of the inventory summary (Crit Chance / Crit Damage / Nova Cooldown).
- The total crit chance used in combat is capped at 60%, no matter how much gear and upgrades stack.

### 🔥❄️ Status effects

- **Ember Edge** (upgrade): melee hits and Nova set enemies on fire for 3s. Each level adds 50% of your base damage per second (ticks every 0.5s). Re-hitting refreshes the timer.
- **Frost Touch** (upgrade): hits slow enemies for 2s, -15% speed per level, down to 40% speed at level 4.
- Both stack with crits, combo and Bomber friendly fire. Burn kills count for your combo. New file: `Assets/Scripts/Enemies/EnemyStatus.cs`.

### 🛡️ Mini-boss & run summary

- **Warden Brute** appears on floors 3 and 8: a larger, golden Armored Slime (180 HP, ground slam, hits for 20) that always drops equipment.
- The game-over screen now also shows your **Best Combo** for the run (reset every new run).

### 🔊 Sounds

New generated SFX (no audio files needed): `explode` (Bomber blast), `fuse` (accelerating beeps while the Bomber's fuse burns) and `combo` (every 5th kill of a combo).

### 🎨 Graphics upgrade

All done in code, no scene/asset setup needed (`Assets/Scripts/Dungeon/VisualFX.cs`, starts automatically):

- **Post-processing (URP):** bloom on bright effects, a soft vignette, and slightly boosted saturation/contrast. Skipped automatically if the project is not running URP.
- **Damage feedback:** the screen edge pulses red when the player gets hurt (stronger for bigger hits).
- **Particles (pooled):** white hit sparks on every hit, gold ones on crits, colour-matched debris when enemies die, and a fiery burst when a Bomber explodes. Capped to keep the frame rate stable on crowded floors.
- **Shadows:** every enemy now has a soft ground shadow like the player.
- **New Bomber Slime sprite:** hand-drawn pixel art (shaded orange body, angry eyes, lit fuse) instead of a plain circle.

- **Ambient dust:** soft floating motes tinted by the floor's biome colour.
- **Level-up and Nova bursts:** a golden/cyan burst when you level up, and a cyan shockwave of sparks when you cast Nova.

- Press **F3** in game to toggle the post-processing (bloom/vignette) on or off.

- **Pickup sparkles:** coins, XP gems, potions and opening a chest all pop small colour-matched sparks.

### 🩸 Blood Shrine (random event)

- From floor 2 (never on boss, shop or treasure floors) there is a 30% chance of a **Blood Shrine** in the room.
- Touch it to pay 15% of your max HP (min 10) for one **random free upgrade** from the whole pool. One use per shrine.
- It never kills you: if you are too weak it refuses and costs nothing. New file: `Assets/Scripts/Dungeon/ShrineAltar.cs`.

---

## Standalone EXE update (C++ / raylib)

`GeometricDungeon.exe` is a **separate C++ port** (`StandaloneApp/main.cpp`), not the Unity project, so it needs its own updates. It now has:

- **Bomber Slime** (floor 4+): rushes you, blinks with a red warning circle, then explodes (20 damage, hurts other enemies too). A self-destruct drops no loot and does not count for the combo.
- **Warden Brute** mini-boss on floors 3 and 8 (golden, 180 HP, always drops a potion and gold).
- **Blood Shrine** (floor 2+, 30% chance, never on boss floors): touch it to pay 15% max HP for a random free upgrade. It never kills you.
- **Ember Edge** (burn) and **Frost Touch** (slow) upgrade cards.
- **Effects:** hit sparks, death debris, level-up/Nova/pickup bursts, floating dust, vignette with a red pulse when hurt, short hit-stop on crits and boss kills.
- **Game over** screen shows your Best Combo.

The new exe is built statically (no `libraylib.dll` needed next to it). To rebuild it yourself, run `build_game.ps1` as before.
