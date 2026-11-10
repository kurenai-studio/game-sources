# A small standalone check for tile.gd/tile_pool.gd/tile_bag.gd, runnable
# without the editor via:
#   godot4 --headless --path . --script tests/test_tiles.gd
#
# `extends SceneTree` makes this the whole running program instead of a
# game scene — Godot's `--script` flag runs one file as the entire
# application, calling `_initialize()` once at startup. This project has no
# test framework/addon installed (would be extra scaffolding for 3 small
# files); this is just plain GDScript doing checks and printing PASS/FAIL,
# closer to a shell script with assertions than a unit-test framework.
extends SceneTree

# Counts failures so the final exit code can tell a CI/terminal whether
# everything passed, without needing a test framework to interpret it.
var _failures := 0


# Prints FAIL and records it if `condition` is false; otherwise prints PASS.
# `message` should describe what was being checked.
func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_test_tile_pool()
	_test_tile_flip()
	_test_tile_bag()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	# `quit(code)` stops the SceneTree and sets the process exit code —
	# without this the headless run would hang forever waiting for a next
	# frame that never comes, since there's no window/game loop driving it.
	quit(1 if _failures > 0 else 0)


func _test_tile_pool() -> void:
	var pool := TilePool.new()
	_check(pool.tiles.size() == 117, "TilePool has 117 tiles")

	# Every tile's yellow face is a real letter, never blank.
	var any_blank_yellow := false
	for tile in pool.tiles:
		if tile.front_letter() == "":
			any_blank_yellow = true
	_check(not any_blank_yellow, "no tile has a blank yellow face")

	# Exactly 2 tiles are yellow on both faces (K/U and W/S — see
	# doc/RULES.md), so exactly 2 have back_is_green == false.
	var all_yellow_count := 0
	for tile in pool.tiles:
		if not tile.back_is_green():
			all_yellow_count += 1
	_check(all_yellow_count == 2, "exactly 2 tiles are yellow on both faces")

	# Exactly 12 tiles have a blank ("-") back face — the shorten mechanic.
	var blank_back_count := 0
	for tile in pool.tiles:
		if tile.back_letter() == "":
			blank_back_count += 1
	_check(blank_back_count == 12, "exactly 12 tiles have a blank back face")

	# Yellow letters: 119 total (117 fronts + the 2 all-yellow tiles' backs).
	var yellow_letter_count := 0
	for tile in pool.tiles:
		yellow_letter_count += 1
		if not tile.back_is_green():
			yellow_letter_count += 1
	_check(yellow_letter_count == 119, "119 total yellow letters")

	# Green letters: 103 real letters (117 backs, minus the 2 all-yellow
	# tiles, minus the 12 blanks).
	var green_letter_count := 0
	for tile in pool.tiles:
		if tile.back_is_green() and tile.back_letter() != "":
			green_letter_count += 1
	_check(green_letter_count == 103, "103 real green letters")


func _test_tile_flip() -> void:
	var normal := Tile.new("A", "E", true)
	_check(normal.current_letter() == "A", "fresh tile shows its yellow letter")
	_check(not normal.current_is_green(), "yellow face never counts as green")
	normal.flip()
	_check(normal.current_letter() == "E", "flipped tile shows its back letter")
	_check(normal.current_is_green(), "flipped normal tile counts as green")
	normal.flip()
	_check(normal.current_letter() == "A", "flipping twice returns to yellow")

	var all_yellow := Tile.new("K", "U", false)
	all_yellow.flip()
	_check(not all_yellow.current_is_green(), "K/U-style tile is never green, even flipped")

	var shorten := Tile.new("E", "", true)
	shorten.flip()
	_check(shorten.is_blank(), "flipped shorten tile reads as blank")

	var restorable := Tile.new("A", "E", true)
	_check(restorable.is_showing_front(), "a fresh tile reports showing its front")
	restorable.set_showing_front(false)
	_check(restorable.current_letter() == "E", "set_showing_front restores the back face directly")
	_check(not restorable.is_showing_front(), "...and is_showing_front reflects it")


func _test_tile_bag() -> void:
	var pool := TilePool.new()
	var bag := TileBag.new(pool)
	_check(bag.remaining_count() == 117, "bag starts with all 117 tiles")

	var drawn := bag.draw(0, 9)
	_check(drawn.size() == 9, "drawing 9 tiles returns 9 tiles")
	_check(bag.remaining_count() == 108, "bag has 108 left after drawing 9")
	_check(bag.hand(0).size() == 9, "player 0's hand has 9 tiles")

	var first_tile: Tile = drawn[0]
	bag.return_tile(0, first_tile)
	_check(bag.hand(0).size() == 8, "returning a tile shrinks the hand")
	_check(bag.remaining_count() == 109, "returning a tile grows the bag")

	bag.consume(0, drawn[1])
	_check(bag.hand(0).size() == 7, "consuming a tile shrinks the hand")
	_check(bag.remaining_count() == 109, "consuming a tile does NOT return it to the bag")

	var too_many := bag.draw(1, 9999)
	_check(too_many.size() == 109, "drawing more than remaining returns only what's left")
	_check(bag.remaining_count() == 0, "bag is empty after draining it")

	var picked_up_tile := Tile.new("Q", "", true)
	bag.give_to_hand(0, picked_up_tile)
	_check(bag.hand(0).has(picked_up_tile), "give_to_hand adds the tile straight to that hand")
	_check(bag.remaining_count() == 0, "...without touching what's left in the bag")
