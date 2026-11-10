# Shows a CrosswordPuzzle's 13 clues, one per board row, numbered like the
# rows (in landscape, under the palette beside the board — see
# play_area.gd; in portrait the board shows them as "?" markers instead,
# see clue_markers_view.gd). Holds no puzzle state itself —
# `refresh()` is just handed what to show every time (see main.gd),
# the same read-only relationship every other view has with its session.
class_name ClueListView
extends Control

# `$Column` looks up the child node named "Column" declared in
# clue_list_view.tscn — same `@onready`/`$Name` shorthand as BoardView's
# own `_grid`.
@onready var _column: VBoxContainer = $Column


# Redraws the whole clue list. `solved[i]` says whether `clues[i]`'s row
# currently matches its target (see crossword_puzzle.gd's `solved_rows`)
# — a solved clue turns green with a checkmark, matching the green used
# elsewhere in this project for a correct/positive state.
func refresh(clues: Array[String], solved: Array[bool]) -> void:
	# Throwaway-and-recreate every refresh, same reasoning as
	# HandView.refresh() — only 13 labels, cheap enough to rebuild rather
	# than track and update in place.
	for child in _column.get_children():
		child.queue_free()

	for i in range(clues.size()):
		var label := Label.new()
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Wraps a long clue onto a second line, breaking at word
		# boundaries, instead of letting it overflow this view's width.
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		if solved[i]:
			label.text = "✓ %s" % clues[i]
			label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.55, 1))
		else:
			label.text = "%d. %s" % [i + 1, clues[i]]
		_column.add_child(label)
