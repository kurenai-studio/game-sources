# 🎮 Tetris (Raylib + C++)

A fully playable **Tetris clone** built from scratch in **C++ using raylib**, featuring modern gameplay mechanics like the **7-bag randomizer**, **next-piece preview**, **soft drop**, **rotation**, **scoring**, and **game over detection**.

Made by **marvelboyop & Dwip**.

---

## ✨ Features

### 🧱 Core Gameplay
- Classic Tetris grid (10 × 16)
- All **7 tetrominoes**:
  - I, O, T, S, Z, J, L
- Correct collision handling
- Piece locking and gravity

### 🎒 Randomization
- **7-Bag system** (modern Tetris standard)
- No unfair droughts
- Fair and predictable randomness

### 🎮 Controls
| Action | Key |
|------|----|
| Move Left | ← / A |
| Move Right | → / D |
| Soft Drop | ↓ / S |
| Rotate | ↑ / W |

### ⬇️ Gravity & Movement
- Smooth gravity using frame-time
- **Soft drop** increases fall speed while key is held
- Rotation with collision checks

### 🧮 Scoring
- Score based on **lines cleared per turn**
- Quadratic reward system:

score += linesCleared² × 100


### 🔮 UI & Feedback
- **Next piece preview**
- Grid lines for both playfield and preview
- On-screen score display
- Game Over message

### ❌ Game Over Logic
- Game ends **only if a newly spawned piece cannot be placed**
- Matches authentic Tetris rules

---

## 🛠️ Built With

- **C++**
- **raylib**
- Standard C++ libraries:
- `<vector>`
- `<algorithm>`
- `<random>`

---
## 📦 Releases (Download & Play)

This game is also **released via GitHub Releases**, allowing players to **download and play the game directly without building from source**.

- Pre-built executable is available in the **Releases** section
- Simply download, extract, and run the game
- No additional setup required for players

👉 Check the **Releases tab** on this repository to get the latest playable version.

---
## 🚀 How to Build & Run (From Source)

### Prerequisites
- C++ compiler (GCC / MinGW / Clang)
- **Raylib** installed and configured

### Compile (example – MinGW on Windows)
```bash
g++ main.cpp -o tetris -lraylib -lopengl32 -lgdi32 -lwinmm
```
### Run
```bash
./tetris
```

## 🧠 Technical Highlights
- Board stores Color, not integers (supports animation & effects)
- Clean separation of:
Update logic
Rendering
Collision detection
Shape factory + polymorphism
Deterministic game loop (update → draw)
---
## 🚀 Possible Future Improvements

- Line clear animations (fade / flash)
- Hard drop (spacebar)
- Hold piece
- Ghost piece
- Level-based speed scaling
- Sound effects
- Pause / restart menu
---

## 👥 Credits
Made by
- marvelboyop
- Dwip

---
## 📜 License

This project is for learning and educational purposes.
Feel free to experiment, modify, and extend it.
