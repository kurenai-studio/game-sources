# Manages drawing tiles from a shared, shuffled pool and tracking which
# tiles each player currently holds. This mirrors
# `../trampoline-unity/Assets/Scripts/TokenDistributor.cs` in the Unity project:
# same shuffle-once-then-draw-in-order behavior, same per-player hand
# tracking, just in GDScript.
class_name TileBag
extends RefCounted

# Tiles not yet drawn by any player, next draw first. Godot arrays have no
# dedicated queue type, so a plain Array used via `pop_front()` plays that
# role — the GDScript equivalent of Unity's `Queue<BasicToken>`.
var _undrawn: Array[Tile] = []

# Each player's currently-held, not-yet-placed tiles, keyed by player index
# (0-based). A Dictionary here plays the role of C#'s
# `Dictionary<int, List<BasicToken>>` in `TokenDistributor.cs`.
var _hands: Dictionary = {}


# Takes every tile from `pool` (see tile_pool.gd), shuffles the draw order,
# and starts with every player's hand empty.
func _init(pool: TilePool) -> void:
	# `duplicate()` copies the array itself (so shuffling this bag's copy
	# doesn't reorder `pool.tiles`); the `Tile` objects inside are shared,
	# not cloned, which is fine since there's exactly one physical tile per
	# `Tile` instance for the whole game.
	_undrawn = pool.tiles.duplicate()
	_undrawn.shuffle()


# Draws up to `count` tiles for `player_id`, adding them to that player's
# hand. Returns the tiles actually drawn — fewer than `count` if the bag
# runs out first.
func draw(player_id: int, count: int) -> Array[Tile]:
	if not _hands.has(player_id):
		_hands[player_id] = [] as Array[Tile]
	var drawn: Array[Tile] = []
	for i in range(min(count, _undrawn.size())):
		var tile: Tile = _undrawn.pop_front()
		drawn.append(tile)
		_hands[player_id].append(tile)
	return drawn


# Returns one tile from a player's hand back to the bag (a player giving
# it back to draw another, see game_session.gd's `set_marked_for_discard`).
# It's slipped in at a random place in the pile, not on top, so nobody can
# tell when it will come out again. Does nothing if that player isn't
# actually holding it.
func return_tile(player_id: int, tile: Tile) -> void:
	if not _hands.has(player_id):
		return
	var hand: Array = _hands[player_id]
	var index := hand.find(tile)
	if index == -1:
		return
	hand.remove_at(index)
	# `randi_range(a, b)` is a random whole number from a to b, inclusive.
	_undrawn.insert(randi_range(0, _undrawn.size()), tile)


# Removes a tile from a player's hand without returning it to the bag —
# call this once the tile has actually been placed on the board.
func consume(player_id: int, tile: Tile) -> void:
	if _hands.has(player_id):
		_hands[player_id].erase(tile)


# Adds `tile` directly to `player_id`'s hand, bypassing the shuffled
# `_undrawn` queue entirely — used when a tile comes from somewhere other
# than a fresh draw, e.g. picking a blank tile back up off the board (see
# game_session.gd's `remove_tile`). Unlike `draw`, this doesn't touch
# what's left in the bag at all.
func give_to_hand(player_id: int, tile: Tile) -> void:
	if not _hands.has(player_id):
		_hands[player_id] = [] as Array[Tile]
	_hands[player_id].append(tile)


# The tiles a player currently holds, unplaced — the live array, so a
# player who has never drawn gets their (empty, typed) hand created here,
# rather than a throwaway untyped `[]` that Array[Tile] would reject.
func hand(player_id: int) -> Array[Tile]:
	if not _hands.has(player_id):
		_hands[player_id] = [] as Array[Tile]
	return _hands[player_id]


# How many tiles are left to draw from the bag.
func remaining_count() -> int:
	return _undrawn.size()


# Every tile still waiting to be drawn, next draw first — exposed for
# save_game.gd (gameplay code should go through `draw()` instead).
func undrawn_tiles() -> Array[Tile]:
	return _undrawn


# Overwrites the bag's entire state — the undrawn pile and every player's
# hand — with exactly what's given, bypassing the constructor's shuffle.
# Used only by save_game.gd when loading a save file; never for gameplay.
func restore_state(undrawn: Array[Tile], hands: Dictionary) -> void:
	_undrawn = undrawn
	_hands = hands
