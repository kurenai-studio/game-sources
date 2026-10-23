extends AudioStreamPlayer

var currentTract := 0
var winning := false

func _ready() -> void:
	stream = load("res://Resources/Audio/Music/Game 1.mp3")
	play()

func _on_finished() -> void:
	if winning:
		stream = load("res://Resources/Audio/Music/Game 2.mp3")
		play()
		return
	
	currentTract = 0 if currentTract == 1 else 1
	
	match currentTract:
		0: stream = load("res://Resources/Audio/Music/Game 1.mp3")
		1: stream = load("res://Resources/Audio/Music/Game 3.mp3")
	
	play()
