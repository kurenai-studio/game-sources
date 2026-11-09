extends Control
## Serve power meter shown over the ball while a serve key is held: a needle
## swinging across the bar and a yellow sweet zone. main.gd drives `needle`,
## `zone_c`, `zone_w` and `charge` (0..1); the longer the hold, the faster the
## needle, the narrower and twitchier the zone.

const C_INK := Color(0.040, 0.050, 0.100)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_ZONE := Color(0.980, 0.800, 0.250)
const C_ORANGE := Color(0.980, 0.520, 0.150)
const C_BAR := Color(0.15, 0.19, 0.32)
const C_RED := Color(0.900, 0.080, 0.120)

var needle := 0.5
var zone_c := 0.5
var zone_w := 0.3
var charge := 0.0
var cap := 1.0             # stamina limit on the charge; pips beyond it are locked


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(170.0, 34.0)


func _process(_delta: float) -> void:
	queue_redraw()


func in_zone() -> bool:
	return absf(needle - zone_c) <= zone_w * 0.5


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(C_INK, 0.85))
	var bar := Rect2(Vector2(8.0, 8.0), Vector2(size.x - 16.0, 12.0))
	draw_rect(bar, C_BAR)
	var z0 := bar.position.x + bar.size.x * clampf(zone_c - zone_w * 0.5, 0.0, 1.0)
	var z1 := bar.position.x + bar.size.x * clampf(zone_c + zone_w * 0.5, 0.0, 1.0)
	draw_rect(Rect2(Vector2(z0, bar.position.y), Vector2(z1 - z0, bar.size.y)), C_ZONE)
	draw_rect(bar, C_DIM, false, 1.0)
	var nx := bar.position.x + bar.size.x * clampf(needle, 0.0, 1.0)
	var ncol := C_WHITE if not in_zone() else C_INK
	draw_rect(Rect2(Vector2(nx - 1.5, bar.position.y - 5.0), Vector2(3.0, bar.size.y + 10.0)), ncol)
	draw_colored_polygon(PackedVector2Array([Vector2(nx, bar.position.y - 1.0), Vector2(nx - 5.0, bar.position.y - 7.0), Vector2(nx + 5.0, bar.position.y - 7.0)]), ncol)
	# charge pips: how much spin is on offer (and how wild the needle is)
	for i in 5:
		var lit := charge >= (i + 1) / 5.0 - 0.001
		var locked := (i + 1) / 5.0 > cap + 0.001
		var pip := Rect2(Vector2(8.0 + i * 12.0, 25.0), Vector2(9.0, 5.0))
		draw_rect(pip, C_ORANGE if lit else C_BAR)
		if locked:
			draw_rect(pip, C_RED, false, 1.0)
