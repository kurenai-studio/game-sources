# Wand Magic — Claude Guidelines

## Environment
- Godot 4.x, GDScript

## Project Docs
- `README.md` tracks implemented and planned features — keep it updated as features land
- `docs/architecture.puml` contains high-level system diagrams — update when major systems change, not for every scene

## Code Style
- Short functions, prefer pure functions, keep side effects out of logic
- Composition over inheritance
- Functions under ~20 lines
- snake_case for functions/variables, PascalCase for classes/nodes, `_on_` prefix for signal handlers

## Architecture
- Each scene is a self-contained component — owns its own state, exposes signals
- Nodes communicate via signals, never via direct parent references
- Autoloads only for truly global systems (e.g. AudioManager, SaveSystem)

## Testing
- Use GUT for all tests
- Test logic, not rendering
- Unit test pure functions
- Component tests cover behavior, not visuals

## Folder Structure
- `scenes/` — scene files
- `scripts/` — standalone scripts
- `assets/` — art, audio, fonts
- `tests/` — GUT test files

## Workflow
- Work in short iterations — implement and review one small piece at a time, not complete features in one go
