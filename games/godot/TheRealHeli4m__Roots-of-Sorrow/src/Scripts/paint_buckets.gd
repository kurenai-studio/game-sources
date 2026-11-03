extends Control

@onready var red = $RedBucket
@onready var blue = $BlueBucket
@onready var green = $GreenBucket

@onready var redOverlay = $RedBucket/RedOverlay
@onready var blueOverlay = $BlueBucket/BlueOverlay
@onready var greenOverlay = $GreenBucket/GreenOverlay

@onready var root = $".."

func _ready() -> void:
	pivot_offset = size / 2.0
	redOverlay.modulate.a = 0
	blueOverlay.modulate.a = 0
	greenOverlay.modulate.a = 0
	
 

func onMouseEnterRed() -> void:
	var tween = create_tween()
	tween.tween_property(redOverlay, "modulate:a", 0.75, 0.2)

func onMouseExitRed() -> void:
	var tween = create_tween()
	tween.tween_property(redOverlay, "modulate:a", 0.0, 0.2)


func onMouseEnterBlue() -> void:
	var tween = create_tween()
	tween.tween_property(blueOverlay, "modulate:a", 0.75, 0.2)


func onMouseExitBlue() -> void:
	var tween = create_tween()
	tween.tween_property(blueOverlay, "modulate:a", 0.0, 0.2)


func onMouseEnterGreen() -> void:
	var tween = create_tween()
	tween.tween_property(greenOverlay, "modulate:a", 0.75, 0.2)

func onMouseExitGreen() -> void:
	var tween = create_tween()
	tween.tween_property(greenOverlay, "modulate:a", 0.0, 0.2)


func onRedPressed() -> void:
	root.currentTool = root.tools.PAINTBRUSH
	root.currentPaintColor = root.paintBrushColors.RED

func onBluePressed() -> void:
	root.currentTool = root.tools.PAINTBRUSH
	root.currentPaintColor = root.paintBrushColors.BLUE

func onGreenPressed() -> void:
	root.currentTool = root.tools.PAINTBRUSH
	root.currentPaintColor = root.paintBrushColors.GREEN
