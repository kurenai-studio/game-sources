extends Node2D

@onready var overlay = $NeedleOverlay
@onready var root = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlay.modulate.a = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func onNeedlePressed() -> void:
	root.currentTool = root.tools.NEEDLE


func onMouseEnterNeedle() -> void:
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.25)
	
func onMouseExitNeedle() -> void:
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.25)
