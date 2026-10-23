extends Node


func set_distortion_effect(index: int) -> void:
	match index:
		0: _set_distortion_effect(true, Color.LIGHT_SKY_BLUE)
		1: _set_distortion_effect(true, Color.CHARTREUSE)
		2: _set_distortion_effect(true, Color.ORANGE_RED)
		_: _set_distortion_effect(false, Color.WHITE)


func _set_distortion_effect(enabled: bool, color: Color) -> void:
	$DISTORTION.material.set_shader_parameter("tint", color)
	$DISTORTION.visible = enabled


func _ready() -> void:
	set_distortion_effect(-1)
