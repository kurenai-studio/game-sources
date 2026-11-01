class_name LevelTile
extends TileButton
## A level on the world screen: the tile frame with a small picture of the level's board, and under
## it the number and the state (solved with its stars, current, locked). The picture shows what the
## level asks before the player opens it; a locked level shows it faint. The state is the frame
## (ink, yellow, outline) and the icon under the picture, so color is never the only signal.

## Height of the strip under the picture, in pixels.
const STRIP := 30.0
## Space between the frame and the picture.
const PAD := 6.0

var _view: BoardView
var _number := ""


## Shows `level_data`'s board; `faint` for a level that is locked.
func show_board(level_data: Dictionary, number: String, faint: bool) -> void:
	_number = number
	_view = BoardViews.make(Settings.LOOK_DEPTH if UiLook.depth else Settings.LOOK_FLAT)
	_view.modulate.a = 0.4 if faint else 1.0
	add_child(_view)
	_view.set_level(level_data)
	resized.connect(_place)
	_place()


func _place() -> void:
	if _view == null:
		return
	var side := minf(size.x - 2.0 * PAD, size.y - STRIP - PAD)
	_view.position = Vector2((size.x - side) / 2.0, PAD)
	_view.size = Vector2(side, side)


func _draw_content(rect: Rect2, color: Color) -> void:
	if _view == null:
		super._draw_content(rect, color)
		return
	var strip := Rect2(PAD, rect.size.y - STRIP, rect.size.x - 2.0 * PAD, STRIP - 4.0)
	var px := clampi(int(rect.size.x * 0.17), 13, 22)
	UiKit.text(self, _number, strip, px, color, 1, HORIZONTAL_ALIGNMENT_LEFT)
	var spot := Vector2(strip.end.x - 12.0, strip.get_center().y)
	if stars > 0:
		StarGlyph.row(self, Vector2(strip.end.x - 24.0, strip.get_center().y), stars, 3, 5.0, color)
	elif icon != "":
		UiKit.icon(self, icon, spot, 15.0, color)
