class_name Goalie
extends RigidBody2D
var counter = 0
const OFFSET: int = 32
@export var ghost: Ghost
@export var home_team: bool
@export var stats: Stats.ClassTypes
@export var max_y: float = 650
@export var min_y: float = 400
var statbook: Stats.StatBlock
var rammed: bool = false
var charging: bool = false
var knocked_over: int = 0
var home_x: float
var anim_state: String = ""
var needs_reset: bool = false
var pulled: bool = false
var extra_attacker: Skater = null
var prev_position: Vector2 = Vector2.ZERO

var bump_timer: float = 0.0
var block_timer: float = 0.0

var original_x: float
var bump_offset: Vector2 = Vector2.ZERO

func home() -> void:
	needs_reset = true

func pull() -> void:
	if pulled: return
	pulled = true

	# Create an extra skater
	var skater_scene = load("res://objects/skaters/skater.tscn")
	extra_attacker = skater_scene.instantiate()
	extra_attacker.home_team = home_team
	extra_attacker.global_position = global_position
	extra_attacker.stats = stats
	# Add the extra attacker to the correct team node
	var manager = get_parent()
	if home_team:
		var team1 = manager.get_node_or_null("Team1")
		if team1:
			team1.call_deferred("add_child", extra_attacker)
	else:
		var team2 = manager.get_node_or_null("Team2")
		if team2:
			team2.call_deferred("add_child", extra_attacker)

	# Transfer control if human player is controlling the goalie
	if ghost:
		var temp_ghost = ghost
		ghost.skater = null
		ghost = null
		temp_ghost.skater = extra_attacker
		extra_attacker.ghost = temp_ghost

	# Disable goalie visually and physically
	visible = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	set_deferred("freeze", true)

func return_to_net() -> void:
	if not pulled: return
	pulled = false

	# Enable goalie visually and physically
	visible = true
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	set_deferred("freeze", false)
	needs_reset = true

	if extra_attacker:
		# If human is controlling the extra attacker, return control to goalie
		if extra_attacker.ghost:
			var temp_ghost = extra_attacker.ghost
			extra_attacker.ghost.skater = null
			extra_attacker.ghost = null
			temp_ghost.skater = self
			ghost = temp_ghost
		extra_attacker.remove_from_group("skaters")
		extra_attacker.queue_free()
		extra_attacker = null

func _ready() -> void:
	# add_to_group("skaters")
	home_x = global_position.x
	prev_position = global_position
	$Sprite.texture = $Sprite.texture.duplicate()
	#$Sprite.texture.atlas = $Sprite.texture.atlas.duplicate()
	var st = Globals.random_skin_tone()
	if home_team:
		$Sprite.texture = Globals.home_goalie_textures["Stand"]
		$Sprite.material = Globals.home_shader_material.duplicate()
	else:
		$Sprite.texture = Globals.away_goalie_textures["Stand"]
		$Sprite.material = Globals.away_shader_material.duplicate()
	$Sprite.flip_h = home_team
	$Sprite.material.set("shader_parameter/original_3", Globals.color_to_vec4(Globals.skin_tone))
	$Sprite.material.set("shader_parameter/original_4", Globals.color_to_vec4(Globals.nose_color))
	$Sprite.material.set("shader_parameter/replace_3", Globals.color_to_vec4(st[0]))
	$Sprite.material.set("shader_parameter/replace_4", Globals.color_to_vec4(st[1]))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var anim_name = "Stand"
	$Sprite.region_rect.position.x = 0
	if block_timer > 0:
		block_timer -= delta
		anim_name = "Block Puck"
		$Sprite.position = Vector2.ZERO
	elif bump_timer > 0:
		bump_timer -= delta
		anim_name = "Bump Player"

		# Bonus: Lerping sprite position based on bump_offset and bump_timer
		var t = bump_timer / 0.5 # assuming bump lasts 0.5 sec max
		if t > 0.5:
			# Moving towards offset
			var p = (1.0 - t) * 2.0
			$Sprite.position = bump_offset * p
		else:
			# Moving back to zero
			var p = t * 2.0
			$Sprite.position = bump_offset * p
	elif (global_position - prev_position).length() > 1:
		anim_name = "Skate"
		$Sprite.position = Vector2.ZERO
		$Sprite.region_rect.position.x = (int(Globals.ticks / 10.0) % 6) * 192
	else:
		$Sprite.position = Vector2.ZERO

	if home_team:
		if Globals.home_goalie_textures.has(anim_name):
			$Sprite.texture = Globals.home_goalie_textures[anim_name]
	else:
		if Globals.away_goalie_textures.has(anim_name):
			$Sprite.texture = Globals.away_goalie_textures[anim_name]
	prev_position = global_position
