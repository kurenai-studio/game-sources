@tool
extends Node

@export var alternative_texture: int = 0:
	set(value):
		for affected_material in affected_materials:
			if affected_material: affected_material.set(
				"alternative_texture", value)
		alternative_texture = value

@export_range(-60.0, 60.0) var alternative_speed_scale: float = 1.0:
	set(value):
		for affected_material in affected_materials:
			if affected_material: affected_material.set(
				"alternative_speed_scale", value)
		alternative_speed_scale = value

@export var affected_materials: Array[Material] = []
@export var alternative_textures_size: int = 0


func _ready() -> void:
	self.alternative_texture = alternative_texture
	self.alternative_speed_scale = alternative_speed_scale

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	alternative_texture += 1
