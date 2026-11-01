extends SkinToggle
## Gumdrop sound toggle (DESIGN_SYSTEM.md 4.7): a pill track toggle_w by
## toggle_h with a surface_lip lip, surface_raised when off and accent when
## on, and an ink candy knob (toggle_knob, with a toggle_knob_lip lip in
## surface_lip) that springs across with button_release. The control is at
## least touch_min on each side; the track is centered in it.

const Candy: GDScript = preload("res://src/design/gumdrop/gumdrop_candy.gd")

const TapInput: GDScript = preload("res://src/design/shared/tap_input.gd")

var _skin: SkinData = null
var _tap: TapInput = TapInput.new()
var _on: bool = false
## Knob travel, 0 off to 1 on. button_release springs past the ends.
var _t: float = 0.0
var _track: StyleBoxFlat = null
var _track_size: Vector2 = Vector2.ZERO
var _off_fill: Color = Color.BLACK
var _on_fill: Color = Color.BLACK
var _knob_color: Color = Color.WHITE
var _knob_lip_color: Color = Color.BLACK
var _tween: Tween = null


func _init() -> void:
	focus_mode = Control.FOCUS_NONE


func setup(skin: SkinData) -> void:
	_skin = skin
	_track_size = Vector2(skin.num(&"toggle_w"), skin.num(&"toggle_h"))
	_off_fill = skin.color(&"surface_raised")
	_on_fill = skin.color(&"accent")
	_knob_color = skin.color(&"ink")
	_knob_lip_color = skin.color(&"surface_lip")
	_track = Candy.raised(_off_fill, _knob_lip_color, _track_size.y * 0.5, skin.num(&"button_lip"))
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
	_track.bg_color = _off_fill.lerp(_on_fill, clampf(value, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	if _skin == null:
		return
	var track: Rect2 = Rect2(((size - _track_size) * 0.5).round(), _track_size)
	draw_style_box(_track, track)
	var knob_radius: float = _skin.num(&"toggle_knob") * 0.5
	var knob_lip: float = _skin.num(&"toggle_knob_lip")
	var face_height: float = _track_size.y - _skin.num(&"button_lip")
	var inset: float = face_height * 0.5 - knob_radius
	var left: float = track.position.x + inset + knob_radius
	var right: float = track.end.x - inset - knob_radius
	var center: Vector2 = Vector2(lerpf(left, right, _t), track.position.y + (face_height - knob_lip) * 0.5)
	draw_circle(center + Vector2(0.0, knob_lip), knob_radius, _knob_lip_color, true, -1.0, true)
	draw_circle(center, knob_radius, _knob_color, true, -1.0, true)


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
