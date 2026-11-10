# A single one of the game's 117 double-sided tiles.
#
# `class_name Tile` registers this script as a global type named `Tile`, so
# any other script can just write `Tile.new(...)` — no `preload`/`load`
# needed, similar to how a C++ class becomes usable project-wide once its
# header is included, except GDScript needs no include at all.
#
# `extends RefCounted` makes this a plain reference-counted object (think:
# an ordinary Python class with automatic garbage collection), with none of
# the scene-tree/rendering machinery a Godot `Node` carries. That keeps this
# file pure game-state logic, per the project's "separate logic from
# graphics" rule — nothing here knows how a tile is drawn on screen.
class_name Tile
extends RefCounted

# GDScript has no `private`/`public` keywords at all — a single leading
# underscore is just the official style-guide convention for "internal,
# don't touch from outside" (enforced by nothing but the reader's good
# will). This matches `_add`/`_undrawn`/`_hands` etc. elsewhere in this
# project, and is what `gdlint` (the standard GDScript linter) expects —
# unlike a C++/C#-style trailing underscore, which it rejects outright.

# The letter on this tile's front (yellow) face. Always a real letter, never blank.
var _front_letter: String

# The letter on this tile's other face. Usually a different letter, but two
# special cases exist (see doc/RULES.md):
#   - "" (empty string): this face is blank. Flipping to it lets a row's
#     word end early instead of forcing a full 9 letters (the "shorten"
#     mechanic). 12 of the 117 tiles have this.
#   - the same face can be yellow instead of green — see `_back_is_green`
#     below — for exactly 2 of the 117 tiles (K/U and W/S), which by design
#     never carry the green-letter scoring penalty.
var _back_letter: String

# Whether the back face counts as "green" for scoring, or is actually a
# second yellow face (true for 115 of the 117 tiles, false for the 2
# special all-yellow tiles above).
var _back_is_green: bool

# Which face is currently showing: true = _front_letter, false =
# _back_letter. Starts true, matching a freshly-drawn tile in the physical
# game (yellow side up).
var _showing_front: bool = true


# `_init` is GDScript's constructor — always named `_init`, called
# automatically by `Tile.new(...)`, equivalent to a C++ constructor body.
func _init(front_letter: String, back_letter: String, back_is_green: bool) -> void:
	_front_letter = front_letter
	_back_letter = back_letter
	_back_is_green = back_is_green


# Flips the tile in place: swaps which face is showing. This never removes
# a letter that already "grew" into a word — it only changes which letter
# this specific tile currently contributes.
func flip() -> void:
	_showing_front = not _showing_front


# The letter this tile currently shows. Returns "" if showing a blank back
# face (the shorten mechanic).
func current_letter() -> String:
	return _front_letter if _showing_front else _back_letter


# Whether the currently-showing face counts as green for the -5 scoring
# penalty. The yellow face is never green; the back face is green unless
# it's one of the 2 special all-yellow tiles.
func current_is_green() -> bool:
	return not _showing_front and _back_is_green


# Whether the currently-showing face is blank (the shorten mechanic). Only
# ever true when showing the back face of one of the 12 shorten tiles.
func is_blank() -> bool:
	return current_letter() == ""


# Static-definition accessors below — these describe the tile itself
# (which letters/colors it was made with), independent of whichever face
# currently happens to be showing. Board/scoring logic on placed tiles
# should use `current_letter()`/`current_is_green()`/`is_blank()` above;
# these three exist for code that needs to inspect the tile's fixed
# definition instead (the test suite, mainly).
func front_letter() -> String:
	return _front_letter


func back_letter() -> String:
	return _back_letter


func back_is_green() -> bool:
	return _back_is_green


# Whether the front face is currently showing — the one piece of mutable
# state a tile has. Exposed (alongside `set_showing_front` below)
# specifically for save_game.gd: everything else about a tile is fixed at
# construction and reconstructible from TilePool alone, so a save file
# only needs to record this one bit per tile, not the whole object.
func is_showing_front() -> bool:
	return _showing_front


# Restores the flip state saved via `is_showing_front` — see save_game.gd.
# Not for gameplay use: flipping mid-game should go through `flip()`.
func set_showing_front(showing_front: bool) -> void:
	_showing_front = showing_front
