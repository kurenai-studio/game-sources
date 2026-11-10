# The "Comment jouer" screen: a full-screen overlay showing the rules as
# short looping animations, one card at a time (the cards themselves are
# data, see how_to_play_cards.gd). Each card plays on a mini board — the
# same painted wood, holes and tiles as the game (see tile_view.gd) —
# with a ghost finger doing the moves, under a one-line caption.
#
# Purely visual: it plays with its own throwaway tiles, never a real game
# session. main.gd only calls `open()`; the screen closes itself.
class_name HowToPlayView
# On the same felt as the game (see play_mat.gd).
extends PlayMat

# The painted wood of the box and board (see board_view.tscn): its plain
# painted middle.
const _PAINT := preload("res://assets/textures/box_lid.jpg")
const _PAINT_REGION := Rect2(40, 40, 460, 880)
const _TRAY_COLOR := Color(0.122, 0.165, 0.133)
const _HINT_COLOR := Color(0.953, 0.937, 0.847, 0.45)
const _INK := Color("363a42")
const _FINGER_COLOR := Color(1, 1, 1, 0.6)
# Floating scores: orange for points (`ribbon`), red for a penalty
# (`error`, see doc/ART_DIRECTION.md's palette).
const _GAIN_COLOR := Color("e4733a")
const _LOSS_COLOR := Color("c8463c")

# Board cells are at most this big, and the frame around them this wide.
const _MAX_CELL := 44.0
const _FRAME := 8.0
# Gap between the board and the hand below it, and between hand tiles.
const _HAND_GAP := 24.0
const _TILE_GAP := 4.0
# Tiles in the tray are a little smaller, as in the game (discard_tray.gd).
const _TRAY_SCALE := 0.72
# Height kept free at the top of the stage for the "Fin du tour" or
# "Recommencer" button, on a card that uses it.
const _BUTTON_ROOM := 44.0
# The buttons under the hand, on a card that uses them (see main.tscn's
# HandTools).
const _HAND_BUTTONS := ["Trier", "Tout jaune", "Tout vert"]
const _FINGER_RADIUS := 13.0

# Which card is showing.
var _card_index := 0
# Bumped every time a card (re)starts or the screen closes: a card's
# animation checks it after every pause and quietly stops if it changed
# — how a running animation is cancelled (see `_pause`).
var _run := 0
# Every tween started for the current card, so they can all be stopped.
var _tweens: Array[Tween] = []

# The current card's layout, in Stage coordinates (see `_layout`).
var _cell := 0.0
var _board_rect := Rect2()
var _hand_side := 0.0
var _hand_origin := Vector2.ZERO
var _tray_rect := Rect2()

# The current card's tiles: board tiles by "row,col", hand tiles by slot
# (null once dragged away), tray tiles in order.
var _board_tiles := {}
var _hand_tiles: Array = []
var _tray_tiles: Array = []
# The buttons under the hand, by label (see `_HAND_BUTTONS`).
var _hand_buttons := {}
# The real tiles the current card's tiles are drawn from (see `_make_tile`).
var _unused: Array[Tile] = []

# Everything that belongs to the current card — its tiles, floating
# scores, hand buttons — sits on this layer of the stage, so starting a
# card simply clears it. The ghost finger (a translucent fingertip drawn
# as a circle) and the button at the top some cards tap ("Fin du tour" or
# "Recommencer") stay on the stage for good, above it.
var _card_layer := Control.new()
var _finger := Control.new()
var _top_button := Button.new()

@onready var _caption: Label = $Layout/Caption
# The animation area: drawn on through its `draw` signal (board, holes,
# tray), with the tiles, scores and finger as child nodes on top.
@onready var _stage: Control = $Layout/Stage
@onready var _dots: Label = $Layout/Dots
@onready var _back_button: Button = $Layout/Nav/BackButton
@onready var _next_button: Button = $Layout/Nav/NextButton
@onready var _close_button: Button = $Layout/Top/CloseButton


