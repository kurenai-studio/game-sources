class_name EnergyBars
extends Control
## HUD panel at the bottom center: one energy bar per form with its icon
## and name. The active form is bright with a highlighted frame; the
## resting one is dimmed. See [FormEnergy].

const BAR_SIZE := Vector2(84.0, 6.0)
const ICON_BOX := 14.0
const ICON_GAP := 4.0
## Space between the two halves of the panel.
const CENTER_GAP := 16.0
const LABEL_GAP := 3.0
const FONT_SIZE := 8
const BACKGROUND := Color(0.06, 0.05, 0.1, 0.85)
const FRAME_IDLE := Color(0.35, 0.32, 0.45)
const IDLE_ALPHA := 0.4
const KNIGHT_ICON := preload("res://assets/ninja/weapons/axe.png")
const MAGE_ICON := preload("res://assets/ninja/weapons/magic_wand.png")
const NAMES: PackedStringArray = ["WARRIOR", "MAGE"]

var _levels: PackedFloat32Array = [1.0, 1.0]
var _active: int = 0


static func panel_size() -> Vector2:
	var half := ICON_BOX + ICON_GAP + BAR_SIZE.x
	return Vector2(half * 2.0 + CENTER_GAP, ICON_BOX + LABEL_GAP + FONT_SIZE)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = panel_size()


func show_levels(knight_level: float, mage_level: float, active: Player.Form) -> void:
	if is_equal_approx(knight_level, _levels[0]) and is_equal_approx(mage_level, _levels[1]) and active == _active:
		return
	_levels[0] = clampf(knight_level, 0.0, 1.0)
	_levels[1] = clampf(mage_level, 0.0, 1.0)
	_active = active
	queue_redraw()


func level_of(form: int) -> float:
	return _levels[form]


func active_form() -> int:
	return _active


func _draw() -> void:
	var origin := Vector2((size.x - panel_size().x) * 0.5, 0.0)
	var half := ICON_BOX + ICON_GAP + BAR_SIZE.x
	# Warrior on the left (icon, then bar); mage on the right (bar, then icon).
	_draw_half(Player.Form.KNIGHT, origin, false)
	_draw_half(Player.Form.MAGE, origin + Vector2(half + CENTER_GAP, 0.0), true)


func _draw_half(form: int, at: Vector2, icon_on_right: bool) -> void:
	var active := form == _active
	var color := Player.ui_color(form)
	var alpha := 1.0 if active else IDLE_ALPHA
	var icon_x := at.x + BAR_SIZE.x + ICON_GAP if icon_on_right else at.x
	var bar_x := at.x if icon_on_right else at.x + ICON_BOX + ICON_GAP
	_draw_icon(KNIGHT_ICON if form == Player.Form.KNIGHT else MAGE_ICON, Rect2(icon_x, at.y, ICON_BOX, ICON_BOX), alpha)
	var bar := Rect2(Vector2(bar_x, at.y + (ICON_BOX - BAR_SIZE.y) * 0.5), BAR_SIZE)
	draw_rect(bar.grow(1.0), BACKGROUND)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _levels[form], bar.size.y)), Color(color, alpha))
	draw_rect(bar.grow(1.0), color if active else FRAME_IDLE, false, 1.0)
	var font := get_theme_default_font()
	var label_y := at.y + ICON_BOX + LABEL_GAP + font.get_ascent(FONT_SIZE)
	var label_color := Color(color, alpha) if active else FRAME_IDLE
	draw_string(font, Vector2(bar.position.x, label_y), NAMES[form], HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, FONT_SIZE, label_color)


## Draws [param texture] scaled to fit [param box], keeping its aspect.
func _draw_icon(texture: Texture2D, box: Rect2, alpha: float) -> void:
	var texture_size := texture.get_size()
	var scale_factor := minf(box.size.x / texture_size.x, box.size.y / texture_size.y)
	var drawn := texture_size * scale_factor
	draw_texture_rect(texture, Rect2(box.position + (box.size - drawn) * 0.5, drawn), false, Color(1, 1, 1, alpha))
