class_name TapeIfCells
extends RefCounted
## The two tiles of an IF that are not commands: its header, which reads "IF" and what the
## sensor looks at (an arrow and the word AHEAD, LEFT or RIGHT, so color is never the only
## signal), and the ELSE divider between the then and else tiles.

const SIDE_WORDS := {"AHEAD": "AHEAD", "LEFT": "LEFT", "RIGHT": "RIGHT"}
const FAMILY_WORDS := {"CLEAR": "", "FRESH": "NEW", "BACK": "BACK"}
const SIDE_ICONS := {"AHEAD": "ahead", "LEFT": "sense_left", "RIGHT": "sense_right"}


## True for the header tile of an IF.
static func is_header(cell: Dictionary) -> bool:
	return cell["kind"] == "if"


## The side a sensor looks at, "AHEAD", "LEFT" or "RIGHT".
static func side(sensor: Variant) -> String:
	var parts := String(sensor).split("_")
	return parts[1] if parts.size() == 2 and SIDE_WORDS.has(parts[1]) else "AHEAD"


## The kind of cell a sensor looks for: "CLEAR", "FRESH" or "BACK".
static func family(sensor: Variant) -> String:
	var kind := String(sensor).split("_")[0]
	return kind if FAMILY_WORDS.has(kind) else "CLEAR"


## The word shown for a sensor's side ("AHEAD").
static func word(sensor: Variant) -> String:
	return SIDE_WORDS[side(sensor)]


## The word that tells the cell kind apart from a plain clear cell: "" for CLEAR, else "NEW"
## (no breadcrumb) or "BACK" (the way the breadcrumb points).
static func family_word(sensor: Variant) -> String:
	return FAMILY_WORDS[family(sensor)]


## The icon kind shown for a sensor ("ahead", "fresh_left", "back_right").
static func icon(sensor: Variant) -> String:
	if family(sensor) == "CLEAR":
		return SIDE_ICONS[side(sensor)]
	return "%s_%s" % [family(sensor).to_lower(), side(sensor).to_lower()]


## Draws the IF header, or the ELSE IF header of an else-if chain. `solid` is an ink fill
## (selected, or already passed by the read-head). A tall tile reads head, icon and side; a short
## one reads head, cell kind (for NEW and BACK) and side, because it has no room for the icon.
static func draw_header(canvas: CanvasItem, cell: Dictionary, rect: Rect2, solid: bool) -> void:
	rect = TileDraw.tile(canvas, rect, TileDraw.Tone.SOLID if solid else TileDraw.Tone.PLAIN)
	var color := Palette.ON_INK if solid else Palette.INK
	var head := "ELSE IF" if cell.get("elseif", false) else "IF"
	var label := word(cell["when"])
	var kind := family_word(cell["when"])
	var tall := rect.size.y >= 48.0
	if tall:
		var top := rect.position.y + rect.size.y * 0.06
		var band := rect.size.y * 0.26
		var head_box := Rect2(rect.position.x, top, rect.size.x, band)
		var head_px := TapeHeaders.fit(head, rect.size.x - 4.0, int(rect.size.x * 0.3))
		UiKit.text(canvas, head, head_box, head_px, color, 1)
		var center := Vector2(rect.get_center().x, top + band + rect.size.y * 0.2)
		UiKit.icon(canvas, icon(cell["when"]), center, rect.size.x * 0.36, color)
		var area := Rect2(
			rect.position.x, top + band + rect.size.y * 0.38, rect.size.x, rect.size.y * 0.28
		)
		UiKit.text(canvas, label, area, TapeHeaders.fit(label, rect.size.x - 4.0, 12), color, 0)
		return
	var lines: Array[String] = [head]
	if kind != "":
		lines.append(kind)
	lines.append(label)
	var line_h := rect.size.y / lines.size()
	var start_px := int(rect.size.x * 0.34) if lines.size() == 2 else 10
	for k in lines.size():
		var box := Rect2(rect.position.x, rect.position.y + k * line_h, rect.size.x, line_h)
		var px := TapeHeaders.fit(lines[k], rect.size.x - 4.0, start_px if k == 0 else 12)
		UiKit.text(canvas, lines[k], box, mini(px, int(line_h) + 2), color, 0 if k > 0 else 1)


## Draws the ELSE divider: a dashed tile with the word, no fill.
static func draw_else(canvas: CanvasItem, rect: Rect2) -> void:
	UiKit.outline_chamfer(canvas, rect, Palette.INK, 2.0, true)
	UiKit.text(canvas, "ELSE", rect, TapeHeaders.fit("ELSE", rect.size.x - 4.0, 14), Palette.INK, 1)