func _ready() -> void:
	# The felt's own setup first (see play_mat.gd), like Python's
	# `super().__init__()`.
	super()
	_stage.draw.connect(_draw_stage)
	# Anything sliding in from outside the stage is cut off at its edges.
	_stage.clip_contents = true
	_card_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_card_layer)
	_finger.draw.connect(_draw_finger)
	_finger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finger.size = Vector2.ONE * 2 * _FINGER_RADIUS
	_finger.pivot_offset = _finger.size / 2
	_top_button.theme_type_variation = &"PrimaryButton"
	_top_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_button.focus_mode = Control.FOCUS_NONE
	_stage.add_child(_top_button)
	_stage.add_child(_finger)
	_back_button.pressed.connect(_show_card.bind(-1))
	_next_button.pressed.connect(_on_next_pressed)
	_close_button.pressed.connect(close)


# Shows the screen from the first card.
func open() -> void:
	show()
	_card_index = 0
	_start_card()


# Hides the screen and stops the animation.
func close() -> void:
	_run += 1
	_stop_tweens()
	hide()


func _on_next_pressed() -> void:
	if _card_index == HowToPlayCards.CARDS.size() - 1:
		close()
	else:
		_show_card(1)


# Moves `step` cards forward (1) or back (-1).
func _show_card(step: int) -> void:
	_card_index = clampi(_card_index + step, 0, HowToPlayCards.CARDS.size() - 1)
	_start_card()


# Updates the caption, dots and buttons for the current card, then plays
# its animation in a loop until another card starts.
func _start_card() -> void:
	var card: Dictionary = HowToPlayCards.CARDS[_card_index]
	_caption.text = card["caption"]
	var dots := ""
	for i in range(HowToPlayCards.CARDS.size()):
		dots += "●" if i == _card_index else "○"
	_dots.text = dots
	_back_button.visible = _card_index > 0
	var last := _card_index == HowToPlayCards.CARDS.size() - 1
	_next_button.text = "C'est parti !" if last else "Suivant"
	_run += 1
	_play(card, _run)


# Plays `card` over and over, until the run number changes (another card,
# or the screen closed). A function containing `await` is a coroutine in
# GDScript, like Python's async def: calling it starts it, and it pauses
# at each `await` while the game keeps running.
func _play(card: Dictionary, run: int) -> void:
	# Wait one frame so the stage has been laid out and has its real size.
	await get_tree().process_frame
	while run == _run:
		_reset(card)
		for step: Dictionary in card["steps"]:
			if not await _do(step, card, run):
				return
		if not await _pause(0.4, run):
			return


# Clears the stage and sets the card's starting position: its board
# empty, its hand full, the finger resting off the bottom edge.
func _reset(card: Dictionary) -> void:
	_stop_tweens()
	for node in _card_layer.get_children():
		node.queue_free()
	_board_tiles.clear()
	_hand_tiles.clear()
	_tray_tiles.clear()
	_hand_buttons.clear()
	_card_layer.modulate.a = 1.0
	_unused = TilePool.new().tiles
	_top_button.text = _top_label(card)
	_layout(card)
	for i in range(card["hand"].length()):
		var node := _new_tile_node(_make_tile(card["hand"][i]), _hand_side)
		node.position = _hand_slot(i)
		_hand_tiles.append(node)
	if card.get("hand_buttons", false):
		_add_hand_buttons()
	_top_button.visible = _top_label(card) != ""
	_top_button.scale = Vector2.ONE
	_finger.position = Vector2(_stage.size.x * 0.75, _stage.size.y + 20)
	_finger.scale = Vector2.ONE
	_stage.queue_redraw()


