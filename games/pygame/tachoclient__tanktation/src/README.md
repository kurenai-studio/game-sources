# Tanktation

> *A top-down two-tank battle game built with Python and Pygame.*

---

## Overview

Tanktation is a fast-paced, top-down tank combat game for one or two players. Command a tank across five distinct biomes, eliminate the enemy's entire force - tank, infantry, and vehicles - before they eliminate yours. Drop-in AI opposition with three difficulty levels makes it playable solo, while local two-player mode puts both commanders head-to-head on the same keyboard.

---

## Features

- **5 Biomes** - Plains, Desert, Snow, City, and Volcanic, each with unique terrain, obstacles, and gameplay modifiers (speed, heat, fuel burn, spread)
- **PvP & PvC modes** - Play against a friend or against an AI at Easy, Normal, or Hard difficulty
- **Full combined-arms combat** - Tanks, APCs, Jeeps, Humvees, and four infantry roles (MG, SMG, AT, Sniper)
- **Weapon systems** - Main cannon, machine gun with heat/overheat mechanic, smoke grenades, and repair kits
- **Spawn protection** - Respawning tanks and units are invulnerable for a grace period
- **Airdrops** - Random supply crates grant ammo, fuel, speed, damage, spread, or repair boosts
- **Mines** - Scattered across the battlefield after first contact
- **Smoke & cover** - Smoke clouds degrade enemy accuracy and protect repositioning tanks
- **Animated obstacles** - Top-down trees (oak, palm, pine), buildings with rooftop detail, and a pulsing lava crater
- **Screen shake, recoil, muzzle flash, and kill-cam** - Full visual feedback on every shot and kill
- **GAME OVER screen** - Cinematic end sequence with shockwaves and ticker
- **Post-match stats** - Shots fired, hits, accuracy, damage dealt, best streak, HP remaining, match time
- **Day/Night + weather** - Fog-of-war at night, headlight beams, and weather modifiers that affect handling and accuracy
- **Realistic ballistics** - Wind drift per weather, plus ammo-specific handling (ATGMs are least affected)
- **Armor + critical hits** - Front/side/rear armor, ricochet chance, and engine/turret critical damage that affects mobility and traverse
- **Lighting interference** - Headlights overlap with additive brightness (constructive interference), capped to avoid blowout
- **Radar + settings panel** - Top-center radar and in-game sliders/toggles for audio and cycle speed

---

## Requirements

- Python 3.8+
- Pygame 2.x

Install dependencies:

```bash
pip install pygame
```

---

## Project Structure

```
tanktation/
+-- main.py
+-- assets/
    +-- sprites/
    �   +-- tanks/
    �       +-- gr_chassis.png
    �       +-- gr_turret.png
    �       +-- bl_chassis.png
    �       +-- bl_turret.png
    �       +-- bullet.png
    �       +-- muzzle_flash.png
    +-- audio/
        +-- cannon.mp3
        +-- mg.mp3
        +-- explosion.mp3
        +-- music.mp3
```

---

## How to Run

```bash
python main.py
```

---

## Controls

### Green Tank (Player 1 - always human)

| Action        | Key / Button       |
|---------------|--------------------|
| Move forward  | W                  |
| Move reverse  | S                  |
| Rotate / aim  | A / D              |
| Fire cannon   | Left Mouse Button  |
| Fire MG       | Right Mouse Button |
| Deploy smoke  | Middle Mouse Button|
| Repair        | F                  |

> In **PvC mode**, the green turret aims with the **mouse cursor**.

### Blue Tank (Player 2 - PvP only)

| Action        | Key                |
|---------------|--------------------|
| Move forward  | Up Arrow           |
| Move reverse  | Down Arrow         |
| Rotate / aim  | Left / Right Arrow |
| Fire cannon   | Enter              |
| Fire MG       | Right Shift        |
| Deploy smoke  | Right Ctrl         |
| Repair        | Right Alt          |

### General

| Action         | Key      |
|----------------|----------|
| Restart (PvC)  | R        |
| Leave (PvC)    | Escape   |
| Night Vision   | F2       |

---

## Biome Effects

| Biome    | Speed | Damage | Spread | Heat Cooling | Fuel Burn |
|----------|-------|--------|--------|--------------|-----------|
| Plains   | x1.00 | x1.00  | x1.00  | x1.00        | x1.00     |
| Desert   | x0.95 | x1.05  | x1.15  | x0.90        | x1.15     |
| Snow     | x0.92 | x1.00  | x1.05  | x1.10        | x1.05     |
| City     | x1.05 | x1.00  | x0.95  | x1.00        | x1.00     |
| Volcanic | x0.98 | x1.10  | x1.10  | x0.85        | x1.20     |

---

## Win Condition

Eliminate **all** enemy units - the tank (across all lives), all infantry, and all vehicles. If both tanks are destroyed and 60 seconds pass, or the match reaches 3 minutes total, the game ends in a **Stalemate**.

---

## Infantry Roles

| Role   | HP | Speed | Range | Cooldown | Damage | Notes                    |
|--------|----|-------|-------|----------|--------|--------------------------|
| MG     | 18 | 80    | 220   | 260 ms   | 2.0    | Suppressive fire         |
| SMG    | 14 | 95    | 160   | 160 ms   | 1.5    | Fast, short range        |
| AT     | 20 | 70    | 240   | 820 ms   | 6.5    | Prioritises tanks        |
| Sniper | 12 | 75    | 360   | 900 ms   | 14.0   | Long range, high damage  |

---

## Credits

- Background music: Heroic Age by Kevin MacLeod (incompetech.com)
- Built with [Pygame](https://www.pygame.org)
