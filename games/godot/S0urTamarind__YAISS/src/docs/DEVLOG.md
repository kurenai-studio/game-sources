# YAISS Development Log


### [2345e58] - 2026-10-14 23:50 UTC
**Commit:** Initial Godot Commit
- Created `Characters/Player.tscn` rooted at an `Area2D` node with a child `Sprite2D` (utilizing `player_sheet.png` with `hframes = 3`) and a `CollisionShape2D` utilizing a `CircleShape2D` with radius 43.01.
- Created `MainScenes/Gameplay.tscn` as a `Node2D` root scene instantiating the Player scene at a fixed initial position of `Vector2(960, 540)`.
- Configured `project.godot` targeting Godot 4.7 with GL Compatibility renderer, establishing a 1920x1080 viewport with canvas-item stretching and Jolt Physics as the engine default.


### [cb61ef0] - 2026-10-14 23:51 UTC
**Commit:** Initial commit
- Added the GNU General Public License v3 (LICENSE) file to establish open-source distribution terms for the codebase.


### [3e8ecc9] - 2026-10-14 23:53 UTC
**Commit:** Merge branch 'main' of https://github.com/S0urTamarind/YAISS
- Added the GNU General Public License v3 (`LICENSE`) file to the root directory to establish open-source distribution terms for the project codebase.


### [392d527] - 2026-10-15 03:09 UTC
**Commit:** Add sights
- Added `Characters/Sights.tscn` (`Sprite2D`) governed by `sights.gd`, implementing directional movement physics via `@export var speed: float` and constrained positioning relative to an `@export var player: Area2D` dependency using bounding radius calculations.
- Updated `project.godot` input map with new actions: `Shoot`, `Shift Aim Up`, `Shift Aim Down`, `Shift Aim Left`, and `Shift Aim Right`.
- Integrated the Sights scene into `MainScenes/Gameplay.tscn` and renamed root nodes in `Characters/Player.tscn` from generic `Area2D` to `Player`.


### [955bda9] - 2026-10-31 12:56 UTC
**Commit:** Fix Sights
- Updated `Characters/sights.gd` to use `Input.get_vector()` for directional movement processing, replacing manual individual action checks.
- Added `@export var extra_margin: float = 10.0` and integrated `Sprite2D` texture dimensions into `calcPadding()` to prevent visual clipping against the `Area2D` player node.
- Replaced manual zero-length checks with `is_zero_approx()` and corrected collision shape property lookups (`child.shape`) during runtime radius calculations.


### [83cf459] - 2026-10-31 16:30 UTC
**Commit:** Add shooting
- Created `Characters/Bullet.tscn` using an `Area2D` root node with `Sprite2D`, `CollisionShape2D` (CapsuleShape2D), and `VisibleOnScreenNotifier2D` nodes, connecting the `screen_exited` signal to `queue_free()`.
- Implemented `Characters/bullet.gd` extending `Area2D` with an exported `speed` parameter, updating `global_position` via vector math and aligning `rotation` based on travel direction in `_physics_process`.
- Implemented `Characters/player.gd` extending `Area2D` with exported `bullet_scene` and `sight` dependencies, instantiating projectiles into the root tree and calculating spawn transforms using normalized direction vectors.
- Updated `MainScenes/Gameplay.tscn` to assign the `sight` node path export property on the Player instance.


### [0fbf0c0] - 2026-10-31 18:41 UTC
**Commit:** Fixed pi/2 rotation issue
- Updated `Characters/Bullet.tscn` by applying a $\pi/2$ ($1.5707964$ rad) rotation offset to the `Sprite2D`, `CollisionShape2D`, and `VisibleOnScreenNotifier2D` nodes to correct asset orientation.
- Removed the $\pi/2$ radian offset (`+ (PI / 2)`) from `rotation` calculations in `Characters/bullet.gd` (`_physics_process`) and `Characters/player.gd` (`shoot`), aligning node rotation directly with `direction.angle()`.


### [fb2bd3e] - 2026-11-01 11:50 UTC
**Commit:** Added basic logging functionality
* Added `res://src/yaiss/logging.gd` as a `RefCounted` utility providing a static `record()` method, `Level` enum, and timestamped console output formatting.
* Integrated logging into `Characters/player.gd` by preloading the logging utility and adding a static `player_log()` helper to record `INFO` level events tagged with `["Player"]` during `shoot()` executions.
* Reordered node children in `Characters/Player.tscn` to place `CollisionShape2D` before `Sprite2D` within the root `Area2D` hierarchy.


### [664a4fe] - 2026-11-01 12:31 UTC
**Commit:** Added runtime debugging and better logging
- Added `src/yaiss/runtime.gd` providing static error and fatal handling functions that log, trigger engine `push_error`, print stack traces, and manage `SceneTree` termination.
- Expanded `src/yaiss/logging.gd` with a `FATAL` log level, rich text formatting (`print_rich`), color/bold arguments, and shorthand static methods (`record_debug`, `record_info`, etc.).
- Refactored `Characters/player.gd` to remove local logging wrappers and directly invoke `Log.record_debug()`.
- Removed `window/size/mode=4` from `project.godot`.

