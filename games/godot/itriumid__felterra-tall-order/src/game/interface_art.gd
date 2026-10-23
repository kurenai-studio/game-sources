class_name InterfaceArt
extends RefCounted
## The interface's drawing kit: framed panels, bars, bold titles, key caps and small icons, all in
## palette pixels on whole pixels, so the interface keeps to the same style rules as the art.

## Icons, 7 by 7: "x" is the icon's color, "." is clear.
const ICONS := {
	"health": ".xx.xx. xxxxxxx xxxxxxx .xxxxx. ..xxx.. ...x... .......",
	"level": "...x... ..xxx.. xxxxxxx .xxxxx. .xx.xx. x.....x .......",
	"dodge": "..xxx.. .x...x. x..x... x.x.... x...x.. .x...x. ..xxx..",
	"aim": "...x... .xxxxx. .x.x.x. xxx.xxx .x.x.x. .xxxxx. ...x...",
	"kills": "x.x.x.. x.x.x.. .xxx... xxxxx.. xxxxx.. .xxx... .......",
	"time": "..xxx.. .x.x.x. x..x..x x..xx.x x.....x .x...x. ..xxx..",
	"cage": "xxxxxxx x.x.x.x x.x.x.x x.x.x.x x.x.x.x x.x.x.x xxxxxxx",
	"salvage": "..xxx.. .xx.xx. xx...xx .xx.xx. ..xxx.. ...x... ...x...",
	"cloth": "xxxxxxx x.x.x.x xxxxxxx x.x.x.x xxxxxxx x.x.x.x xxxxxxx",
	"cats": "x.....x xx...xx xxxxxxx x.xxx.x xxxxxxx .xxxxx. ..xxx..",
}


## A framed panel: a dark rim, a lit edge on top and left, a shadowed edge below and right, as if
## lit from the top left like everything else.
static func panel(canvas: CanvasItem, box: Rect2, fill := Palette.GRAPHITE) -> void:
	box = Rect2(box.position.round(), box.size.round())
	canvas.draw_rect(box, Palette.PANEL_DARK)
	canvas.draw_rect(box.grow(-1), fill)
	canvas.draw_rect(Rect2(box.position + Vector2(1, 1), Vector2(box.size.x - 2, 1)), Palette.PANEL_LIGHT)
	canvas.draw_rect(Rect2(box.position + Vector2(1, 1), Vector2(1, box.size.y - 2)), Palette.PANEL_LIGHT)
	canvas.draw_rect(Rect2(box.position + Vector2(1, box.size.y - 2), Vector2(box.size.x - 2, 1)), Palette.PANEL_DARK)
	canvas.draw_rect(Rect2(box.position + Vector2(box.size.x - 2, 1), Vector2(1, box.size.y - 2)), Palette.PANEL_DARK)


## A sunken box, for a picture or a bar to sit in.
static func well(canvas: CanvasItem, box: Rect2) -> void:
	box = Rect2(box.position.round(), box.size.round())
	canvas.draw_rect(box, Palette.PANEL_DARK)
	canvas.draw_rect(Rect2(box.position + Vector2(0, box.size.y - 1), Vector2(box.size.x, 1)), Palette.PANEL_LIGHT)


## A bar filled to a share, in a well.
static func bar(canvas: CanvasItem, box: Rect2, share: float, fill: Color) -> void:
	well(canvas, box)
	var inner := box.grow(-1)
	inner.size.x = roundf(inner.size.x * clampf(share, 0.0, 1.0))
	if inner.size.x > 0.0:
		canvas.draw_rect(inner, fill)


## Text drawn twice, a pixel apart: bold without a second font.
static func bold(canvas: CanvasItem, at: Vector2, text: String, color: Color) -> void:
	PixelFont.draw(canvas, at, text, color)
	PixelFont.draw(canvas, at + Vector2(1, 0), text, color)


static func bold_width(text: String) -> int:
	return PixelFont.width(text) + 1


static func icon(canvas: CanvasItem, at: Vector2, name: String, color: Color) -> void:
	var rows: PackedStringArray = (ICONS[name] as String).split(" ")
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == "x":
				canvas.draw_rect(Rect2(at + Vector2(x, y), Vector2.ONE), color)


## A key, drawn as a cap with its label, so controls read as keys to press.
static func key_cap(canvas: CanvasItem, at: Vector2, label: String) -> float:
	var width := PixelFont.width(label) + 6
	var box := Rect2(at.round(), Vector2(width, PixelFont.HEIGHT + 3))
	canvas.draw_rect(box, Palette.PANEL_DARK)
	canvas.draw_rect(Rect2(box.position, box.size - Vector2(0, 1)), Palette.PANEL_LIGHT)
	PixelFont.draw(canvas, box.position + Vector2(3, 1), label, Palette.OFF_WHITE)
	return width


## A line of key caps and what they do: ["R", "rerolls", "Tab", "reads"], laid out from a point.
## Returns the width it took.
static func key_line(canvas: CanvasItem, at: Vector2, pairs: Array[String]) -> float:
	var x := at.x
	for index in range(0, pairs.size(), 2):
		x += key_cap(canvas, Vector2(x, at.y), pairs[index]) + 3
		PixelFont.draw(canvas, Vector2(x, at.y + 2), pairs[index + 1], Palette.OFF_WHITE)
		x += PixelFont.width(pairs[index + 1]) + 10
	return x - at.x - 10


static func key_line_width(pairs: Array[String]) -> float:
	var width := 0.0
	for index in range(0, pairs.size(), 2):
		width += PixelFont.width(pairs[index]) + 6 + 3 + PixelFont.width(pairs[index + 1]) + 10
	return width - 10
