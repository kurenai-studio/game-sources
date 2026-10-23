# Space Miner

A browser-based 3D endless runner built with Three.js and Vite. The player navigates a spaceship across lanes, dodging incoming asteroids while collecting crystals to score points.

---

## Features

- **3D Scene & Rendering**: Perspective camera, dynamic lighting, soft shadows, background starfield, and depth fog.
- **Player Movement & Dynamics**: Horizontal lane steering with banking/pitch tilt animations and visual thruster flame effects.
- **Speed Control**: Variable speed mechanics with acceleration boost and braking.
- **Procedural Obstacles & Pickups**: Randomly spawned rotating asteroids and glowing crystals aligned to discrete lanes.
- **Collision Detection**: Distance and radius-based bounding collision checks.
- **HUD & Game State**: Real-time score, crystal counter, speed multiplier display, and game-over overlay with instant restart.

---

## Controls

| Key / Input | Action |
| --- | --- |
| `A` / `Left Arrow` | Move Left |
| `D` / `Right Arrow` | Move Right |
| `W` / `Up Arrow` | Boost / Accelerate |
| `S` / `Down Arrow` | Brake / Slow Down |
| `R` / Restart Button | Restart Game (on Game Over) |

---

## Tech Stack

- **Three.js** (`v0.168+`) - 3D scene graph, geometry, materials, and WebGL rendering
- **Vite** - Build tool and development server
- **Vanilla JavaScript (ES Modules)** - Game logic, animation loop, and state management
- **HTML5 / CSS3** - Responsive HUD overlay and UI styling

---

## Project Structure

```text
├── index.html         # Entry HTML page and HUD markup
├── package.json       # Project dependencies and npm scripts
├── src/
│   ├── main.js        # Three.js setup, game loop, entities, and physics logic
│   └── styles.css     # HUD, UI overlay, and layout styling
└── vite.config.js     # Vite configuration (optional)
```

---

## Getting Started

### Prerequisites

Ensure you have [Node.js](https://nodejs.org/) (version 18 or higher recommended) installed.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/space-miner-threejs.git
   cd space-miner-threejs
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

### Running Locally

Start the local development server:

```bash
npm run dev
```

Open your browser and navigate to the local URL shown in your terminal (typically `http://localhost:5173`).

### Production Build

To build the static assets for deployment:

```bash
npm run build
```

The optimized production output will be generated in the `dist` directory. You can preview the build locally with:

```bash
npm run preview
```

---

## License

This project is licensed under the MIT License.
