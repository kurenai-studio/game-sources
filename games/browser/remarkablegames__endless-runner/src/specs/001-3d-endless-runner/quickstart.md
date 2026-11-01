# Quickstart: 3D Endless Runner Game

**Feature**: 001-3d-endless-runner
**Date**: 2026-03-16
**Purpose**: Get developers up and running quickly with the game

---

## Prerequisites

- Node.js 24 (check: `node --version`)
- npm (comes with Node.js)
- Modern web browser (Chrome, Firefox, Edge, Safari)

---

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Start Development Server

```bash
npm start
```

This starts Vite dev server at `http://localhost:5173`

### 3. Open in Browser

Navigate to `http://localhost:5173` and the game should load.

---

## Controls

| Input           | Action                            |
| --------------- | --------------------------------- |
| Left Arrow / A  | Move left (switch to left lane)   |
| Right Arrow / D | Move right (switch to right lane) |
| Up Arrow / W    | Jump (avoid ground obstacles)     |
| Down Arrow / S  | Duck (avoid airborne obstacles)   |
| P / Escape      | Pause game                        |
| R               | Restart (on game over screen)     |

---

## Gameplay

1. **Start Screen**: Press any key or click to start
2. **Running**: Character runs automatically - avoid obstacles!
3. **Pause**: Press P to pause, press again to resume
4. **Game Over**: Collision ends the run - see your score
5. **Restart**: Press R to try again

---

## Development Workflow

### Run Linting

```bash
npm run lint:fix    # Fix ESLint errors
npm run lint:tsc    # Type check (must pass before commit)
```

### Build for Production

```bash
npm run build       # Outputs to dist/
npm run preview     # Preview production build
```

### Hot Reload

Vite automatically reloads on file changes. No manual refresh needed.

---

## Debugging Tips

### View Console Logs

Open browser DevTools (F12) to see console output.

### Debug Mode (Future)

Add debug UI to tweak:

- Speed multiplier
- Obstacle density
- Player invincibility

### Performance Profiling

- Chrome DevTools → Performance tab
- Babylon.js Inspector: `scene.debugLayer.show()`

---

## Common Issues

### "Cannot find module '@babylonjs/core'"

```bash
npm install    # Reinstall dependencies
```

### Port 5173 Already in Use

```bash
# Vite will auto-select next available port (5174, etc.)
# Or specify: npx vite --port 3000
```

### TypeScript Errors

```bash
npm run lint:tsc    # See all type errors
# Fix errors in reported files
```

### Game Not Loading

1. Check browser console for errors
2. Verify `npm start` is running
3. Clear browser cache (Ctrl+Shift+R / Cmd+Shift+R)

---

## Next Steps

1. Read `data-model.md` for entity relationships
2. Read `plan.md` for implementation architecture
3. Start implementing Phase 1 tasks
4. Playtest frequently during development!

---

## Project Structure

```
src/
├── config/         # Game constants (speeds, lane positions)
├── core/           # Game state machine, score tracking
├── entities/       # Player, Obstacle classes
├── scenes/         # Main game scene setup
├── systems/        # Input, collision, movement systems
├── types/          # TypeScript type definitions
└── utils/          # Helper functions
```

Key files to start with:

- `src/scenes/gameScene.ts` - Main scene entry point
- `src/core/gameState.ts` - State machine
- `src/entities/player.ts` - Player entity
