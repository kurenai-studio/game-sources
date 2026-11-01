extends "res://src/design/shared/booster_bar_base.gd"
## Nova booster bar (DESIGN_SYSTEM.md 6.7): five ring buttons in a row with
## no container, each in an equal slot of the width inside board_margin, the
## cost under each ring. The hint_height row above holds the hint: centered
## ink_muted text in the label role, no panel. Place it full width,
## bar_height tall; the rings and costs sit at the bottom.
##
## The Suggested badge (D-42) is a full pill in badge sitting on the ring's
## top edge, in the hint row; it hides while any booster is active, so it
## never meets the hint.
## Text pairs: ink_muted on bg_glow, badge_ink on badge.

const NovaBoosterButton: GDScript = preload("res://src/design/nova/nova_booster_button.gd")
const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")

var _font: Font = null
var _font_size: int = 1
var _badge_style: StyleBoxFlat = null
var _badge_height: float = 0.0
var _suggested_text: String = ""
var _suggested_width: float = 0.0
var _hint_origin: Vector2 = Vector2.ZERO


func _on_setup() -> void:
	_font = _skin.font(&"label")
	_font_size = _skin.font_size(&"label")
	_badge_height = _font.get_height(_font_size) + _skin.num(&"space_xs") * 2.0
	_badge_style = ThemeKit.box(_skin.color(&"badge"), _badge_height * 0.5)
	_suggested_text = _skin.cased(&"label", UiCopy.SUGGESTED)
	_suggested_width = _font.get_string_size(_suggested_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x + _skin.num(&"space_s") * 2.0


func _make_button() -> BoosterButtonBase:
	return NovaBoosterButton.new()


## The top of the ring row.
func content_top() -> float:
	if _skin == null:
		return 0.0
	return size.y - NovaBoosterButton.needed_height(_skin)


func _place() -> void:
	var margin: float = _skin.num(&"board_margin")
	var needed: float = NovaBoosterButton.needed_height(_skin)
	var top: float = size.y - needed
	var count: int = _buttons.size()
	if count > 0:
		var slot: float = (size.x - margin * 2.0) / float(count)
		for i: int in count:
			var button: BoosterButtonBase = _buttons[i]
			button.position = Vector2(margin + slot * float(i), top)
			button.size = Vector2(slot, needed)
			if button.suggested and badges_shown():
				var x: float = clampf(button.position.x + (slot - _suggested_width) * 0.5, 0.0, size.x - _suggested_width)
				var rect: Rect2 = Rect2(x, top - _badge_height, _suggested_width, _badge_height)
				_badge_rects.append(rect)
				_badge_origins.append(Vector2(x, rect.position.y + _skin.num(&"space_xs") + _font.get_ascent(_font_size)))
	var row: float = _skin.num(&"hint_height")
	var line: float = _font.get_height(_font_size)
	_hint_origin = Vector2(0.0, top - row + (row - line) * 0.5 + _font.get_ascent(_font_size))


func _draw() -> void:
	if _skin == null or _hint.is_empty():
		return
	draw_string(_font, _hint_origin, _hint, HORIZONTAL_ALIGNMENT_CENTER, size.x, _font_size, _skin.color(&"ink_muted"))


func _draw_badges() -> void:
	var ink: Color = _skin.color(&"badge_ink")
	for i: int in _badge_rects.size():
		_badges.draw_style_box(_badge_style, _badge_rects[i])
		_badges.draw_string(_font, _badge_origins[i], _suggested_text, HORIZONTAL_ALIGNMENT_CENTER, _badge_rects[i].size.x, _font_size, ink)
