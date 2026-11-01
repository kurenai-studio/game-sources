extends Control
## Gumdrop sound toggle: a chunky candy pill track with a lip and a round
## white candy knob. On is hot pink. The knob springs across with the
## button_release curve. The control is at least touch_min on each side.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal toggled(on: bool)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const ThemeKit: GDScript = preload("res://tools/directions/ui_common/theme_kit.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

var _tokens: DirectionTokens = null
var _on: bool = false
var _t: float = 0.0
var _track: StyleBoxFlat = null
## Track size at rest, lip included, from the toggle_track tokens.
var _track_size: Vector2 = Vector2.ZERO
var _tween: Tween = null


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	_track_size = Vector2(tokens.num("toggle_track_w"), tokens.num("toggle_track_h"))
	_track = ThemeKit.box(tokens.color("surface_raised"), _track_size.y * 0.5)
	_track.border_width_bottom = roundi(tokens.num("button_lip"))
	custom_minimum_size = Vector2(maxf(_track_size.x, tokens.num("touch_min")), maxf(_track_size.y, tokens.num("touch_min")))
	_set_t(1.0 if _on else 0.0)


func set_on(on: bool, animate: bool = false) -> void:
	_on = on
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target: float = 1.0 if on else 0.0
	if not animate or _tokens == null:
		_set_t(target)
		return
	_tween = Motion.tween_for(self, _tokens, "button_release")
	_tween.tween_method(_set_t, _t, target, _tokens.duration("button_release"))


func _set_t(value: float) -> void:
	_t = value
	if _tokens == null:
		return
	var mix: float = clampf(value, 0.0, 1.0)
	_track.bg_color = _tokens.color("surface_raised").lerp(_tokens.color("accent"), mix)
	_track.border_color = _tokens.color("surface_lip").lerp(_tokens.color("accent_lip"), mix)
	queue_redraw()


func _track_rect() -> Rect2:
	return Rect2((size - _track_size) * 0.5, _track_size)


func _draw() -> void:
	if _tokens == null:
		return
	var track: Rect2 = _track_rect()
	draw_style_box(_track, track)
	var knob: float = _tokens.num("toggle_knob")
	var knob_lip: float = _tokens.num("toggle_knob_lip")
	var face_height: float = _track_size.y - _tokens.num("button_lip")
	var inset: float = (face_height - knob) * 0.5
	var radius: float = knob * 0.5
	var left: float = track.position.x + inset + radius
	var right: float = track.end.x - inset - radius
	var center: Vector2 = Vector2(lerpf(left, right, _t), track.position.y + face_height * 0.5 - knob_lip * 0.5)
	draw_circle(center + Vector2(0.0, knob_lip), radius, _tokens.color("ink_soft"), true, -1.0, true)
	draw_circle(center, radius, _tokens.color("ink"), true, -1.0, true)


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT or _tokens == null:
		return
	accept_event()
	if not button.pressed and Rect2(Vector2.ZERO, size).has_point(button.position):
		set_on(not _on, true)
		toggled.emit(_on)
