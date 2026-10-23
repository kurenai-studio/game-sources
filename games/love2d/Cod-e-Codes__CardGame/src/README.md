# Love2D Card Game

A turn-based card game implementation built with Love2D. Features a playable game with AI opponent, modular architecture, and comprehensive testing.

## Features

### Game Implementation
- Turn-based gameplay with mana system and win conditions
- AI opponent with strategic card playing
- Card effects system with multiple abilities (damage, healing, burn, armor)
- Interactive UI with drag-and-drop card playing
- Multiple scenes: menu, game, deck builder, settings

### User Experience
- Responsive UI that adapts to different screen resolutions
- Non-blocking animation system with multiple easing functions
- Clean card rendering with proper text spacing
- Smooth transitions between game states
- Unified input handling for mouse, keyboard, and touch

### Architecture
- Modular design with clean system separation
- Data-driven card definitions in Lua tables
- Stack-based scene management supporting overlays
- Seedable random number generation for consistent gameplay
- Comprehensive test suite with coverage reporting

## Installation

### Prerequisites
- Love2D 11.4+ installed from https://love2d.org/
- Basic knowledge of Lua programming

### Running the Game

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Cod-e-Codes/CardGame.git
   cd CardGame
   ```

2. **Install Love2D:**
   - Download from https://love2d.org/
   - **Windows**: Add Love2D to your PATH, or use full path to executable
   - **Linux**: Install via package manager or add to PATH

3. **Run the game:**
   
   **If Love2D is in PATH:**
   ```bash
   love .
   ```
   
   **If Love2D is not in PATH (Windows):**
   ```bash
   "C:\Program Files\LOVE\love.exe" .
   ```
   
   **If Love2D is not in PATH (Linux):**
   ```bash
   /usr/bin/love .
   # or wherever you installed Love2D
   ```
   
   **Alternative**: Drag the CardGame folder onto the Love2D executable

4. **Run tests:**
   ```bash
   love . --test
   ```

## How to Play

1. Start Game: Click "Start Game" from the main menu
2. Play Cards: Drag cards from your hand to the play area
3. Use Mana: Each card costs mana - you get more each turn
4. End Turn: Click "End Turn" to let the AI play
5. Win Condition: Reduce opponent's health to 0 or survive 25 turns

## Card Types

- **Creatures**: Have attack/health stats and can have special abilities
- **Spells**: Instant effects like direct damage or healing
- **Artifacts**: Permanent effects or mana generation

**Special Abilities**:
- Direct Damage: Lightning bolt effects
- Healing: Restore health points
- Burn: Extra damage over time
- Armor: Damage reduction
- Flying: Cannot be blocked
- Regenerate: Heal owner when played

## Project Structure

```
CardGame/
├── main.lua                    # Love2D entry point and game loop
├── conf.lua                   # Love2D configuration
├── lib/                       # Core engine modules
│   ├── scene_manager.lua      # Scene state management
│   ├── layout.lua            # UI positioning and containers
│   ├── animation.lua         # Tweening and easing system
│   ├── input.lua             # Input handling and events
│   ├── card_renderer.lua     # Card drawing and effects
│   ├── audio_manager.lua     # Sound effects and music
│   └── utils.lua             # Math, RNG, and utilities
├── scenes/                    # Game state scenes
│   ├── game_scene.lua        # Main gameplay with turn-based combat
│   ├── menu_scene.lua        # Main menu with navigation
│   ├── deck_builder.lua      # Card collection and deck building
│   └── settings_scene.lua    # Game settings and options
├── data/                      # Game data definitions
│   ├── cards.lua             # Card definitions with abilities
│   └── atlas_config.lua      # Sprite atlas configuration
└── tests/                     # Test suite
    ├── test_runner.lua       # Test framework with coverage
    ├── test_cards.lua        # Card system tests
    ├── test_utils.lua        # Utility function tests
    ├── test_animation.lua    # Animation system tests
    ├── test_layout.lua       # UI layout tests
    ├── test_input.lua        # Input handling tests
    ├── test_scenes.lua       # Scene management tests
    └── test_coverage.lua     # Code coverage reporting
```

## Core Systems

### Scene Management

Handles game state transitions with support for scene stacking and smooth transitions:

```lua
-- Switch to a new scene
Game.scene_manager:switchScene("game_scene", {
    type = "fade",
    duration = 0.5
})

-- Push scene as overlay
Game.scene_manager:pushScene("pause_menu")

-- Return to previous scene
Game.scene_manager:popScene()
```

### Animation System

Non-blocking animation system with chaining and parallel execution:

```lua
local Animation = require('lib.animation')

-- Basic tween
local tween = Animation.Tween:new(card, 0.5, {x = 100, y = 200}, Animation.Easing.outCubic)

-- Chain animations
local bounce = Animation.Tween:new(card, 0.2, {scale = 1.2}, Animation.Easing.outBack)
local settle = Animation.Tween:new(card, 0.15, {scale = 1.0}, Animation.Easing.inCubic)
bounce:chain(settle)