# Works out where the card's board, hand and tray go on the stage: the
# board as big as fits (cells at most `_MAX_CELL`), centered, with the
# hand below it.
func _layout(card: Dictionary) -> void:
	var rows: int = card["rows"]
	var has_hand: bool = card["hand"] != ""
	var top := _BUTTON_ROOM if _top_label(card) != "" else 0.0
	var width := _stage.size.x - 2 * _FRAME
	var height := _stage.size.y - 2 * _FRAME - top
	# With a hand, it takes one more row of cells plus the gap above it —
	# and one more for the buttons under it, if any.
	var below := (1 if has_hand else 0) + (1 if card.get("hand_buttons", false) else 0)
	var height_rows := rows + below
	var spare := _HAND_GAP if has_hand else 0.0
	_cell = floorf(minf(minf(width / Board.COLUMNS, (height - spare) / height_rows), _MAX_CELL))
	var board_size := Vector2(Board.COLUMNS, rows) * _cell
	var content_height := board_size.y + (spare + _cell * below if has_hand else 0.0)
	var origin_y := top + _FRAME + (height - content_height) / 2
	_board_rect = Rect2(Vector2((_stage.size.x - board_size.x) / 2, origin_y), board_size)

	# The hand: one row of tiles under the board, shrunk if the tray needs
	# room beside it; "slots" leaves room for tiles swapped into it.
	var count: int = card.get("slots", card["hand"].length())
	var tray_width := 0.0
	if card.get("tray", false):
		tray_width = 2 * _cell * _TRAY_SCALE + 3 * _TILE_GAP
	var available := board_size.x - tray_width - (_TILE_GAP if tray_width > 0 else 0.0)
	_hand_side = minf(_cell - _TILE_GAP, available / maxi(count, 1) - _TILE_GAP)
	_hand_origin = Vector2(_board_rect.position.x, _board_rect.end.y + _FRAME + spare)
	_tray_rect = Rect2(
		Vector2(_board_rect.end.x - tray_width, _hand_origin.y), Vector2(tray_width, _hand_side)
	)
	_top_button.reset_size()
	_top_button.position = Vector2(
		_board_rect.end.x - _top_button.size.x, (top - _top_button.size.y) / 2
	)


# Where hand slot `i`'s tile sits.
func _hand_slot(i: int) -> Vector2:
	return _hand_origin + Vector2(i * (_hand_side + _TILE_GAP), 0)


# Where `node`'s `position` goes for it to sit in hand slot `i`, scaled to
# the hand's tile size — a tile scales around its centre (see
# `_new_tile_node`), so its centre is what lines up.
func _slot_position(node: Control, i: int) -> Vector2:
	return _hand_slot(i) + Vector2.ONE * _hand_side / 2 - node.size / 2


# The label of the button at the top of `card`'s stage: "Recommencer" if
# it resets, "Fin du tour" if it ends a turn, "" for none.
func _top_label(card: Dictionary) -> String:
	if card["steps"].any(func(s): return s.has("reset")):
		return "Recommencer"
	if card["steps"].any(func(s): return s.has("end_turn")):
		return "Fin du tour"
	return ""


# The centre of board cell [row, col].
func _cell_center(at: Array) -> Vector2:
	return _cell_tile_rect(at[0], at[1]).get_center()


# Adds the buttons under the hand (see `_HAND_BUTTONS`). They're only
# pictures here: the finger "taps" them (see `_tap_hand_button`).
func _add_hand_buttons() -> void:
	var x := _hand_origin.x
	for label: String in _HAND_BUTTONS:
		var button := Button.new()
		button.text = label
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", int(_cell * 0.32))
		_card_layer.add_child(button)
		button.reset_size()
		button.position = Vector2(x, _hand_origin.y + _hand_side + 2 * _TILE_GAP)
		button.pivot_offset = button.size / 2
		x += button.size.x + 2 * _TILE_GAP
		_hand_buttons[label] = button


