extends Control
## Slate sound toggle: a rectangular track with a square knob, hard edges.
## Off is a rule outline with an ink_muted knob; on fills the track with
## paper and the knob turns ink_dark, like a selected chip. The knob moves
## with the fast button_release curve. The control is at least touch_min
## on each side.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal toggled(on: bool)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

var _tokens: DirectionTokens = null
var _on: bool = false
var _t: float = 0.0
## Track size from the toggle_track tokens.
var _track_size: Vector2 = Vector2.ZERO
var _tween: Tween = null


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	_track_size = Vector2(tokens.num("toggle_track_w"), tokens.num("toggle_track_h"))
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
	queue_redraw()


func _draw() -> void:
	if _tokens == null:
		return
	var track: Rect2 = Rect2(((size - _track_size) * 0.5).round(), _track_size)
	var rule: float = _tokens.num("rule_width")
	var inset: float = _tokens.num("toggle_knob_inset")
	var knob_side: float = _track_size.y - inset * 2.0
	var left: float = track.position.x + inset
	var right: float = track.end.x - inset - knob_side
	var knob: Rect2 = Rect2(roundf(lerpf(left, right, _t)), track.position.y + inset, knob_side, knob_side)
	# The paper fill cuts in at the halfway point: Slate steps, it does not blend.
	if _t >= 0.5:
		draw_rect(track, _tokens.color("ink"))
		draw_rect(knob, _tokens.color("ink_dark"))
	else:
		draw_rect(track.grow(-rule * 0.5), _tokens.color("rule"), false, rule)
		draw_rect(knob, _tokens.color("ink_muted"))


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT or _tokens == null:
		return
	accept_event()
	if not button.pressed and Rect2(Vector2.ZERO, size).has_point(button.position):
		set_on(not _on, true)
		toggled.emit(_on)
