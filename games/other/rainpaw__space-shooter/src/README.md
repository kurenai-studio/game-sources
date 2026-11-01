# Space Shooter

A 2D space shooter game written in Go using the Ebiten game engine.

## Play Online

**[Play the game in your browser!](https://echosingh.github.io/space-shooter/)**

The game runs directly in your browser using WebAssembly - no installation needed!

## How to Play

The goal is simple: shoot down enemy ships, avoid getting hit, and rack up points. The game gets progressively harder as you survive longer.

### Controls
- **WASD or Arrow Keys** - Move your spaceship around the screen
- **Spacebar** - Hold to continuously fire bullets at enemies
- **P** - Pause the game
- **ESC** - Return to main menu or quit

### Gameplay
- Different colored enemy ships come down from the top of the screen
- Red enemies are basic and slow
- Orange enemies are fast and zigzag
- Dark red enemies are tanks with more health
- Purple enemies have sine wave patterns
- Shoot them before they reach you or collide with you
- Each enemy type gives different points when destroyed
- Your health is shown as a bar below your ship
- Game ends when your health reaches zero

## Running the Game

You need Go 1.21 or higher installed on your system.

On Linux, you'll also need some graphics libraries:
```bash
sudo apt-get install libc6-dev libgl1-mesa-dev libxcursor-dev libxi-dev libxinerama-dev libxrandr-dev libxxf86vm-dev libasound2-dev pkg-config
```

Then just run:
```bash
go mod download
go run cmd/game/main.go
```

Or build an executable:
```bash
go build -o space-shooter cmd/game/main.go
./space-shooter
```

## What's Included

The game has:
- 4 different enemy types with unique movement patterns
- Particle effects for explosions
- Score tracking
- Health system
- Progressive difficulty (gets harder over time)
- Pause functionality

## Code Structure

- `cmd/game/` - Main entry point
- `internal/entities/` - Player, enemies, bullets, particles
- `internal/game/` - Main game loop
- `internal/physics/` - Collision detection
- `pkg/vector/` - Math utilities

## License

MIT License - see LICENSE file
