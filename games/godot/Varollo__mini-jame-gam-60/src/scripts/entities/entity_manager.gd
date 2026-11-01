extends Node2D
class_name EntityManager

const ENTITIES_GROUP_NAME = "entities"

var _loaded_entities: Array[Node2D] = []


func _ready() -> void:
  GameManager.event_manager.scene_2d_loaded.connect(_on_scene_2d_loaded)


func _on_scene_2d_loaded(_scene: Node2D) -> void:
  var entities: Array = get_tree().get_nodes_in_group(ENTITIES_GROUP_NAME)

  for entity in entities:
    if entity in _loaded_entities:
      _loaded_entities.erase(entity)
      entity.queue_free()
      remove_child(entity)
    else:
      _loaded_entities.append(entity)
      entity.reparent(self)
