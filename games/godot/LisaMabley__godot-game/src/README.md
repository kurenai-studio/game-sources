# godot-game

A small arena survival game in the style of *Vampire Survivors*, built with Godot 4.

You move; your weapons attack on their own. Defeated enemies drop experience gems, and every level-up offers a choice of upgrades. Survive five minutes to win.

## Features

- **Auto-attacking abilities.** The sword strikes the nearest enemy. The axe can be unlocked as an upgrade and spins out from the player.
- **Upgrades on level-up.** Pick one of two randomly offered cards: new abilities, damage boosts, and faster attacks. Upgrades have stack limits, and some only appear once you've unlocked the ability they improve.
- **Rising difficulty.** Enemies spawn faster over time, and tougher enemy types join the mix as the round goes on.
- **Loot drops.** Enemies can drop experience gems and health vials, chosen from weighted loot tables.
- **Game feel.** Hit flashes, floating damage numbers, death animations, and animated pickups.

## Controls

| Action | Keys |
| --- | --- |
| Move | WASD or arrow keys |
| Choose an upgrade | Left click |

## Running the game

1. Install [Godot 4.7](https://godotengine.org/download) (standard edition; no C#/.NET needed).
2. Clone this repo.
3. Open Godot, choose **Import**, and select the `project.godot` file in the repo.
4. Press **F5** (or the Play button) to run.

## Project structure

```
scenes/
  main/          Main scene: wires together managers, UI, and the arena
  manager/       Game-wide systems: timer and difficulty, enemy spawning, experience, upgrades
  component/     Reusable building blocks (health, hitbox/hurtbox, velocity, loot drops, ...)
  game_object/   Player, enemies, drops, and camera
  ability/       Each weapon: a controller that fires it, plus the attack scene itself
  ui/            HUD, upgrade cards, end screen, floating text
  autoload/      GameEvents, a global signal bus
resources/       Custom Resource types (upgrades)
scripts/         Shared utilities (WeightedTable) and balance.gd, the one place for tuning numbers
assets/          Sprites and tiles (potential_sprites/ holds art not yet in use)
theme/           UI theme and font
```

Game objects are built by composition: an enemy is a `CharacterBody2D` plus components like `HealthComponent`, `HurtboxComponent` (takes damage), and `VelocityComponent`. Weapons carry a `HitboxComponent` (deals damage). Systems that don't know about each other talk through the `GameEvents` autoload.

**Tuning balance:** enemy health, speed, drop chances and loot, the spawn schedule, weapon damage and cooldowns, and the level-up upgrades (names, descriptions, effects, how often they appear) all live in [`scripts/balance.gd`](scripts/balance.gd). Edit the numbers there; you don't need to touch any scenes.

## Credits

- This project started from the Udemy course [Create a Complete 2D Arena Survival Roguelike Game in Godot 4](https://www.udemy.com/course/create-a-complete-2d-arena-survival-roguelike-game-in-godot-4/) by [Firebelley Games](https://firebelley.com/). It has since grown in its own direction, so some systems here differ from the course.
- Art from [Kenney](https://kenney.nl/) (CC0).
- Font (Rockboxcond12) provided with the course assets.

## License

The code is released under the [MIT License](LICENSE). Third-party assets keep their own licenses (see Credits).

## Contributing

[CLAUDE.md](CLAUDE.md) has the detailed architecture notes, code conventions, and step-by-step checklists for adding enemies, abilities, and upgrades. It's written for AI coding assistants but is just as useful for people.
