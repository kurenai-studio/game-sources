extends Node

signal scene_changed(scene_path: String)

func change_scene(scene_path: String) -> void:
	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Impossible de charger la scene : " + scene_path)
		return
	scene_changed.emit(scene_path)

func reload_current_scene() -> void:
	var scene_file_path: String = get_tree().current_scene.scene_file_path
	if scene_file_path == "":
		push_warning("Aucune scene active a recharger.")
		return
	change_scene(scene_file_path)

func quit_game() -> void:
	get_tree().quit()
