class_name BoardViews
extends RefCounted
## Makes the board view for the player's look: the flat board or the depth board. Both take the
## same state, so a screen does not care which one it holds.


static func make(look: String) -> BoardView:
	var board: BoardView = BoardView25D.new() if look == Settings.LOOK_DEPTH else BoardView.new()
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return board
