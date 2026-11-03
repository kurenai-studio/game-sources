extends Control

signal scroll_done

@export_multiline var texts:Array[String]
@export var display_on_ready: = false
@export var label:Label
@export var button:Button

var current_text: = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if display_on_ready:
		activate()
	else:
		disable()

func disable():
	label.text = ""
	visible = false

func activate():
	visible = true
	label.text = texts[current_text]
	button.pressed.connect(next_text)
	
func next_text():
	current_text += 1
	if current_text < texts.size():
		label.text = texts[current_text]
	else:
		scroll_done.emit()
		disable()