# The rectangle a tile fills in board cell (row, col): its hole, minus a
# small gap all round.
func _cell_tile_rect(row: int, col: int) -> Rect2:
	var cell := Rect2(_board_rect.position + Vector2(col, row) * _cell, Vector2.ONE * _cell)
	return cell.grow(-3)


# The board and tray, drawn under the tiles (see `_ready`).
func _draw_stage() -> void:
	if _cell <= 0:
		return
	# The painted wood, frame included, then a hole for every cell.
	_stage.draw_texture_rect_region(_PAINT, _board_rect.grow(_FRAME), _PAINT_REGION)
	for row in range(roundi(_board_rect.size.y / _cell)):
		for col in range(Board.COLUMNS):
			var cell := Rect2(_board_rect.position + Vector2(col, row) * _cell, Vector2.ONE * _cell)
			TileView.draw_hole(_stage, cell.grow(-2))
	if _tray_rect.size.x > 0:
		_stage.draw_rect(_tray_rect.grow(_TILE_GAP), _TRAY_COLOR)
		if _tray_tiles.is_empty():
			var font := get_theme_font("font", "Label")
			var baseline := _tray_rect.get_center() + Vector2(-_tray_rect.size.x / 2, 5)
			_stage.draw_string(
				font,
				baseline,
				"À rendre",
				HORIZONTAL_ALIGNMENT_CENTER,
				_tray_rect.size.x,
				13,
				_HINT_COLOR
			)


# The fingertip: a translucent disc with an ink outline.
func _draw_finger() -> void:
	var center := _finger.size / 2
	_finger.draw_circle(center, _FINGER_RADIUS, _FINGER_COLOR)
	_finger.draw_arc(center, _FINGER_RADIUS, 0, TAU, 32, _INK, 2, true)


# Runs one step (see how_to_play_cards.gd for the list). Returns false if
# the card was stopped meanwhile, so `_play` stops too.
func _do(step: Dictionary, card: Dictionary, run: int) -> bool:
	var still_playing := true
	if step.has("wait"):
		still_playing = await _pause(step["wait"], run)
	elif step.has("word"):
		still_playing = await _place_word(step, run)
	elif step.has("drag"):
		still_playing = await _drag_to_board(step["drag"], step["to"], run)
	elif step.has("tap"):
		still_playing = await _tap(step["tap"], run)
	elif step.has("float"):
		_float_text(step["float"], step["at"])
		still_playing = await _pause(0.5, run)
	elif step.has("discard"):
		still_playing = await _drag_to_tray(step["discard"], run)
	elif step.has("end_turn"):
		still_playing = await _end_turn(card, run)
	elif step.has("box"):
		still_playing = await _box_move(step, run)
	elif step.has("arrange"):
		still_playing = await _arrange(step["arrange"], step["before"], run)
	elif step.has("button"):
		still_playing = await _tap_hand_button(step["button"], run)
	elif step.has("reset"):
		still_playing = await _reset_turn(card, run)
	return still_playing


# The finger drags hand tile `index` into the board cell `to` = [row, col].
# On a tile, the two swap: that one slides into the hand's first free
# slot (see GameSession.place_tile).
func _drag_to_board(index: int, to: Array, run: int) -> bool:
	var rect := _cell_tile_rect(to[0], to[1])
	var key := "%d,%d" % [to[0], to[1]]
	var displaced: Control = _board_tiles.get(key)
	var node: Control = await _carry(index, rect.position, rect.size.x, run)
	if node == null:
		return false
	_board_tiles[key] = node
	if displaced != null:
		var slot := _hand_tiles.find(null)
		if slot == -1:
			slot = _hand_tiles.size()
			_hand_tiles.append(null)
		_hand_tiles[slot] = displaced
		var tween := _tween().set_parallel()
		tween.tween_property(displaced, "position", _slot_position(displaced, slot), 0.4).set_trans(
			Tween.TRANS_SINE
		)
		tween.tween_property(displaced, "scale", Vector2.ONE * _hand_side / displaced.size.x, 0.4)
		return await _pause(0.45, run)
	return true


