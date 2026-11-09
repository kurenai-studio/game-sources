extends CharacterBody2D

const SPEED: float = 64.0
const TILE_SIZE: float = 16.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var push_ray: RayCast2D = $PushRay

@onready var hud : HUD = get_tree().get_first_node_in_group("hud")

var last_direction: Vector2 = Vector2.DOWN
var interactable : Node = null
var is_locked: bool = false:
	set(value):
		is_locked = value
		if value:
			velocity = Vector2.ZERO
			sprite.play("idle_" + _dir_name(last_direction))

func _ready() -> void:
	add_to_group("player")
	interaction_area.area_entered.connect(_on_interaction_area_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_area_exited)
	if push_ray:
		push_ray.target_position = Vector2(17, 0)

func _physics_process(_delta: float) -> void:
	if is_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	
	if push_ray and direction != Vector2.ZERO:
		var dominant: Vector2 = _dominant_direction(direction)
		push_ray.target_position = dominant * (TILE_SIZE / 2.0 + 1)
		push_ray.force_raycast_update()

		if push_ray.is_colliding():
			var collider: Variant = push_ray.get_collider()
			if collider.is_in_group("pushable"):
				collider.try_push(dominant, TILE_SIZE)
	
	velocity = direction * SPEED
	move_and_slide()
	position = position.round()
	_update_animation(direction)
	
func _dominant_direction(dir: Vector2) -> Vector2:
	if abs(dir.x) > abs(dir.y):
		return Vector2(sign(dir.x), 0)
	else:
		return Vector2(0, sign(dir.y))
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and interactable:
		interactable.interact()

# --- Animation ---
func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		last_direction = direction
		sprite.play("walk_" + _dir_name(direction))
	else:
		sprite.play("idle_" + _dir_name(last_direction))

func _dir_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

# --- Interaction ---
func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		interactable = area
		if hud:
			hud.show_prompt(area.prompt_text if "prompt_text" in area else "[E] Interact")

func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area == interactable:
		interactable = null
		if hud:
			hud.hide_prompt()
