# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name LicenseViewer
extends PageFrame
## Shows the pieces of one license text (LicenseText). The page opens at once
## with the first pieces and adds the rest a few every frame, so a long text
## never stalls the screen and scrolling stays smooth.

## Time spent adding pieces in one frame, in microseconds.
const BUDGET_US: int = 6000

var _pieces: Array[Dictionary]
var _next: int = 0
var _box: VBoxContainer


func _init(title: String, text_pieces: Array[Dictionary]) -> void:
	super(title)
	_pieces = text_pieces
	_box = UiKit.section()
	column.add_child(_box.get_parent())
	_add_some(BUDGET_US)


func _process(_delta: float) -> void:
	if _next >= _pieces.size():
		set_process(false)
		return
	_add_some(BUDGET_US)


## True once every piece is on the page.
func is_complete() -> bool:
	return _next >= _pieces.size()


## Adds every remaining piece now (tests, and screens that must be whole).
func finish_now() -> void:
	_add_some(-1)


func _add_some(budget_us: int) -> void:
	var started: int = Time.get_ticks_usec()
	while _next < _pieces.size():
		var piece: Dictionary = _pieces[_next]
		var text: String = piece["text"]
		if piece["head"]:
			_box.add_child(UiKit.heading(text))
		else:
			_box.add_child(UiKit.label(text))
		_next += 1
		if budget_us >= 0 and Time.get_ticks_usec() - started >= budget_us:
			return
