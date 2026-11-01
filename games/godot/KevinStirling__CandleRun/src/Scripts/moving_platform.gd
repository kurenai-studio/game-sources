extends AnimatableBody2D

@export var speed = 1.0
@export var origin_point : Vector2
@export var destination_point : Vector2

@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.start()
	timer.timeout.connect(func():
		if position == origin_point:
			move_destination()
		elif position == destination_point:
			move_origin()
		)

func move_destination():
	var tween = get_tree().create_tween()
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", destination_point, speed)
	await tween.finished
	timer.start()
	
func move_origin():
	var tween = get_tree().create_tween()
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", origin_point, speed)
	await tween.finished
	timer.start()

