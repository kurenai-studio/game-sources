extends Node2D

const PLANET_SCENE: PackedScene = preload("res://galaxy_entities/planets/planet.tscn")
const PLANET_SCENE_PATH: String = "res://galaxy_entities/planets/planet.tscn"
const PLANET_VISUALS_DIRECTORY: String = "res://galaxy_entities/planets"

@export_range(120.0, 420.0, 1.0) var horizontal_spacing: float = 240.0
@export_range(0.2, 4.0, 0.01) var planet_scale: float = 0.85
@export_range(32.0, 512.0, 1.0) var visual_pixel_size: float = 180.0
@export var fit_to_viewport: bool = true
@export var show_labels: bool = true

@onready var planets_parent: Node2D = $Planets
@onready var labels_parent: Node2D = $Labels
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_populate_planet_variants()


func _populate_planet_variants() -> void:
	_clear_children(planets_parent)
	_clear_children(labels_parent)

	var planet_scene_paths := _get_planet_visual_scene_paths()
	if planet_scene_paths.is_empty():
		push_warning("No planet visual scenes found in %s" % PLANET_VISUALS_DIRECTORY)
		return

	var spacing := _resolve_spacing(planet_scene_paths.size())
	var start_x := -spacing * float(planet_scene_paths.size() - 1) * 0.5
	for index in planet_scene_paths.size():
		var visual_scene_path := planet_scene_paths[index]
		var variant_name := _get_variant_name(visual_scene_path)
		var planet := PLANET_SCENE.instantiate() as Planet
		if planet == null:
			continue

		planet.name = variant_name
		planet.position = Vector2(start_x + spacing * float(index), -20.0)
		planet.visual_pixel_size = visual_pixel_size
		planet.visual_scene_path = visual_scene_path
		planet.seed = 1001 + index * 97
		planet.planet_scale = planet_scale
		planet.size_jitter = 0.0
		planet.rotation_jitter = 0.0
		planet.brightness_jitter = 0.0
		planet.visual_rotation_speed = 0.16
		planets_parent.add_child(planet)

		if show_labels:
			_add_variant_label(variant_name, planet.position, spacing)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _resolve_spacing(variant_count: int) -> float:
	if not fit_to_viewport or variant_count <= 1:
		return horizontal_spacing

	var viewport_width := get_viewport_rect().size.x
	if viewport_width <= 0.0:
		return horizontal_spacing

	var camera_zoom_x := 1.0
	if camera != null:
		camera_zoom_x = maxf(camera.zoom.x, 0.001)

	var available_width := viewport_width / camera_zoom_x * 0.88
	var fitted_spacing := available_width / float(variant_count - 1)
	return minf(horizontal_spacing, fitted_spacing)


func _add_variant_label(variant_name: String, planet_position: Vector2, spacing: float) -> void:
	var label := Label.new()
	label.name = "%sLabel" % variant_name
	label.text = variant_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(spacing, 32.0)
	label.position = planet_position + Vector2(-spacing * 0.5, 112.0)
	label.add_theme_color_override("font_color", Color(0.82, 0.88, 1.0, 0.92))
	label.add_theme_font_size_override("font_size", 18)
	labels_parent.add_child(label)


func _get_variant_name(scene_path: String) -> String:
	return scene_path.get_file().get_basename()


func _get_planet_visual_scene_paths() -> PackedStringArray:
	var scene_paths := PackedStringArray()
	_collect_planet_visual_scene_paths(PLANET_VISUALS_DIRECTORY, scene_paths)
	scene_paths.sort()
	return scene_paths


func _collect_planet_visual_scene_paths(directory_path: String, scene_paths: PackedStringArray) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_warning("Could not open planet visuals directory: %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		var entry_path := directory_path.path_join(entry_name)
		if directory.current_is_dir():
			if not entry_name.begins_with("."):
				_collect_planet_visual_scene_paths(entry_path, scene_paths)
		elif entry_name.get_extension() == "tscn" and entry_path != PLANET_SCENE_PATH:
			if ResourceLoader.exists(entry_path):
				scene_paths.append(entry_path)
			else:
				push_warning("Available planet visual scene does not exist: %s" % entry_path)
		entry_name = directory.get_next()
