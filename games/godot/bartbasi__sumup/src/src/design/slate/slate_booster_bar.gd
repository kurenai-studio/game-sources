extends "res://src/design/shared/booster_bar_base.gd"
## Slate booster strip (DESIGN_SYSTEM.md 5.7): full width, strip_height tall,
## a hairline in line on top and hairlines between five equal columns. No
## box, no shadow. The targeting hint lives in the HUD's context row, so
## set_hint() shows nothing here.
##
## The Suggested badge (D-42) is a "SUGGESTED" badge, square corners, across
## the column's top hairline, centered on the column and kept inside the bar.
## It hides while any booster is active, so it never covers the board's bottom
## row while the player taps tiles.
## Text pair: badge_ink on badge.

const SlateBoosterButton: GDScript = preload("res://src/design/slate/slate_booster_button.gd")

var _font: Font = null
var _font_size: int = 1
var _suggested_text: String = ""
var _suggested_width: float = 0.0
## Hairline rects, worked out on layout so _draw() only fills them.
var _rules: Array[Rect2] = []


func _on_setup() -> void:
	_font = _skin.font(&"label")
	_font_size = _skin.font_size(&"label")
	_suggested_text = _skin.cased(&"label", UiCopy.SUGGESTED)
	_suggested_width = _font.get_string_size(_suggested_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x + _skin.num(&"space_s") * 2.0


func _make_button() -> BoosterButtonBase:
	return SlateBoosterButton.new()


## Slate shows the targeting hint in its HUD context row.
func set_hint(_text: String) -> void:
	pass


## The whole strip, top hairline included, is always visible.
func content_top() -> float:
	return 0.0


func _place() -> void:
	var hairline: float = _skin.num(&"hairline")
	_rules.clear()
	_rules.append(Rect2(0.0, 0.0, size.x, hairline))
	var count: int = _buttons.size()
	if count == 0:
		return
	var column: float = (size.x - hairline * float(count - 1)) / float(count)
	var line: float = _font.get_height(_font_size)
	var badge_height: float = line + _skin.num(&"space_xs") * 2.0
	for i: int in count:
		var x: float = roundf((column + hairline) * float(i))
		var right: float = roundf((column + hairline) * float(i) + column)
		var button: BoosterButtonBase = _buttons[i]
		button.position = Vector2(x, hairline)
		button.size = Vector2(right - x, size.y - hairline)
		if i < count - 1:
			_rules.append(Rect2(right, hairline, hairline, size.y - hairline))
		if button.suggested and badges_shown():
			var badge_x: float = clampf(x + (right - x - _suggested_width) * 0.5, 0.0, size.x - _suggested_width)
			var rect: Rect2 = Rect2(badge_x, hairline * 0.5 - badge_height * 0.5, _suggested_width, badge_height)
			_badge_rects.append(rect)
			_badge_origins.append(Vector2(rect.position.x, rect.position.y + _skin.num(&"space_xs") + _font.get_ascent(_font_size)))


func _draw() -> void:
	if _skin == null:
		return
	var color: Color = _skin.color(&"line")
	for rect: Rect2 in _rules:
		draw_rect(rect, color)


func _draw_badges() -> void:
	var fill: Color = _skin.color(&"badge")
	var ink: Color = _skin.color(&"badge_ink")
	for i: int in _badge_rects.size():
		_badges.draw_rect(_badge_rects[i], fill)
		_badges.draw_string(_font, _badge_origins[i], _suggested_text, HORIZONTAL_ALIGNMENT_CENTER, _badge_rects[i].size.x, _font_size, ink)
