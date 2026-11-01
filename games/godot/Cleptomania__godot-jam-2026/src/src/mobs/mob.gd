class_name Mob extends CharacterBody2D

var animation_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

@export var speed: float = 75

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

@onready var player: Player = get_tree().get_first_node_in_group("player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(player != null, "Failed to find Player node")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	direction = self.position.direction_to(player.position)
	velocity = direction * speed
	
func _physics_process(delta: float) -> void:
	move_and_slide()

func set_animation_direction() -> bool:
	var new_dir: Vector2 = animation_direction
	if direction == Vector2.ZERO:
		return false
	
	if direction.y == 0 or abs(direction.x) > abs(direction.y):
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0 or abs(direction.y) > abs(direction.x):
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN

	if new_dir == animation_direction:
		return false
		
	animation_direction = new_dir
	sprite.scale.x = -1 if animation_direction == Vector2.LEFT else 1
	return true
		
	
func update_animation(state: String) -> void:
	animation_player.play(state + "_" + get_animation_direction())
	
func get_animation_direction() -> String:
	if animation_direction == Vector2.DOWN:
		return "down"
	elif animation_direction == Vector2.UP:
		return "up"
	else:
		return "side"
