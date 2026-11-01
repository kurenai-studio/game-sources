extends BoardController
## A BoardController whose skin board view is the recording stub, for the
## board tests. Everything else is the real controller.
## Not a test file: the runner only loads files named test_*.gd.

const StubBoardView: GDScript = preload("res://tests/board/stub_board_view.gd")

## Effect lengths every new stub view starts with.
var durations: Dictionary[StringName, float] = {}
## How many views this board made.
var views_made: int = 0


func _make_view(_skin: SkinData) -> SkinBoardView:
	var view: StubBoardView = StubBoardView.new()
	view.durations = durations.duplicate()
	views_made += 1
	return view


## The view the board shows now.
func stub() -> StubBoardView:
	return _view as StubBoardView
