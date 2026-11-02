# Rainbow Climb — Game Design Specification

## Overview

**Rainbow Climb** is a generative vertical platformer for Android inspired by *Rainbow Islands* (Taito, 1987). The player climbs upward through infinite procedurally generated levels, creating rainbow bridges to reach platforms while an auto-scrolling camera pushes them ever higher. Features 2D pixel art graphics and fully procedural electronic music.

**Platform**: Android (API 24+)
**Engine**: libGDX 1.12+ with Kotlin
**Art style**: 2D pixel art (32x32 base tile size)
**Music**: Procedurally generated electronic / chiptune
**Monetization**: Free, no ads, "Buy Me a Coffee" donation link
**Connectivity**: Fully offline

---

## Core Gameplay

### The Loop

1. Player starts at the bottom of a procedurally generated vertical level
2. Camera auto-scrolls upward at a constant pace
3. Player jumps between platforms and **shoots rainbows** to create temporary bridges
4. Enemies patrol platforms and fly in patterns — contact means death
5. Collectibles (gems, stars) increase score
6. Falling below the camera's bottom edge = death
7. Every ~50 platforms the biome changes (new tileset, palette, music parameters)
8. Game ends on death — score = max height + collectibles
9. Restart instantly

### Controls

| Input | Action |
|-------|--------|
| Left side of screen (touch/hold) | Move left |
| Right side of screen (touch/hold) | Move right |
| Tap right side while holding left (or vice versa) | Jump |
| Swipe up | Shoot rainbow upward-arc |
| Swipe left/right | Shoot rainbow in that direction |

Alternative control scheme (settings):
- Virtual D-pad (left) + action buttons (right)

### Rainbow Mechanic

- Player shoots a rainbow arc in a direction
- The rainbow solidifies into a **temporary platform** (lasts 4 seconds, then fades)
- Rainbows can also **damage enemies** on contact
- Rainbow ammo: regenerates 1 per second, max 3 stored
- Rainbow arc follows a parabolic curve, length ~3-4 tiles

### Difficulty Scaling

- **Base scroll speed**: ~30 pixels/second at level 1
- **Scroll speed increase**: **+0.2% per level** (compounding)
- Level = every 50 platform-rows climbed
- Additional scaling per level:
  - Platform gaps widen slightly
  - Enemy density +0.2%
  - Moving/crumbling platform frequency +0.2%
  - Enemy speed +0.2%

At level 100 the scroll speed is ~1.22x base. At level 350 it's ~2x base. The curve is gentle but relentless.

### Power-ups

| Power-up | Effect | Duration |
|----------|--------|----------|
| Rainbow Boost | Max rainbow ammo becomes 6, regen 2x | 15 sec |
| Double Jump | Extra mid-air jump | 20 sec |
| Shield | Survive one enemy hit | Until hit |
| Slow Time | Camera scroll speed halved | 10 sec |
| Magnet | Attract collectibles within 3-tile radius | 15 sec |

Power-ups spawn on platforms with ~5% probability, weighted by rarity.

---

## Procedural Level Generation

### Chunk System

- The world is divided into vertical **chunks** of 16 tiles height
- 3 chunks are kept in memory: current, one above, one below
- New chunks generate ahead of the player; old chunks are recycled
- Each chunk contains 3-6 platforms, 0-3 enemies, 0-2 collectibles

### Platform Placement Algorithm

```
For each chunk:
  1. Divide chunk into 3-4 horizontal bands
  2. For each band, place 1-2 platforms
  3. Validate: every platform must be reachable from at least one platform
     in the band below via jump arc (or rainbow arc as fallback)
  4. Apply variation: moving platforms, crumbling platforms, one-way platforms
  5. Place enemies on or near platforms
  6. Place collectibles (biased toward harder-to-reach spots)
```

### Reachability Guarantee

- Max jump height: 4 tiles
- Max jump horizontal distance: 3 tiles
- Rainbow reach: 4 tiles in arc
- Platform placement must ensure at least one path exists using jump alone
- Rainbow should enable bonus/shortcut paths, not be mandatory

### Biomes

Each biome defines: tileset, palette, background layers, enemy skins, music parameters.

| # | Biome | Colors | Mood |
|---|-------|--------|------|
| 1 | Sky Garden | Green, sky blue, white | Cheerful, bright |
| 2 | Cloud Kingdom | White, gold, light blue | Dreamy, floaty |
| 3 | Neon City | Purple, pink, cyan | Energetic, urban |
| 4 | Crystal Cave | Dark blue, teal, silver | Mysterious |
| 5 | Fire Ruins | Red, orange, dark gray | Intense, dangerous |
| 6 | Candy Land | Pastel pink, yellow, mint | Playful, sweet |
| 7 | Space Station | Black, white, electric blue | Sci-fi, vast |
| 8 | Haunted Forest | Dark green, purple, gray | Eerie |

