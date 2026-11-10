# Lane Legends: Human vs AI 🏎️💨

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![Pygame](https://img.shields.io/badge/Pygame--CE-2.5%2B-green.svg)](https://pyga.me/)
[![Algorithm](https://img.shields.io/badge/AI%2FML-Tabular%20Q--Learning-orange.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()
[![Tests](https://img.shields.io/badge/Tests-17%20Passed-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> A high-performance top-down 2D arcade car racing game featuring a genuine **Reinforcement Learning (Tabular Q-Learning)** agent competing in real time against a human driver across parallel, synchronized obstacle tracks.

---

## 📸 Overview

**Lane Legends: Human vs AI** demonstrates practical reinforcement learning in a real-time, interactive environment. Built in Python with **Pygame Community Edition (Pygame-CE)** and **NumPy**, the game features two parallel 3-lane tracks side by side:

- **Left Track**: Controlled by **Player 1** (Human).
- **Right Track**: Controlled by the **Autonomous Q-Learning Agent** (or **Player 2** in local multiplayer mode).

Both tracks feature an identical, synchronized obstacle stream to guarantee complete competitive fairness. The racer who navigates hazards, manages nitro boosts, and crosses the 3,000-meter chequered finish line first wins.

---

## ✨ Key Features

- **Genuine Reinforcement Learning AI**: Zero hard-coded heuristic or if-else steering rules. The AI opponent makes real-time driving decisions purely using a trained **81-state Tabular Q-Table**.
- **Live AI Telemetry & Explainability**: Press `[ I ]` or `[ E ]` during any race to open a live HUD telemetry panel showing the agent's discrete state, radar distance sensor values, Q-value distribution across actions, and natural-language rationale.
- **Two Distinct Game Modes**:
  1. **Player vs AI (Default Mode)**: Race head-to-head against the Q-learning agent with selectable difficulty profiles.
  2. **Player vs Player (Local 2P)**: Two human players compete on the same keyboard with separate controls, physics, and scoring.
- **Three Calibrated AI Difficulties**:
  - 🐼 **Puncture Panda (Easy)**: Relaxed pace, slower reaction latency (~0.48s), controlled action exploration (24% blunders), conservative nitro.
  - 🏎️ **Nitro Nawab (Medium)**: Balanced pace, moderate reaction latency (~0.26s), low randomness (5%), strategic nitro boost.
  - 🐆 **Cyber Cheetah (Hard)**: Lightning reflexes (~0.12s), 100% optimal Q-value exploitation (0% randomness), aggressive nitro management.
- **100% Procedural Audio & Visuals (Zero Asset Downloads)**:
  - All car models, hazard barriers, traffic cones, and oil slicks are procedurally rendered with anti-aliasing and drop shadows.
  - All 8 arcade sound effects (countdown beeps, engine hum, nitro surge, crash crunch, pass chime, victory fanfare) are dynamically synthesized in memory using Python's standard `math` and `wave` modules.
- **Realistic Arcade Physics**: LERP lane-change interpolation with body banking/tilt, nitro boost meters, brake regeneration, collision momentum loss, and oil slick skidding.
- **Persistent High Scores & Leaderboard**: Local JSON database tracking the top 10 leaderboard scores, mode records, and head-to-head human vs AI win tallies.

---

## 📁 Repository Structure

```
lane_legends/
│
├── main.py              # Application launcher & startup checks
├── game.py              # Master game loop, state machine & event handling
├── settings.py          # Configuration constants, track geometry, & RL hyperparameters
├── entities.py          # Car physics, procedural sprites, & particle systems
├── track.py             # Dual-track road rendering, scrolling, & synchronized hazards
├── ai_agent.py          # Tabular Q-Learning agent, action masking, & explainability
├── ai_trainer.py        # Headless offline training simulation & model generator
├── scoreboard.py        # Score tracking, leaderboard, & persistent JSON storage
├── sound_effects.py     # In-memory procedural 8-bit WAV sound synthesizer
├── ui.py                # Arcade UI system: menus, HUD, telemetry overlay, & results
├── requirements.txt     # Python project dependencies
├── README.md            # Comprehensive project documentation
│
├── assets/              # Optional asset directory (procedural fallbacks built-in)
│   ├── images/
│   └── sounds/
│
├── data/                # Persistent JSON storage
│   ├── q_table.json     # Trained Tabular Q-Learning policy (81 states)
│   └── high_scores.json # Persistent records and win/loss tallies
│
└── tests/               # Automated unit & integration test suite
    ├── test_ai.py       # Q-learning tests (Bellman update, masking, encoding)
    ├── test_game.py     # Physics, track symmetry fairness, & scoreboard tests
    └── test_integration.py # Headless end-to-end game loop integration test
```

---

## ⚡ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/lane_legends.git
cd lane_legends
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Run the Game
```bash
python main.py
```
> *Note: If `data/q_table.json` is missing or deleted, the launcher automatically runs a fast offline training pass in ~2-3 seconds before starting the game.*

---

## 🕹️ Controls & Mechanics

### Gameplay Controls

| Action | Player 1 (Left Track) | Player 2 (Right Track - 2P Mode) |
|---|---|---|
| **Steer Left** | `A` | `Left Arrow` |
| **Steer Right** | `D` | `Right Arrow` |
| **Nitro Boost** | `W` (Hold) | `Up Arrow` (Hold) |
| **Brake / Coast** | `S` (Hold) | `Down Arrow` (Hold) |

### Hotkeys
- `[ I ]` or `[ E ]` : Toggle Live AI Telemetry / Reasoning Overlay
- `[ P ]` or `[ ESC ]` : Pause / Resume Race
- `[ M ]` : Toggle Sound (Mute / Unmute)
- `[ R ]` : Quick Restart Current Race

### Hazards Guide
- 🚗 **Traffic Cars**: Slower vehicles cruising along lanes. Impact reduces speed to 35% and deducts 250 points.
- 🚧 **Road Barriers**: Heavy barricades that cause severe deceleration and sparks.
- 🔶 **Traffic Cones**: Work-zone pylons that reduce momentum and deduct score.
- 🛢️ **Oil Slicks**: Glossy puddles causing 0.9 seconds of lateral skidding and reduced steering authority.

---

## 🧠 Reinforcement Learning Architecture

The AI opponent is powered by **Tabular Q-Learning**, a model-free, off-policy Temporal Difference reinforcement learning algorithm.

```
       +---------------------------------------------+
       |             Racing Environment              |
       |  (Car Lane, Sensor Distances [L, M, R])     |
       +---------------------------------------------+
             |                                 ^
      State  |                                 | Action
       s_t   v                                 | a_t (Left / Stay / Right)
       +---------------------------------------------+
       |           Tabular Q-Learning Agent          |
       |  Q(s, a) <-- Q(s, a) + alpha * TD_Error     |
       +---------------------------------------------+
```

### 1. State Space Discretization
To guarantee convergence and sub-millisecond evaluation latency, the continuous racing state is discretized into a 4-dimensional tuple:

$$\text{State } S = (\text{Lane}, \text{Dist}_{\text{Left}}, \text{Dist}_{\text{Mid}}, \text{Dist}_{\text{Right}})$$

- **$\text{Lane} \in \{0, 1, 2\}$**: The vehicle's active lane (`0` = Left, `1` = Center, `2` = Right).
- **$\text{Dist} \in \{0, 1, 2\}$**: Discretized distance to the nearest oncoming obstacle in each lane:
  - **$0$ (Near)**: Distance $\le 175\text{ px}$ (immediate collision danger).
  - **$1$ (Medium)**: Distance between $175\text{ px}$ and $360\text{ px}$ (approaching hazard).
  - **$2$ (Far / Clear)**: Distance $> 360\text{ px}$ or no obstacle detected.

$$\text{Total State Space Size} = 3 \times 3 \times 3 \times 3 = \mathbf{81 \text{ discrete states}}$$

### 2. Action Space & Geometric Masking
The action space consists of 3 discrete maneuvers:
$$\mathcal{A} = \{0: \text{MOVE\_LEFT}, 1: \text{STAY}, 2: \text{MOVE\_RIGHT}\}$$

Actions leading off the road boundaries are masked out:
- In **Lane 0 (Leftmost)**: $\text{MOVE\_LEFT}$ is masked to $Q = -999.0$.
- In **Lane 2 (Rightmost)**: $\text{MOVE\_RIGHT}$ is masked to $Q = -999.0$.

### 3. Bellman Optimality Equation
During offline training, Q-values are updated using the standard Bellman equation:

$$Q(s, a) \leftarrow Q(s, a) + \alpha \left[ r + \gamma \max_{a' \in \text{valid}(s')} Q(s', a') - Q(s, a) \right]$$

- **Learning Rate ($\alpha$)**: `0.15`
- **Discount Factor ($\gamma$)**: `0.90`
- **Exploration ($\epsilon$)**: Decayed from `1.0` to `0.03` over 1,600 training episodes.

### 4. Reward Matrix
| Event | Reward Value | Description |
|---|---:|---|
| **Collision with Obstacle** | **$-28.0$** | Heavy penalty against crashes |
| **Pass Obstacle Safely** | **$+10.0$** | High reward for clearing hazard checkpoints |
| **Avoid Danger by Changing Lane** | **$+6.0$** | Positive reinforcement for evading near obstacles |
| **Unnecessary Lane Change** | **$-1.5$** | Discourages weaving when the current lane is safe |
| **Safe Progress Step** | **$+1.0$** | Continuous forward progression reward |
| **Complete Race** | **$+35.0$** | Terminal goal completion bonus |

---

## 🎯 Difficulty Calibration

All three difficulty levels use the **same trained Q-table policy**, varying in sensory reaction latency, exploration noise ($\epsilon$), and nitro aggressiveness:

| Difficulty Level | Nickname | Speed Multiplier | Reaction Delay | Randomness ($\epsilon$) | Nitro Threshold |
|---|---|:---:|:---:|:---:|---|
| **Easy** | 🐼 Puncture Panda | $0.88\times$ | $0.48\text{ s}$ | $24\%$ | Rare (meter $>92\%$) |
| **Medium** | 🏎️ Nitro Nawab | $1.00\times$ | $0.26\text{ s}$ | $5\%$ | Strategic (meter $>55\%$) |
| **Hard** | 🐆 Cyber Cheetah | $1.10\times$ | $0.12\text{ s}$ | $0\%$ (greedy) | Aggressive (meter $>30\%$) |

---

## 🔄 Retraining the AI Model

To retrain the Q-learning agent from scratch or experiment with custom hyperparameters:

```bash
# Train default 1,600 episodes
python ai_trainer.py

# Or train with custom episode count
python ai_trainer.py 2500
```

The training process executes headlessly in under 12 seconds, printing live convergence logs and updating `data/q_table.json`.

---

## 🧪 Testing & Verification

The project includes an automated test suite with **17 unit and integration tests** verifying reinforcement learning mechanics, collision physics, track symmetry, and game loop stability:

```bash
python -m unittest discover tests
```

### Verified Test Modules:
- `tests/test_ai.py`: 81-state discretization, boundary action masking, Bellman update correctness, save/load serialization.
- `tests/test_game.py`: Car physics, nitro drain/recharge, collision invulnerability, track fairness, solvable obstacle groupings, and scoreboard persistence.
- `tests/test_integration.py`: Headless end-to-end integration tests running continuous frames of Player vs AI and 2-Player modes.

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
