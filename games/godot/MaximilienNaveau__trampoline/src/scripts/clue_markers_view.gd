# The phone-sized way of showing a crossword's clues: instead of a list
# under the board (which pushes the palette off-screen on a portrait
# phone), one small round "?" per row, pinned on the board frame's right
# edge. Tapping one pops up a manga-style speech bubble with that row's
# clue, its tail pointing back at the "?"; tapping it again closes it. A
# solved row's "?" turns into a green "✓".
#
# Lives as a child of BoardView in main.tscn, drawn on top of the grid,
# but knows nothing about BoardView or the puzzle: `refresh()` is handed
# the clues, which rows are solved, and where each row sits on screen
# (see BoardView.row_rect) — same read-only relationship as
# ClueListView, which is still used in landscape where a list fits.
class_name ClueMarkersView
extends Control

# Colors from doc/ART_DIRECTION.md's palette: `ink` for outlines/text,
# a near-white "paper" for the bubble, and the same green ClueListView
# already uses for a solved clue.
const _INK := Color("363a42")
const _PAPER := Color("fffdf5")
const _SOLVED_COLOR := Color(0.6, 0.85, 0.55)

# Width of the strip, right of the grid and inside the frame, that the
# "?" column sits in — main.gd hands this to BoardView (see its
# `reserved_right_width`) so the cells shrink just enough to leave room
# for it, instead of the markers covering the last column.
const LANE_WIDTH := 30.0
const _BUBBLE_FONT_SIZE := 16
const _BUBBLE_PADDING := Vector2(14, 10)
const _BUBBLE_OUTLINE := 3
# Vertical gap between the row and the bubble, which the tail spans.
const _TAIL_HEIGHT := 14.0
# Width of the tail where it meets the bubble.
const _TAIL_BASE := 22.0

# Last values handed to `refresh()`, kept so a marker tap can redraw
# without main.gd having to call back in.
var _clues: Array[String] = []
var _solved: Array[bool] = []
var _row_rects: Array[Rect2] = []

# One Button per board row, built once in `_ready()`.
var _markers: Array[Button] = []

# Which row's bubble is open, or -1 for none.
var _open_row := -1

# The bubble's outline and fill — a StyleBoxFlat is the same kind of
# resource main.tscn uses for its panels, but here drawn by hand in
# `_draw()` (see below) instead of attached to a node.
var _bubble_style := StyleBoxFlat.new()


func _ready() -> void:
	_bubble_style.bg_color = _PAPER
	_bubble_style.border_color = _INK
	_bubble_style.set_border_width_all(_BUBBLE_OUTLINE)
	_bubble_style.set_corner_radius_all(16)
	_bubble_style.shadow_color = Color(0, 0, 0, 0.25)
	_bubble_style.shadow_size = 4
	_bubble_style.shadow_offset = Vector2(0, 2)

	for row in range(Board.ROWS):
		var marker := Button.new()
		# No keyboard-focus ring — these are tapped, never tabbed to.
		marker.focus_mode = Control.FOCUS_NONE
		marker.pressed.connect(_on_marker_pressed.bind(row))
		add_child(marker)
		_markers.append(marker)


# Built-in callback Godot calls on a node for various engine events
# (`what` says which). Here: close any open bubble once this view is
# hidden (leaving crossword mode, or switching to landscape), so it
# doesn't pop back open on the next puzzle.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_open_row = -1


# Repositions and restyles every marker, and redraws the open bubble (if
# any). `row_rects[i]` is where board row i sits, in this node's own
# coordinates (see BoardView.row_rect).
func refresh(clues: Array[String], solved: Array[bool], row_rects: Array[Rect2]) -> void:
	_clues = clues
	_solved = solved
	_row_rects = row_rects
	# BoardView's frame shrinks to fit its children (see main.tscn), so
	# asking for the grid's width plus the lane is what keeps the "?"
	# column inside the frame rather than hanging off its right edge.
	custom_minimum_size.x = row_rects[0].end.x + LANE_WIDTH
	for row in range(_markers.size()):
		var marker := _markers[row]
		var rect := row_rects[row]
		# Scales with the board's cells, within a range that stays
		# tappable on a phone without crowding a big screen.
		var diameter: float = clamp(rect.size.y * 0.8, 20.0, LANE_WIDTH - 4)
		marker.size = Vector2(diameter, diameter)
		marker.position = Vector2(
			rect.end.x + LANE_WIDTH / 2 - diameter / 2, rect.get_center().y - diameter / 2
		)
		marker.text = "✓" if solved[row] else "?"
		marker.add_theme_font_size_override("font_size", int(diameter * 0.6))

		# Solved: green. Open: inverted (ink fill, paper text), so it's
		# clear which "?" the bubble belongs to. Otherwise: paper fill.
		var fill := _PAPER
		var text_color := _INK
		if solved[row]:
			fill = _SOLVED_COLOR
		elif row == _open_row:
			fill = _INK
			text_color = _PAPER
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = _INK
		style.set_border_width_all(2)
		# A corner radius of half the side turns the square into a circle.
		style.set_corner_radius_all(int(diameter / 2))
		# A Button has a separate look per state (idle, hovered,
		# pressed, ...) — all the same here, so tapping doesn't flash.
		for state in ["normal", "hover", "pressed", "focus"]:
			marker.add_theme_stylebox_override(state, style)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
			marker.add_theme_color_override(color_name, text_color)
	# Asks Godot to call `_draw()` again on the next frame — a Control
	# only redraws its custom drawing when told to.
	queue_redraw()


