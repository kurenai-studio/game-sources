extends RefCounted

const ITEM_ICON_TEXTURES: Dictionary = {
	&"laser": preload("res://textures/items/laser1.png"),
	&"laser_rate": preload("res://textures/items/laser1_rate.png"),
	&"battery": preload("res://textures/items/battery.png"),
	&"drone": preload("res://textures/items/drone.png"),
	&"homing_missile": preload("res://textures/items/homing_missile.png"),
	&"radar": preload("res://textures/items/radar.png"),
	&"repairset": preload("res://textures/items/repairset.png"),
	&"invisibility": preload("res://textures/items/invisibility.png"),
	&"xpbox": preload("res://textures/items/box.png"),
	&"wormhole_dash": preload("res://textures/artifacts/wormhole-dash.png"),
	&"vortex": preload("res://textures/artifacts/vortex.png"),
	&"nuke": preload("res://textures/artifacts/nuke.png"),
	&"explorer_beacon": preload("res://textures/artifacts/explorer-beacon.png"),
	&"colony_beacon": preload("res://textures/items/colony_beacon.png"),
}
const DEBUG_ITEM_KINDS: Array[StringName] = [&"laser", &"laser_rate", &"battery", &"drone", &"homing_missile", &"shield", &"vacuum", &"radar", &"repairset", &"invisibility", &"colony_beacon", &"wormhole_dash", &"vortex", &"nuke", &"explorer_beacon"]
const ARTIFACT_ITEM_KINDS: Array[StringName] = [&"wormhole_dash", &"vortex", &"nuke", &"explorer_beacon"]
const SHIELD_TEXTURE_PATH: String = "res://textures/items/shield.png"
const VACUUM_TEXTURE_PATH: String = "res://textures/items/vacuum.png"

var _shield_icon_texture: Texture2D
var _vacuum_icon_texture: Texture2D


func get_debug_item_kinds() -> Array[StringName]:
	return DEBUG_ITEM_KINDS


func get_artifact_item_kinds() -> Array[StringName]:
	return ARTIFACT_ITEM_KINDS


func is_artifact_item_kind(item_kind: StringName) -> bool:
	return ARTIFACT_ITEM_KINDS.has(item_kind)


func create_inventory_row(item_kind: StringName, item_level: int) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = get_item_icon_texture(item_kind)
	row.add_child(icon)

	var label := Label.new()
	label.text = format_inventory_item_label(item_kind, item_level)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)

	return row


func format_inventory_item_name(item_kind: StringName) -> String:
	match item_kind:
		&"laser":
			return "Laser"
		&"laser_rate":
			return "Laser Rate Boost"
		&"battery":
			return "Battery"
		&"drone":
			return "Drone"
		&"homing_missile":
			return "Homing Missile"
		&"shield":
			return "Shield"
		&"vacuum":
			return "Vacuum"
		&"radar":
			return "Radar"
		&"repairset":
			return "Repair Kit"
		&"invisibility":
			return "Invisibility"
		&"xpbox":
			return "XP Box"
		&"wormhole_dash":
			return "Wormhole Dash"
		&"vortex":
			return "Vortex"
		&"nuke":
			return "Nuke"
		&"explorer_beacon":
			return "Explorer Beacon"
		&"colony_beacon":
			return "Colony Beacon"
		_:
			return _format_fallback_item_name(item_kind)


func get_item_icon_texture(item_kind: StringName) -> Texture2D:
	var item_texture: Texture2D = ITEM_ICON_TEXTURES.get(item_kind, null)
	if item_texture != null:
		return item_texture

	if item_kind == &"shield":
		return _load_shield_icon_texture()

	if item_kind == &"vacuum":
		return _load_vacuum_icon_texture()

	return null


func format_inventory_item_label(item_kind: StringName, item_level: int) -> String:
	if item_kind == &"invisibility":
		return "%s (%s)" % [format_inventory_item_name(item_kind), _format_timer_seconds(item_level)]

	return "%s (%d)" % [format_inventory_item_name(item_kind), item_level]


func _format_fallback_item_name(item_kind: StringName) -> String:
	var raw_name := String(item_kind).replace("_", " ").strip_edges()
	if raw_name.is_empty():
		return "Item"

	var words: PackedStringArray = raw_name.split(" ", false)
	var formatted_words: Array[String] = []
	for word in words:
		if word.is_empty():
			continue

		formatted_words.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())

	if formatted_words.is_empty():
		return "Item"

	return " ".join(formatted_words)


func _format_timer_seconds(seconds: int) -> String:
	var safe_seconds := maxi(seconds, 0)
	var minutes := int(safe_seconds / 60)
	var remaining_seconds := safe_seconds % 60
	if minutes > 0:
		return "%d:%02d" % [minutes, remaining_seconds]

	return "%ds" % remaining_seconds


func _load_shield_icon_texture() -> Texture2D:
	if _shield_icon_texture != null:
		return _shield_icon_texture

	var texture := load(SHIELD_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_shield_icon_texture = texture
	return _shield_icon_texture


func _load_vacuum_icon_texture() -> Texture2D:
	if _vacuum_icon_texture != null:
		return _vacuum_icon_texture

	var texture := load(VACUUM_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_vacuum_icon_texture = texture
	return _vacuum_icon_texture