# The finger drags hand tile `index` into the tray, beside any already
# there, shrinking it to the tray's tile size.
func _drag_to_tray(index: int, run: int) -> bool:
	var side := _cell * _TRAY_SCALE
	var slot := _tray_tiles.size()
	# Side by side in the tray's one row, centred on the hand's height.
	var at := _tray_rect.position + Vector2(slot * (side + _TILE_GAP), (_hand_side - side) / 2)
	var node: Control = await _carry(index, at, side, run)
	if node == null:
		return false
	_tray_tiles.append(node)
	_stage.queue_redraw()
	return true


# Waits `seconds`; returns whether the card is still the one playing.
func _pause(seconds: float, run: int) -> bool:
	await get_tree().create_timer(seconds).timeout
	return run == _run


# A tween for the current card, remembered so `_stop_tweens` can stop it.
func _tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _stop_tweens() -> void:
	for tween in _tweens:
		tween.kill()
	_tweens.clear()


# A real tile for `letter` (lowercase = showing its green face), taken
# from the game's 117 so its corner shows its real other face. `back`,
# if given, overrides that other face.
func _make_tile(letter: String, back: String = "") -> Tile:
	var green := letter != letter.to_upper()
	var upper := letter.to_upper()
	if back != "":
		return Tile.new(upper, back, true)
	for tile in _unused:
		var matches := (
			tile.back_letter() == upper and tile.back_is_green()
			if green
			else tile.front_letter() == upper
		)
		if matches:
			_unused.erase(tile)
			if green:
				tile.flip()
			return tile
	return Tile.new(upper, "", false)


# A tile's picture, `side` px square, added to the card's layer. The
# tile itself is kept on the node as metadata (`set_meta`: a named value
# any node can carry), for `_tap` to flip.
func _new_tile_node(tile: Tile, side: float) -> Control:
	var node := TileView.build_tile_visual(tile, Vector2.ONE * side)
	node.set_meta("tile", tile)
	node.pivot_offset = node.size / 2
	_card_layer.add_child(node)
	return node


