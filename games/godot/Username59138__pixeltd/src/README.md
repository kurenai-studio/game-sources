# Pixel TD v0.21

A pixel art tower defense game made with Godot 4.7.2 (GL Compatibility renderer, runs on pretty much any Linux machine with OpenGL 3.3).

**Play it in your browser or download it on itch.io: https://username59138.itch.io/pixel-td**

## Running

```
chmod +x PixelTD.x86_64
./PixelTD.x86_64
```

Progress is saved to `~/.local/share/godot/app_userdata/Pixel TD/pixel_td_save.json`.

## Controls

Every key below is a default and can be changed in **Settings** (gear button in the main menu, or Settings in the pause menu). Keys follow the physical keyboard position, so they work on any layout.

| Action | Default |
|---|---|
| Buy a tower | Button on the right or keys **1–9, 0** (the shop only shows unlocked towers) |
| Place it | Left click on a tile (hold **Shift** to place several) |
| Select a tower | Left click on it |
| Upgrade selected tower | **E** |
| Sell selected tower | **X** |
| Targeting mode | **T** |
| Next wave | **Space** |
| Game speed 1x/2x/3x | **F** |
| Pause | **P** |
| Zoom in / out | Mouse wheel (1x, 2x, 3x) |
| Move the map when zoomed | Hold the mouse wheel and drag |
| Cancel / deselect / back | **Esc** or right click (fixed) |
| Fullscreen | **F11** (fixed) |

Hover over an enemy to see its name, class, HP, speed, armor, fire resistance, control strength, traits (flying, invisible...) and current effects.

## Mechanics

- **Enemy classes I–IV** only weaken control effects (stun, slow): 100% / 70% / 40% / 20%. Damage, including burning, always applies in full.
- **Difficulties:** Light (20 waves), Medium (30), Difficult (40), Hardcore (40 waves, 50 lives), Ultracore (40 waves, 1 life; opens on a map once Hardcore is beaten there). Selling a tower pays back 80% on Light and 70% on the rest. Every difficulty has its own handmade waves; after a win, Continue keeps going with generated waves.
- **Enemy HP is fixed** per enemy type, on every map and difficulty (like TDS). Later waves are harder because of tougher enemy types, bigger crowds and **Bloated** enemies: they look like any other but have twice the HP (hover one to see it).
- **Tower limits:** at most 50 towers in a battle and 10 of each type. The shop shows how many you have.
- **Maps are bought with paper maps.** Only Green Meadow is open at the start. Every battle pays paper maps: a win pays by map tier (Beginner 10, Intermediate 20, Advanced 35, Expert 60) times the difficulty (Light x1, Medium x1.5, Difficult x2.5, Hardcore x4, Ultracore x6); a loss pays 40% of that, scaled by the waves survived. A map costs 30 / 60 / 150 / 300 by tier. Repeat wins pay the same, so you can farm.
- **Towers are bought with paper maps.** Beating a tower's map (a higher difficulty counts too) puts it on sale in the Armory, then you buy it:
  - Soldier: on sale from the start, 25 paper maps
  - Garage: Gas Station on Difficult, 75
  - Flamethrower: Volcano on Medium, 140
  - Sniper: Green Meadow on Difficult, 40
  - Necromancer (Halloween character): Old Graveyard on Difficult, 130
  - Freezer: Frozen Lake on Difficult, 130
  - Toxic Gunner: Acid Refinery on Difficult, 130
  - Toxic Assassin: Acid Refinery on Hardcore, 200
  - Farm: Farmlands on Difficult, 75
  - Minigunner: Green Meadow on Hardcore, 90
