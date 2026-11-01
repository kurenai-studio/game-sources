# 🚀 Space Evader

A 2D retro arcade shooter built with Python and the **Pygame** library. Pilot your spaceship, shoot down meteors and enemy ships, collect coins and power-ups, and spend your coins in the shop on new ship skins and upgrades.

---

## 🎮 About the Game

- **Player:** A spaceship that can move freely around the screen and shoot lasers.
- **Meteors:** Fall from the top at random X positions. They get faster every time you destroy one.
- **Enemy spaceship:** Flies back and forth at the top and shoots lasers at you. After you destroy it, it respawns after a short delay.
- **Lives:** You start with **3 lives**. Getting hit by a meteor or an enemy laser costs one life.
- **Game Over:** When you run out of lives, your score, high score and coins are shown.

### Scoring and coins

| Action | Score | Coins |
| --- | --- | --- |
| Shoot a meteor | +1 | +1 |
| Shoot the enemy ship | +5 | +3 |

Your **high score**, **coins** and **shop purchases** are saved automatically, so they persist between runs.

---

## ⚡ Power-ups

A destroyed enemy ship has a 50% chance to drop a random power-up. Fly into it to collect it.

| Power-up | Icon | Effect |
| --- | --- | --- |
| Extra life | Heart | +1 life |
| Shield | Blue **S** | Blocks all damage for 10 seconds |
| Rapid fire | Orange **R** | Hold `Space` to shoot automatically for 10 seconds |
| 2x coins | Coin | Doubles all coins you earn for 10 seconds |

Active effects and their remaining time are shown under the coin counter.

---

## 🛒 Shop

Open "Shop" in main menu and spend your coins on:

### Ship skins

| Skin | Price |
| --- | --- |
| Default | Free |
| Skin 2 | 50 coins |
| Skin 3 | 100 coins |

Buy a skin once, then equip it any time. The new skin appears when you start a new game.

### Upgrades

Prices grow with every level.

| Upgrade | Effect per level | Max level | Prices |
| --- | --- | --- | --- |
| Extra starting life | +1 starting life | 2 | 40, 80 |
| Ship speed | +1 movement speed | 3 | 30, 60, 90 |
| Power-up duration | +2 seconds per power-up | 3 | 50, 100, 150 |

---

## 🛠 Requirements & Installation

You need **Python 3.x** and **Pygame** (or `pygame-ce`) installed.

### 1. Clone the repository

```bash
git clone https://github.com/pepaskopec-blip/My-first-PyGame.git
cd My-first-PyGame
```

### 2. Set up a virtual environment (optional)

Linux / macOS:
```bash
python -m venv .venv
source .venv/bin/activate
```

Windows:
```cmd
python -m venv .venv
.venv\Scripts\activate
```

### 3. Install dependencies

Standard Pygame:
```bash
pip install pygame
```

For Apple Silicon or newer Python versions:
```bash
pip install pygame-ce
```

### 4. Run the game

Run it from the project folder, because the game loads its images from the current directory:

```bash
python main.py
```

The following image files must be next to `main.py`: `player.png`, `player_skin2.png`, `player_skin3.png`, `meteor.png`, `enemy_spaceship.png`, `life.png`, `coin.png` and `default_background.jpg`.

Save files (`highscore.txt`, `coins.txt` and `shop.json`) are created automatically while you play.

---

## 🕹 Controls

### In the game

| Key | Action |
| --- | --- |
| `Left Arrow` / `A` | Move left |
| `Right Arrow` / `D` | Move right |
| `Up Arrow` / `W` | Move up |
| `Down Arrow` / `S` | Move down |
| `Space` | Shoot (hold it with the Rapid fire power-up) |

### In the menus

| Key | Action |
| --- | --- |
| `Up Arrow` / `Down Arrow` | Select an item (shop) |
| `Enter` | Buy or equip the selected item (shop) |
| `Esc` | Back to the main menu (shop) |
| `R` | Restart (game over screen) |
| `M` | Back to the main menu (game over screen) |

---

## 📝 License

This project is open-source and available under the **GPL 3.0 License**.