func _physics_process(delta: float) -> void:
	if ghost:
		ghost.handle(delta, self)
	else:
		var puck_node = Globals.get_closest_node(global_position, "pucks")
		if puck_node:
			var target_y = clamp(puck_node.global_position.y + OFFSET, min_y, max_y)
			var difficulty = Globals.home_ai_difficulty if home_team else Globals.away_ai_difficulty
			var target_x = home_x
			var target_shooter = null
			if puck_node.posessor and puck_node.posessor is Skater and puck_node.posessor.home_team != home_team:
				target_shooter = puck_node.posessor

			if difficulty == 2 and target_shooter:
				# come out of the net to try to bump skaters away / block more angles
				var dist_to_shooter = global_position.distance_to(target_shooter.global_position)
				if dist_to_shooter < 300:
					target_x = home_x + (target_shooter.global_position.x - home_x) * 0.5
					if dist_to_shooter < 100 and randf() < 0.05:
						# sometimes come out to bump
						target_x = target_shooter.global_position.x
						target_y = target_shooter.global_position.y

			var diffx = clamp(global_position.x - target_x, -16, 16)
			if abs(diffx) > 4:
				apply_impulse(Vector2.LEFT * diffx)

			if difficulty >= 1 and puck_node.posessor and puck_node.posessor.charging:
				var shooter = puck_node.posessor
				var aim_dir = Vector2.ZERO
				if shooter.ghost and "shotDir" in shooter.ghost:
					aim_dir = shooter.ghost.shotDir.normalized()
				elif shooter.ai and "shot_aim_dir" in shooter.ai:
					aim_dir = shooter.ai.shot_aim_dir.normalized()
				if aim_dir.length_squared() > 0 and aim_dir.x != 0:
					var dist_x = home_x - shooter.global_position.x
					if (dist_x > 0 and aim_dir.x > 0) or (dist_x < 0 and aim_dir.x < 0):
						var t = dist_x / aim_dir.x
						target_y = clamp(shooter.global_position.y + aim_dir.y * t + OFFSET, min_y, max_y)
			elif difficulty == 2 and target_shooter and target_shooter.linear_velocity.length() > 10:
				# anticipate where the shot will be shot at
				var predict_time = 0.5
				var predicted_pos = target_shooter.global_position + target_shooter.linear_velocity * predict_time
				target_y = clamp(predicted_pos.y + OFFSET, min_y, max_y)
			var diffy = global_position.y - target_y
			if abs(diffy) > 4:
				apply_impulse(Vector2.UP * diffy)
	#counter += 1

func impulse(dx: float, dy: float) -> void:
	var impulse_vec = Vector2(dx, dy) * 30.0

	if impulse_vec.length() > 0:
		counter += 1
	apply_impulse(impulse_vec)

func do_check() -> void:
	pass

func do_grab(_is_just_pressed: bool = true) -> void:
	pass

func release_grab() -> void:
	pass

var puck = null

func shoot(dir: Vector2, power: float, inaccuracy_modifier: float = 1) -> void:
	if puck:
		var snap = statbook.snap_power + ((1 - statbook.snap_power) * power)
		var vec = dir.normalized() * 200 * snap * statbook.shot_power
		var vec2 = vec.rotated(inaccuracy_modifier * statbook.shot_variance * (1 - (2*randf())))
		puck.shoot(name, vec2)

		var camera = get_viewport().get_camera_2d()
		if camera:
			var shake_amount = 2.0 + (power * 8.0)
			var shake_tween = create_tween()
			var r = shake_amount
			shake_tween.tween_property(camera, "offset", \
				Vector2(randf_range(-r, r), randf_range(-r, r)), 0.05)
			var r2 = shake_amount/2.0
			shake_tween.tween_property(camera, "offset", \
				Vector2(randf_range(-r2, r2), randf_range(-r2, r2)), 0.05)
			shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if needs_reset:
		var trans = state.get_transform()
		trans.origin = Vector2(home_x, (min_y + max_y) / 2.0)
		state.set_transform(trans)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		needs_reset = false
		return

	for i in range(state.get_contact_count()):
		# Get the impulse vector for this specific contact point
		var myimpulse: Vector2 = state.get_contact_local_velocity_at_position(i)
		var collider = state.get_contact_collider_object(i)
		if "mass" in collider:
			myimpulse *= 1 + (collider.mass - mass)
		var impulse_strength: float = myimpulse.length()

		if collider is Puck:
			block_timer = 0.5
			if not collider.shot_on_goal_counted and collider.last_possessor != "":
				if not Globals.shot_stats.has(collider.last_possessor):
					Globals.shot_stats[collider.last_possessor] = 0
				Globals.shot_stats[collider.last_possessor] += 1
				collider.shot_on_goal_counted = true
		elif collider is Skater:
			#if impulse_strength > 10.0:
			bump_timer = 0.5
			bump_offset = myimpulse.normalized() * 10.0

		if impulse_strength > 150.0:
			# drop the puck
			rammed = true
