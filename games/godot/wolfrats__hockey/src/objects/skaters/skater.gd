class_name Skater
extends RigidBody2D
var counter = 0
@export var ghost: Ghost
var ai: Ghost
@export var home_team: bool
@export var stats: Stats.ClassTypes
var statbook: Stats.StatBlock
var rammed: bool = false
var charging: bool = false
var started_charge: int = 0
var knocked_over: int = 0
var checking: int = 0
var holding: int = 0
var swapping: int = 0
var puck: Puck = null
var skate_dir: Vector2 = Vector2.ONE
var last_move: Vector2 = Vector2.ONE
var facing_dir: Vector2 = Vector2.ONE
var scrape_counter: int = 0
var faceoff_cooldown: float = 0.0
var faceoff_shake: float = 0.0
var initial_position: Vector2
var base_initial_position: Vector2
var needs_reset: bool = false
var anim_state: String = ""
var health: float
var spring: DampedSpringJoint2D
var penalty_time: float = 0.0
var needs_penalty_reset: bool = false
var damage_tween: Tween
var skater_size: String = "medium"

enum LookDir {
	SIDE,
	DOWN,
	UP
}


func _ready() -> void:
	initial_position = global_position
	base_initial_position = initial_position
	add_to_group("skaters")

	var team_data = StatBook.TEAMS[Globals.home_team_index] if home_team else StatBook.TEAMS[Globals.away_team_index]
	var index = get_index()
	if index >= 0 and index < team_data["composition"].size():
		stats = team_data["composition"][index]
	statbook = StatBook.Classes[stats]
	skater_size = statbook.size
	mass = statbook.weight
	health = statbook.max_health
	spring = $Spring #DampedSpringJoint2D.new()
	#add_child(spring)
	spring.node_a = get_path()
	var st = Globals.random_skin_tone()
	# The texture itself will be updated dynamically in _physics_process based on animation state
	if home_team:
		facing_dir = Vector2(1, 0)
		$Sprite.material = Globals.home_shader_material.duplicate()
	else:
		facing_dir = Vector2(-1, 0)
		$Sprite.material = Globals.away_shader_material.duplicate()
	$Sprite.material.set("shader_parameter/skin", Globals.color_to_vec4(Globals.skin_tone))
	$Sprite.material.set("shader_parameter/nose", Globals.color_to_vec4(Globals.nose_color))
	$Sprite.material.set("shader_parameter/replace_skin", Globals.color_to_vec4(st[0]))
	$Sprite.material.set("shader_parameter/replace_nose", Globals.color_to_vec4(st[1]))
	if stats == Stats.ClassTypes.LIGHT:
		$Sprite.scale.x = 0.9
		$Sprite.scale.y = 1.1
	if stats == Stats.ClassTypes.HEAVY:
		$Sprite.scale.x = 1.2
		#$Sprite.scale.y = 1.1
	if not Globals.manager.is_practice:
		ai = preload("res://objects/skaters/ai.tscn").instantiate()
		add_child(ai)
		

func get_player_name() -> String:
	var current_name = "Home AI" if home_team else "Away AI"
	if ghost:
		current_name = ghost.name
	return current_name

func home() -> void:
	needs_reset = true
	self.puck = null
	health = statbook.max_health
	penalty_time = 0.0
	holding = 0
	if not spring.node_b.is_empty():
		spring.node_b = NodePath("")

func penalty(duration: float) -> void:
	var current_name = get_player_name()
	if not Globals.penalty_stats.has(current_name):
		Globals.penalty_stats[current_name] = 0
	Globals.penalty_stats[current_name] += 1

	penalty_time = duration
	anim_state = "entering_penalty"
	checking = 0
	charging = false
	holding = 0
	if puck:
		puck.shoot(name, Vector2.ZERO)
	if not spring.node_b.is_empty():
		spring.node_b = NodePath("")

func _process(_delta: float) -> void:
	pass