Biomes cycle in random order (no immediate repeats). After all 8 are shown, reshuffle.

---

## Enemies

### Base Types

| Enemy | Behavior | Sprite size |
|-------|----------|-------------|
| **Walker** | Patrols left-right on a platform | 16x16 |
| **Flyer** | Moves in sine-wave pattern vertically | 16x16 |
| **Hopper** | Jumps between platforms | 16x16 |
| **Shooter** | Stationary, fires projectile horizontally | 16x16 |
| **Bomber** | Flies overhead, drops projectiles down | 16x24 |
| **Chaser** | Activates when player is near, follows for 3 sec | 16x16 |

Each enemy type is reskinned per biome (palette swap + minor sprite variation).

Enemies are defeated by rainbow contact (1 hit). They drop collectibles on death (50% chance).

---

## Procedural Music System

### Architecture

A real-time music engine generates electronic music using synthesized waveforms.

### Sound Generation

- **Oscillators**: Square, sawtooth, triangle, sine, noise
- **ADSR envelopes** per voice
- **4 simultaneous tracks**:
  1. **Drums** — Kick (sine + pitch drop), snare (noise burst), hi-hat (filtered noise)
  2. **Bass** — Square/saw wave, follows chord root
  3. **Lead/Arp** — Procedurally generated melody using Markov chains
  4. **Pad/Atmosphere** — Long sustained chords, slow filter sweep

### Musical Rules

- **Scale**: Pentatonic minor (safe, always sounds good)
- **Tempo**: 110-140 BPM, tied to biome
- **Time signature**: 4/4
- **Chord progressions**: Pre-defined pool of 4-bar progressions per mood
- **Melody generation**: Note-to-note transition probabilities (Markov chain), biased toward stepwise motion and chord tones
- **Biome influence**: Each biome specifies tempo range, preferred waveforms, reverb amount, and note density

### Adaptive Behavior

- Layers are added/removed based on game intensity
- Near-death (close to bottom of screen): drums intensify, tempo nudges up
- Collecting items: triggers melodic flourish
- Biome transition: 4-bar crossfade between old and new parameters
- Enemy kill: percussive hit synced to beat

### Implementation

- Custom lightweight synthesizer using libGDX AudioDevice (PCM output)
- 44100 Hz sample rate, 16-bit mono
- ~200 samples buffer for low latency
- All generation happens on a dedicated audio thread

---

## Technical Architecture

### Project Structure

```
rainbow-climb/
├── android/              # Android launcher, manifest, assets
├── core/                 # Shared game code (Kotlin)
│   ├── src/main/kotlin/
│   │   └── com/darumahq/rainbowclimb/
│   │       ├── RainbowClimbGame.kt       # Main game class
│   │       ├── screen/
│   │       │   ├── GameScreen.kt          # Main gameplay
│   │       │   ├── MenuScreen.kt          # Title/menu
│   │       │   └── GameOverScreen.kt      # Score display
│   │       ├── world/
│   │       │   ├── World.kt               # World state, chunk management
│   │       │   ├── ChunkGenerator.kt      # Procedural level generation
│   │       │   ├── Platform.kt            # Platform types
│   │       │   └── Biome.kt               # Biome definitions
│   │       ├── entity/
│   │       │   ├── Player.kt              # Player physics, state
│   │       │   ├── Rainbow.kt             # Rainbow projectile/platform
│   │       │   ├── Enemy.kt               # Enemy base + types
│   │       │   └── Collectible.kt         # Items, power-ups
│   │       ├── audio/
│   │       │   ├── MusicEngine.kt         # Procedural music generator
│   │       │   ├── Synthesizer.kt         # Waveform generation, ADSR
│   │       │   ├── Sequencer.kt           # Beat/pattern sequencing
│   │       │   └── SfxManager.kt          # Sound effects
│   │       ├── input/
│   │       │   └── TouchInputHandler.kt   # Touch controls
│   │       ├── render/
│   │       │   ├── GameRenderer.kt        # Sprite batch rendering
│   │       │   └── ParallaxBackground.kt  # Scrolling backgrounds
│   │       └── util/
│   │           ├── Constants.kt           # Game constants
│   │           └── SeededRandom.kt        # Deterministic RNG
├── desktop/              # Desktop launcher (for dev/testing)
├── assets/
│   ├── sprites/          # Sprite sheets (PNG)
│   ├── tiles/            # Tileset PNGs
│   ├── ui/               # UI elements
│   └── fonts/            # Pixel fonts
├── build.gradle.kts
├── settings.gradle.kts
├── SPEC.md
├── LICENSE
└── README.md
```

### Key Technical Decisions

