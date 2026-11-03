# Dungeon Explorer

A 2D dungeon exploration game built with MonoGame using an Entity-Component-System (ECS) architecture. Navigate through procedurally generated dungeons, avoid enemies, collect treasures, and survive as long as possible!

## 🎮 Features

- **Entity-Component-System Architecture**: Clean, modular code design
- **Procedural Dungeon Generation**: Randomly generated levels for endless replayability
- **AI-Driven Enemies**: Smart enemies with pathfinding, states (patrol, chase, attack, search)
- **Player Progression**: Score system, treasure collection, and health management
- **Collision System**: Precise collision detection and resolution
- **Camera System**: Smooth following camera with zoom and shake effects
- **Save/Load System**: JSON-based game state persistence
- **Achievement System**: Track progress with unlockable achievements
- **Input Management**: Responsive keyboard and mouse controls

## 🏗️ Architecture

### Core Systems
- **Movement System**: Handles player input and entity movement
- **AI System**: Manages enemy behavior and decision-making
- **Collision System**: Detects and resolves collisions between entities and world
- **Render System**: Manages all visual rendering operations

### Components
- **TransformComponent**: Position, rotation, and scale
- **RenderComponent**: Visual representation and rendering properties
- **MovementComponent**: Velocity, acceleration, and physics
- **HealthComponent**: Health management and damage handling
- **AIComponent**: AI behavior, pathfinding, and state management

### Entities
- **Player**: Player-controlled character with input handling
- **Enemy**: AI-controlled enemies with various behaviors
- **Treasure**: Collectible items that increase player score

## 🎯 Gameplay

### Controls
- **WASD** or **Arrow Keys**: Move character
- **Mouse**: Camera control and targeting
- **Escape**: Pause/Menu

### Objectives
- Explore the dungeon and collect treasures
- Avoid or defeat enemies
- Survive as long as possible
- Achieve high scores and unlock achievements

### Enemy AI Behavior
Enemies have multiple AI states:
- **Idle**: Standing still, waiting
- **Patrolling**: Moving between predefined points
- **Chasing**: Actively pursuing the player
- **Attacking**: Close combat with the player
- **Searching**: Looking for the player at last known location

## 🛠️ Technical Details

### Pathfinding
- **A* Algorithm**: Efficient pathfinding for enemy AI
- **Grid-based Navigation**: 32x32 tile-based movement system
- **Path Optimization**: Simplified paths with redundant waypoint removal

### Collision Detection
- **AABB Collision**: Axis-Aligned Bounding Box collision detection
- **World Boundaries**: Prevents entities from leaving the playable area
- **Tile-based Collision**: Precise collision with dungeon walls and obstacles

### Data Management
- **JSON Serialization**: Save/load game state
- **Player Progress Tracking**: Persistent statistics and achievements
- **Preferences System**: Customizable game settings

## 🚀 Getting Started

### Prerequisites
- .NET 6.0 or higher
- MonoGame Framework 3.8+
- Visual Studio 2022 or Visual Studio Code

### Installation
1. Clone the repository
2. Open the solution in Visual Studio
3. Restore NuGet packages
4. Build and run the project

### Building
```bash
dotnet build
dotnet run
```

## 🎨 Asset Requirements

The game expects the following texture assets:
- `player.png` - Player character sprite
- `enemy.png` - Enemy character sprite
- `treasure.png` - Treasure item sprite
- `wall.png` - Wall tile texture
- `floor.png` - Floor tile texture
- `door.png` - Door tile texture (optional)

Assets should be placed in the Content folder and included in the MonoGame Content Pipeline.

## 🏆 Achievements

- **First Treasure**: Collect your first treasure
- **Treasure Hunter**: Collect 50 treasures
- **Treasure Master**: Collect 100 treasures
- **Enemy Slayer**: Defeat 100 enemies
- **Survivor**: Complete a level without taking damage
- **Speed Runner**: Complete a level in under 2 minutes
- **High Scorer**: Reach 10,000 points
- **Marathon Runner**: Play for 5 hours total

## 📊 Game Statistics

The game tracks various statistics:
- Total games played
- Highest score achieved
- Total treasures collected
- Total enemies defeated
- Total play time
- Best completion time
- Per-level statistics

## 🔧 Configuration

### Camera Settings
- Follow speed and smoothness
- Zoom limits (min/max)
- Movement boundaries

### AI Parameters
- Detection range for enemies
- Attack range and damage
- Movement speed and pathfinding behavior
- State transition timings

### Game Balance
- Player health and movement speed
- Enemy spawn rates and difficulty
- Treasure values and spawn locations
- Scoring multipliers

## 🐛 Known Issues

- Pathfinding may occasionally fail in complex dungeon layouts
- Enemy AI can sometimes get stuck in corners
- Camera bounds checking needs refinement for very small dungeons

## 🚧 Future Enhancements

- **Sound System**: Audio effects and background music
- **Particle Effects**: Visual effects for combat and collection
- **Multiple Enemy Types**: Different AI behaviors and abilities
- **Procedural Music**: Dynamic soundtrack based on game state
- **Multiplayer Support**: Local or network multiplayer modes
- **Level Editor**: Tools for creating custom dungeons
- **Mobile Support**: Touch controls and mobile optimization

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

### Development Guidelines
- Follow the existing ECS architecture
- Maintain code documentation and comments
- Add unit tests for new features
- Follow C# coding conventions

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- MonoGame Framework team for the excellent game development framework
- Community contributors and testers
- Inspiration from classic dungeon crawler games

---

*Made with ❤️ using MonoGame*