func do_check() -> void:
	if anim_state in ["entering_penalty", "in_penalty", "leaving_penalty", "return_from_penalty"]:
		return
	if checking <= Globals.ticks and knocked_over <= Globals.ticks:
		checking = Globals.ticks + 20

		var current_name = get_player_name()
		if not Globals.check_stats.has(current_name):
			Globals.check_stats[current_name] = 0
		Globals.check_stats[current_name] += 1

		# Find nearest opposing skater or referee
		var nearest_skater: Node2D = null
		var min_dist: float = INF
		var skaters = get_tree().get_nodes_in_group("skaters")
		var referees = get_tree().get_nodes_in_group("referees")
		var checkable_targets = skaters + referees
		for s in checkable_targets:
			var is_opponent = true
			if "home_team" in s:
				is_opponent = s.home_team != home_team

			if is_opponent and s != self:
				var dist = global_position.distance_to(s.global_position)
				if dist < min_dist:
					min_dist = dist
					nearest_skater = s

		# Lunge forward
		var lunge_dir = Vector2.RIGHT if $Sprite.flip_h else Vector2.LEFT
		if nearest_skater:
			lunge_dir = (nearest_skater.global_position - global_position).normalized()
		else:
			if abs(last_move.y) > abs(last_move.x):
				lunge_dir = Vector2.DOWN if last_move.y > 0 else Vector2.UP
			elif last_move.length() > 0:
				lunge_dir = last_move.normalized()
		apply_impulse(lunge_dir * statbook.speed * 10.0)

		var hit_target = false
		for s in checkable_targets:
			if s != self and global_position.distance_to(s.global_position) < 80:
				var dmg = statbook.check_damage * randf_range(0.8, 1.2)
				if spring and spring.node_b == s.get_path():
					dmg *= 1.5
				var target_downed_before = ("knocked_over" in s and s.knocked_over > Globals.ticks)
				if s.has_method("take_damage"):
					s.take_damage(dmg)
				if "spring" in s and s.spring:
					s.spring.node_b = NodePath("")

				if not Globals.hit_stats.has(current_name):
					Globals.hit_stats[current_name] = 0
				Globals.hit_stats[current_name] += 1

				if not target_downed_before and "knocked_over" in s and s.knocked_over > Globals.ticks:
					if not Globals.down_stats.has(current_name):
						Globals.down_stats[current_name] = 0
					Globals.down_stats[current_name] += 1

				# Knockback target
				var knockback_dir = (s.global_position - global_position).normalized()
				var mass_ratio = s.mass / mass if s is RigidBody2D else 1.0
				if s is RigidBody2D:
					s.apply_impulse(knockback_dir * dmg * 1.0 * mass_ratio)
				hit_target = true

		if hit_target:
			Globals.play_sound_at("Check", global_position)
			var camera = get_viewport().get_camera_2d()
			if camera:
				var shake_tween = create_tween()
				shake_tween.tween_property(camera, "offset", Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.05)
				shake_tween.tween_property(camera, "offset", Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
				shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
		else:
			Globals.play_sound_at("CheckMiss", global_position)
		for ref in referees:
			if ref.has_method("is_in_cone") and ref.is_in_cone(global_position):
				if randf() < 0.3: # 30% chance to be sent to penalty box
					penalty(30.0)
					if Globals.manager and "anim_manager" in Globals.manager and Globals.manager.anim_manager:
						Globals.manager.anim_manager.set_phase(AnimationManager.Phase.PRE_PENALTY_SKATE)
						if ref:
							ref.anim_state = "skate_to"
							ref.target_pos = Vector2(1005.5, 509)


func release_grab() -> void:
	spring.node_b = NodePath("")
	holding = 0

func do_grab(is_just_pressed: bool = true) -> void:
	if anim_state in ["entering_penalty", "in_penalty", "leaving_penalty", "return_from_penalty"]:
		return
	holding = 1
	if not spring.node_b.is_empty():
		return
	#if is_just_pressed and checking <= Globals.ticks and knocked_over <= Globals.ticks:
	#	checking = Globals.ticks + 30

	if knocked_over <= Globals.ticks:
		var skaters = get_tree().get_nodes_in_group("skaters")
		for s in skaters:
			if s != self and global_position.distance_to(s.global_position) < 80:
				spring.node_b = s.get_path()
				s.take_damage(0, Color.DIM_GRAY)
				Globals.play_sound_at("Grab", global_position)
				# Camera shake feedback
				var camera = get_viewport().get_camera_2d()
				if camera:
					var shake_tween = create_tween()
					shake_tween.tween_property(camera, "offset", Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
					shake_tween.tween_property(camera, "offset", Vector2(randf_range(-2, 2), randf_range(-2, 2)), 0.05)
					shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
				break


func take_damage(damage: float, color: Color = Color(1, 0, 0)) -> void:
	if knocked_over > Globals.ticks or anim_state in ["entering_penalty", "in_penalty", "leaving_penalty", "return_from_penalty"]:
		return
	if not spring.node_b.is_empty() and randf() < 0.3333:
		release_grab()
	health -= damage
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()
	$Sprite.modulate = color
	damage_tween = create_tween()
	damage_tween.tween_property($Sprite, "modulate", Color.WHITE, 0.3)
	if health <= 0:
		knocked_over = Globals.ticks + 120
		checking = 0
		charging = false
		if puck:
			puck.shoot(name, Vector2.ZERO)

func _physics_process(delta: float) -> void:
	set_collision_layer_value(4, true)
	if puck and puck.posessor != self:
		puck = null
	if Globals.manager.is_replay:
		return
	if faceoff_shake > 0:
		faceoff_shake -= delta
	if faceoff_cooldown > 0:
		faceoff_cooldown -= delta
	if knocked_over <= Globals.ticks and health < statbook.max_health:
		health = min(statbook.max_health, health + delta * 15.0) # Regenerate 15 hp per second
	if anim_state in ["entering_penalty", "in_penalty", "leaving_penalty", "return_from_penalty"]:
		if anim_state == "entering_penalty":
			linear_velocity = Vector2(0, 100)
			$Sprite.modulate.a = max(0.0, $Sprite.modulate.a - delta * 1.5)
			if $Sprite.modulate.a <= 0.0:
				anim_state = "in_penalty"
				needs_penalty_reset = true
		elif anim_state == "in_penalty":
			$Sprite.modulate.a = min(1.0, $Sprite.modulate.a + delta * 2.0)
			if penalty_time > 0:
				if Globals.manager and "anim_manager" in Globals.manager and Globals.manager.anim_manager:
					if Globals.manager.anim_manager.current_phase == AnimationManager.Phase.PLAYING:
						penalty_time -= delta
				else:
					penalty_time -= delta
				if penalty_time <= 0:
					anim_state = "leaving_penalty"
		elif anim_state == "leaving_penalty":
			linear_velocity = Vector2(0, -100)
			$Sprite.modulate.a = max(0.0, $Sprite.modulate.a - delta * 1.5)
			if $Sprite.modulate.a <= 0.0:
				anim_state = "return_from_penalty"
				needs_reset = true
		elif anim_state == "return_from_penalty":
			$Sprite.modulate.a = min(1.0, $Sprite.modulate.a + delta * 2.0)
			if $Sprite.modulate.a >= 1.0:
				anim_state = ""
	elif anim_state == "skating_around":
		if randf() < 0.05:
			impulse(randf_range(-1, 1), randf_range(-1, 1))
		var diff = initial_position - global_position
		if diff.length() > 500:
			impulse(diff.normalized().x, diff.normalized().y)
	elif anim_state == "skating_circle" or anim_state == "skating_figure8":
		var time_offset = float(get_instance_id() % 1000)
		var time = (Globals.ticks + time_offset) / 60.0
		var target_dir = Vector2.ZERO
		if anim_state == "skating_circle":
			target_dir = Vector2(cos(time), sin(time)) * 4
		else:
			target_dir = Vector2(cos(time), sin(time * 2.0) * 0.8) * 4
		if randf() < 0.1:
			impulse(target_dir.x, target_dir.y)
		var diff = initial_position - global_position
		if diff.length() > 800:
			if randf() < 0.1:
				impulse(diff.normalized().x, diff.normalized().y)
	elif anim_state == "skating_out":
		var target_y = -200
		var diffy = target_y - global_position.y
		if randf() < 0.1:
			impulse(randf_range(-10, 10), 0)
		if abs(diffy) > 10:
			impulse(0, sign(diffy))
		if global_position.y < 200:
			$Sprite.modulate.a = max(0.0, $Sprite.modulate.a - delta)
	elif anim_state == "swapping":
		swapping += 1
		if swapping < 60:
			$Sprite.modulate.a = max(0.0, $Sprite.modulate.a - delta)
			impulse(0, -0.1)
		else:
			$Sprite.modulate.a = min(1.0, $Sprite.modulate.a + delta)
			impulse(0, 0.1)
		if swapping > 120:
			swapping = 0
			anim_state = ""
	elif anim_state == "face_off":
		# Only players near center can take the face-off
		var faceoff_pos = Vector2(1005.5, 509)
		var pucks = get_tree().get_nodes_in_group("pucks")
		if pucks.size() > 0:
			faceoff_pos = pucks[0].global_position

		if global_position.distance_to(faceoff_pos) < 150:
			var tried_faceoff = false
			if ghost:
				if ghost.has_method("is_action_just_pressed_custom"):
					if ghost.is_action_just_pressed_custom("pass"):
						tried_faceoff = true
			elif ai:
				if pucks.size() > 0:
					var p = pucks[0]
					var chance = 0.02
					if not p.freeze:
						chance = 0.2
					if randf() < chance:
						tried_faceoff = true

			if tried_faceoff:
				faceoff_shake = 0.15

			if tried_faceoff and faceoff_cooldown <= 0:
				if pucks.size() > 0:
					var p = pucks[0]
					if not p.freeze:
						# Won the face-off
						var current_name = get_player_name()
						if not Globals.faceoff_won_stats.has(current_name):
							Globals.faceoff_won_stats[current_name] = 0
						Globals.faceoff_won_stats[current_name] += 1

						var backward_dir = Vector2(-1, randf_range(-0.5, 0.5)) if home_team else Vector2(1, randf_range(-0.5, 0.5))
						var shoot_dir = backward_dir.normalized()
						# Temporarily act like we have puck to shoot it
						p.posessor = self
						self.puck = p
						shoot(shoot_dir, 0.5)

						# Change phase to PLAYING
						if Globals.manager and "anim_manager" in Globals.manager and Globals.manager.anim_manager:
							Globals.manager.anim_manager.set_phase(AnimationManager.Phase.PLAYING)
					else:
						# Too early
						faceoff_cooldown = 1.0

	elif ghost:
		ghost.handle(delta, self)
	elif ai:
		ai.handle(delta, self)
	var speed = linear_velocity.length()
	var look_dir: LookDir = LookDir.SIDE

	if knocked_over <= Globals.ticks and checking <= Globals.ticks:
		if facing_dir.x != 0:
			$Sprite.flip_h = (facing_dir.x > 0)

	if (abs(facing_dir.x) < abs(facing_dir.y)):
		$Sprite.flip_h = false
		look_dir = LookDir.DOWN
		if (facing_dir.y < 0):
			look_dir = LookDir.UP

	if not spring.node_b.is_empty():
		var held = get_node_or_null(spring.node_b)
		if held:
			var diff = held.global_position - global_position
			$Sprite.flip_h = (diff.x > 0)
			if abs(diff.x) < abs(diff.y):
				$Sprite.flip_h = false
				look_dir = LookDir.DOWN
				if diff.y < 0:
					look_dir = LookDir.UP
			else:
				look_dir = LookDir.SIDE

	if speed > 5 or speed == 0:
		linear_damp = 0.9

	if rammed:
		rammed = false
		if puck:
			puck.shoot(name, Vector2.ZERO)

	var anim_name = "Glide Left"
	var frame = 0

	if knocked_over > Globals.ticks:
		anim_name = "Die 1"
		z_index = -1
		if knocked_over - Globals.ticks > 90:
			$Sprite.position = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		else:
			$Sprite.position = Vector2.ZERO
	elif charging:
		z_index = 0
		if faceoff_shake > 0:
			$Sprite.position = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		else:
			$Sprite.position = Vector2.ZERO
		if started_charge == 0:
			started_charge = Globals.ticks
		anim_name = "Shoot Left"
		frame = min(int((Globals.ticks - started_charge) / 4.0), 2)
	elif not spring.node_b.is_empty():
		z_index = 0
		if faceoff_shake > 0:
			$Sprite.position = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		else:
			$Sprite.position = Vector2.ZERO
		started_charge = 0
		if checking > Globals.ticks:
			if look_dir == LookDir.UP:
				anim_name = "Pummel Up"
			elif look_dir == LookDir.DOWN:
				anim_name = "Pummel Down"
			else:
				anim_name = "Check Left"
		else:
			if look_dir == LookDir.UP:
				anim_name = "Grab Up"
			elif look_dir == LookDir.DOWN:
				anim_name = "Grab Down"
			else:
				anim_name = "Grab Left"
	elif checking > Globals.ticks:
		z_index = 0
		if faceoff_shake > 0:
			$Sprite.position = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		else:
			$Sprite.position = Vector2.ZERO
		started_charge = 0
		if look_dir == LookDir.UP:
			anim_name = "Check Up"
		elif look_dir == LookDir.DOWN:
			anim_name = "Check Down"
		else:
			anim_name = "Check Left"
	else:
		z_index = 0
		if faceoff_shake > 0:
			$Sprite.position = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		else:
			$Sprite.position = Vector2.ZERO
		started_charge = 0
		if speed > 5:
			frame = (int(counter / 10.0) % 6)
			if look_dir == LookDir.UP:
				anim_name = "Skate Up"
			elif look_dir == LookDir.DOWN:
				anim_name = "Skate Down"
			else:
				anim_name = "Skate Left"
		else:
			frame = 0
			if look_dir == LookDir.UP:
				anim_name = "Skate Up"
			elif look_dir == LookDir.DOWN:
				anim_name = "Skate Down"
			else:
				anim_name = "Skate Left"

	if home_team:
		if Globals.home_textures[skater_size].has(anim_name):
			$Sprite.texture = Globals.home_textures[skater_size][anim_name]
	else:
		if Globals.away_textures[skater_size].has(anim_name):
			$Sprite.texture = Globals.away_textures[skater_size][anim_name]

	var spacing = 192
	$Sprite.region_rect = Rect2(frame * spacing, 0, 192, 192) #statbook.sprite_index
	$Sprite.region_enabled = true
	if abs(last_move.angle_to(linear_velocity)) > 3.1 and Globals.ticks > scrape_counter:
		var s: Icesputter = preload("res://objects/environment/icesplutter.tscn").instantiate()
		Globals.manager.add_child(s)
		skate_dir = linear_velocity
		scrape_counter = Globals.ticks + 20
		if linear_velocity.x > 0:
			var m: ParticleProcessMaterial = s.process_material
			m.direction.x = -m.direction.x
		s.global_position = (global_position + Vector2.DOWN * 16)
	skate_dir = skate_dir.lerp(self.linear_velocity, 0.03)

func impulse(dx: float, dy: float) -> void:
	if knocked_over > Globals.ticks or checking > Globals.ticks or anim_state in ["entering_penalty", "in_penalty", "leaving_penalty", "return_from_penalty"]:
		return
	last_move = Vector2(dx, dy)
	if last_move.length() > 0:
		counter += 1
	if last_move.length_squared() > 0:
		facing_dir = last_move.normalized()
	apply_impulse(last_move * statbook.speed)

func shoot(dir: Vector2, power: float, inaccuracy_modifier: float = 1) -> void:
	if knocked_over > Globals.ticks or checking > Globals.ticks or anim_state in ["entering_penalty", "in_penalty", "leaving_penalty", "return_from_penalty"]:
		return
	var vec = dir.normalized() * 200 * (statbook.snap_power + ((1 - statbook.snap_power) * power)) * statbook.shot_power
	var vec2 = vec.rotated(inaccuracy_modifier * statbook.shot_variance * (1 - (2*randf())))
	if puck:
		puck.shoot(name, vec2)
		set_collision_layer_value(4, false)
		if power < 0.33:
			Globals.play_sound_at("HitSlow", global_position)
		elif power < 0.90:
			Globals.play_sound_at("HitMedium", global_position)
		else:
			Globals.play_sound_at("HitFast", global_position)
		var s: GPUParticles2D = preload("res://objects/environment/icesplutter.tscn").instantiate()
		Globals.manager.add_child(s)
		s.global_position = (global_position + dir.normalized() * 16)

		var camera = get_viewport().get_camera_2d()
		if camera:
			var shake_amount = 2.0 + (power * 8.0)
			var shake_tween = create_tween()
			shake_tween.tween_property(camera, "offset", Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount)), 0.05)
			shake_tween.tween_property(camera, "offset", Vector2(randf_range(-shake_amount/2.0, shake_amount/2.0), randf_range(-shake_amount/2.0, shake_amount/2.0)), 0.05)
			shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if (anim_state == "lerping" or anim_state == "face_off") and penalty_time <= 0:
		var trans = state.get_transform()
		trans.origin = trans.origin.lerp(initial_position, 0.05)
		state.set_transform(trans)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		$Sprite.modulate.a = min(1.0, $Sprite.modulate.a + state.step * 2.0)
		return

	if needs_reset:
		var trans = state.get_transform()
		trans.origin = initial_position
		state.set_transform(trans)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		needs_reset = false
		initial_position = base_initial_position
		return

	if needs_penalty_reset:
		var trans = state.get_transform()
		trans.origin = Vector2(1000, 950) # Penalty box position
		state.set_transform(trans)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		needs_penalty_reset = false
		return

	if anim_state == "in_penalty":
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		return

	for i in range(state.get_contact_count()):
		var myimpulse: Vector2 = state.get_contact_local_velocity_at_position(i)
		var collider = state.get_contact_collider_object(i)
		if collider is Goalie:
			# Bounce away from goalie
			var bounce_dir = (global_position - collider.global_position).normalized()
			state.linear_velocity = bounce_dir * 300.0
			Globals.play_sound_at("Bump", global_position)
			continue

		if "mass" in collider:
			myimpulse *= 1 + (collider.mass - mass)
		var impulse_strength: float = myimpulse.length()
		if impulse_strength > 150.0:
			rammed = true
			if "statbook" in collider and collider.statbook:
				var target_downed_before = knocked_over > Globals.ticks
				# Take half check damage when rammed hard by someone
				take_damage(collider.statbook.check_damage * randf_range(0.8, 1.2) * 0.5)
				Globals.play_sound_at("Bump", global_position)
				if collider.has_method("get_player_name"):
					var collider_name = collider.get_player_name()
					if not Globals.hit_stats.has(collider_name):
						Globals.hit_stats[collider_name] = 0
					Globals.hit_stats[collider_name] += 1
					if not target_downed_before and knocked_over > Globals.ticks:
						if not Globals.down_stats.has(collider_name):
							Globals.down_stats[collider_name] = 0
						Globals.down_stats[collider_name] += 1
			else:
				take_damage(10)
				Globals.play_sound_at("Board", global_position)
