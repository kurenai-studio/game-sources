extends Node2D

@onready var UIcanvaslayer = $UI

@onready var gameboyCursor = load("res://Assets/Cursors/gameboy_mouse_cursor.png")
@onready var scissorsCursor = load("res://Assets/Cursors/gameboy_scissors_cursor.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_visibility_changed() -> void:
	if UIcanvaslayer:
		UIcanvaslayer.visible = self.visible