# A word's tiles popping onto the board one after another.
func _place_word(step: Dictionary, run: int) -> bool:
	var word: String = step["word"]
	var backs: Dictionary = step.get("backs", {})
	for i in range(word.length()):
		var rect := _cell_tile_rect(step["row"], step["col"] + i)
		var node := _new_tile_node(_make_tile(word[i], backs.get(i, "")), rect.size.x)
		node.position = rect.position
		node.scale = Vector2.ONE * 0.5
		# TRANS_BACK + EASE_OUT overshoots a little before settling — the
		# tile's small bounce as it lands.
		(
			_tween()
			. tween_property(node, "scale", Vector2.ONE, 0.2)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
		_board_tiles["%d,%d" % [step["row"], step["col"] + i]] = node
		if not await _pause(0.06, run):
			return false
	return await _pause(0.2, run)


# Moves the finger onto `point` (a tile's center), presses it down.
func _press_at(point: Vector2, run: int) -> bool:
	var target := point - _finger.size / 2
	_tween().tween_property(_finger, "position", target, 0.35).set_trans(Tween.TRANS_SINE)
	if not await _pause(0.4, run):
		return false
	_tween().tween_property(_finger, "scale", Vector2.ONE * 0.8, 0.08)
	return await _pause(0.1, run)


func _release() -> void:
	_tween().tween_property(_finger, "scale", Vector2.ONE, 0.08)


# The finger picks hand tile `index` up and carries it to `to`, resizing
# it to `side` on the way. Returns the moved tile, or null if stopped.
func _carry(index: int, to: Vector2, side: float, run: int) -> Control:
	var node: Control = _hand_tiles[index]
	if not await _press_at(node.position + node.size / 2, run):
		return null
	_hand_tiles[index] = null
	# Raised above the other tiles while carried, then dropped back.
	node.z_index = 1
	var size_scale := Vector2.ONE * side / node.size.x
	# The tile scales around its center, so its top-left corner lands at
	# `to` once its centre is where a `side`-wide tile's centre would be.
	var center_to := to + Vector2.ONE * side / 2
	var tween := _tween().set_parallel()
	tween.tween_property(node, "position", center_to - node.size / 2, 0.45).set_trans(
		Tween.TRANS_SINE
	)
	tween.tween_property(node, "scale", size_scale, 0.45)
	tween.tween_property(_finger, "position", center_to - _finger.size / 2, 0.45).set_trans(
		Tween.TRANS_SINE
	)
	if not await _pause(0.5, run):
		return null
	node.z_index = 0
	_release()
	return node


# The finger taps the board tile at `at`, which flips: it narrows to a
# sliver, turns to its other face, and widens again, like a token turned
# over.
func _tap(at: Array, run: int) -> bool:
	var key := "%d,%d" % [at[0], at[1]]
	var node: Control = _board_tiles[key]
	if not await _press_at(node.position + node.size / 2, run):
		return false
	var flipped: Control = await _flip(node, run)
	if flipped == null:
		return false
	_board_tiles[key] = flipped
	_release()
	return await _pause(0.15, run)


# Turns `node`'s tile over: it narrows to a sliver, turns to its other
# face, and widens again. Returns the new picture (the old one goes), or
# null if the card was stopped meanwhile.
func _flip(node: Control, run: int) -> Control:
	var scale_y := node.scale.y
	_tween().tween_property(node, "scale:x", 0.0, 0.1)
	if not await _pause(0.1, run):
		return null
	var tile: Tile = node.get_meta("tile")
	tile.flip()
	var flipped := _new_tile_node(tile, node.size.x)
	flipped.position = node.position
	flipped.scale = Vector2(0.0, scale_y)
	node.queue_free()
	_tween().tween_property(flipped, "scale:x", scale_y, 0.1)
	return flipped


# A score floating up from board cell `at` and fading out.
func _float_text(text: String, at: Array) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", TileView.LETTER_FONT)
	label.add_theme_font_size_override("font_size", int(_cell * 0.6))
	label.add_theme_color_override(
		"font_color", _LOSS_COLOR if text.begins_with("−") else _GAIN_COLOR
	)
	_card_layer.add_child(label)
	label.reset_size()
	var rect := _cell_tile_rect(at[0], at[1])
	label.position = rect.get_center() - label.size / 2 - Vector2(0, _cell * 0.4)
	var tween := _tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - _cell, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)


