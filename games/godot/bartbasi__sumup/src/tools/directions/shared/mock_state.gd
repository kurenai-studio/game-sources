extends RefCounted
## The fixed game moments that all three Phase 1 directions render, so Bart
## compares like for like. Every screen scene reads its numbers, board and
## text from here. The numbers follow docs/GDD.md (draft for Hard Stop 1):
## labels D-31, number formats D-32, costs D-20, Undo D-27 and D-28, the no
## moves offer D-19. The UI text is placeholder copy.
##
## Two moments:
## - Board and targeting screens: highest tile 2048 has just appeared, score
##   41,286, which is what the GDD score model (section 17) gives when 2048
##   first appears. The player has just used Undo, so there is no Undo
##   snapshot and Undo is disabled until the next chain commits (13.7, U3).
##   That is the disabled booster on these screens.
## - Game over screen: the no moves offer (D-19) at highest tile 4096, score
##   76,410 (the model gives about 75,000), last chain worth 96 points. Every
##   booster is usable, Shuffle is the suggested rescue.
##
## Board cells are Vector2i(column, row). Column 0 is the left edge, row 0 is
## the top row. Board arrays hold ROWS rows of COLUMNS values, top row first.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

## Default capture size. Composed screens fill whatever viewport they get.
const CANVAS_SIZE: Vector2i = Vector2i(1080, 2400)
## Default simulated safe area: status bar with a punch hole camera at the
## top, gesture bar at the bottom. Keep text and touch targets out of these
## bands. The capture tool can change it for other phones, see safe_top.
const SAFE_TOP: int = 120
const SAFE_BOTTOM: int = 66

const COLUMNS: int = 5
const ROWS: int = 8

# Board and targeting screens

const SCORE: int = 41286
## Best Score updates live (D-16), so it is at least every score shown.
const BEST_SCORE: int = 96520
## Best tile ever (D-17), shown in tile label format.
const BEST_TILE: int = 8192
## Highest tile on the board screen's board.
const HIGHEST_TILE: int = 2048
## The player has just used Undo, so there is no snapshot (GDD 13.7).
const HAS_UNDO_SNAPSHOT: bool = false

## The chain being dragged on the board screen: 8, 8, 16, 32, 64, 128.
## Its sum is 256, a power of two, so the preview is 256 (D-02, round down).
const CHAIN_PREVIEW: int = 256

# Boosters, in bar order

const BOOSTER_IDS: PackedStringArray = ["hammer", "swap", "shuffle", "double", "undo"]
const BOOSTER_NAMES: PackedStringArray = ["Hammer", "Swap", "Shuffle", "Double", "Undo"]
## Costs on the board screen (D-20): B = max(2048, 128) = 2048. Hammer, Swap
## and Shuffle cost B, Double 2B, Undo B/2. Shown in tile label format (D-32).
const BOOSTER_COSTS: PackedInt32Array = [2048, 2048, 2048, 4096, 1024]
## The word between a booster name and its cost on a buy button: "Shuffle for 4K".
const BUY_FOR: String = "for"

# Targeting screen

## The booster in targeting mode, and the tile under the finger.
const TARGETING_BOOSTER: String = "hammer"
const TARGET_CELL: Vector2i = Vector2i(2, 5)
const TARGET_HINT: String = "Tap a tile to smash it"
const TARGET_CANCEL_HINT: String = "Tap Hammer again to cancel"

# Game over screen: the no moves offer (D-19)

## The run's score while the offer is open.
const FINAL_SCORE: int = 76410
const GAMEOVER_HIGHEST_TILE: int = 4096
## Costs at the game over board (D-20): B = 4096.
const GAMEOVER_COSTS: PackedInt32Array = [4096, 4096, 4096, 8192, 2048]
## The last chain's points, for Undo's check (D-28).
const GAMEOVER_LAST_CHAIN_POINTS: int = 96
const GAMEOVER_HAS_UNDO_SNAPSHOT: bool = true
const RUN_BEST_TILE: int = 4096
const IS_NEW_BEST: bool = false
## The suggested rescue (D-19).
const RESCUE_BOOSTER: String = "shuffle"
const GAMEOVER_TITLE: String = "Out of moves"
const GAMEOVER_BODY: String = "Pick a booster to keep this run going."
const GAMEOVER_END: String = "End run"

# Settings screen

const SETTINGS_TITLE: String = "Settings"
const SOUND_LABEL: String = "Sound"
const SOUND_ON: bool = true
const SKIN_LABEL: String = "Skin"
## Built in skins shown in the picker. Each direction shows its own name as
## selected. Whether the unpicked directions become skins is Bart's call at
## Hard Stop 1; the picker here only shows what one would look like.
const SKIN_NAMES: PackedStringArray = ["Gumdrop", "Slate", "Nova"]
const SKIN_IDS: PackedStringArray = ["gumdrop", "slate", "nova"]
## Tile values shown as a preview inside each skin choice.
const SKIN_PREVIEW_VALUES: PackedInt32Array = [2, 4, 8]
const VERSION_TEXT: String = "SumUp 0.1"

# HUD text

const SCORE_LABEL: String = "Score"
const BEST_LABEL: String = "Best"
const BEST_TILE_LABEL: String = "Best tile"
const CHAIN_LABEL: String = "Chain"

## Safe area used by the composed screens. The capture tool sets these with
## use_safe_area() to simulate other phones.
static var safe_top: int = SAFE_TOP
static var safe_bottom: int = SAFE_BOTTOM


## Sets the safe area for the composed screens.
static func use_safe_area(top: int, bottom: int) -> void:
	safe_top = top
	safe_bottom = bottom


