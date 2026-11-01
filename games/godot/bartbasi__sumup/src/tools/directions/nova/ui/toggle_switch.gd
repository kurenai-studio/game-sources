extends Control
## Nova sound toggle: a thin ring track with a round knob. Off is a ring
## colored track with an ink_muted knob; on turns the track aurora cyan and
## the knob lights up with a soft glow. The knob glides with the sine
## button_release curve. The control is at least touch_min on each side.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal toggled(on: bool)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const ThemeKit: GDScript = preload("res://tools/directions/ui_common/theme_kit.gd")
const Glow: GDScript = preload("res://tools/directions/ui_common/glow.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

var _tokens: DirectionTokens = null
var _on: bool = false
var _t: float = 0.0
var _track: StyleBoxFlat = null
## Track size from the toggle_track tokens.
var _track_size: Vector2 = Vector2.ZERO
var _knob_color: Color = Color.WHITE
var _glow_color: Color = Color.TRANSPARENT
var _tween: Tween = null


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	_track_size = Vector2(tokens.num("toggle_track_w"), tokens.num("toggle_track_h"))
	_track = ThemeKit.box(Color(tokens.color("ring"), 0.0), _track_size.y * 0.5)
	_track.draw_center = false
	_track.set_border_width_all(roundi(tokens.num("ring_width")))
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
	_track.border_color = _tokens.color("ring").lerp(_tokens.color("accent"), _t)
	_knob_color = _tokens.color("ink_muted").lerp(_tokens.color("accent"), _t)
	_glow_color = Color(_tokens.color("accent"), _tokens.num("toggle_glow_alpha") * _t)
	queue_redraw()


func _draw() -> void:
	if _tokens == null:
		return
	var track: Rect2 = Rect2((size - _track_size) * 0.5, _track_size)
	draw_style_box(_track, track)
	var knob: float = _tokens.num("toggle_knob")
	var radius: float = knob * 0.5
	var inset: float = (_track_size.y - knob) * 0.5
	var left: float = track.position.x + inset + radius
	var right: float = track.end.x - inset - radius
	var center: Vector2 = Vector2(lerpf(left, right, _t), track.get_center().y)
	if _t > 0.0:
		Glow.draw(self, center, radius * _tokens.num("toggle_glow_spread"), _glow_color)
	draw_circle(center, radius, _knob_color, true, -1.0, true)


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT or _tokens == null:
		return
	accept_event()
	if not button.pressed and Rect2(Vector2.ZERO, size).has_point(button.position):
		set_on(not _on, true)
		toggled.emit(_on)
