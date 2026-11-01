extends StaticBody2D
class_name WaxChunk

#@export var fall_speed : float
@export var fall_height : float
@export var fall_time_to_descent : float

@onready var fall_gravity : float = ((-2.0 * fall_height) / (fall_time_to_descent * fall_time_to_descent)) * -1.0
@onready var trigger_area = $TriggerArea
@onready var animation_player = $AnimationPlayer
@onready var sprite_2d = $Sprite2D

var falling = false

# Called when the node enters the scene tree for the first time.
func _ready():
	trigger_area.body_entered.connect(_body_entered)
	animation_player.play("shake")
	await(animation_player.animation_finished)
	falling = true


func _body_entered(body : Node2D):
#	check if body is tile map or character
	if body is TileMap || body is Flammable:
		sprite_2d.play("splash")
		await sprite_2d.animation_looped
		queue_free()
	elif body is CharacterBody2D:
		if body.has_method("increase_anim_size") :
			body.increase_anim_size()
			queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if falling :
		position.y += fall_gravity * delta
	
