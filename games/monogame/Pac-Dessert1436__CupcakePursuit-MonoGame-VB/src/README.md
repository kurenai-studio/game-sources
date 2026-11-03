# Cupcake Pursuit (MonoGame + VB.NET)

## 📌 PROJECT STATUS: DEVELOPMENT PAUSED

**This project is currently on hold due to academic commitments.** The developer is focusing on preparation for the Postgraduate Entrance Exam and will resume development at the end of 2026 — see the [Future Development](#-future-development) section for a detailed roadmap.

### Project Name Reservation
The name **"Cupcake Pursuit"** is reserved for this project. While this is a free, non-commercial GitHub release, unauthorized use of this name for game publishing is not permitted.

---

## 🎮 Project Overview

**Cupcake Pursuit** is a maze chase game currently in early development, built upon the **[MonoGame 2D StartKit VB.NET](https://www.nuget.org/packages/PacDessert1436.MonoGame.StartKitVB/)** template (latest version 1.3.0, with experimental iOS support) — a NuGet package created by the project owner specifically for MonoGame VB.NET development.

The game concept follows a baker's quest to collect cupcake ingredients while evading enemies in a vibrant, maze-based environment.

### Current Development Progress
- __Title Card Artwork__: Draft completed (color palette and decorative elements pending finalization)
- __Core Framework__: Utilizes the MonoGame StartKit VB.NET template with its demo game logic
- __Control System__: Gamepad, keyboard, and virtual joystick support (as provided by the template)
- __A* Pathfinding Module__: Implemented for enemy navigation and path optimization

> **Note on Game Assets**: Only the title card artwork has been customized thus far. All other game logic and assets remain unchanged from the MonoGame StartKit VB.NET demo.

![Title Card Artwork](CupcakePursuitMGVB.Core/Content/Images/title_card.png)

---

## ⚙️ Technical Requirements

To build or contribute to this project, the following tools are required:

| Component | Version |
|-----------|---------|
| [.NET SDK](https://dotnet.microsoft.com/download/dotnet/10.0) | 10.0 or later |
| [MonoGame Framework](https://www.monogame.net/) | 3.8.5.1 or later |
| IDE | Visual Studio 2026, Visual Studio Code, or compatible .NET IDE |

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [MonoGame 2D StartKit VB.NET](https://www.nuget.org/packages/PacDessert1436.MonoGame.StartKitVB/) | 1.3.0 | Project template and demo game logic |
| [ModuleEventRaiser.Generator](https://www.nuget.org/packages/ModuleEventRaiser.Generator/) | 1.2.5.1 | Source generator for thread-safe event scheduling |
| [MonoGame.Framework.Native](https://www.nuget.org/packages/MonoGame.Framework.Native/) | 3.8.5.1 | Native platform support for MonoGame |

---

## 📁 Project Structure

This solution follows the standard MonoGame multi-platform project structure:

```
CupcakePursuitMGVB/
├── CupcakePursuitMGVB.Android/       # Android platform project
│   ├── Resources/                    # Android-specific resources
│   └── MainActivity.cs               # Android entry point
├── CupcakePursuitMGVB.Core/          # Core game logic (VB.NET)
│   ├── Content/                      # Game assets
│   │   ├── Fonts/                    # Sprite fonts and typefaces
│   │   ├── Images/                   # Game textures and sprites
│   │   └── Sounds/                   # Background music and sound effects
│   ├── scripts/                      # Icon generation scripts
│   ├── Actor.vb                      # Game actor base class (Player, Enemy, Seed)
│   ├── Essentials.vb                 # Constants, enums, events, and utility functions
│   ├── GameMain.vb                   # Main game class (initialization & game loop)
│   ├── GameManager.vb                # Game state management and collision logic
│   ├── HardcodedValues.vb            # Hand-crafted maze layout data (XML literals)
│   ├── Pathfinding.vb                # A* pathfinding module for enemy navigation
│   ├── Renderer.vb                   # Rendering, HUD, and screen scaling
│   ├── SoundManager.vb               # Audio playback and event-driven sound triggers
│   ├── SpriteSheet.vb                # Sprite sheet and animation handling
│   └── VirtualJoystick.vb            # Touch input with dead zone support
├── CupcakePursuitMGVB.DesktopGL/     # Desktop OpenGL platform
│   └── Program.cs                    # Desktop entry point
├── CupcakePursuitMGVB.WindowsDX/     # Windows DirectX platform
│   └── Program.cs                    # Windows entry point
├── CupcakePursuitMGVB.iOS/           # iOS platform project
│   ├── AppIcon.xcassets/             # iOS app icons
│   └── Program.cs                    # iOS entry point
├── BEGINNER_GUIDE.md                 # MonoGame guide for VB.NET developers
└── CupcakePursuitMGVB.sln            # Solution file
```

### Key Directories Explained

| Directory | Purpose | Language |
|-----------|---------|----------|
| `CupcakePursuitMGVB.Core/` | Contains all shared game logic and assets | VB.NET |
| `CupcakePursuitMGVB.Android/` | Android-specific project configuration | C# |
| `CupcakePursuitMGVB.DesktopGL/` | Cross-platform desktop build target | C# |
| `CupcakePursuitMGVB.WindowsDX/` | Windows-optimized DirectX build target | C# |
| `CupcakePursuitMGVB.iOS/` | iOS-specific project configuration | C# |

---

## 📜 License

This project is licensed under the **BSD 3-Clause License**. For detailed terms, please refer to the [LICENSE](LICENSE) file.

---

## 📅 Future Development

Development will resume upon completion of the developer's academic commitments. The following is a **preliminary roadmap** for when work resumes:

### Planned Milestones
1. **Core Game Implementation**
   - Custom maze generation algorithms (procedural generation already in place via `Essentials.vb`; hand-crafted layouts in `HardcodedValues.vb` to be designed)
   - Cupcake ingredient collection mechanics
   - Enemy AI behavior patterns
   - Player power-ups and abilities

2. **Art and Asset Development**
   - Complete title card artwork
   - Character sprites and animations
   - Environment tilesets and backgrounds
   - UI/UX elements

3. **Audio and Polish**
   - Original soundtrack composition (or sourcing from Open Game Art)
   - Sound effect implementation (or sourcing from Open Game Art)
   - Game balancing and tuning

4. **Platform Optimization**
   - Performance improvements
   - Cross-platform testing
   - Mobile-specific optimizations

**Target Resumption**: December 21st, 2026  
**Last Updated**: August 25th, 2026