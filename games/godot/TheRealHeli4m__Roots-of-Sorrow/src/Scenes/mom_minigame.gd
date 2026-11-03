extends CanvasLayer

@onready var progressbar = $ProgressBar
@onready var hover = $Hover
@onready var gameboy = $"../Gameboy"
@onready var gameboyAnim = $"../AnimationPlayer"
var mouseInArea = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progressbar.hide()
	hover.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Global.inMomMinigame:
		progressbar.show()
		hover.show()
		progressbar.value -= 0.1
		if mouseInArea:
			progressbar.value += 0.2

func _on_control_mouse_entered() -> void:
	mouseInArea = true


func _on_control_mouse_exited() -> void:
	mouseInArea = false