func _on_marker_pressed(row: int) -> void:
	_open_row = -1 if _open_row == row else row
	refresh(_clues, _solved, _row_rects)


# Godot calls this whenever this node needs redrawing (see `queue_redraw`
# above) — the place for hand-drawn shapes, like Qt's paintEvent or an
# HTML canvas. Everything drawn here sits under this node's own children
# (the markers), but over the grid, BoardView's earlier child.
func _draw() -> void:
	if _open_row == -1 or _open_row >= _row_rects.size():
		return
	var row_rect := _row_rects[_open_row]
	var marker := _markers[_open_row]
	var font := get_theme_font("font", "Label")

	# Bubble spans the row's width, minus a little on the right so it
	# doesn't run under the other rows' markers.
	var bubble_width := row_rect.size.x
	var text := "%d. %s" % [_open_row + 1, _clues[_open_row]]
	var text_width := bubble_width - 2 * _BUBBLE_PADDING.x
	var text_size := font.get_multiline_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, text_width, _BUBBLE_FONT_SIZE
	)
	var bubble_size := Vector2(bubble_width, text_size.y + 2 * _BUBBLE_PADDING.y)

	# Top half of the board: bubble below the row. Bottom half: above it,
	# so it never hangs off the bottom of the board.
	var below := _open_row < Board.ROWS / 2
	var bubble_y := (
		row_rect.end.y + _TAIL_HEIGHT
		if below
		else row_rect.position.y - _TAIL_HEIGHT - bubble_size.y
	)
	var bubble := Rect2(Vector2(row_rect.position.x, bubble_y), bubble_size)
	draw_style_box(_bubble_style, bubble)

	# The tail: a triangle from the bubble's edge (near its right end) to
	# the marker. `side` is +1 when the bubble is below (tail goes up),
	# -1 when above (tail goes down).
	var side := 1.0 if below else -1.0
	var edge_y := bubble.position.y if below else bubble.end.y
	var base_right := Vector2(bubble.end.x - 16, edge_y)
	var base_left := base_right - Vector2(_TAIL_BASE, 0)
	# Tip on the marker's circle, on its lower-left (or upper-left) side,
	# so the wedge points at the "?" from the bubble's direction.
	var tip := (
		marker.position
		+ marker.size / 2
		+ Vector2(-0.3 * marker.size.x, side * 0.4 * marker.size.y)
	)
	# Fill first, pushed slightly into the bubble so it covers that stretch
	# of the bubble's own outline — the tail and bubble read as one shape.
	var inset := Vector2(0, side * (_BUBBLE_OUTLINE + 1))
	draw_colored_polygon(PackedVector2Array([base_left + inset, tip, base_right + inset]), _PAPER)
	# Then only the two slanted sides get an outline.
	draw_line(base_left, tip, _INK, _BUBBLE_OUTLINE, true)
	draw_line(base_right, tip, _INK, _BUBBLE_OUTLINE, true)

	# `draw_multiline_string`'s position is the first line's baseline,
	# not its top — hence adding the font's ascent.
	var text_origin := (
		bubble.position + _BUBBLE_PADDING + Vector2(0, font.get_ascent(_BUBBLE_FONT_SIZE))
	)
	draw_multiline_string(
		font, text_origin, text, HORIZONTAL_ALIGNMENT_LEFT, text_width, _BUBBLE_FONT_SIZE, -1, _INK
	)