## Mid game board for the board and targeting screens. Highest tile 2048,
## which has just appeared, so the 2s from the old spawn window are still
## around (D-13).
static func board_values() -> Array[PackedInt32Array]:
	return [
		PackedInt32Array([2, 16, 4, 2, 8]),
		PackedInt32Array([4, 1024, 64, 8, 2]),
		PackedInt32Array([16, 128, 2, 32, 4]),
		PackedInt32Array([2, 4, 512, 16, 64]),
		PackedInt32Array([32, 8, 8, 2, 16]),
		PackedInt32Array([4, 2048, 16, 4, 2]),
		PackedInt32Array([8, 2, 32, 256, 8]),
		PackedInt32Array([64, 4, 2, 8, 4]),
	]


## The chain on the board screen, in drag order. The finger is on the last cell.
static func chain_cells() -> Array[Vector2i]:
	return [
		Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 3),
		Vector2i(3, 2), Vector2i(2, 1), Vector2i(1, 2),
	]


## Where the finger is, in board cell units (Vector2(0, 0) is the top left
## corner of the board, Vector2(5, 8) the bottom right). It sits just past the
## center of the last chain cell, heading down and left.
static func drag_point() -> Vector2:
	return Vector2(1.36, 2.72)


## Board at game over: no two touching tiles (eight directions) are equal,
## so no chain can start (D-15). Highest tile 4096.
static func gameover_values() -> Array[PackedInt32Array]:
	return [
		PackedInt32Array([4, 32, 2, 16, 8]),
		PackedInt32Array([16, 8, 64, 4, 2]),
		PackedInt32Array([2, 128, 2, 512, 32]),
		PackedInt32Array([64, 16, 32, 8, 4]),
		PackedInt32Array([8, 4096, 2, 128, 16]),
		PackedInt32Array([2, 64, 16, 4, 256]),
		PackedInt32Array([32, 4, 1024, 64, 8]),
		PackedInt32Array([8, 16, 2, 32, 2]),
	]


## Cost basis B (D-20): the larger of the highest tile and 128.
static func cost_basis(highest: int) -> int:
	return maxi(highest, 128)


## Cost of a booster at a given highest tile (D-20).
static func cost_for(booster_id: String, highest: int) -> int:
	var basis: int = cost_basis(highest)
	match booster_id:
		"hammer", "swap", "shuffle":
			return basis
		"double":
			return basis * 2
		"undo":
			@warning_ignore("integer_division")
			return basis / 2
	push_error("unknown booster '%s'" % booster_id)
	return 0


## Whether a booster is usable (GDD 13.1 and 13.7): the score covers its cost,
## and for Undo a snapshot exists and the score minus the last chain's points
## covers the cost (D-28).
static func is_usable(booster_id: String, score: int, highest: int, has_snapshot: bool, last_chain_points: int) -> bool:
	var cost: int = cost_for(booster_id, highest)
	if booster_id == "undo":
		return has_snapshot and score - last_chain_points >= cost
	return score >= cost


## Usable flags in bar order for the board and targeting screens.
static func board_usable() -> Array[bool]:
	var flags: Array[bool] = []
	for booster_id: String in BOOSTER_IDS:
		flags.append(is_usable(booster_id, SCORE, HIGHEST_TILE, HAS_UNDO_SNAPSHOT, 0))
	return flags


## Usable flags in bar order for the game over offer.
static func gameover_usable() -> Array[bool]:
	var flags: Array[bool] = []
	for booster_id: String in BOOSTER_IDS:
		flags.append(is_usable(booster_id, FINAL_SCORE, GAMEOVER_HIGHEST_TILE, GAMEOVER_HAS_UNDO_SNAPSHOT, GAMEOVER_LAST_CHAIN_POINTS))
	return flags


## Cost of a booster on the board screen.
static func booster_cost(booster_id: String) -> int:
	return cost_for(booster_id, HIGHEST_TILE)


## Display name of a booster by id.
static func booster_name(booster_id: String) -> String:
	var index: int = BOOSTER_IDS.find(booster_id)
	if index < 0:
		push_error("unknown booster '%s'" % booster_id)
		return ""
	return BOOSTER_NAMES[index]


## Whether the booster is usable on the board and targeting screens. Kept
## under this name for the artists' review scenes; same as board_usable().
static func is_affordable(booster_id: String) -> bool:
	return is_usable(booster_id, SCORE, HIGHEST_TILE, HAS_UNDO_SNAPSHOT, 0)


## Buy button text, for example "Shuffle for 4K" (D-32: costs use the tile label format).
static func buy_text(booster_id: String, cost: int) -> String:
	return "%s %s %s" % [booster_name(booster_id), BUY_FOR, tile_label(cost)]


## Tile label (D-31). Up to 1024 the full number. From 2048 up, a number from
## 1 to 512 followed by K, M, B or T in steps of 1024: 2048 is 2K, 65536 is
## 64K, 131072 is 128K, 1048576 is 1M, 2^30 is 1B, 2^40 is 1T. Never more
## than 4 characters up to 2^49.
static func tile_label(value: int) -> String:
	if value <= 0:
		return ""
	var k: int = 0
	var v: int = value
	while v > 1:
		v = v >> 1
		k += 1
	if k <= 10:
		return str(value)
	@warning_ignore("integer_division")
	var unit: int = mini(k / 10, 4)
	var suffixes: PackedStringArray = ["K", "M", "B", "T"]
	return "%d%s" % [1 << (k - 10 * unit), suffixes[unit - 1]]


## Cost text (D-32): costs are powers of two and use the tile label format.
static func cost_label(cost: int) -> String:
	return tile_label(cost)


## Score text with thousands separators, for example 41,286 (D-32).
static func format_number(value: int) -> String:
	var digits: String = str(absi(value))
	var out: String = ""
	var count: int = 0
	for i: int in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" + out) if value < 0 else out
