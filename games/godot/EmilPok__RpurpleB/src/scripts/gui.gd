extends CanvasLayer

@onready var red_cursor = $RedCursor
@onready var blue_cursor = $BlueCursor

@export var character1 : CharacterBody2D
@export var character2 : CharacterBody2D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta: float) -> void:
	
	red_cursor.visible = character1.active
	blue_cursor.visible = character2.active
