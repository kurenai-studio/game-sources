# I Built a 2D Shoot-'em-Up in C++ Without a Game Engine — Here's What I Learned

![Gameplay Demo](https://raw.githubusercontent.com/dominicharmon-commits/PlaneWarUltimate/main/screenshots/gameplay.gif)

---

After a few weeks of late nights and too much coffee, I shipped my first real game: **Plane War Ultimate** — a classic arcade shoot-'em-up built from scratch in C++17.

No Unity. No Unreal. No Godot. Just C++, raylib, and a lot of trial and error.

- **GitHub:** [github.com/dominicharmon-commits/PlaneWarUltimate](https://github.com/dominicharmon-commits/PlaneWarUltimate)
- **Download:** [v1.0 Release](https://github.com/dominicharmon-commits/PlaneWarUltimate/releases)

---

## Why Build Without an Engine?

Because I wanted to understand what's actually happening under the hood.

When you use Unity, a lot is done for you — physics, collision, rendering pipeline, object lifecycle. Building from scratch forces you to answer questions like:

- How do I manage 300 particles without GC stutter?
- What's the cleanest way to structure a game loop?
- How do I make a boss fight feel satisfying?

Every feature in this game is something I had to design, implement, and debug myself. That's where the real learning happens.

---

## What the Game Actually Does

| Feature | Details |
|---------|---------|
| Combat | Hold-to-shoot, triple-shot power-up, screen-clearing bomb |
| Enemies | 3 types (small/medium/large) with difficulty scaling |
| Boss | 2-phase AI — aimed shots in phase 1, 5-way fan pattern in phase 2 |
| Death FX | Screen flash, slow-motion, multi-stage explosion |
| Visuals | Particle explosions, combo popups, screen shake, procedural sprites |
| Audio | Procedural SFX generation (sine/square/saw waves) |
| Persistence | Local high score save/load |
| Settings | Master volume + SFX volume, fullscreen toggle |

---

## Architecture: Keep It Simple

The codebase is ~2,300 lines split across 7 modules:

```
main.cpp           Entry point
game.h / game.cpp  Game loop, state machine, rendering (1,200 lines)
player             Movement, shooting, invincibility frames
enemy              Three enemy types, spawning logic
boss               2-phase AI, attack patterns, death effects
particle           Explosion particle system
powerup            Heal / triple-shot / bomb pickups
pool.h             Generic object pool template (37 lines!)
```

### The Object Pool

Every dynamic object in the game — bullets, enemies, particles, powerups — uses the same 37-line template:

```cpp
template<typename T, int N>
struct Pool {
    T items[N];

    T* Acquire() {
        for (int i = 0; i < N; i++)
            if (!items[i].active) {
                items[i] = {};
                items[i].active = true;
                return &items[i];
            }
        return nullptr;
    }

    void Clear() {
        for (int i = 0; i < N; i++)
            items[i].active = false;
    }
};
```

No `new`. No `delete`. No heap allocation during gameplay. At 60 FPS with 300 particles, 100 bullets, and 30 enemies on screen, this matters.

### State Machine

The game uses a flat enum-based state machine:

```cpp
enum class GameState { MENU, SETTINGS, PLAYING, PAUSED, GAMEOVER };

void Game::Update() {
    switch (state) {
    case GameState::MENU:     UpdateMenu();     break;
    case GameState::SETTINGS: UpdateSettings(); break;
    case GameState::PLAYING:  UpdatePlaying();  break;
    case GameState::PAUSED:   UpdatePaused();   break;
    case GameState::GAMEOVER: UpdateGameOver(); break;
    }
}
```

No framework, no middleware — just a switch statement. It's boring code, and boring code is easy to debug.

---

## The Boss Fight

The boss was the most fun to design. 240x140 pixels, all drawn in code:

```
Phase 1 (HP > 50%):
  - Two wing pods with gun barrels
  - Central hull with panel lines
  - Blue-glowing core
  - Twin engine exhaust with animated flames
  - Single aimed shot at the player

Phase 2 (HP <= 50%):
  - Core turns red with pulsing glow
  - Red border flicker on all modules
  - Sinusoidal vertical movement
  - 5-way fan-pattern attacks
  - Visible hull cracks at low HP
```

On death: screen flashes white, 3 simultaneous explosions spawn 90 particles, and the shake intensity doubles. It's dumb, it's over-the-top, and it's exactly what a boss fight should feel like.

---

## The Hardest Bug

I shipped a bug where the game froze after 2 seconds. Turns out I'd accidentally renamed a function in a way that created infinite recursion:

```cpp
// The method was originally named PlaySfx, calling raylib's PlaySound
void Game::PlaySound(Sound& snd) {
    SetSoundVolume(snd, sfxVolume);
    PlaySound(snd);  // Calls itself! Stack overflow -> freeze
}
```

A `replace_all` refactor gone wrong. Lesson: never blindly rename functions that shadow library APIs. Name your wrapper something unambiguous: `PlayGameSfx`, not `PlaySound`.

---

## What I'd Do Differently

1. **Split game.cpp earlier.** 1,200 lines in one file is manageable but pushing it. I'd split into `game_menus.cpp`, `game_combat.cpp`, `game_render.cpp` from the start.

2. **Add unit tests for Pool.** It's a 37-line template, but it's the backbone of the entire game. A simple test suite would have caught edge cases early.

3. **Use a fixed-point physics timestep.** Right now, everything runs at display rate. If vsync fails or the monitor is 144Hz, gameplay speed changes. A proper accumulator-based loop would fix this.

4. **Pre-render complex shapes to textures.** The boss is drawn with ~30 draw calls every frame. Baking that into a render texture would cut that to 1.

---

## Try It Yourself

The project builds on Windows with Visual Studio 2022 and raylib 6.0. Everything you need is in the repo:

```bash
git clone https://github.com/dominicharmon-commits/PlaneWarUltimate.git
# Open MyFirstGame.sln in VS2022
# Switch to Release + x64, press F5
```

Or just download the zip from [Releases](https://github.com/dominicharmon-commits/PlaneWarUltimate/releases) and run.

---

## Final Thoughts

Building a game without an engine is not the efficient way to make a game. But if your goal is to learn — to actually understand memory management, game loops, collision detection, and audio pipelines — there's no substitute.

The full source is on GitHub. Star it if you find it useful, and I'd love feedback from anyone who's walked this path before.

**Tags:** `#cpp` `#gamedev` `#raylib` `#tutorial` `#beginners`
