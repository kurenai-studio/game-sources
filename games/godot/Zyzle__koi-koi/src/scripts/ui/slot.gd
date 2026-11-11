class_name Slot
extends Node2D

const HIGHLIGHT_SHADER_PATH = "res://shaders/card_highlight_shader.gdshader"

var card_visual: CardVisual

@onready var outline = $Outline

func is_occupied() -> bool:
	return card_visual != null


func apply_highlight() -> void:
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload(HIGHLIGHT_SHADER_PATH)
	shader_material.set_shader_parameter("color", Color.YELLOW)
	shader_material.set_shader_parameter("inner_stroke_thickness", 20.0)
	shader_material.set_shader_parameter("frequency", 9.0)
	shader_material.set_shader_parameter("phase_speed", 8.0)
	outline.material = shader_material


func remove_highlight() -> void:
	outline.material = null