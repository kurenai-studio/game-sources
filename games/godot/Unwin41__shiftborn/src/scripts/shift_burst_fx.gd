class_name ShiftBurstFx
extends Node2D
## Expanding ring drawn once when the Shift Burst upgrade fires.

const DURATION := 0.25
const COLOR := Color(0.6, 0.85, 1.0)
const LINE_WIDTH := 3.0
const SEGMENTS := 48
const GLOW_BOOST := 3.0
const UNSHADED := preload("res://assets/fx/unshaded.tres")
const LIGHT_TEXTURE := preload("res://assets/fx/light_radial.tres")
const LIGHT_ENERGY := 1.4
## The light texture is 128 px wide, so this maps radius to texture scale.
const LIGHT_TEXTURE_RADIUS := 64.0

var radius: float = 64.0

var _time: float = 0.0
var _light: PointLight2D


static func create(burst_radius: float) -> ShiftBurstFx:
	var fx := ShiftBurstFx.new()
	fx.radius = burst_radius
	return fx


func _ready() -> void:
	material = UNSHADED
	_light = PointLight2D.new()
	_light.texture = LIGHT_TEXTURE
	_light.texture_scale = radius * 1.5 / LIGHT_TEXTURE_RADIUS
	_light.color = COLOR
	_light.energy = LIGHT_ENERGY
	add_child(_light)


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
	_light.energy = LIGHT_ENERGY * (1.0 - minf(_time / DURATION, 1.0))
	queue_redraw()


func _draw() -> void:
	var t := minf(_time / DURATION, 1.0)
	draw_arc(Vector2.ZERO, radius * t, 0.0, TAU, SEGMENTS, Color(Quality.glow(COLOR, GLOW_BOOST), 1.0 - t), LINE_WIDTH)
