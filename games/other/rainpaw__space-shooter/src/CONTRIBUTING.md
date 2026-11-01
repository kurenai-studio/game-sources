# Space Shooter - Contributing Guide

Thank you for your interest in contributing to Space Shooter!

## Development Setup

1. Fork and clone the repository
2. Install Go 1.21 or higher
3. Install dependencies: `go mod download`
4. Run tests: `make test`
5. Run the game: `make run`

## Code Style

- Follow standard Go conventions
- Use `gofmt` to format code
- Run `golangci-lint` before submitting
- Keep functions small and focused
- Add comments for exported functions

## Project Structure

```
internal/       - Private application code
  entities/     - Game entities (player, enemies, etc.)
  game/         - Core game logic
  engine/       - Game engine components
  physics/      - Physics and collision
  ui/           - User interface

pkg/            - Public reusable packages
  vector/       - Vector math utilities
  pool/         - Object pooling

cmd/            - Application entry points
configs/        - Configuration files
```

## Adding Features

### New Enemy Types

1. Add enemy type to `internal/entities/enemy.go`
2. Configure in `configs/game.yaml`
3. Add tests in `internal/entities/enemy_test.go`

### New Weapons

1. Add weapon type to `internal/entities/entity.go`
2. Implement firing logic in `internal/entities/player.go`
3. Add projectile types to `internal/entities/bullet.go`

### New Power-ups

1. Create power-up entity in `internal/entities/powerup.go`
2. Add spawn logic in `internal/game/game.go`
3. Implement effects in player

## Testing

- Write unit tests for new code
- Maintain >80% code coverage
- Run benchmarks for performance-critical code
- Test collision detection thoroughly

```bash
# Run tests
make test

# Run with coverage
make test-coverage

# Run benchmarks
make bench
```

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Add tests
4. Run `make lint` and fix issues
5. Update documentation if needed
6. Submit PR with clear description

## Commit Messages

Use conventional commits format:

```
feat: add new enemy type
fix: correct collision detection bug
docs: update README
test: add player movement tests
refactor: simplify spawn system
perf: optimize particle rendering
```

## Questions?

Open an issue for discussion before major changes.

Thank you for contributing! 🚀
