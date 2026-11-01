class_name TapeProcCells
extends RefCounted
## The two tiles of the procedure mechanic: the header of a definition ("PROC" and its name) and
## a CALL ("CALL" and the name it runs). Both carry the name as a letter, so color is never the
## only signal, and an icon above it when the tile is tall enough.

## Fill states of a tile: PLAIN outlined, SOLID ink (selected or already run), ACTIVE yellow
## (the tile the read-head is on, or the CALL that is running).
enum Fill { PLAIN, SOLID, ACTIVE }


static func is_header(cell: Dictionary) -> bool:
	return cell["kind"] == "proc"


static func is_call(cell: Dictionary) -> bool:
	return cell["kind"] == "call"


## Draws a procedure header or a CALL cell into rect.
static func draw(canvas: CanvasItem, cell: Dictionary, rect: Rect2, fill: Fill) -> void:
	var color := Palette.INK
	var tone := TileDraw.Tone.PLAIN
	match fill:
		Fill.ACTIVE:
			tone = TileDraw.Tone.ACTIVE
			color = Palette.ON_SIGNAL
		Fill.SOLID:
			tone = TileDraw.Tone.SOLID
			color = Palette.ON_INK
	rect = TileDraw.tile(canvas, rect, tone)
	var word := "PROC" if is_header(cell) else ("CALL IF" if cell.has("when") else "CALL")
	var tall := rect.size.y >= 48.0
	if tall:
		var kind := "proc" if is_header(cell) else "call"
		if cell.has("when"):
			kind = TapeIfCells.icon(cell["when"])
		var center := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.24)
		UiKit.icon(canvas, kind, center, rect.size.x * 0.4, color)
	var area := Rect2(
		rect.position.x,
		rect.position.y + (rect.size.y * 0.42 if tall else 0.0),
		rect.size.x,
		rect.size.y * (0.56 if tall else 1.0)
	)
	var half := area.size.y / 2.0
	var small := Rect2(area.position.x, area.position.y, area.size.x, half)
	var big := Rect2(area.position.x, area.position.y + half, area.size.x, half)
	UiKit.text(
		canvas,
		word,
		small,
		TapeHeaders.fit(word, rect.size.x - 4.0, int(rect.size.x * 0.22)),
		color,
		1
	)
	UiKit.text(canvas, str(cell["name"]), big, int(rect.size.x * 0.4), color, 1)
