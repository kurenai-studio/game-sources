extends Sprite2D
class_name Eraser


@onready var animation_player = $AnimationPlayer
@onready var timer = $Timer
@onready var original_position = position

static var _instance: Eraser


func _ready() -> void:
	_instance = self


static func erase(node: Node2D) -> void:	
	_instance.animation_player.play('Erase')
	_instance.timer.start()
	
	
static func stop_erasing() -> void:
	_instance.animation_player.play('Idle')
	
	
