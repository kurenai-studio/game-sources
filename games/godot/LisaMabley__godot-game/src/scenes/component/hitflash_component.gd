extends Node

@export var health_component: Node
@export var sprite: Sprite2D
@export var hitflash_material: ShaderMaterial

var hitflash_tween: Tween
var hitflash_material_instance: ShaderMaterial

func _ready():
	health_component.health_changed.connect(_on_health_changed)
	hitflash_material_instance = hitflash_material.duplicate() as ShaderMaterial
	hitflash_material_instance.set_shader_parameter("lerp_percent", 0.0)
	sprite.material = hitflash_material_instance


func _on_health_changed():
	if hitflash_tween != null && hitflash_tween.is_valid():
		hitflash_tween.kill()
	
	hitflash_material_instance.set_shader_parameter("lerp_percent", 1.0)
	hitflash_tween = create_tween()
	hitflash_tween.set_ease(Tween.EASE_IN)
	hitflash_tween.set_trans(Tween.TRANS_CUBIC)
	hitflash_tween.tween_method(_set_lerp_percent, 1.0, 0.0, 0.25)


func _set_lerp_percent(value: float) -> void:
	hitflash_material_instance.set_shader_parameter("lerp_percent", value)
