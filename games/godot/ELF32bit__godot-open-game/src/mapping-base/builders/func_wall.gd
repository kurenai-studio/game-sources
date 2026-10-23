extends MapperUtilities

const BASE_CLASS_TARGETNAME := true
const MESH_PROPERTIES: Dictionary = {
	"cast_shadow": MeshInstance3D.SHADOW_CASTING_SETTING_OFF,
}

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: AnimatableBody3D = null
	node = create_merged_brush_entity(entity, "AnimatableBody3D")
	if not node: return null

	var material_script := map.loader.load_script(
		"scripts/func_wall-material")

	var alternative_textures_size: int = -1
	var animated_materials: Array[Material] = []
	for child in node.get_children():
		if not (child is MeshInstance3D and child.mesh): continue
		for index in range(child.mesh.get_surface_count()):
			var base_material: Material = null
			base_material = child.mesh.surface_get_material(index)
			var size := _get_material_alternative_textures_size(map, base_material)
			if alternative_textures_size == -1 and size > 0:
				alternative_textures_size = size
			if alternative_textures_size == -1:
				continue

			# creating unique base material
			var unique_base_material := _create_unique_material(map,
				base_material, alternative_textures_size)

			if unique_base_material and unique_base_material != base_material:
				child.mesh.surface_set_material(index, unique_base_material)
				unique_base_material.set_script(material_script)
				animated_materials.append(unique_base_material)

			# creating unique override material
			var override_material: Material = null
			override_material = child.get_surface_override_material(index)
			var unique_override_material := _create_unique_material(map,
				override_material, alternative_textures_size)

			if unique_override_material and unique_override_material != override_material:
				child.set_surface_override_material(index, unique_override_material)
				unique_override_material.set_script(material_script)
				animated_materials.append(unique_override_material)

	node.set_script(map.loader.load_script("scripts/func_wall"))
	node.set("alternative_textures_size", alternative_textures_size)
	node.set("affected_materials", animated_materials)

	return node


static func _get_material_alternative_textures_size(map: MapperMap, material: Material) -> int:
	var property := map.settings.alternative_textures_metadata_property
	var alternative_textures: Dictionary = material.get_meta(property, {})
	for slot in alternative_textures:
		if alternative_textures[slot].size() > 0:
			return alternative_textures[slot].size()
	return 0


static func _create_unique_material(map: MapperMap, material: Material, alternative_textures_size: int) -> Material:
	if not material: return null
	if not alternative_textures_size > 0: return material
	var property := map.settings.alternative_textures_metadata_property
	var alternative_textures: Dictionary = material.get_meta(property, {})
	if not alternative_textures.size(): return material

	# ignoring materials with texture slots of different sizes
	for slot in alternative_textures:
		if not alternative_textures[slot].size() > 0: continue
		if alternative_textures[slot].size() != alternative_textures_size:
			return material

	# creating unique material instance with unique animated textures
	var unique_material := material.duplicate()
	var unique_slot_textures: Dictionary = {}

	for slot in alternative_textures:
		var unique_textures: Array[Texture2D] = []
		for alternative_texture in alternative_textures[slot]:
			# duplicating animated textures in material metadata
			if alternative_texture is AnimatedTexture:
				unique_textures.append(alternative_texture.duplicate())
			else:
				unique_textures.append(alternative_texture)
				continue

			# also replacing material animated texture for the current slot
			var material_texture: Texture2D
			if unique_material is BaseMaterial3D:
				material_texture = unique_material.get_texture(slot)
				if material_texture and material_texture == alternative_texture:
					unique_material.set_texture(slot, unique_textures[-1])
			elif unique_material is ShaderMaterial:
				material_texture = unique_material.get_shader_parameter(slot)
				if material_texture and material_texture == alternative_texture:
					unique_material.set_shader_parameter(slot, unique_textures[-1])
		unique_slot_textures[slot] = unique_textures

	if unique_slot_textures.size() == 0: return material
	unique_material.set_meta(property, unique_slot_textures)
	return unique_material


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_wall", ":",
		'"wall with alternative textures"',
		"[",
			"\n\ttargetname(target_source)", ":", '"entity name"',
		"\n]\n",
	]).replace(" \n", "\n"))
