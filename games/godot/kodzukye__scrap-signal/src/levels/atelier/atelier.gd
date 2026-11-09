extends Node2D

func _ready() -> void:
	AudioManager.play_ambiance("atelier")
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("document.querySelector('canvas').focus()")
