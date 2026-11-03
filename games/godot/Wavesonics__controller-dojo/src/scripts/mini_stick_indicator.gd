extends Control

const StickInput := preload("res://scripts/stick_input.gd")
const StickRegions := preload("res://scripts/stick_regions.gd")

const RADIUS := 46.0
const DRIFT_DEADZONE := 0.09
const CURSOR_RADIUS := 7.0

const FIELD_COLOR := Color(0.11, 0.14, 0.25)
const BAND_COLOR := Color(0.15, 0.19, 0.33)
const CORE_COLOR := Color(0.09, 0.11, 0.2)
const GUIDE_COLOR := Color(0.22, 0.27, 0.44)
const IDLE_COLOR := Color(0.42, 0.48, 0.6)
const TIER_COLORS := [Color(0.42, 0.86, 1.0), Color(0.55, 1.0, 0.62), Color(1.0, 0.58, 0.32)]

var device: int = -1
var stick: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * (RADIUS * 2.0 + 12.0)


func _process(_delta: float) -> void:
	var current := StickInput.read(device, DRIFT_DEADZONE)
	if not current.is_equal_approx(stick):
		stick = current
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, RADIUS, BAND_COLOR)
	draw_circle(center, StickRegions.EDGES[2] * RADIUS, FIELD_COLOR)
	draw_circle(center, StickRegions.EDGES[1] * RADIUS, BAND_COLOR)
	draw_circle(center, StickRegions.EDGES[0] * RADIUS, CORE_COLOR)
	for i in 3:
		draw_arc(center, StickRegions.EDGES[i + 1] * RADIUS, 0.0, TAU, 40, GUIDE_COLOR, 1.0, true)

	var ring := StickRegions.ring_for(stick.length())
	var color: Color = TIER_COLORS[ring] if ring >= 0 else IDLE_COLOR
	var point := center + stick * RADIUS
	var glow := color
	glow.a = 0.3
	draw_circle(point, CURSOR_RADIUS * 1.8, glow)
	draw_circle(point, CURSOR_RADIUS, color)
