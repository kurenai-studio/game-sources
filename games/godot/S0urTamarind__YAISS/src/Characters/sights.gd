extends Sprite2D

@export var speed: float = 600
@export var player: Area2D
@export var extra_margin: float = 10.0

var padding: float = 120
var vel := Vector2.ZERO

func _ready() -> void:
	padding = calcPadding(player)

func _physics_process(delta: float) -> void:
	
	# TODO: Handle input system better somehow
	var dirVec := Input.get_vector(
		"Shift Aim Left", "Shift Aim Right", 
		"Shift Aim Up", "Shift Aim Down"
	)
		
	vel = dirVec.normalized() * speed
	position += vel * delta
	
	if player:
		var difference:= position - player.global_position
		var radius:= difference.length()
		if radius < padding:
			if is_zero_approx(radius):
				position = player.global_position + Vector2.UP * padding
			else:
				position = player.global_position + difference.normalized() * padding
	
func calcPadding(target: Area2D) -> float:
	const DEFAULT_PADDING: float = 120
	if not target:
		return DEFAULT_PADDING
		
	var sight_radius: float = 0.0
	if texture:
		sight_radius = (texture.get_size().length() * 0.5) * max(scale.x, scale.y)
	
	for child in target.get_children():
		if child is CollisionShape2D and child.shape:
			var shape = child.shape
			var max_scale: float = max(child.global_scale.x, child.global_scale.y)
			
			if shape is CircleShape2D:
				return (shape.radius * max_scale) + sight_radius + extra_margin
			elif shape is RectangleShape2D:
				return ((shape.size.length() * 0.5) * max_scale) + sight_radius + extra_margin
			elif shape is CapsuleShape2D:
				return (max(shape.radius, shape.height * 0.5) * max_scale) + sight_radius + extra_margin
				
	return DEFAULT_PADDING
