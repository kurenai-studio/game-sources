extends Object
class_name SceneManager

const SCENE_DIR = "res://scenes"

var current_scene: Node
var _parent: Node


func _init(parent: Node) -> void:
  _parent = parent


func load_scene(scene_name: String) -> void:
  unload_scene()
  
  var scene = load(SCENE_DIR.path_join(scene_name + ".tscn")) as PackedScene
  var instance = scene.instantiate()
  
  _parent.add_child(instance)


func unload_scene() -> void:
  if current_scene:
    current_scene.queue_free()
    _parent.remove_child(current_scene)