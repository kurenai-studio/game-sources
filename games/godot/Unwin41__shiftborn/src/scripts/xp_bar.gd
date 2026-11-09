class_name XpBar
extends Control
## HUD experience bar with the level written on it. The fill eases toward
## the real value and the bar flashes on level-up.

const BAR_HEIGHT := 10.0
const BORDER_WIDTH := 1.0
const FONT_SIZE := 8
## Fill easing rate per second (exponential).
const FILL_RATE := 10.0
const FLASH_TIME := 0.45
const BACKGROUND_COLOR := Color(0.06, 0.05, 0.1, 0.85)
const BORDER_COLOR := Color(0.55, 0.5, 0.7)
const FILL_COLOR := Color(0.3, 0.7, 1.0)
const FILL_TOP_COLOR := Color(0.6, 0.88, 1.0)
const FLASH_COLOR := Color(1.0, 0.95, 0.7)
const TEXT_COLOR := Color.WHITE
const TEXT_OUTLINE_COLOR := Color(0.02, 0.02, 0.06)

var _level: int = 1
var _target: float = 0.0
var _shown: float = 0.0
var _flash: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_progress(level: int, progress: float) -> void:
	if level > _level:
		_shown = 0.0
		_flash = FLASH_TIME
	_level = level
	_target = clampf(progress, 0.0, 1.0)


func shown_fill() -> float:
	return _shown


func is_flashing() -> bool:
	return _flash > 0.0


func label_text() -> String:
	return "Lv %d" % _level


## Advances easing and flash by [param delta] seconds.
func tick(delta: float) -> void:
	_shown = lerpf(_shown, _target, 1.0 - exp(-FILL_RATE * delta))
	_flash = maxf(_flash - delta, 0.0)


func _process(delta: float) -> void:
	tick(delta)
	queue_redraw()


func _draw() -> void:
	var bar := Rect2(Vector2.ZERO, Vector2(size.x, BAR_HEIGHT))
	draw_rect(bar, BACKGROUND_COLOR)
	var inner := bar.grow(-BORDER_WIDTH)
	var fill := Rect2(inner.position, Vector2(inner.size.x * _shown, inner.size.y))
	var flash := _flash / FLASH_TIME
	draw_rect(fill, FILL_COLOR.lerp(FLASH_COLOR, flash))
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), FILL_TOP_COLOR.lerp(FLASH_COLOR, flash))
	if flash > 0.0:
		draw_rect(inner, Color(FLASH_COLOR, 0.35 * flash))
	draw_rect(bar, BORDER_COLOR.lerp(FLASH_COLOR, flash), false, BORDER_WIDTH)
	var font := get_theme_default_font()
	var baseline := (BAR_HEIGHT + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) * 0.5
	var at := Vector2(0.0, baseline)
	var text := label_text().to_upper()
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, FONT_SIZE, 3, TEXT_OUTLINE_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, FONT_SIZE, TEXT_COLOR)
