extends Node2D

@onready var root = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func onRedPressed() -> void:
	root.currentTool = root.tools.NEEDLE
	root.currentThreadColor = root.threadColors.RED

func onBluePressed() -> void:
	root.currentTool = root.tools.NEEDLE
	root.currentThreadColor = root.threadColors.BLUE

func onGreenPressed() -> void:
	root.currentTool = root.tools.NEEDLE
	root.currentThreadColor = root.threadColors.GREEN

func onWhitePressed() -> void:
	root.currentTool = root.tools.NEEDLE
	root.currentThreadColor = root.threadColors.WHITE

func onGoldPressed() -> void:
	root.currentTool = root.tools.NEEDLE
	root.currentThreadColor = root.threadColors.GOLD
