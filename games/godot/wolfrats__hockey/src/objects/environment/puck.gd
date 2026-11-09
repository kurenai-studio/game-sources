class_name Puck extends RigidBody2D
@export var posessor: Skater
var blocklist: Dictionary[String, float] = {}
var colidable: bool = true
var initial_position: Vector2
var needs_reset: bool = false
var block_all: int = 0
var last_possessor: String = ""
var assist_possessor: String = ""
var possessor_team: bool = false
var shot_on_goal_counted: bool = false

func _ready() -> void:
	initial_position = global_position

func home() -> void:
	needs_reset = true
	if self.posessor:
		self.posessor.puck = null
	self.posessor = null
	self.freeze = false
	shot_on_goal_counted = false

func _process(delta: float) -> void:
	if posessor:
		freeze = true
		($PointerAbove).visible = true
		($CollisionShape2D).disabled = freeze 
		self.global_position = posessor.global_position + posessor.facing_dir * 30.0
	else:
		freeze = false
		($CollisionShape2D).disabled = freeze 
		($PointerAbove).visible = false
	if Globals.ticks > block_all:
		set_collision_mask_value(4, true)
	var to_erase: Array[String] = []
	for key in blocklist:
		blocklist[key] -= delta
		if blocklist[key] <= 0:
			to_erase.append(key)

	for key in to_erase:
		blocklist.erase(key)

func _physics_process(_delta: float) -> void:
	if global_position.x < -200 or global_position.x > 2200 or global_position.y < -200 or global_position.y > 1400:
		home()
	_update_pointer()

	#if posessor:
		## Manual check for stealing when frozen
		#for skater in get_tree().get_nodes_in_group("skaters"):
			#if skater != posessor and (not blocklist.has(skater.name)) and colidable and not skater.puck:
				#if skater.global_position.distance_to(global_position) < 40.0:
					#assign_possessor(skater)
					#break # Only one stealer per frame

	for body in get_colliding_bodies():
		if body is Skater and (not blocklist.has(body.name)) and colidable and not body.puck:
			assign_possessor(body)
			
func assign_possessor(body: Skater) -> void:
	var prev_possessor = posessor

	if posessor:
		posessor.puck = null

	posessor = body
	posessor.puck = self
	if posessor.ghost == null:
		var manager = posessor.get_parent().get_parent()
		var ghosts_node = manager.get_node_or_null("Ghosts")
		if ghosts_node:
			var closest_player = null
			var min_dist = INF
			for p in ghosts_node.get_children():
				if p.name.begins_with("Player") and p.player_index >= 0:
					if p.skater and p.skater.home_team == posessor.home_team and (p.player_index >= Globals.player_auto_swap.size() or Globals.player_auto_swap[p.player_index]):
						var dist = p.skater.global_position.distance_to(posessor.global_position)
						if dist < min_dist:
							min_dist = dist
							closest_player = p
			if closest_player:
				var old_skater = closest_player.skater
				if old_skater:
					old_skater.ghost = null
				posessor.ghost = closest_player
				closest_player.skater = posessor

	var current_name = ("Home AI" if posessor.home_team else "Away AI")
	if posessor.ghost:
		current_name = posessor.ghost.name

	if prev_possessor != posessor:
		if posessor.home_team == possessor_team and current_name != last_possessor:
			assist_possessor = last_possessor
		elif posessor.home_team != possessor_team:
			assist_possessor = ""
		last_possessor = current_name
		possessor_team = posessor.home_team

func do_shoot(vector):
	freeze = false
	apply_impulse(vector)
	var new_transform = get_transform() 
	new_transform.origin = global_position
	set_transform(new_transform)

func shoot(shooter, vector) -> bool:
	if not posessor or shooter != posessor.name:
		return false
	posessor.puck = null
	Globals.manager.shot.emit(posessor.home_team, global_position, vector)
	posessor = null
	blocklist[shooter] = 0.25
	#block_all = Globals.ticks + 1
	#get_tree().create_timer(1.0/60.0).timeout.connect(_enable_collision)
	#set_collision_mask_value(4, false)
	set_deferred("freeze", false)
	call_deferred("do_shoot", vector)
	shot_on_goal_counted = false
	return true

func _enable_collision() -> void:
	set_collision_mask_value(4, true)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if needs_reset:
		var trans = state.get_transform()
		trans.origin = initial_position
		state.set_transform(trans)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		needs_reset = false
		
func _update_pointer() -> void:
	if not has_node("Pointer"):
		return
	var pointer = $Pointer
	var viewport = get_viewport()
	var canvas_transform = viewport.get_canvas_transform()
	var screen_pos = canvas_transform * global_position
	var viewport_rect = viewport.get_visible_rect()

	var margin = 40.0
	var bounds = viewport_rect.grow(-margin)

	if bounds.has_point(screen_pos):
		pointer.visible = false
	else:
		pointer.visible = true

		var clamped_pos = screen_pos
		clamped_pos.x = clamp(screen_pos.x, bounds.position.x, bounds.end.x)
		clamped_pos.y = clamp(screen_pos.y, bounds.position.y, bounds.end.y)

		pointer.global_position = canvas_transform.affine_inverse() * clamped_pos

		var point_dir = (screen_pos - clamped_pos).normalized()
		if point_dir.length_squared() > 0:
			pointer.global_rotation = point_dir.angle() - PI/2