# The finger taps "Fin du tour": the tray's tiles go back to the bag
# (shrinking away), and new ones slide up into the hand's gaps.
func _end_turn(card: Dictionary, run: int) -> bool:
	if not await _press_at(_top_button.position + _top_button.size / 2, run):
		return false
	_top_button.pivot_offset = _top_button.size / 2
	_tween().tween_property(_top_button, "scale", Vector2.ONE * 0.92, 0.08)
	_release()
	if not await _pause(0.1, run):
		return false
	_tween().tween_property(_top_button, "scale", Vector2.ONE, 0.08)
	for node: Control in _tray_tiles:
		var tween := _tween().set_parallel()
		tween.tween_property(node, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(
			Tween.EASE_IN
		)
		tween.chain().tween_callback(node.queue_free)
	_tray_tiles.clear()
	if not await _pause(0.35, run):
		return false
	_stage.queue_redraw()
	# The finger moves aside, then the new tiles rise into the gaps.
	_tween().tween_property(_finger, "position:y", _stage.size.y + 20, 0.3)
	var refill: String = card.get("refill", "")
	var next := 0
	for i in range(_hand_tiles.size()):
		if _hand_tiles[i] != null or next >= refill.length():
			continue
		var node := _new_tile_node(_make_tile(refill[next]), _hand_side)
		next += 1
		node.position = _hand_slot(i) + Vector2(0, _hand_side)
		node.modulate.a = 0.0
		var tween := _tween().set_parallel()
		(
			tween
			. tween_property(node, "position", _hand_slot(i), 0.3)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)
		tween.tween_property(node, "modulate:a", 1.0, 0.2)
		_hand_tiles[i] = node
		if not await _pause(0.12, run):
			return false
	return true


# The finger draws the selection box from cell `step["box"][0]` (an empty
# one) to `step["box"][1]`, then drags the tiles inside it by the one at
# `step["grab"]` to `step["to"]`: they all move together (see
# board_view.gd's selection box and block_move.gd).
func _box_move(step: Dictionary, run: int) -> bool:
	var corners: Array = step["box"]
	var start := _cell_center(corners[0])
	if not await _press_at(start, run):
		return false
	# The dotted box: a Control drawing its own dashed outline, growing
	# with the finger. Godot redraws a Control whenever its size changes.
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.draw.connect(func() -> void: _draw_dashed_rect(box))
	box.position = start
	_card_layer.add_child(box)
	var end := _cell_center(corners[1])
	var tween := _tween().set_parallel()
	tween.tween_property(box, "size", end - start, 0.6)
	tween.tween_property(_finger, "position", end - _finger.size / 2, 0.6)
	if not await _pause(0.65, run):
		return false
	_release()
	# On release, the box snaps round the cells it covers.
	var first := Vector2i(mini(corners[0][1], corners[1][1]), mini(corners[0][0], corners[1][0]))
	var last := Vector2i(maxi(corners[0][1], corners[1][1]), maxi(corners[0][0], corners[1][0]))
	var selected: Array[Vector2i] = []
	for key: String in _board_tiles:
		var cell := Vector2i(int(key.get_slice(",", 1)), int(key.get_slice(",", 0)))
		if cell.x >= first.x and cell.x <= last.x and cell.y >= first.y and cell.y <= last.y:
			selected.append(cell)
	var snapped := Rect2(
		_board_rect.position + Vector2(first) * _cell, Vector2(last - first + Vector2i.ONE) * _cell
	)
	tween = _tween().set_parallel()
	tween.tween_property(box, "position", snapped.position, 0.15)
	tween.tween_property(box, "size", snapped.size, 0.15)
	if not await _pause(0.4, run):
		return false

	# Then the finger drags them all by the grabbed one.
	var grab: Array = step["grab"]
	var to: Array = step["to"]
	if not await _press_at(_cell_center(grab), run):
		return false
	var offset := Vector2(to[1] - grab[1], to[0] - grab[0]) * _cell
	var moved := {}
	tween = _tween().set_parallel()
	for cell in selected:
		var node: Control = _board_tiles["%d,%d" % [cell.y, cell.x]]
		_board_tiles.erase("%d,%d" % [cell.y, cell.x])
		tween.tween_property(node, "position", node.position + offset, 0.45)
		moved["%d,%d" % [cell.y + to[0] - grab[0], cell.x + to[1] - grab[1]]] = node
	tween.tween_property(box, "position", snapped.position + offset, 0.45)
	tween.tween_property(_finger, "position", _finger.position + offset, 0.45)
	if not await _pause(0.5, run):
		return false
	_board_tiles.merge(moved)
	_release()
	_tween().tween_property(box, "modulate:a", 0.0, 0.3)
	return await _pause(0.3, run)


# `box`'s outline, dashed, in ink — like the game's selection box (see
# board_view.gd's `_dotted_rect`).
func _draw_dashed_rect(box: Control) -> void:
	var r := Rect2(Vector2.ZERO, box.size).abs()
	var corners := [
		r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)
	]
	for i in range(4):
		box.draw_dashed_line(corners[i], corners[(i + 1) % 4], _INK, 2.0, 6.0)


