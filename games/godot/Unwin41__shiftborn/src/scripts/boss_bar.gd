class_name BossBar
extends Control
## Boss health bar at the top of the HUD. The fill takes the color of the
## form that currently beats the boss, and flashes when it swaps.

const BOSS_NAME := "THE SHIFTING DEMON"
const BAR_WIDTH := 280.0
const BAR_HEIGHT := 7.0
const FONT_SIZE := 8
const NAME_GAP := 2.0
const FLASH_TIME := 0.35
const BACKGROUND := Color(0.06, 0.05, 0.1, 0.9)
const FRAME := Color(0.85, 0.8, 0.95)
const FLASH_COLOR := Color.WHITE

var _fraction: float = 1.0
var _weak_form: int = 0
var _flash: float = 0.0


static func fraction(current: float, maximum: float) -> float:
	if maximum <= 0.0:
		return 0.0
	return clampf(current / maximum, 0.0, 1.0)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_boss(current: float, maximum: float, weak_form: int) -> void:
	if weak_form != _weak_form and visible:
		_flash = FLASH_TIME
	_fraction = fraction(current, maximum)
	_weak_form = weak_form
	show()


func _process(delta: float) -> void:
	if not visible:
		return
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var name_height := font.get_height(FONT_SIZE)
	draw_string(font, Vector2(0.0, font.get_ascent(FONT_SIZE)), BOSS_NAME, HORIZONTAL_ALIGNMENT_CENTER, size.x, FONT_SIZE, FRAME)
	var bar := Rect2(Vector2((size.x - BAR_WIDTH) * 0.5, name_height + NAME_GAP), Vector2(BAR_WIDTH, BAR_HEIGHT))
	draw_rect(bar.grow(1.0), BACKGROUND)
	var color := Player.ui_color(_weak_form).lerp(FLASH_COLOR, _flash / FLASH_TIME)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _fraction, bar.size.y)), color)
	draw_rect(bar.grow(1.0), FRAME, false, 1.0)
