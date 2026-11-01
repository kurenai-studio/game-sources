class_name TapeHeaders
extends RefCounted
## The first tile of a loop on the tape. REPEAT shows its count ("x3"); REPEAT_UNTIL shows the
## words UNTIL BLOCKED and a wall icon (or UNTIL GOAL and a ring), because it has no count.
## A loop that counts with N shows "N" and, on a tall tile, a counter icon. While a run is shown,
## the loop the read-head is in shows its 1-based round, and loops already passed are solid
## (TapeView decides which).


## True for the first cell of a loop of either kind.
static func is_header(cell: Dictionary) -> bool:
	return cell["kind"] == "count" or cell["kind"] == "until"


## Draws the header of a loop into rect. `solid` is an ink fill (selected, or already reached by
## the read-head). `round_number` is the round to show: the 1-based round of the loop the
## read-head is in, -1 for a loop that is finished, 0 when it is not known or not running.
static func draw(
	canvas: CanvasItem, cell: Dictionary, rect: Rect2, solid: bool, round_number: int
) -> void:
	rect = TileDraw.tile(canvas, rect, TileDraw.Tone.SOLID if solid else TileDraw.Tone.PLAIN)
	var color := Palette.ON_INK if solid else Palette.INK
	if cell["kind"] == "until":
		_draw_until(canvas, rect, color, maxi(round_number, 0), cell["until"] == "GOAL")
		return
	var counted: bool = cell["count"] is String
	var count_text := "N" if counted else str(int(cell["count"]))
	# Running: "round/count" once the loop has started, "x3" before it. A loop that counts with N
	# does not know its rounds until it starts, so its finished state shows N.
	var text := "\u00d7" + count_text
	if round_number > 0:
		text = "%d/%s" % [round_number, count_text]
	elif round_number < 0:
		text = "%s/%s" % [count_text, count_text]
	var area := rect
	if counted and rect.size.y >= 48.0:
		# A counter icon above the text tells N from a number.
		UiKit.icon(
			canvas,
			"counter",
			rect.position + Vector2(rect.size.x / 2.0, rect.size.y * 0.27),
			rect.size.x * 0.34,
			color
		)
		area = Rect2(
			rect.position.x, rect.position.y + rect.size.y * 0.42, rect.size.x, rect.size.y * 0.5
		)
	var px := fit(text, rect.size.x - 4.0, int(rect.size.x * 0.42))
	UiKit.text(canvas, text, area, px, color, 0)


## "UNTIL" over "BLOCKED" with a wall icon above when the tile is big enough; while the loop
## runs, "ROUND" over the round number replaces the words.
static func _draw_until(
	canvas: CanvasItem, rect: Rect2, color: Color, round_number: int, goal: bool
) -> void:
	var tall := rect.size.y >= 48.0
	var top := rect.position.y + rect.size.y * (0.08 if tall else 0.0)
	var lines: Array[String] = ["UNTIL", "GOAL" if goal else "BLOCKED"]
	if round_number > 0:
		lines = ["ROUND", str(round_number)]
	if tall:
		var center := Vector2(rect.get_center().x, top + rect.size.y * 0.24)
		UiKit.icon(canvas, "goal" if goal else "until", center, rect.size.x * 0.4, color)
	var area := Rect2(
		rect.position.x,
		top + (rect.size.y * 0.4 if tall else 0.0),
		rect.size.x,
		rect.size.y * (0.52 if tall else 1.0)
	)
	var line_h := area.size.y / 2.0
	for k in 2:
		var line_rect := Rect2(area.position.x, area.position.y + k * line_h, area.size.x, line_h)
		var px := fit(lines[k], rect.size.x - 4.0, int(rect.size.x * 0.2))
		UiKit.text(canvas, lines[k], line_rect, px, color, 0)


## The largest font size up to `start` (at least 8) at which `value` fits in `width`.
static func fit(value: String, width: float, start: int) -> int:
	var px := maxi(start, 8)
	while px > 8 and UiKit.text_width(value, px, 0) > width:
		px -= 1
	return px
