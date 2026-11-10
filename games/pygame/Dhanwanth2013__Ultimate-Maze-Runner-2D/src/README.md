# 🧩 Maze Explorer 2D

A polished **2D Maze Exploration Game** built with **Python & Pygame**, featuring procedurally generated mazes, smooth controls, zoom & pan, themes, power-ups, hints, save/load support, and a competitive leaderboard.

Explore, solve, and escape — faster and smarter every time.

---

## 🎮 Features

* 🌀 **Procedural Maze Generation** (DFS-based)
* 🎯 **Automatic Start & Exit Detection**
* 🎨 **Multiple Themes** (Classic, Dark, Forest, Sunset)
* 🧠 **Hint System** using shortest-path search (BFS)
* ⚡ **Power-Ups** hidden inside the maze
* 🔍 **Zoom & Pan** (mouse wheel + drag)
* ⏸️ **Pause Menu** with full controls
* 💾 **Save / Load Game State** (JSON-based)
* 🏆 **Leaderboard** (Top 10 fastest runs)
* 🎚️ **Difficulty Levels** (15×15, 21×21, 31×31)
* 🎮 **Custom Key Bindings**
* 🖥️ **Fullscreen Gameplay**

---

## 🕹️ Controls

### Movement

* **W / A / S / D** or **Arrow Keys** – Move player

### Gameplay

* **H** – Show hint path
* **T** – Toggle hint path visibility
* **P** – Pause menu
* **R** – Restart maze
* **N** – Generate new maze
* **M** – Return to main menu
* **ESC** – Quit game

### Save / Load

* **F5** – Save game
* **F9** – Load game

### Camera

* **Mouse Wheel** – Zoom in / out
* **Left Click + Drag** – Pan maze

---

## 🧪 How It Works

* Mazes are generated using **Depth-First Search (DFS)**
* Hint paths are calculated using **Breadth-First Search (BFS)**
* Player movement leaves a visible trail
* Game state is serialized using JSON
* Leaderboard ranks runs by fastest completion time

---

## 📂 Project Structure

```
maze_explorer/
│
├── main.py              # Main game source code
├── maze_save.json       # Save file (auto-generated)
├── leaderboard.json     # Leaderboard data
├── key_bindings.json    # Custom key bindings
├── requirements.txt
└── README.md
```

---

## 🚀 Installation & Run

### 1️⃣ Install dependencies

```bash
pip install -r requirements.txt
```

### 2️⃣ Run the game

```bash
python main.py
```

> 💡 Requires **Python 3.8+** and a system capable of running Pygame.

---

## 🏁 Win Condition

Reach the exit tile as fast as possible with the fewest steps.
Your **time and steps** are automatically saved to the leaderboard.

---

## 📸 Screenshots

*Add gameplay screenshots or GIFs here for extra GitHub polish.*

---

## 🛠️ Built With

* Python
* Pygame
* JSON

---

## 📜 License

MIT License — free to use, modify, and distribute.

---

## 💡 Future Ideas

* Enemy AI or timed challenges
* Fog-of-war mode
* Online leaderboard
* Animated tiles & effects
* Controller support

---

Enjoy exploring the maze! 🧩✨
