class_name Ship extends Area2D

## Distance ahead to look for always dodge obstacles.
const OBSTACLE_SEARCH_DISTANCE: int = 400
## Distance ahead that rocks are counted as being seen.
const ROCK_VIEW_DISTANCE: int = 250
## Speed of the ship in pixels per second.
const SPEED: float = 720.0 / 60.0
## Rotation speed in radians.
const ROTATION_SPEED: float = PI / 32

## Velocity of the ship.
var velocity: Vector2 = Vector2.UP
## Whether this ship has crashed.
var crashed: bool = false
## Whether this is a big ship.
var is_big_ship: bool = false
## Texture to display when this boat crashes
var crash_texture

## Signal for when the ship leaves the game area.
signal left_bounds(score: int)
## Signal for when the ship crashes.
signal did_crash()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var texture
	if self.is_big_ship:
		texture = load("res://Images/Boat/BigBoat.png")
		self.crash_texture = load("res://Images/Boat/BigBoatCrash.png")
		$ShipArea.scale = Vector2(2.0, 2.0)
	else:
		texture = load("res://Images/Boat/Boat" + str(randi_range(1, 2)) + ".png")
		self.crash_texture = load("res://Images/Boat/Boat" + str(randi_range(1, 2)) + "Crash.png")
	$Sprite.texture = texture
	$ShipSpawnAudio.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.crashed:
		return
	# Far ahead prediction of collision with objects
	$AlwaysDodgeRay.target_position = self.velocity.normalized() * OBSTACLE_SEARCH_DISTANCE
	$RockRay.target_position = self.velocity.normalized() * ROCK_VIEW_DISTANCE
	var collide_target: CollisionObject2D = get_collide_target()
	$Sprite.modulate.g = 1.0
	$Sprite.modulate.b = 1.0
	if collide_target != null:
		# Rotate both directions, "move forward", and see which is farther from the obstacle center.
		var new_velocity_a: Vector2 = velocity.rotated(self.rotation_speed() * delta).normalized()
		var new_velocity_b: Vector2 = velocity.rotated(-self.rotation_speed() * delta).normalized()
		
		var new_pos_a: Vector2 = self.position + new_velocity_a
		var new_pos_b: Vector2 = self.position + new_velocity_b
		if new_pos_a.distance_squared_to(collide_target.position) > new_pos_b.distance_squared_to(collide_target.position):
			self.velocity = new_velocity_a * get_speed()
		else:
			self.velocity = new_velocity_b * get_speed()
		
		if Global.Powerup.STUDY_SHIP_VIEW in Global.powerups and collide_target is Rock:
			$Sprite.modulate.g = 0.5
			$Sprite.modulate.b = 0.5
	
	# Move based on velocity
	self.position += self.velocity * delta
	
	# Check if the RockRayHit in our center (rather than our entire collision area to be nice and to make other ray
	# code easier) is in a rock.
	if $RockRayHit.is_colliding():
		self.crashed = true
		self.did_crash.emit()
		$Sprite.texture = self.crash_texture
		$ShipCrashAudio.play()
	

## Get the nearest target that the ship can collide with.
func get_collide_target() -> CollisionObject2D:
	var always_dodge_target = $AlwaysDodgeRay.get_collider()
	var rock_target = $RockRay.get_collider()
	if rock_target != null:
		var rock: Rock = rock_target as Rock
		if not rock.in_light:
			rock_target = null
	if always_dodge_target != null and rock_target != null:
		if self.position.distance_squared_to($AlwaysDodgeRay.get_collision_point()) < self.position.distance_squared_to($RockRay.get_collision_point()):
			return always_dodge_target as CollisionObject2D
		else:
			return rock_target as CollisionObject2D
	elif always_dodge_target != null:
		return always_dodge_target as CollisionObject2D
	elif rock_target != null:
		return rock_target as Rock
	else:
		return null


## Get speed of this ship.
func get_speed() -> float:
	return SPEED


func rotation_speed() -> float:
	if self.is_big_ship:
		return ROTATION_SPEED / 2.0
	else:
		return ROTATION_SPEED


func _on_on_screen_notifier_screen_exited() -> void:
	var score: int = 1
	if self.is_big_ship:
		score += 1
	self.left_bounds.emit(score)
	self.queue_free()
