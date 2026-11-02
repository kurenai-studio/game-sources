# Rainbow Climb

A generative vertical platformer for Android inspired by *Rainbow Islands* (Taito, 1987).

Climb infinitely through procedurally generated levels, shoot rainbows to create platforms, and survive an ever-accelerating auto-scrolling camera. Features 8 unique biomes with procedurally generated electronic music.

## Features

- **Infinite procedural levels** — chunk-based generation ensures every run is unique
- **Rainbow mechanic** — shoot rainbow arcs that become temporary platforms and damage enemies
- **8 biomes** — Sky Garden, Cloud Kingdom, Neon City, Crystal Cave, Fire Ruins, Candy Land, Space Station, Haunted Forest
- **Procedural electronic music** — real-time synthesized chiptune/techno that adapts to gameplay
- **6 enemy types** — Walker, Flyer, Hopper, Shooter, Bomber, Chaser
- **5 power-ups** — Rainbow Boost, Double Jump, Shield, Slow Time, Magnet
- **Difficulty scaling** — +0.2% per level (compounding), gentle but relentless
- **Fully offline** — no internet required
- **Seed sharing** — same seed = same level layout

## Tech Stack

- **Engine**: [libGDX](https://libgdx.com/) 1.12+
- **Language**: Kotlin
- **Build**: Gradle (Kotlin DSL)
- **Platforms**: Android (primary), Desktop (dev/testing)
- **Audio**: Custom PCM synthesizer — no sample files needed

## Project Structure

```
rainbow-climb/
├── core/           # Shared game code (Kotlin)
├── android/        # Android launcher
├── desktop/        # Desktop launcher (for dev/testing)
├── assets/         # Sprites, tiles, fonts
├── SPEC.md         # Full game design specification
└── build.gradle.kts
```

## Building

### Desktop (for development)

```bash
./gradlew desktop:run
```

### Android

```bash
./gradlew android:assembleDebug
```

The APK will be at `android/build/outputs/apk/debug/android-debug.apk`.

## Controls

### Desktop
| Key | Action |
|-----|--------|
| Arrow keys / A,D | Move left/right |
| Up / W | Jump |
| Space / Z | Create rainbow bridge (direction follows player) |
| P | Pause |

### Mobile
| Input | Action |
|-------|--------|
| Touch left/right half | Move |
| Second finger tap | Jump |
| Swipe | Create rainbow bridge |

## Credits

### Art Assets (all CC0 — Public Domain)

| Asset Pack | Author | Used for |
|-----------|--------|----------|
| [Pixel Adventure 1](https://pixelfrog-assets.itch.io/pixel-adventure-1) | **Pixel Frog** | Player character, collectibles, terrain, platforms, backgrounds, UI |
| [Kings and Pigs](https://pixelfrog-assets.itch.io/kings-and-pigs) | **Pixel Frog** | Walker & Bomber enemies, tilesets, HUD elements |
| [Treasure Hunters](https://pixelfrog-assets.itch.io/treasure-hunters) | **Pixel Frog** | Hopper, Chaser & Shooter enemies |
| [Pixel Art Gem Pack](https://karsiori.itch.io/free-pixel-art-gem-pack) | **karsiori** | Gem collectibles (8 color variants) |
| [Public Pixel Font](https://ggbot.itch.io/public-pixel-font) | **GGBotNet** | HUD and UI text |

All assets are released under Creative Commons Zero (CC0). Full details in [assets/LICENSES.md](assets/LICENSES.md).

## License

**Code**: MIT License
**Assets**: See [assets/LICENSES.md](assets/LICENSES.md)

## Support

This game is free with no ads. If you enjoy it, consider [buying me a coffee](https://buymeacoffee.com/)!
