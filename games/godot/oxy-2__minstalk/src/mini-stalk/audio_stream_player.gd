extends "res://gunlogic.gd"
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var outlaw

func _ready() -> void:
	audio.stream = shoot_audio
