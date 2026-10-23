extends CharacterBody2D
class_name Enemy

var speed := 150
@onready var player: CharacterBody2D = get_parent().get_node("Player")
var playerNoticed := false
var direction : Vector2 = Vector2.ZERO
var lastSeenPosition : Vector2
var detectPlayer : Array[bool]

func _ready() -> void:
	for ray in get_children():
		if ray is RayCast2D:
			detectPlayer.append(false)

func _process(_delta: float) -> void:
	_find_player()
	
	if _is_player_noticed(detectPlayer):
		playerNoticed = true
		lastSeenPosition = player.position
	else:
		playerNoticed = false
	
	_move_with_player_detection()

func _find_player() -> void:
	for ray in get_children():
		if ray is not RayCast2D:
			continue
		
		var index = int(ray.name.lstrip("Ray")) - 1
		
		if ray.get_collider() == null:
			detectPlayer[index] = false
			continue
			
		if ray.get_collider().name == "Player":
			detectPlayer[index] = true

func _is_player_noticed(boolArray: Array[bool]) -> bool:
	for x in boolArray:
		if x == true:
			return true
	return false

func _move_with_player_detection() -> void:
	if playerNoticed:
		direction = (player.position - position).normalized()
		
		rotation = lerp_angle(rotation, (player.position - position).normalized().angle(), 0.0325)
		velocity = speed * direction
		
		$AnimatedSprite2D.play("default")
		
		if not $Walk.playing:
			_walk_sounds()
			$Walk.play()
	
	if not playerNoticed and lastSeenPosition:
		direction = (lastSeenPosition - position).normalized()
		
		if position.length() <= lastSeenPosition.length() or \
		   position.length() > lastSeenPosition.length() + 2:
			velocity = speed * direction
			rotation = lerp_angle(rotation, (lastSeenPosition - position).normalized().angle(), 0.0325)
			
			$AnimatedSprite2D.play("default")
			
			if not $Walk.playing:
				_walk_sounds()
				$Walk.play()
		else:
			velocity = Vector2.ZERO
			rotation += 0.01
			$Walk.stop()
			$AnimatedSprite2D.stop()
	
	$CollisionShape2D.rotation = -rotation
	$AnimatedSprite2D.rotation = -rotation
	
	move_and_slide()

func _walk_sounds() -> void:
	$Walk.stream = load("res://Resources/Audio/Walk Sounds/walk.ogg")