- **Halloween event (Oct 10 - Nov 7):** Green Meadow gets an autumn look with jack-o'-lanterns. Only the looks change, the layout stays the same.
- **Volcano:** two short roads, lava on the best spots and an eruption every second wave. Tiles next to the lava flash orange, then towers on them stop shooting for 6 seconds.
- **Murky Swamp:** the boardwalk crosses itself, so towers near the crossing hit enemies twice. The bog eats the best spots.
- **Old Graveyard:** a second road starts at the crypt in the middle of the map. Grave plots take some of the space.
- **Farmlands:** a winding country road between fenced crop fields and a big red barn, which take some of the space.
- **Acid Refinery:** two roads, from the top left and the bottom left, join in the middle. Acid lakes, storage tanks and huge hazard barrels take some of the space.
- **Acid** hurts over time through armor and, while it lasts, eats some of the enemy's armor, so physical towers hit harder too. The strongest acid on an enemy wins; class doesn't weaken it (it's damage, not control).
- **Lead enemies** (from Difficult up) are cast in grey lead: only towers that pierce lead can aim at and hurt them. Fire melts lead and acid eats through it, so the Flamethrower, Toxic Gunner and Toxic Assassin always can; so do Garage cars, the Soldier from AP Rounds and the Sniper from Full Metal Jacket. Gunslinger, Knight, Necromancer and Freezer can't, and undead just bounce off.
- **Invisible enemies** (Ghost, Wraith) are drawn see-through and can only be aimed at by towers that spot them: Gunslinger from Hollow Points, Soldier from AP Rounds, and the Sniper always. The Flamethrower can't aim at them, but its flames still burn any that walk through the cone. Garage cars run them over.
- **Flying enemies** (Bat, Harpy, Gargoyle) follow the road in the air. Gunslinger, Soldier and Sniper can shoot them. Knight, Flamethrower, grenades and cars can't reach them.
- **Skeletons** fall apart when killed and get back up once with half HP (the **Bone Dragon** boss with 30%). **Orc Berserkers** run twice as fast below half HP. **Cave Trolls** heal 2% of their HP a second, but not while they burn or acid eats them.
- The final boss of a run gets a big HP bar at the top of the screen. Hover other enemies to see their HP.
- Hover a tower to see its level on its card ("Lv. 1" ... "Lv. 7").

## Towers

Towers don't all go as far: early game towers (Gunslinger, Toxic Gunner) are cheap and stop at level 5, mid game ones (Garage, Necromancer, Freezer) at level 6, and the pricey end game towers go up to level 7 with upgrades that cost tens of thousands. A tower's top level is shown in gold.

- **Gunslinger:** single shots; armor reduces bullet damage. Quick Draw → Hollow Points → Dual Pistols (2 targets + slow) → Fan the Hammer. An early game tower: 5 levels.
- **Knight:** melee, ignores 50% of armor, every 3rd hit stuns. Sharpened Blade → Cleave → Champion → Templar → Paladin (ignores all armor) → Holy Champion (towers within 48 px deal 15% more damage; auras don't stack).
- **Soldier:** long range rifle bursts. AP Rounds (armor and lead piercing) → Grenades → Machine Gun → Elite Soldier → Heavy Gunner → Commando.
- **Garage:** must be built next to a road. Sends friendly cars (`is_friendly` enemies) that drive along the road towards the enemies. On a crash both sides lose `min(car HP, enemy HP)`. Pickup → Truck → Armored Car (with a turret) → Reinforced Plating → Twin Turret. A mid game tower: 6 levels.
- **Flamethrower:** fire cone and burning, ignores armor, but the Fire Imp is immune. Bigger Tank → Napalm → Blue Flame → Pyromania → Inferno → Dragon's Breath (burns through any fire resistance).
- **Necromancer:** dark bolts that ignore 60% of armor. An enemy his bolt kills rises as a friendly undead (Garage-style crash) with part of its max HP: 20% → 35% → 50% → 70% → 85% → 100%. They rise at a random spot of road inside his range. No flyers, no bosses, and undead never raise more undead. Dark Pact → Bone Army (sees invisible) → Lich → Soul Harvest → Lord of Bones. A mid game tower: 6 levels.
- **Toxic Gunner:** shoots globs of acid, hits flying enemies. Corrosive Mix → Scope (sees invisible) → Acid Splash (acid on everyone around the target) → Toxic Overload. An early game support tower: 5 levels.
- **Toxic Assassin:** fast melee with poisoned blades that ignore 25% of armor, ground only. Poisoned Blades → Swift Strikes → Throwing Daggers (a ranged second attack whose daggers hit flying enemies, flyers first) → Twin Daggers (2 at once, sees invisible) → Master Assassin → Shadow Blade (3 daggers).
- **Freezer:** sprays a cone of ice water. Every enemy in it builds up chill (scaled by class like any control effect): the more chill, the slower it walks, and at 100% it freezes solid in a block of ice for a while (also scaled by class, so bosses freeze rarely and briefly). Water puts out burning enemies, and the Flamethrower's fire melts the chill and the ice. Ground only; it can't aim at invisible enemies but soaks them anyway. Cold Water → Pressure Hose → Ice Water (cold damage that ignores armor) → Liquid Nitrogen → Cryo Cannon (enemies it freezes take 25% more damage from everything). A mid game tower: 6 levels.
- **Minigunner:** spins up while it keeps shooting: the fire rate climbs from a few shots a second to its top speed, and with nothing in range it winds down twice as fast. Best on bosses and tanks, hits flying enemies. Bigger Drum → Hot Barrels → Tungsten Rounds (armor and lead piercing, sees invisible) → Twin Barrels → Heavy Minigun → Bullet Storm (ignores all armor).
- **Farm:** doesn't fight, pays money at the end of every wave: $60, then $110 → $230 → $500 → $1000 → $2000 → $4000 with Bigger Fields → Barn → Tractor → Irrigation → Greenhouses → Agro Empire. At most 8 farms in a battle.
- **Sniper:** slow, heavy shots from almost across the map, sees invisible and hits flying enemies. Optics → Full Metal Jacket (ignores all armor, pierces lead) → Headshot (15% chance to kill any non-boss outright) → Elite Sniper → Anti-Material Rifle → Deadeye (25%).

Open **Towers** in the main menu and click a portrait to see every tower's full stats and upgrade path.

## Source

> **After cloning or pulling**, open the project in the Godot editor once (or run `godot --headless --import`)
> before running the game. Scripts use `class_name`, and Godot only registers those names when it scans the
> project. Without that step you get errors like `Identifier "Defs" not declared in the current scope`.


- `scripts/data/defs.gd`: all the numbers (towers, enemies, difficulties, the wave generator used after Continue).
- `scripts/data/waves.gd`: the handmade waves of every difficulty: groups of [enemy, count, gap, start time], optionally "bloated" and / or "lead".
- `scripts/battle/`: the battlefield (`battle.gd`), towers (`tower.gd`) and enemies (`enemy.gd`).
- `scripts/ui/`: menus, the in-battle HUD and tooltips.
- `tools/gen_art.py`, `tools/sprites.py`, `tools/units.py`: generate all the pixel art and maps (Python + Pillow). Run `python3 tools/gen_art.py` after editing them. `scripts/data/maps_data.gd` is generated too, so don't edit it by hand.
- `scripts/data/changelog.gd`: the Changelog shown in the main menu, newest version first.
- `tools/gen_sfx.py`: generates the 8-bit sound effects.
- Building: install the Godot 4.7.2 export templates, then `godot --headless --export-release "Web" build/web/index.html` (same for "Windows" → `build/windows/PixelTD.exe` and "Linux" → `build/linux/PixelTD.x86_64`). `build/.gdignore` keeps Godot from importing the builds into the project.

Developer flags (passed after `--`):

- `--sim`: run the balance bot on every map and difficulty (works with `--headless`).
- `--unlock-all`: unlock every map and tower.
- `--cheats`: adds Cheats buttons. In the main menu: give paper maps, open any map, mark any difficulty of any map as beaten (its towers go on sale), unlock all maps and towers at once. These only last for the session: the save keeps the real progress. In the pause menu: jump to any wave, give money or lives, start the next wave now, clear the enemies, win the battle. Wins after using a cheat are not saved.
- `--save-fake`: write progress from `--unlock-all`, menu cheats and cheated wins to the save file anyway.
- `--halloween` / `--no-halloween`: force the Halloween event on or off.
- `--reset-data`: start with no progress and default settings, without touching the save file (nothing is saved that session). With `--save-fake` the save file is deleted for real.
- `--mechtest`: headless checks of the invisible / flying / skeleton / berserker / sniper rules.
- `--battle <map> <0-3> --bot`: watch the bot play.

## License

The game is licensed under the **GNU General Public License v3.0**, see [LICENSE](LICENSE).

The fonts are third party and keep their own license, the SIL Open Font License 1.1:

- Tiny5: [assets/fonts/OFL-tiny5.txt](assets/fonts/OFL-tiny5.txt)
- Press Start 2P: [assets/fonts/OFL-pressstart2p.txt](assets/fonts/OFL-pressstart2p.txt)