# The finger drags hand tile `index` to just before tile `before` (both
# slots as the card's hand starts out), the others sliding aside — the
# player arranging their hand (see hand_row.gd).
func _arrange(index: int, before: int, run: int) -> bool:
	var node: Control = _hand_tiles[index]
	var target: Control = _hand_tiles[before]
	if not await _press_at(node.position + node.size / 2, run):
		return false
	_hand_tiles.erase(node)
	_hand_tiles.insert(_hand_tiles.find(target), node)
	node.z_index = 1
	var tween := _tween().set_parallel()
	_slide_hand(tween)
	var center := _hand_slot(_hand_tiles.find(node)) + Vector2.ONE * _hand_side / 2
	tween.tween_property(_finger, "position", center - _finger.size / 2, 0.4)
	if not await _pause(0.45, run):
		return false
	node.z_index = 0
	_release()
	return true


# Adds to `tween` every hand tile sliding to its slot.
func _slide_hand(tween: Tween) -> void:
	for i in range(_hand_tiles.size()):
		var node: Control = _hand_tiles[i]
		if node != null:
			tween.tween_property(node, "position", _slot_position(node, i), 0.4).set_trans(
				Tween.TRANS_SINE
			)


# The finger taps the hand button `label` (see `_HAND_BUTTONS`), and the
# hand follows: sorted A to Z, or every tile turned yellow or green (see
# hand_tiles.gd).
func _tap_hand_button(label: String, run: int) -> bool:
	var button: Button = _hand_buttons[label]
	if not await _press_at(button.position + button.size / 2, run):
		return false
	_tween().tween_property(button, "scale", Vector2.ONE * 0.92, 0.08)
	_release()
	if not await _pause(0.1, run):
		return false
	_tween().tween_property(button, "scale", Vector2.ONE, 0.08)
	var nodes := _hand_tiles.filter(func(n): return n != null)
	if label == "Trier":
		nodes.sort_custom(
			func(a: Control, b: Control) -> bool:
				return (
					HandTiles.sort_key(a.get_meta("tile")) < HandTiles.sort_key(b.get_meta("tile"))
				)
		)
		_hand_tiles = nodes
		_slide_hand(_tween().set_parallel())
		return await _pause(0.45, run)
	var green := label == "Tout vert"
	for i in range(_hand_tiles.size()):
		var node: Control = _hand_tiles[i]
		if node == null:
			continue
		var tile: Tile = node.get_meta("tile")
		var turn := (
			tile.back_is_green() and tile.is_showing_front()
			if green
			else not tile.is_showing_front()
		)
		if turn:
			var flipped: Control = await _flip(node, run)
			if flipped == null:
				return false
			_hand_tiles[i] = flipped
	return await _pause(0.15, run)


# The finger taps "Recommencer": the card's tiles fade out and come back
# as they were when the turn began — the hand as the card starts, and the
# card's "word" steps, the words already on the board (see
# GameSession.reset_turn).
func _reset_turn(card: Dictionary, run: int) -> bool:
	if not await _press_at(_top_button.position + _top_button.size / 2, run):
		return false
	_top_button.pivot_offset = _top_button.size / 2
	_tween().tween_property(_top_button, "scale", Vector2.ONE * 0.92, 0.08)
	_release()
	_tween().tween_property(_card_layer, "modulate:a", 0.0, 0.25)
	if not await _pause(0.3, run):
		return false
	var finger_at := _finger.position
	_reset(card)
	# `_reset` sent the finger off the stage; it stays by the button.
	_finger.position = finger_at
	_card_layer.modulate.a = 0.0
	_tween().tween_property(_card_layer, "modulate:a", 1.0, 0.25)
	# The words already on the board as the turn began come back too.
	for step: Dictionary in card["steps"]:
		if step.has("word") and not await _place_word(step, run):
			return false
	return await _pause(0.3, run)
