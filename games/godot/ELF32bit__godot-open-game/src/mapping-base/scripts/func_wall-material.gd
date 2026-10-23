@tool
extends Material

@export var alternative_texture: int = 0:
	set(value):
		_update_alternative_texture(value)
		alternative_texture = value

func _update_alternative_texture(value: int) -> void:
	var textures := get_alternative_textures()
	if is_class("BaseMaterial3D"):
		for slot in textures:
			call("set_texture", slot, textures[slot][
				posmod(value, textures[slot].size())])
	elif is_class("ShaderMaterial"):
		for slot in textures:
			call("set_shader_parameter", slot, textures[slot][
				posmod(value, textures[slot].size())])

@export_range(-60.0, 60.0) var alternative_speed_scale: float = 1.0:
	set(value):
		_update_alternative_textures_speed_scale(value)
		alternative_speed_scale = value

func _update_alternative_textures_speed_scale(value: float) -> void:
	var textures := get_alternative_textures()
	for slot_textures in textures.values():
		for slot_texture in slot_textures:
			if slot_texture is AnimatedTexture:
				slot_texture.speed_scale = value

# validating alternative textures in material metadata
func get_alternative_textures(meta: StringName = "alternative_textures") -> Dictionary:
	var textures: Variant = get_meta(meta, {})
	if typeof(textures) != TYPE_DICTIONARY:
		return {}

	var is_base_material := false
	var is_shader_material := false
	for slot in textures:
		if slot is int: is_base_material = true
		elif slot is String or slot is StringName:
			is_shader_material = true

		if is_base_material:
			if slot < 0: return {}
			if slot >= BaseMaterial3D.TEXTURE_MAX:
				return {}

		if not is_base_material and not is_shader_material: return {}
		if is_base_material and is_shader_material: return {}
		if typeof(textures[slot]) != TYPE_ARRAY: return {}

		for slot_texture in textures[slot]:
			if not slot_texture is Texture2D:
				return {}

	return textures
