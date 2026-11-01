class_name SkinHud extends Control
## The play screen HUD of one skin (docs/ARCHITECTURE.md section 7). Each
## skin subclasses it in src/design/<id>/. Screens get one from
## UiKit.make_hud(), place it full width with its top on the safe area's top,
## height preferred_height(), and use only the signal and methods below.
##
## The HUD ignores the mouse except on its pause button.

## The HUD's pause button was tapped.
signal pause_pressed()


func setup(_skin: SkinData) -> void:
	_missing(&"setup")


## Shows the score and the Best Score, formatted with NumberFormat.score
## (9,221,253,119B past 10 digits). The score's size fits its slot
## (DESIGN_SYSTEM.md 2.6). To count the score up, call set_scores with the new
## values first, so the size fits the final value, then Motion.count_up on
## score_label().
func set_scores(_score: BigNum, _best_score: BigNum) -> void:
	_missing(&"set_scores")


## The context row: "Chain 6" while dragging (highlight false), or the
## targeting hint (highlight true), in the screen's words; "" clears it. A
## skin with no context row ignores it.
func set_context(_text: String, _highlight: bool) -> void:
	_missing(&"set_context")


## Where the screen puts a SkinTileView merge preview, sized to fill it. null
## when the skin shows the preview on the board.
func preview_slot() -> Control:
	_missing(&"preview_slot")
	return null


## The score label, for Motion.count_up.
func score_label() -> Label:
	_missing(&"score_label")
	return null


## D-38 and D-45 clear notice (AT-104). values are the values the notice
## names, ascending: the move's MoveResult.notice_values, not cleared_values.
## Builds its own copy (DESIGN_SYSTEM.md 7.10) and places itself: Gumdrop and
## Nova on the board's top edge (board_rect is global), Slate in its context
## row. stars_earned > 0 adds "+n" and a filled star after the copy and plays
## the star earned effect into the counter (3.6).
##
## While a notice layer is set and the HUD is hidden (the offer has its place,
## QA6-04), the notice and the star take their offer placement in that layer
## (DESIGN_SYSTEM.md 7.1, 7.5). It never blocks input, and a later call
## replaces a notice still showing.
func show_clear_notice(_values: PackedInt64Array, _board_rect: Rect2, _stars_earned: int = 0) -> void:
	_missing(&"show_clear_notice")


## D-45, D-46: this run's star count, with the counter's progress fill, and
## the free boosters held (the free count hides at 0). Shown at once, with no
## effect, unless a running star effect will deliver exactly these values:
## then the effect ends on them. Any other values (a new run, a load, a free
## booster used) end the effect and show at once.
func set_stars(_count: int, _free_held: int) -> void:
	pass


## QA6-04: the play screen's notice layer, a full screen Control above the
## board and the offer panel and below every dialog. The notice and the
## flying stars are its children, never the HUD's, so they show while the HUD
## is hidden. null (the default) makes the HUD draw them on itself.
func set_notice_layer(_layer: Control) -> void:
	pass


## The HUD's height in px: the skin's hud_height.
func preferred_height() -> float:
	_missing(&"preferred_height")
	return 0.0


func _missing(method: StringName) -> void:
	var script: Script = get_script() as Script
	var path: String = script.resource_path if script != null else "?"
	push_error("%s does not implement SkinHud.%s()" % [path, method])
