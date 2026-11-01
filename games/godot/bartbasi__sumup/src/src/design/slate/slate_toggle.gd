extends SkinToggle
## Slate sound toggle (DESIGN_SYSTEM.md 5.7): a rectangular track toggle_w by
## toggle_h with a square knob (track height less toggle_knob_inset on each
## side), hard edges.
##   On: the track fills ink (the paper), the ink_dark knob sits right, and
##     "ON" in the label role, ink_dark, sits inside the track on the left.
##   Off: the track is bg with a hairline outline in line, the ink_muted knob
##     sits left, and "OFF" in ink_muted sits inside on the right.
## The word and the fill both change, so the state reads without color. The
## knob moves on button_release; fill and word cut over at half way, since
## Slate steps and never blends.
## Text pairs: ink_dark on ink, ink_muted on bg.

const TapInput: GDScript = preload("res://src/design/shared/tap_input.gd")

var _skin: SkinData = null
var _tap: TapInput = TapInput.new()
var _on: bool = false
var _t: float = 0.0
var _track_size: Vector2 = Vector2.ZERO
var _font: Font = null
var _font_size: int = 1
var _on_word: String = ""
var _off_word: String = ""
var _on_width: float = 0.0
var _off_width: float = 0.0
var _tween: Tween = null


func _init() -> void:
	focus_mode = Control.FOCUS_NONE


func setup(skin: SkinData) -> void:
	_skin = skin
	_track_size = Vector2(skin.num(&"toggle_w"), skin.num(&"toggle_h"))
	_font = skin.font(&"label")
	_font_size = skin.font_size(&"label")
	_on_word = skin.cased(&"label", "On")
	_off_word = skin.cased(&"label", "Off")
	_on_width = _font.get_string_size(_on_word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x
	_off_width = _font.get_string_size(_off_word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x
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


## The word showing now. For tests.
func word() -> String:
	return _on_word if _t >= 0.5 else _off_word


func _set_t(value: float) -> void:
	_t = value
	queue_redraw()


func _draw() -> void:
	if _skin == null:
		return
	var track: Rect2 = Rect2(((size - _track_size) * 0.5).round(), _track_size)
	var inset: float = _skin.num(&"toggle_knob_inset")
	var knob_side: float = _track_size.y - inset * 2.0
	var left: float = track.position.x + inset
	var right: float = track.end.x - inset - knob_side
	var knob: Rect2 = Rect2(roundf(lerpf(left, right, _t)), track.position.y + inset, knob_side, knob_side)
	var line: float = _font.get_height(_font_size)
	var baseline: float = track.position.y + (track.size.y - line) * 0.5 + _font.get_ascent(_font_size)
	if _t >= 0.5:
		draw_rect(track, _skin.color(&"ink"))
		draw_rect(knob, _skin.color(&"ink_dark"))
		# The word centered between the track's left edge and the knob.
		var space: float = knob.position.x - track.position.x
		draw_string(_font, Vector2(track.position.x + (space - _on_width) * 0.5, baseline), _on_word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _skin.color(&"ink_dark"))
	else:
		var hairline: float = _skin.num(&"hairline")
		draw_rect(track, _skin.color(&"bg"))
		draw_rect(track.grow(-hairline * 0.5), _skin.color(&"line"), false, hairline)
		draw_rect(knob, _skin.color(&"ink_muted"))
		# The word centered between the knob and the track's right edge.
		var space: float = track.end.x - knob.end.x
		draw_string(_font, Vector2(knob.end.x + (space - _off_width) * 0.5, baseline), _off_word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _skin.color(&"ink_muted"))


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
