extends Node2D
class_name SceneManager2D

var _manager: SceneManager = SceneManager.new(self)


func load_scene(scene_name: String) -> void:
  _manager.load_scene(scene_name)
  GameManager.event_manager.scene_2d_loaded.emit(_manager.current_scene)


func unload_scene() -> void:
  _manager.unload_scene()