# Lays out the board and, beside or under it, HandArea (the hand, or free
# play's palette and clue list, on their felt mat): stacked in portrait (a
# phone held upright), side by side in landscape. Side by side, the mat is
# sized like the board — as tall, and as wide (9 tiles a line, like a board
# row) — and the two sit together in the middle of the screen, where the
# player looks. Without that, on a big screen the mat stretched over all the
# width the board didn't use, and the hand ran along one long line far from
# the board. Pure layout: main.gd says which orientation, nothing here knows
# the game.
class_name PlayArea
# A BoxContainer, not a VBoxContainer/HBoxContainer: Godot only lets its
# `vertical` (stacked or side by side) change at runtime on this base class.
extends BoxContainer

# True while a re-fit of the mat is waiting for the end of the frame (see
# `_queue_fit`).
var _fit_queued := false

# The two children, as main.tscn lays them out, and the "À rendre" tray
# beside the hand (see discard_tray.gd), which the mat makes room for.
@onready var _board_view: Control = $BoardView
@onready var _hand_area: PlayMat = $HandArea
@onready var _discard_tray: Control = $HandArea/HandBar/DiscardTray
# Free play's palette and a crossword's clue list, on the same mat.
@onready var _palette_view: HandView = $HandArea/PaletteView
@onready var _clue_list: Control = $HandArea/ClueListView


func _ready() -> void:
	# `minimum_size_changed`: a Control's signal, emitted when its own
	# natural size changes — here the board's (its cells re-fit on every
	# window resize, see board_view.gd), which the mat copies.
	_board_view.minimum_size_changed.connect(_queue_fit)
	# The tray only shows during a turn-based game (not in free play).
	_discard_tray.visibility_changed.connect(_queue_fit)
	# Nor the clue list outside a crossword.
	_clue_list.visibility_changed.connect(_queue_fit)


# Stacks the board and the mat (`portrait`) or puts them side by side.
func arrange(portrait: bool) -> void:
	vertical = portrait
	# Where a BoxContainer puts its children when they don't fill it: side
	# by side, together in the middle; stacked, from the top as before.
	alignment = ALIGNMENT_BEGIN if portrait else ALIGNMENT_CENTER
	# Side by side, the board keeps its own height instead of stretching to
	# this container's: the mat copies that height, and a stretched board
	# would hold on to an outdated one (a too-tall mat, the page scrolling).
	_board_view.size_flags_vertical = SIZE_FILL if portrait else SIZE_SHRINK_BEGIN
	# Likewise this container: as tall as the board side by side, rather
	# than all the room below the scores — that room, right after a window
	# resize, can still be the old one, which put the mat (centred on this
	# container's height) halfway down the page. Stacked, it takes that
	# room, for the hand under the board.
	size_flags_vertical = SIZE_EXPAND_FILL if portrait else SIZE_SHRINK_BEGIN
	_queue_fit()


# Re-fits the mat once the current layout pass is over: these signals come
# while Godot is laying out the page, and sizes changed during that pass
# aren't laid out again until something else asks for it (a scroll, for
# instance), which left the page with a stale, too-tall size after a
# resize. `call_deferred` runs a function at the end of the frame; asked
# several times in one frame (board, tray, clue list), it runs once.
func _queue_fit() -> void:
	if not _fit_queued:
		_fit_queued = true
		_fit_hand_area.call_deferred()


# Side by side: the mat as tall as the board and as wide — plus the tray
# when it's shown, so a line of the hand still holds 9 tiles; twice as wide
# for a crossword, so the palette takes half the height and leaves the
# other half to the clues — or narrower if the window leaves less room.
# Stacked: the mat back to the full width.
func _fit_hand_area() -> void:
	_fit_queued = false
	if vertical:
		_palette_view.fixed_columns = 0
		_hand_area.custom_minimum_size = Vector2.ZERO
		_hand_area.size_flags_horizontal = SIZE_EXPAND_FILL
		_hand_area.size_flags_vertical = SIZE_FILL
		return
	# The board's own size: its 13x9 cells and frame.
	var board := _board_view.get_combined_minimum_size()
	var width := board.x
	var columns := Board.COLUMNS
	if _clue_list.visible:
		width *= 2
		columns *= 2
	if _discard_tray.visible:
		var hand_bar := _discard_tray.get_parent() as Control
		width += _discard_tray.get_combined_minimum_size().x
		width += hand_bar.get_theme_constant("separation")
	# The width left beside the board: this container's, minus the board's
	# and the gap between them (`separation`, set in main.tscn).
	var room := size.x - board.x - get_theme_constant("separation")
	var fitted := minf(width, maxf(room, 0.0))
	# The felt is drawn `bleed` beyond the mat's box (see play_mat.gd):
	# shorter by that much at the top and bottom, and centred (SHRINK_CENTER)
	# on the board's height, the felt as drawn covers exactly the board's
	# height — not reaching up into the scores — and the hand starts inside
	# it, not on its edge.
	_hand_area.custom_minimum_size = Vector2(fitted, board.y - 2.0 * _hand_area.bleed.y)
	# Fewer palette tiles a line when the mat had to be narrower.
	_palette_view.fixed_columns = maxi(1, floori(columns * fitted / width))
	# SHRINK: take exactly that minimum size, instead of growing (EXPAND)
	# into all the space the container has.
	_hand_area.size_flags_horizontal = SIZE_SHRINK_BEGIN
	_hand_area.size_flags_vertical = SIZE_SHRINK_CENTER
