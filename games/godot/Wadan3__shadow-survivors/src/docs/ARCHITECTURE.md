# Architecture

`Game.gd` composes the arena, HUD, player, camera, enemy container, and wave director. It is the authority for high-level run states: `playing`, `paused`, `upgrade`, and `game_over`.

`GameManager` is an autoload that owns run statistics and local save data. `AudioManager` is an autoload that synthesizes short sound effects into `AudioStreamWAV` resources on demand. `WaveManager` remains scene-local so restarting the gameplay scene cleanly resets its timers and difficulty.

Enemies share `Enemy.gd`, with scene-exported archetype names selecting stat packages and visuals. `Boss.gd` extends that base with radial/aimed projectile patterns and a periodic charge. Actor visuals use `_draw()` and are deliberately texture-free.

The HUD owns three independent modal scenes—Pause, Upgrade, and Game Over. These use `PROCESS_MODE_ALWAYS`, allowing their controls to remain interactive while the SceneTree is paused.

Collision layers are named in `project.godot`:

1. World
2. Player
3. Enemies
4. Player bullets
5. Enemy bullets
6. Pickups

