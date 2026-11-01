class_name HowToRow
extends HBoxContainer
## One explained control on the how-to-play screen: an icon tile, a name, and a sentence.


static func make(icon_kind: String, name_text: String, body_text: String) -> HowToRow:
	var row := HowToRow.new()
	row.add_theme_constant_override("separation", 14)
	var tile := _Tile.new()
	tile.kind = icon_kind
	tile.custom_minimum_size = Vector2(52.0, 52.0)
	row.add_child(tile)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(UiKit.label(name_text, 20, Palette.INK, 1))
	var body := UiKit.label(body_text, 15, Palette.MUTE, 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	row.add_child(column)
	return row


class _Tile:
	extends Control

	var kind := "move"

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		UiKit.fill_chamfer(self, rect, Palette.GROUND)
		UiKit.outline_chamfer(self, rect, Palette.INK)
		UiKit.icon(self, kind, size / 2.0, size.x * 0.5, Palette.INK)
