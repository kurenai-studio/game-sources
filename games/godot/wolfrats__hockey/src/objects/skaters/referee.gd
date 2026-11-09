class_name Referee
extends RigidBody2D

var initial_position: Vector2
var needs_reset: bool = false
var skate_dir: Vector2 = Vector2.ONE
var last_move: Vector2 = Vector2.ONE
var counter = 0
var anim_state: String = ""
var target_pos: Vector2 = Vector2.ZERO
var health: float = 100.0
var knocked_over: int = 0
var damage_tween: Tween

# Cone of sight parameters
var cone_angle: float = PI / 3.0 # 60 degrees
var cone_radius: float = 300.0

@onready var sprite = $Sprite
@onready var sight_polygon = $SightCone

func take_damage(damage: float, color: Color = Color(1, 0, 0)) -> void:
	if knocked_over > Globals.ticks:
		return
	health -= damage
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()
	$Sprite.modulate = color
	damage_tween = create_tween()
	damage_tween.tween_property($Sprite, "modulate", Color.WHITE, 0.3)
	if health <= 0:
		knocked_over = Globals.ticks + 120

func _ready() -> void:
	initial_position = global_position
	target_pos = initial_position
	add_to_group("referees")
	mass = 100
	# The referee uses the same textures, just black/white
	_update_cone_visuals()

func home() -> void:
	needs_reset = true

func shake() -> void:
	if knocked_over > Globals.ticks:
		return
	var shake_tween = create_tween()
	for _i in range(6):
		shake_tween.tween_property($Sprite, "position", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.05)
	shake_tween.tween_property($Sprite, "position", Vector2.ZERO, 0.05)

func _physics_process(delta: float) -> void:
	if knocked_over <= Globals.ticks and health < 100.0:
		health += delta * 5.0
		if health > 100.0:
			health = 100.0

	if knocked_over > Globals.ticks:
		linear_damp = 3.0
		sprite.texture = Globals.referee_textures["Die 1"]
		sprite.region_rect = Rect2(0, 0, 192, 192)
		sprite.region_enabled = true
		_update_cone_visuals()
		return

	if anim_state == "skating_around":
		if randf() < 0.05:
			impulse(randf_range(-1, 1), randf_range(-1, 1))
		var diff = initial_position - global_position
		if diff.length() > 500:
			impulse(diff.normalized().x, diff.normalized().y)
	elif anim_state == "skate_to":
		var diff = target_pos - global_position
		if diff.length() > 10:
			if randf() < 0.2:
				impulse(diff.normalized().x, diff.normalized().y)
	else:
		# Randomly skate around the rink
		var diff = target_pos - global_position
		if diff.length() < 100 or randf() < 0.01:
			# Rink dimensions roughly 300 to 1700 X, 200 to 800 Y
			var target_x = randf_range(300, 1700)
			var target_y = randf_range(200, 800)
			target_pos = Vector2(target_x, target_y)
			diff = target_pos - global_position

		# Occasionally push towards target to simulate skating strides
		if randf() < 0.1:
			impulse(diff.normalized().x, diff.normalized().y)

	var speed = linear_velocity.length()
	if speed > 5 or speed == 0:
		linear_damp = 0.9

	counter += 1
	var anim_name = "Skate Left"
	var frame = 0

	# Adjust Sprite facing
	if linear_velocity.x != 0:
		sprite.flip_h = (linear_velocity.x > 0)

	if speed > 5:
		frame = (int(counter / 10.0) % 6)

	if (linear_velocity.abs().x < linear_velocity.abs().y):
		sprite.flip_h = false
		anim_name = "Skate Down"
		if (linear_velocity.y < 0):
			anim_name = "Skate Up"

	if not Globals.referee_textures.has(anim_name):
		return

	sprite.texture = Globals.referee_textures[anim_name]

	var spacing = 192
	sprite.region_rect = Rect2(frame * spacing, 0, 192, 192)
	sprite.region_enabled = true

	skate_dir = skate_dir.lerp(self.linear_velocity, 0.03)

	_update_cone_visuals()

func impulse(dx: float, dy: float) -> void:
	last_move = Vector2(dx, dy)
	apply_impulse(last_move * 300.0) # Arbitrary speed

func _update_cone_visuals():
	if not sight_polygon:
		return
	if knocked_over > Globals.ticks:
		sight_polygon.visible = false
		return
	sight_polygon.visible = true

	var facing_dir = linear_velocity.normalized()
	if facing_dir.length_squared() < 0.1:
		facing_dir = last_move.normalized()
	if facing_dir.length_squared() < 0.1:
		facing_dir = Vector2.RIGHT

	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	var num_segments = 10
	var base_angle = facing_dir.angle()
	var start_angle = base_angle - cone_angle / 2.0

	for i in range(num_segments + 1):
		var a = start_angle + cone_angle * (float(i) / num_segments)
		points.append(Vector2(cos(a), sin(a)) * cone_radius)
	sight_polygon.polygon = points

func is_in_cone(point: Vector2) -> bool:
	if knocked_over > Globals.ticks:
		return false
	var diff = point - global_position
	if diff.length() > cone_radius:
		return false

	var facing_dir = linear_velocity.normalized()
	if facing_dir.length_squared() < 0.1:
		facing_dir = last_move.normalized()
	if facing_dir.length_squared() < 0.1:
		facing_dir = Vector2.RIGHT

	var angle_to_point = facing_dir.angle_to(diff.normalized())
	return abs(angle_to_point) <= cone_angle / 2.0

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if anim_state == "lerping":
		var trans = state.get_transform()
		trans.origin = trans.origin.lerp(initial_position, 0.05)
		state.set_transform(trans)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		return

	if needs_reset:
		var trans = state.get_transform()
		trans.origin = initial_position
		state.set_transform(trans)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		needs_reset = false
		return

func swap_colors_in_texture(tex: Texture2D) -> ImageTexture:
	return swap_color_in_texture(
		swap_color_in_texture(
			swap_color_in_texture(
				tex, Globals.shirt_color
			), Globals.helmet_color
		), Globals.skate_color
	)
func swap_color_in_texture(tex: Texture2D, from_col: Color) -> ImageTexture:
	# Convert Texture2D to an Image you can edit
	var img: Image = tex.get_image()
	#img.lock() # Required for fast pixel manipulation in some contexts
	 # Loop through every pixel coordinates (x, y)
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var current_color = img.get_pixel(x, y)
			# Optional: add a small tolerance check if dealing with compressed/anti-aliased art
			if current_color.is_equal_approx(from_col):
				var to_col = Color(0.01, 0.01, 0.01)
				if int(x / 6.0) % 2 == 0 and y > 95 and y < 120:
					to_col = Color.LIGHT_GRAY
				img.set_pixel(x, y, to_col)
	#img.unlock()
	# Create a new ImageTexture from the modified Image
	return ImageTexture.create_from_image(img)
