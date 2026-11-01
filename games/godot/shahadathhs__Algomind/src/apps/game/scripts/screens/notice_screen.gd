class_name NoticeScreen
extends ScreenBase
## A full-screen state with an icon, a heading, a few lines of text, and up to two actions:
## the first is the primary (yellow), the second is outlined. Used for Load error and Update
## required. Subclasses fill `icon_kind`, `heading`, `body`, `primary`, and `secondary` in
## `_prepare`, and handle the two actions.

var icon_kind := "offline"
var heading := ""
var body := ""
var detail := ""
var primary_label := ""
var secondary_label := ""

var _back: TileButton
var _icon: _IconTile
var _heading: Label
var _body: Label
var _detail: Label
var _primary: TileButton
var _secondary: TileButton


func _prepare() -> void:
	pass


func _on_primary() -> void:
	pass


func _on_secondary() -> void:
	pass


func _build() -> void:
	_prepare()
	_back = TileButton.make(TileButton.Kind.SECONDARY, "", "back")
	_back.accessibility_name = "Back"
	_back.pressed.connect(go_back)
	add_child(_back)

	_icon = _IconTile.new()
	_icon.kind = icon_kind
	add_child(_icon)
	_heading = UiKit.label(heading, 32, Palette.INK, 1)
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_heading)
	_body = UiKit.label(body, 16, Palette.MUTE, 1)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_body)
	_detail = UiKit.label(detail, 14, Palette.MUTE, 2)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_detail)

	_primary = TileButton.make(TileButton.Kind.PRIMARY, primary_label, "", 24)
	_primary.pressed.connect(_on_primary)
	add_child(_primary)
	_secondary = TileButton.make(TileButton.Kind.SECONDARY, secondary_label, "", 18)
	_secondary.pressed.connect(_on_secondary)
	_secondary.visible = not secondary_label.is_empty()
	add_child(_secondary)


func _layout() -> void:
	if _secondary == null:
		return
	var m := margin()
	var width := size.x - 2.0 * m
	var top := inset_top() + (28.0 if size.y >= 700.0 else 12.0)
	_back.position = Vector2(m, top)
	_back.size = Vector2(44.0, 44.0)
	var bottom := size.y - inset_bottom() - m
	var secondary_h := 52.0
	var primary_h := 64.0 if size.y >= 700.0 else 56.0
	_secondary.size = Vector2(width, secondary_h)
	_secondary.position = Vector2(m, bottom - secondary_h)
	var button_top := bottom - (secondary_h + 12.0 if _secondary.visible else 0.0)
	_primary.size = Vector2(width, primary_h)
	_primary.position = Vector2(m, button_top - primary_h)
	var y := maxf(top + 80.0, size.y * 0.3)
	_icon.position = Vector2(m, y)
	_icon.size = Vector2(72.0, 72.0)
	y += 96.0
	_heading.position = Vector2(m, y)
	_heading.size = Vector2(width, 80.0)
	y += 84.0
	_body.position = Vector2(m, y)
	_body.size = Vector2(width, 80.0)
	y += 88.0
	_detail.position = Vector2(m, y)
	_detail.size = Vector2(width, 40.0)


## The large outlined square with the state icon.
class _IconTile:
	extends Control

	var kind := "offline"

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		UiKit.fill_chamfer(self, rect, Palette.GROUND)
		UiKit.outline_chamfer(self, rect, Palette.INK)
		UiKit.icon(self, kind, size / 2.0, size.x * 0.5, Palette.INK)
