extends SkinToggle
## Nova sound toggle (DESIGN_SYSTEM.md 6.7): a thin ring track toggle_w by
## toggle_h, ring_width wide, in line, with a round toggle_knob knob.
##   Off: a disabled_ink knob on the left.
##   On: an accent knob on the right with a glow (toggle_glow_spread,
##     toggle_glow_alpha), and the track ring turns accent.
## The knob glides on button_release. The control is at least touch_min on
## each side; the track is centered in it.

const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")
const Glow: GDScript = preload("res://src/design/shared/glow.gd")

const TapInput: GDScript = preload("res://src/design/shared/tap_input.gd")

var _skin: SkinData = null
var _tap: TapInput = TapInput.new()
var _on: bool = false
var _t: float = 0.0
var _track: StyleBoxFlat = null
var _track_size: Vector2 = Vector2.ZERO
var _knob_color: Color = Color.WHITE
var _glow_color: Color = Color.TRANSPARENT
var _tween: Tween = null


func _init() -> void:
	focus_mode = Control.FOCUS_NONE


func setup(skin: SkinData) -> void:
	_skin = skin
	_track_size = Vector2(skin.num(&"toggle_w"), skin.num(&"toggle_h"))
	_track = ThemeKit.outline(skin.color(&"line"), skin.num(&"ring_width"), _track_size.y * 0.5)
	var touch: float = skin.num(&"touch_min")
	custom_minimum_size = Vector2(maxf(_track_size.x, touch), maxf(_track_size.y, touch))
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = custom_minimum_size
	_set_t(1.0 if _on else 0.0)


func set_on(on: bool, animate: bool = false) -> void:
	_on = on
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target: float = 1.0 if on else 0.0
	if not animate or _skin == null:
		_set_t(target)
		return
	_tween = Motion.tween_for(self, _skin, &"button_release")
	_tween.tween_method(_set_t, _t, target, _skin.duration(&"button_release"))


## Whether it shows on.
func is_on() -> bool:
	return _on


func _set_t(value: float) -> void:
	_t = value
	if _skin == null:
		return
	var mix: float = clampf(value, 0.0, 1.0)
	var accent: Color = _skin.color(&"accent")
	_track.border_color = _skin.color(&"line").lerp(accent, mix)
	_knob_color = _skin.color(&"disabled_ink").lerp(accent, mix)
	_glow_color = Color(accent, _skin.num(&"toggle_glow_alpha") * mix)
	queue_redraw()


func _draw() -> void:
	if _skin == null:
		return
	var track: Rect2 = Rect2((size - _track_size) * 0.5, _track_size)
	draw_style_box(_track, track)
	var radius: float = _skin.num(&"toggle_knob") * 0.5
	var inset: float = _track_size.y * 0.5 - radius
	var left: float = track.position.x + inset + radius
	var right: float = track.end.x - inset - radius
	var center: Vector2 = Vector2(lerpf(left, right, _t), track.get_center().y)
	if _glow_color.a > 0.0:
		Glow.draw(self, center, radius * _skin.num(&"toggle_glow_spread"), _glow_color)
	draw_circle(center, radius, _knob_color, true, -1.0, true)


func _gui_input(event: InputEvent) -> void:
	if _skin == null:
		return
	# One tap rule for every design control (QA6-01): never the copies of
	# Godot's mouse and touch emulation.
	var read: int = _tap.read(event, size)
	if read == TapInput.IGNORED:
		return
	accept_event()
	if read == TapInput.TAPPED:
		set_on(not _on, true)
		toggled.emit(_on)
