extends Ghost
@export var device_id: int = 0
var skater
var puck: Puck
var power: float = 0
var charge: float = 0.03
var shot_dir: Vector2
var player_index: int = -1

var prev_button_state = {}
var cur_button_state = {}

var action_map = {
	"swap": JOY_BUTTON_Y,
	"check": JOY_BUTTON_B,
	"grab": JOY_BUTTON_RIGHT_SHOULDER,
	"shoot": JOY_BUTTON_X,
	"pass": JOY_BUTTON_A,
}

func _update_buttons() -> void:
	if device_id < 0:
		return
	for action in action_map.keys():
		if not prev_button_state.has(action):
			prev_button_state[action] = false
			cur_button_state[action] = false
		else:
			prev_button_state[action] = cur_button_state[action]

		cur_button_state[action] = Input.is_joy_button_pressed(device_id, action_map[action])

func set_color(c: Color) -> void:
	if has_node("Pointer"):
		$Pointer.modulate = c
	if has_node("CircleFill"):
		$CircleFill.modulate = c
	if has_node("Angle"):
		$Angle.default_color = c

func is_action_just_pressed_custom(action: String) -> bool:
	if device_id == -2 and Input.is_action_just_pressed(action):
		return true
	if device_id >= 0 and cur_button_state.has(action):
		return cur_button_state[action] and not prev_button_state[action]
	return false

func is_action_pressed_custom(action: String) -> bool:
	if device_id == -2 and Input.is_action_pressed(action):
		return true
	if device_id >= 0 and cur_button_state.has(action):
		return cur_button_state[action]
	return false

func is_action_just_released_custom(action: String) -> bool:
	if device_id == -2 and Input.is_action_just_released(action):
		return true
	if device_id >= 0 and cur_button_state.has(action):
		return not cur_button_state[action] and prev_button_state[action]
	return false

func get_axis_custom(axis_name: String) -> float:
	var val = 0.0
	if device_id == -2:
		if axis_name == "skate_x":
			val = Input.get_axis("skate_left", "skate_right")
		elif axis_name == "skate_y":
			val = Input.get_axis("skate_up", "skate_down")
	if device_id >= 0:
		var joy_val = 0.0
		if axis_name == "skate_x":
			joy_val = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
		elif axis_name == "skate_y":
			joy_val = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)

		if abs(joy_val) > 0.2:
			if abs(joy_val) > abs(val):
				val = joy_val
	return val

func _physics_process(_delta: float) -> void:
	_update_buttons()
	var hide_indicator = false
	if Globals.manager and Globals.manager.anim_manager:
		var phase = Globals.manager.anim_manager.current_phase
		if phase == AnimationManager.Phase.POST_PERIOD_SKATE_OUT:
			hide_indicator = true
		elif phase == AnimationManager.Phase.POST_PERIOD_WAIT:
			hide_indicator = true
	if hide_indicator:
		visible = false
	else:
		visible = (skater != null)
	if not skater:
		return
	global_position = skater.global_position#global_position.lerp(skater.global_position, 0.1)
	_update_pointer()
	if is_action_just_pressed_custom("swap"):
		var team_node = "Team1" if skater.home_team else "Team2"
		var siblings = Globals.manager.get_node(team_node).get_children()
		if Globals.allow_goalie_control:
			var manager = Globals.manager
			if manager:
				for child in manager.get_children():
					if child is Goalie and child.home_team == skater.home_team and not child.pulled:
						if not siblings.has(child):
							siblings.append(child)

		var num_siblings = siblings.size()
		var current_idx = siblings.find(skater)

		for i in range(1, num_siblings):
			var idx = (current_idx + i) % num_siblings
			var newskater = siblings[idx]
			if ("ghost" in newskater) and newskater.ghost == null:
				skater.release_grab()
				skater.ghost = null
				newskater.ghost = self
				skater = newskater
				return

func get_best_pass_target(cur_skater, input_dir: Vector2) -> Node2D:
	var nodes = get_tree().get_nodes_in_group("skaters")
	var best_teammate = null
	var min_angle: float = INF

	if input_dir.length_squared() < 0.01:
		input_dir = cur_skater.facing_dir
	input_dir = input_dir.normalized()

	for node in nodes:
		if node is Skater and node.home_team == cur_skater.home_team and node != cur_skater:
			var to_node = (node.global_position - cur_skater.global_position).normalized()
			var angle = abs(input_dir.angle_to(to_node))
			if angle < min_angle:
				min_angle = angle
				best_teammate = node
	return best_teammate

func handle(_delta: float, cur_skater) -> void:
	self.skater = cur_skater
	var dx = get_axis_custom("skate_x")
	var dy = get_axis_custom("skate_y")

	if is_action_just_pressed_custom("check"):
		cur_skater.do_check()

	if is_action_pressed_custom("grab"):
		cur_skater.do_grab(is_action_just_pressed_custom("grab"))
	if is_action_just_released_custom("grab"):
		if cur_skater.has_method("release_grab"):
			cur_skater.release_grab()

	if is_action_just_pressed_custom("pass") and cur_skater.puck:
		var input_dir = Vector2(dx, dy)
		var teammate = get_best_pass_target(cur_skater, input_dir)
		if teammate:
			var dir = ((teammate.global_position + Vector2(6, 30)) - cur_skater.global_position).normalized()
			cur_skater.shoot(dir, 0.5, 0)


	if is_action_just_released_custom("pass") and not cur_skater.puck:
		var nodes = get_tree().get_nodes_in_group("skaters")
		for node in nodes:
			var is_teammate = node is Skater and node.home_team == cur_skater.home_team
			if is_teammate and node.puck and node.ghost == null:
				var dir = ((cur_skater.global_position + Vector2(6, 30)) - node.global_position).normalized()
				node.shoot(dir, 0.5, 0)
				break
	if is_action_just_pressed_custom("shoot"):
		shot_dir = Vector2(dx, dy)
	if not is_action_pressed_custom("shoot"):
		#if ((dx != 0) or (dy != 0)): cur_skater.counter += 1
		cur_skater.impulse(dx, dy)
		charge = 0.03
		#power = 0
		$Angle.visible = false
		cur_skater.charging = false
	else:
		if dx != 0 or dy != 0:
			shot_dir = shot_dir.lerp(Vector2(dx, dy), 0.1)
		$Angle.visible = true
		power += charge
		if power > 1:
			power = 1
			#charge = -charge
		elif power < 0:
			power = 0
			charge = -charge
		if power < 0.33:
			$Angle.default_color = Color(0.2, 0.8, 0.2, 1.0)
		elif power < 0.66:
			$Angle.default_color = Color(0.8, 0.8, 0.2, 1.0)
		else:
			$Angle.default_color = Color(0.8, 0.2, 0.2, 1.0)
		cur_skater.charging = true
		$Angle.set_point_position(1, shot_dir.normalized() * (power * 64 + 16))
	if is_action_just_released_custom("shoot"):
		if cur_skater.puck:
			cur_skater.shoot(shot_dir, power)
		power = 0



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
			pointer.global_rotation = point_dir.angle() + PI/2
