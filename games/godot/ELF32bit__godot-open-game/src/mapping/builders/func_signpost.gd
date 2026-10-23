extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: AnimatableBody3D = null
	node = create_merged_brush_entity(entity, "AnimatableBody3D")
	if not node: return null

	node.set_script(map.loader.load_script("scripts/func_signpost"))
	node.set("mouse_cursor_override", entity.get_int_property("cursor", 1))
	node.set("hover_text", entity.get_string_property("message", ""))

	var gui_label := build_gui_label("GUI_LABEL")
	node.add_child(gui_label, map.settings.readable_node_names)
	node.set("_gui_label", node.get_path_to(gui_label))

	return node


static func build_gui_label(name: String = "") -> Node3D:
	var scene := "res://interfaces/scenes/waypoint.tscn"
	var gui_label: Node3D = load(scene).instantiate()
	if not name.is_empty():
		gui_label.name = name

	gui_label.text = ""
	gui_label.visible = false
	gui_label.sticky = false

	return gui_label


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_signpost", ":",
		'"road sign with on hover text"',
		"[",
			"\n\tmessage(string)", ":", '"text to display on hover"',
			"\n\tcursor(integer)", ":", '"mouse cursor override"', ":", "1",
		"\n]\n",
	]).replace(" \n", "\n"))
