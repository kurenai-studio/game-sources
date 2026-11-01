extends Control
## Token sheet: the three directions side by side, each with its tile ramp
## (2 to 131072 and the rule above), palette swatches and type roles, drawn
## straight from the token files. A plain review aid for the designer, not a
## direction render: tiles here are simple rounded squares.
##
## Capture it with:
##     godot --path . res://tools/capture.tscn -- --scene res://tools/directions/shared/palette_sheet.tscn --out <png path>

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")

const COLUMN_PADDING: float = 28.0
const TILE: float = 92.0
const TILE_GAP: float = 12.0
const SWATCH: float = 40.0
const SWATCH_ROW: float = 50.0

var _directions: Array[DirectionTokens] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for direction_id: String in Directions.IDS:
		var tokens: DirectionTokens = Directions.load_tokens(direction_id)
		if tokens != null:
			_directions.append(tokens)
	queue_redraw()


func _draw() -> void:
	if _directions.is_empty():
		return
	var column_width: float = size.x / float(_directions.size())
	for i: int in _directions.size():
		_draw_column(_directions[i], Rect2(column_width * i, 0.0, column_width, size.y))


func _draw_column(tokens: DirectionTokens, area: Rect2) -> void:
	draw_rect(area, tokens.color("bg"))
	var x: float = area.position.x + COLUMN_PADDING
	var width: float = area.size.x - COLUMN_PADDING * 2.0
	var y: float = float(MockState.SAFE_TOP)
	var ink: Color = tokens.color("ink")
	var muted_key: String = "ink_soft" if tokens.palette.has("ink_soft") else "ink_muted"
	var muted: Color = tokens.color(muted_key)

	var title_font: Font = tokens.font("title")
	y += float(tokens.font_size("title"))
	draw_string(title_font, Vector2(x, y), tokens.cased("title", tokens.display_name), HORIZONTAL_ALIGNMENT_LEFT, width, tokens.font_size("title"), ink)
	y += 40.0

	# Tile ramp, three per row, then the rule above 131072.
	var values: Array[int] = []
	var value: int = DirectionTokens.RAMP_LOW
	for _index: int in DirectionTokens.RAMP_SIZE + 1:
		values.append(value)
		value *= 2
	var tile_font: Font = tokens.font("tile")
	for i: int in values.size():
		var cell: Vector2 = Vector2(x + (i % 3) * (TILE + TILE_GAP), y + floorf(i / 3.0) * (TILE + TILE_GAP))
		var rect: Rect2 = Rect2(cell, Vector2(TILE, TILE))
		_draw_rounded(rect, 18.0, tokens.fill_for(values[i]))
		var label: String = MockState.tile_label(values[i])
		var font_size: int = tokens.tile_font_size(TILE, label)
		var baseline: float = rect.position.y + (TILE + tile_font.get_ascent(font_size) - tile_font.get_descent(font_size)) * 0.5
		draw_string(tile_font, Vector2(rect.position.x, baseline), label, HORIZONTAL_ALIGNMENT_CENTER, TILE, font_size, tokens.ink_for(values[i]))
	y += ceilf(values.size() / 3.0) * (TILE + TILE_GAP) + 36.0

	# Type roles.
	for role: String in ["display", "body", "label"]:
		var font: Font = tokens.font(role)
		var font_size: int = mini(tokens.font_size(role), 96)
		y += float(font_size)
		var sample: String = MockState.format_number(MockState.SCORE) if role == "display" else ("Shuffle for 1,500" if role == "body" else "Best tile")
		draw_string(font, Vector2(x, y), tokens.cased(role, sample), HORIZONTAL_ALIGNMENT_LEFT, width, font_size, ink if role != "label" else muted)
		y += 22.0
	y += 24.0

	# Palette swatches.
	var label_font: Font = tokens.font("body")
	for key: String in tokens.palette.keys():
		var swatch_color: Color = tokens.palette[key]
		var swatch: Rect2 = Rect2(Vector2(x, y), Vector2(SWATCH, SWATCH))
		draw_rect(swatch, tokens.color("bg"))
		_draw_rounded(swatch, 8.0, swatch_color)
		draw_rect(swatch, muted, false, 1.0)
		var text: String = "%s  #%s" % [key, swatch_color.to_html(swatch_color.a < 1.0).to_upper()]
		draw_string(label_font, Vector2(x + SWATCH + 14.0, y + SWATCH * 0.72), text, HORIZONTAL_ALIGNMENT_LEFT, width - SWATCH - 14.0, 24, muted)
		y += SWATCH_ROW


func _draw_rounded(rect: Rect2, radius: float, fill: Color) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(int(radius))
	box.anti_aliasing = true
	draw_style_box(box, rect)
