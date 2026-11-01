extends "res://src/design/shared/booster_bar_base.gd"
## Gumdrop booster bar (DESIGN_SYSTEM.md 4.7): the hint row (hint_height) on
## top, then a floating dock (dock_height, dock_radius corners, surface with a
## surface_lip lip) board_margin from the screen sides, with five raised
## booster buttons inside. Place it full width, bar_height tall.
##
## The dock's lip is part of dock_height, and the buttons sit space_xs inside
## the dock's face on every side and space_xs apart, so each button (face and
## lip) is dock_height less the dock lip less 2 x space_xs tall. The dock
## sits board_margin inside the bar's own rect (the content column, QA6-08).
##
## Touch (QA6-05): each button takes touch on the dock face's whole height
## and across to the middle of the gaps beside it (the outer ones to the
## dock's edge), while it draws as before.
##
## The hint is a lemon badge pill centered in the hint row. The Suggested
## badge (D-42) sits on top of its button's top edge, in the hint row; it
## hides while any booster is active, so it never meets the hint.
## Text pair for both: badge_ink on badge.

const Candy: GDScript = preload("res://src/design/gumdrop/gumdrop_candy.gd")
const GumdropBoosterButton: GDScript = preload("res://src/design/gumdrop/gumdrop_booster_button.gd")

var _dock_style: StyleBoxFlat = null
var _badge_style: StyleBoxFlat = null
var _font: Font = null
var _font_size: int = 1
var _badge_ink: Color = Color.BLACK
var _badge_face: float = 0.0
var _suggested_text: String = ""
var _suggested_width: float = 0.0
var _hint_rect: Rect2 = Rect2()
var _hint_origin: Vector2 = Vector2.ZERO


func _on_setup() -> void:
	var lip: float = _skin.num(&"button_lip")
	_dock_style = Candy.raised(_skin.color(&"surface"), _skin.color(&"surface_lip"), _skin.num(&"dock_radius"), lip)
	_font = _skin.font(&"label")
	_font_size = _skin.font_size(&"label")
	_badge_ink = _skin.color(&"badge_ink")
	_badge_face = _font.get_height(_font_size) + _skin.num(&"space_xs") * 2.0
	_badge_style = Candy.badge(_skin, _badge_face)
	_suggested_text = _skin.cased(&"label", UiCopy.SUGGESTED)
	_suggested_width = _text_width(_suggested_text) + _skin.num(&"space_s") * 2.0


func _make_button() -> BoosterButtonBase:
	return GumdropBoosterButton.new()


func content_top() -> float:
	if _skin == null:
		return 0.0
	return size.y - _skin.num(&"dock_height")


func _dock_rect() -> Rect2:
	var margin: float = _skin.num(&"board_margin")
	var dock_height: float = _skin.num(&"dock_height")
	return Rect2(margin, size.y - dock_height, size.x - margin * 2.0, dock_height)


func _place() -> void:
	var dock: Rect2 = _dock_rect()
	var pad: float = _skin.num(&"space_xs")
	var lip: float = _skin.num(&"button_lip")
	var count: int = _buttons.size()
	var badge_height: float = _badge_face + lip
	if count > 0:
		var width: float = (dock.size.x - pad * 2.0 - pad * float(count - 1)) / float(count)
		var height: float = dock.size.y - lip - pad * 2.0
		for i: int in count:
			var button: GumdropBoosterButton = _buttons[i] as GumdropBoosterButton
			var rest: Rect2 = Rect2(dock.position.x + pad + (width + pad) * float(i), dock.position.y + pad, width, height)
			# The touch area: the dock face's height, to the middle of the gaps
			# beside the button, or to the dock's edge.
			var left: float = dock.position.x if i == 0 else rest.position.x - pad * 0.5
			var right: float = dock.end.x if i == count - 1 else rest.end.x + pad * 0.5
			button.position = Vector2(left, dock.position.y)
			button.size = Vector2(right - left, dock.size.y - lip)
			button.set_rest_rect(Rect2(rest.position - button.position, rest.size))
			if button.suggested and badges_shown():
				var x: float = clampf(rest.position.x + (width - _suggested_width) * 0.5, 0.0, size.x - _suggested_width)
				var rect: Rect2 = Rect2(x, rest.position.y - badge_height, _suggested_width, badge_height)
				_badge_rects.append(rect)
				_badge_origins.append(_text_origin(rect))
	if not _hint.is_empty():
		var hint_width: float = _text_width(_hint) + _skin.num(&"space_s") * 2.0
		var row: float = _skin.num(&"hint_height")
		var top: float = dock.position.y - row + (row - badge_height) * 0.5
		_hint_rect = Rect2((size.x - hint_width) * 0.5, top, hint_width, badge_height)
		_hint_origin = _text_origin(_hint_rect)


## Where a badge's text starts so it sits centered on the badge's face.
func _text_origin(rect: Rect2) -> Vector2:
	var line: float = _font.get_height(_font_size)
	return Vector2(rect.position.x, rect.position.y + (_badge_face - line) * 0.5 + _font.get_ascent(_font_size))


func _text_width(text: String) -> float:
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x


func _draw() -> void:
	if _skin == null:
		return
	draw_style_box(_dock_style, _dock_rect())
	if not _hint.is_empty():
		draw_style_box(_badge_style, _hint_rect)
		draw_string(_font, _hint_origin, _hint, HORIZONTAL_ALIGNMENT_CENTER, _hint_rect.size.x, _font_size, _badge_ink)


func _draw_badges() -> void:
	for i: int in _badge_rects.size():
		_badges.draw_style_box(_badge_style, _badge_rects[i])
		_badges.draw_string(_font, _badge_origins[i], _suggested_text, HORIZONTAL_ALIGNMENT_CENTER, _badge_rects[i].size.x, _font_size, _badge_ink)