-- Play with callback
Game.animation:play(bounce, function()
    print("Animation complete!")
end)
```

### Responsive UI Layout

Container-based layout system with anchoring and automatic scaling:

```lua
local Layout = require('lib.layout')

-- Create container
local container = Layout.Container:new(0, 0, 400, 300, {
    background_color = {0.2, 0.2, 0.3, 0.8},
    border_color = {0.4, 0.4, 0.5, 1}
})

-- Anchor to screen center
container:setAnchor("center", 0, 0)

-- Add child with relative positioning
local button = Layout.Container:new(0, 0, 100, 50)
container:addChild(button, {
    anchor = "bottom-center",
    padding = {10, 10, 10, 10}
})
```

## Card Data Schema

Cards are defined using Lua tables with a standardized schema:

```lua
{
    id = "fire_sprite",
    name = "Fire Sprite",
    description = "A small elemental creature that deals burn damage.",
    cost = 1,
    type = "creature",
    attack = 1,
    health = 1,
    abilities = {"burn"},
    artwork = "fire_sprite",
    rarity = "common",
    collectible = true,
    set = "basic",
    flavor_text = "Born from ember, destined for flame."
}
```

### Adding New Cards

1. Define card data in `data/cards.lua`
2. Add artwork to sprite atlas
3. Update `data/atlas_config.lua` with sprite coordinates
4. Implement any new abilities in game logic

## Testing

The framework includes a comprehensive test suite with over 150 unit tests covering all major systems.

### Running Tests

```bash
love . --test
```

Example output:
```
✓ test_cards         PASS (25/25)
✓ test_utils         PASS (35/35) 
✓ test_animation     PASS (20/20)
✓ test_layout        PASS (18/18)
✓ test_input         PASS (22/22)
✓ test_scenes        PASS (15/15)

TOTAL: 135 passed, 0 failed (45.2 ms)
Code Coverage: 78.5% (156/199 functions)
```

### Test Coverage

The test suite provides detailed coverage reporting:
- Function Coverage: Tracks which functions are tested
- Module Breakdown: Per-module coverage statistics  
- Performance Metrics: Test execution time
- Missing Coverage: Lists untested functions

### Test Categories

- Card System: Validation, filtering, copying, schema consistency
- Utilities: RNG, math functions, table operations, string handling
- Animation: Tweening, easing functions, chaining, performance
- Layout: UI containers, anchoring, responsive design
- Input: Key/mouse handling, drag-and-drop, touch support
- Scenes: Scene management, transitions, lifecycle events

## Development

### Debug Mode

The game includes built-in debug features:

```bash
love . --debug
```

Debug Features:
- Performance Overlay: FPS, memory usage, draw calls
- Visual Bounds: UI container boundaries  
- Input State: Current key/mouse states
- Animation Info: Active tweens and timing

### In-Game Hotkeys

- `F1`: Toggle debug overlay
- `F2`: Run test suite (debug mode only)
- `D`: Draw new card (in game scene)
- `T`: End turn (in game scene)  
- `Escape`: Go back/return to menu
- `Q`: Quit game (from main menu)

### Development Workflow

1. Make Changes: Edit Lua files
2. Test Changes: `love . --test` 
3. Run Game: `love .`
4. Debug Issues: `love . --debug`

### Adding New Features

The modular architecture makes it easy to extend:
- New Cards: Add to `data/cards.lua`
- New Scenes: Create in `scenes/` directory
- New Abilities: Extend card effect system
- New UI: Use layout system components
- New Tests: Add to `tests/` directory

## Performance Guidelines

### Memory Management

- Use object pooling for frequently created objects
- Batch draw calls using SpriteBatch
- Limit simultaneous audio instances (max 16)
- Cache layout calculations
- Clean up completed animations

### Rendering Optimization

- Use texture atlases to reduce draw calls
- Enable nearest-neighbor filtering for pixel art
- Minimize GPU state changes
- Implement efficient collision detection

### Animation Performance

- Use fixed timestep for deterministic updates
- Cache easing function calculations
- Automatically clean up completed tweens
- Limit concurrent animations per object

## Multiplayer Considerations

### Deterministic Gameplay

The framework uses seedable RNG for consistent game states:

```lua
-- Set seed for deterministic shuffling
Utils.setSeed(12345)
local shuffled_deck = Utils.shuffle(deck)
```

### Networking Architecture

For multiplayer implementation:
1. Authoritative Server: Validate all game actions server-side
2. Client Prediction: Show immediate feedback, rollback on mismatch  
3. State Synchronization: Send delta updates, not full game state
4. Input Buffering: Handle network latency gracefully

### Recommended Libraries

- lua-enet: Low-latency UDP networking (included with Love2D)
- json.lua: For network message serialization
- lz4: For state compression

## Contributing

Contributions are welcome. Please test your changes and follow the existing code style.

## License

MIT License