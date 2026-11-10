# Trampoline (Godot rewrite) — vibe-coding ground rules

Godot/GDScript rewrite of the "Trampoline" word game. The original Unity/C#
version (v3.x, no longer released) lives in `../trampoline-unity` for
reference. The user knows C++, C, Python, CMake and Nix well, and knows
Unity/C# from the original game, but has never used Godot or GDScript.
These rules apply to everything in this repository and
override the general defaults for comments and commit granularity.

## 1. Minimalistic git commits
- One logical change per commit — don't bundle unrelated fixes/features.
- Short, imperative commit messages describing *what* changed.
- Never commit unless explicitly asked to.

## 2. Explain every line of GDScript
- The user doesn't know GDScript yet, so every non-trivial line needs a
  comment saying what it does.
- GDScript is close to Python (indentation-based, dynamically typed by
  default, `func`/`var` instead of `def`/no keyword) — lean on that analogy
  wherever it applies. Where a Godot-specific concept has no Python/C++
  equivalent (nodes, the scene tree, signals, `_ready()`/`_process()`
  lifecycle callbacks), say so explicitly rather than forcing a comparison.
- First time a new Godot concept appears (a node type, signals, autoloads,
  `.tscn` scene files, export variables, etc.), explain it briefly even if
  it recurs later without a fresh comment.
- Trivial repeated boilerplate does not need its own comment once the
  pattern has been explained.

## 3. Minimalistic code
- Simplest node/script that does the job — no speculative abstractions, no
  unused scaffolding, no "just in case" flexibility.
- Don't add a plugin/addon unless it's clearly needed for the task at hand.

# Separation of concern

We are developing a video game so logic and graphics logic must be well separated.