- **No Box2D**: Custom simple AABB physics — lighter, more predictable for a platformer
- **Object pooling**: All entities (platforms, enemies, rainbows, particles) are pooled to avoid GC pressure
- **Chunk recycling**: Ring buffer of 3 chunks, rewritten as player ascends
- **Deterministic RNG**: Seeded random per run — same seed = same level layout (enables sharing seeds)
- **Sprite atlas**: All sprites packed into one or two texture atlases (TexturePacker)
- **Target frame rate**: 60 FPS
- **Virtual resolution**: 240x400 pixels, scaled to fit device (pixel-perfect integer scaling preferred)

### Physics

- Gravity: 900 px/s²
- Jump velocity: -350 px/s (negative = up)
- Move speed: 150 px/s
- Max fall speed: 500 px/s
- All collision is AABB (axis-aligned bounding box)
- One-way platforms: collide only when falling (vy > 0)

---

## Sprites & Art Assets

### Source Strategy

1. **Primary**: Free assets from OpenGameArt.org, itch.io, Kenney.nl (CC0/CC-BY)
2. **Custom**: Palette-swap and modify base sprites to match biome themes
3. **Tools**: Aseprite or LibreSprite for editing, TexturePacker for atlas generation

### Sprite Specifications

- Player: 16x24 px, 6 animations (idle: 2fr, run: 6fr, jump: 2fr, fall: 2fr, shoot: 3fr, death: 4fr)
- Enemies: 16x16 px, 2-4 frames each
- Platforms: 32x8 px tiles (composable for variable width)
- Collectibles: 8x8 px, 4-frame sparkle animation
- Rainbow: 48x16 px arc segments, 3 fade-out frames
- Particles: 4x4 px, 3-4 frames
- Backgrounds: 240x400 px per parallax layer (tileable vertically)

---

## UI / UX

### Screens

1. **Title Screen**: Logo, "Tap to Play", "High Score: X", "Buy Me a Coffee" button, settings gear icon
2. **Game Screen**: Minimal HUD — score (top center), rainbow ammo (top right, 1-3 rainbow icons), current height (top left)
3. **Game Over Screen**: "Height: X", "Score: X", "Best: X", "Tap to Retry", "Share Seed" button
4. **Settings**: Control scheme toggle, music on/off, SFX on/off, vibration on/off

### Persistence

- SharedPreferences for: high score, settings, last seed
- No cloud save (offline-first)
- No accounts, no login

---

## Monetization

- **Completely free**, no ads, no in-app purchases
- **"Buy Me a Coffee"** link on title screen and game over screen
- Links to external browser: `https://buymeacoffee.com/<TBD>`

---

## Build & Distribution

- **Build system**: Gradle with Kotlin DSL
- **Min SDK**: 24 (Android 7.0)
- **Target SDK**: 34 (Android 14)
- **APK size target**: < 15 MB
- **Distribution**: Google Play Store + GitHub Releases (APK)
- **CI**: GitHub Actions — build APK on push, release on tag

---

## Development Phases

### Phase 1 — Core (MVP)
- [ ] Project setup (libGDX + Kotlin + Gradle)
- [ ] Player movement and jump physics
- [ ] Basic platform generation (static platforms)
- [ ] Camera auto-scroll
- [ ] Rainbow shooting mechanic
- [ ] Collision detection
- [ ] Single biome with placeholder sprites
- [ ] Basic HUD (score, height)
- [ ] Game over + restart

### Phase 2 — Content
- [ ] All 8 biomes with tilesets and palettes
- [ ] 6 enemy types with AI
- [ ] 5 power-ups
- [ ] Moving / crumbling / one-way platforms
- [ ] Parallax backgrounds
- [ ] Particle effects
- [ ] Difficulty scaling (+0.2%/level)

### Phase 3 — Audio
- [ ] Procedural music engine (synthesizer + sequencer)
- [ ] Per-biome music parameters
- [ ] Adaptive music (intensity, layer transitions)
- [ ] Sound effects (jump, rainbow, collect, enemy death, game over)

### Phase 4 — Polish
- [ ] Title screen, game over screen, settings
- [ ] Touch control refinement
- [ ] High score persistence
- [ ] Seed sharing
- [ ] "Buy Me a Coffee" integration
- [ ] Performance optimization (object pooling, GC tuning)
- [ ] Android back button handling
- [ ] Screen orientation lock (portrait)

### Phase 5 — Release
- [ ] Google Play Store listing
- [ ] GitHub Actions CI pipeline
- [ ] Privacy policy (no data collected)
- [ ] GitHub Releases with APK
- [ ] Play Store screenshots and description

---

## License

**Code**: MIT License
**Assets**: Per-asset license (CC0/CC-BY, tracked in `assets/LICENSES.md`)
