extends Node

@export var _first_scene_name: String

@onready var camera: Camera = $"World2D/Camera2D"
@onready var scene_manager_2d: SceneManager2D = $"World2D/SceneManager2D"
@onready var scene_manager_ui: SceneManagerUI = $"UI/SceneManagerUI"

var event_manager: EventManager = EventManager.new()


func _ready() -> void:
  if _first_scene_name != "":
    scene_manager_2d.load_scene(_first_scene_name)