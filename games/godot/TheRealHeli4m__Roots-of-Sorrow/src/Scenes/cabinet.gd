extends TextureButton

@onready var highlight = $"../CabinetHighlight"
@onready var anim = $AnimatedSprite2D
@onready var root = $"../.."
@onready var switchToCabinetAnimPlayer = $"../../CanvasLayer2/SwitchToCabinet"
@onready var cabinetColRect = $"../../CanvasLayer2/ColorRect"

@onready var camera = $"../../Camera2D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cabinetColRect.modulate.a = 0
	highlight.modulate.a = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(highlight, "modulate:a", 1, 0.25)


func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(highlight, "modulate:a", 0, 0.25)


func _on_pressed() -> void:
	switchToCabinetAnimPlayer.play("change_room")
	highlight.hide()
	anim.play("default")
	
	await get_tree().create_timer(0.25).timeout
	root.currentRoom = "cabinet"
	
	
	
