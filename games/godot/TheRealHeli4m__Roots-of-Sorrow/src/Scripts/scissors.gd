extends Node2D

@onready var scissorsOverlay = $ScissorsOverlay
@onready var root = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scissorsOverlay.modulate.a = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func onMouseEnterScissors() -> void:
	var tween = create_tween()
	tween.tween_property(scissorsOverlay, "modulate:a", 1.0, 0.25)

func onMouseExitScissors() -> void:
	var tween = create_tween()
	tween.tween_property(scissorsOverlay, "modulate:a", 0.0, 0.25)

func onScissorsSelected() -> void:
	root.currentTool = root.tools.SCISSORS
