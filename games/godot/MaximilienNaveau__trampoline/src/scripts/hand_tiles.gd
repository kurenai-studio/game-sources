# What a player can do to their own hand's tiles, beside playing them:
# arrange them, sort them, turn them all to one color. Pure logic on a
# hand — the live `Array[Tile]` from TileBag.hand — changing nothing
# else, so it holds no state: every function is `static`, called on the
# class itself (`HandTiles.sort(hand)`), like a C++ namespace of free
# functions.
class_name HandTiles
extends RefCounted


# Moves `tile` to just before `before` (another tile of `hand`), or to the
# end if `before` is null — the player arranging their hand by hand.
# Returns false and does nothing if `tile` isn't in `hand`.
static func move(hand: Array[Tile], tile: Tile, before: Tile) -> bool:
	if not hand.has(tile) or tile == before:
		return false
	hand.erase(tile)
	var index := hand.find(before) if before != null else -1
	if index == -1:
		hand.append(tile)
	else:
		hand.insert(index, tile)
	return true


# Sorts `hand` A to Z by the letter each tile shows, blank faces last.
static func sort(hand: Array[Tile]) -> void:
	# `sort_custom` sorts with a comparison function, like C++'s
	# `std::sort(begin, end, less)`; `func(a, b): ...` is an anonymous
	# function, like a Python `lambda`.
	hand.sort_custom(func(a: Tile, b: Tile) -> bool: return sort_key(a) < sort_key(b))


# Turns every tile of `hand` to its green face (`green` true) — those
# that have one; the others stay as they are — or to its yellow front
# face (`green` false).
static func show_faces(hand: Array[Tile], green: bool) -> void:
	for tile in hand:
		if not green:
			tile.set_showing_front(true)
		elif tile.back_is_green():
			tile.set_showing_front(false)


# What `sort` orders a tile by: the letter it shows — "~" for a blank,
# which comes after "Z" in character order, putting blanks last. Also
# used by how_to_play_view.gd to sort its pictures the same way.
static func sort_key(tile: Tile) -> String:
	return "~" if tile.is_blank() else tile.current_letter()
