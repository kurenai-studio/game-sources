class_name Lighthouse extends Node2D

## Maximum number of stages the light can grow across all gameplay conditions.
var MAX_STAGES: int = 5
## The radius increase per stage. Stage 1 is this radius.
var RADIUS_PER_STAGE: int = 15
## Minimum distance the light can be away from the lighthouse.
var MIN_TRAVEL_RADIUS: int = 100
## Maximum distance the light can be away from the lighthouse.
@onready
var MAX_TRAVEL_RADIUS: int = get_viewport().size.y / 2 - (MAX_STAGES * RADIUS_PER_STAGE)
## Start rotation for the light
var START_ROTATION: float = PI / 2.0
## Time in seconds to go down by a stage (1.0 in radius).
var STAGE_DECREASE_TIME: int = 45
## Time in seconds until relighting begins after starting the process.
var BEGIN_RELIGHT_TIME: float = 5.0
## Time in seconds to relight one stage.
var STAGE_RELIGHT_TIME: float = 15.0 / 4.0

@onready
var light_path_shader: ShaderMaterial = $LightPath.material as ShaderMaterial

## Turn speed in radians per second.
var turn_speed: float = PI / 8.0
## In/out movement speed in pixels per second.
var inout_speed: float = 0.5
## Whether light is being relit.
var doing_relight: bool = false
## Time spent doing relight
var relight_counter: float = 0

## Current radius the light is at.
var current_stage: float = 4.0
## Current rotation of the light.
var current_rotation: float = START_ROTATION
## Current distance of the light from the lighthouse.
var current_distance: float = MIN_TRAVEL_RADIUS

## Signal fired when a relight is complete.
signal relight_done()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var circle_shape: CircleShape2D = $Light/LightCircleShape.shape
	circle_shape.radius = RADIUS_PER_STAGE
	Global.lighthouse = self
	self.reset_for_level()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Input handling
	var play_moving_sound: bool = false
	if not self.doing_relight:
		var input_rotate: float = Input.get_axis("move_left", "move_right") * delta * turn_speed
		if input_rotate != 0:
			current_rotation += input_rotate
			if current_rotation >= PI * 2:
				current_rotation -= PI * 2
			elif current_rotation < 0:
				current_rotation += PI * 2
			self.calc_and_set_pos()
			play_moving_sound = true
		else:
			var input_inout = Input.get_axis("move_down", "move_up")
			if input_inout != 0:
				current_distance += input_inout * inout_speed
				current_distance = min(max(MIN_TRAVEL_RADIUS, current_distance), MAX_TRAVEL_RADIUS)
				self.calc_and_set_pos()
	if play_moving_sound and not $RotateSounds.playing:
		$RotateSounds.play()
	elif not play_moving_sound and $RotateSounds.playing:
		$RotateSounds.stop()
	
	# Light radius
	if self.doing_relight:
		if self.relight_counter >= BEGIN_RELIGHT_TIME:
			var relight_time: float = STAGE_RELIGHT_TIME
			if Global.Powerup.BETTER_OIL in Global.powerups:
				relight_time *= 0.75
			current_stage += delta / relight_time
			if current_stage >= self.max_stage():
				current_stage = self.max_stage()
				self.relight_done.emit()
				self.doing_relight = false
				self.relight_counter = 0.0
		else:
			self.relight_counter += delta
	elif Global.current_hour > 1 or Global.level_num > 1:  # Let player not deal with light shrink on hour 1 of day 1
		current_stage -= delta / STAGE_DECREASE_TIME
		if current_stage < 0:
			current_stage = 0
	
	$Light.scale = Vector2(current_stage, current_stage)
	
	# Light path
	self.update_light_path()


## Resets the light for entering a new level
func reset_for_level() -> void:
	if Global.Powerup.BETTER_OIL in Global.powerups:
		self.current_stage = 6.0
	else:
		self.current_stage = 4.0
	if Global.Powerup.FASTER_MOVEMENT in Global.powerups:
		self.turn_speed = PI / 4.0
		self.inout_speed = 0.75
	else:
		self.turn_speed = PI / 8.0
		self.inout_speed = 0.5
	self.relight_counter = 0.0
	self.doing_relight = false
	self.calc_and_set_pos()

## Calculates and sets the light's position based on its current rotation and distance.
func calc_and_set_pos() -> void:
	var angle: Vector2 = Vector2.RIGHT.rotated(self.current_rotation)
	$Light.position = angle * self.current_distance

## Updates the light path based on the light spot's position and the light radius
func update_light_path() -> void:
	var radius = self.get_light_radius()
	
	var circle_center: Vector2 = $Light.global_position
	var angle: Vector2 = Vector2.RIGHT.rotated(self.current_rotation + PI / 2.0)
	var offset: Vector2 = angle * radius
	
	var light_origin_center: Vector2 = Vector2($Sprite.global_position.x, $Sprite.global_position.y - $Sprite.get_rect().size.y / 2.3)
	
	$LightPath.global_position = Vector2(0, 0)
	$LightPath.polygon = PackedVector2Array([
		light_origin_center,
		circle_center + offset,
		circle_center - offset,
	])
	
	light_path_shader.set_shader_parameter("circle_center", circle_center)
	light_path_shader.set_shader_parameter("radius_squared", radius * radius)

## Get the center of the light
func get_light_center() -> Vector2:
	return $Light.global_position

## Get the radius of the light.
func get_light_radius() -> float:
	return self.current_stage * RADIUS_PER_STAGE

## Get the radius of the light squared.
func get_light_radius_squared() -> float:
	var radius = get_light_radius()
	return radius * radius

## Get maximum stage for light.
func max_stage() -> float:
	if Global.Powerup.BETTER_OIL in Global.powerups:
		return 5.0
	else:
		return 4.0


func do_relight() -> void:
	self.doing_relight = true


func _on_light_area_entered(other: Area2D) -> void:
	if other is Rock:
		(other as Rock).in_light = true


func _on_light_area_exited(other: Area2D) -> void:
	if other is Rock:
		(other as Rock).in_light = false
