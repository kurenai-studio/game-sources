class_name AnimationManager
extends Node

enum Phase {
	PRE_GAME_SKATE,
	PRE_GAME_LERP,
	PLAYING,
	POST_GOAL_SKATE,
	POST_GOAL_LERP,
	POST_PERIOD_SKATE_OUT,
	POST_PERIOD_WAIT,
	PRE_PERIOD_SKATE,
	PRE_PERIOD_LERP,
	PRE_PENALTY_SKATE,
	PRE_PENALTY_LERP,
	FACE_OFF,
	REPLAY
}




var lights: Node



var current_phase: Phase = Phase.PRE_GAME_SKATE
var phase_timer: float = 0.0
var manager: Node = null

func _ready() -> void:
	manager = get_parent()
	set_phase(Phase.PRE_GAME_SKATE)
	lights = get_tree().root.get_node_or_null("Rink/Lights")

func _process(delta: float) -> void:
	if current_phase == Phase.PLAYING:
		return

	phase_timer -= delta

	match current_phase:
		Phase.PRE_GAME_SKATE:
			var start = false
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("pass") \
					or Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("swap") \
					or Input.is_action_just_pressed("check"):
				start = true
			for device in Globals.player_devices:
				if device >= 0:
					if Input.is_joy_button_pressed(device, JOY_BUTTON_A) or \
					Input.is_joy_button_pressed(device, JOY_BUTTON_X) \
						or Input.is_joy_button_pressed(device, JOY_BUTTON_Y) \
				or Input.is_joy_button_pressed(device, JOY_BUTTON_B):
						start = true

			for i in range(0, 3):
				var light: PointLight2D = lights.get_children()[i]
				i += 1
				var radius_large = 60 + i * 9
				var radius_small = 30 - i * 4
				var dist = 40 + i * 20
				var scale = 3
				var time = Globals.ticks / (90.0 - i)
				var diff = radius_large - radius_small
				var mult = diff / radius_small * time
				var x = (diff * cos(time) + dist * cos(mult)) * scale
				var y = (diff * sin(time) + dist * sin(mult)) * scale
				light.global_position = Vector2(1000 + x, 512 + y)
			if start:
				set_phase(Phase.PRE_GAME_LERP)
				get_tree().root.get_node("Rink/CanvasModulate").color = Color.WHITE
				for i in range(0, 3):
					var light: PointLight2D = lights.get_children()[i]
					light.visible = false
		Phase.PRE_GAME_LERP:
			if phase_timer <= 0:
				set_phase(Phase.FACE_OFF)
		Phase.POST_GOAL_SKATE:
			if phase_timer <= 0:
				set_phase(Phase.POST_GOAL_LERP)
		Phase.POST_GOAL_LERP:
			if phase_timer <= 0:
				set_phase(Phase.REPLAY)
		Phase.REPLAY:
			var skip = false
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("pass") \
					or Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("swap") \
					or Input.is_action_just_pressed("check"):
				skip = true
			for device in Globals.player_devices:
				if device >= 0:
					if Input.is_joy_button_pressed(device, JOY_BUTTON_A) or \
					Input.is_joy_button_pressed(device, JOY_BUTTON_X) \
						or Input.is_joy_button_pressed(device, JOY_BUTTON_Y) \
				or Input.is_joy_button_pressed(device, JOY_BUTTON_B):
						skip = true
			if skip:
				if manager and manager.has_method("stop_replay"):
					manager.stop_replay()
				set_phase(Phase.FACE_OFF)
		Phase.POST_PERIOD_SKATE_OUT:
			if phase_timer <= 0:
				set_phase(Phase.POST_PERIOD_WAIT)
		Phase.POST_PERIOD_WAIT:
			if phase_timer <= 0:
				if manager.current_period >= 3:
					manager.current_period += 1
					Globals.match_home_score = manager.home_score
					Globals.match_away_score = manager.away_score
					get_tree().change_scene_to_file("res://menu/score_recap.tscn")
				else:
					set_phase(Phase.PRE_PERIOD_SKATE)
		Phase.PRE_PERIOD_SKATE:
			var start = false
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("pass") \
					or Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("swap") \
					or Input.is_action_just_pressed("check"):
				start = true
			for device in Globals.player_devices:
				if device >= 0:
					if Input.is_joy_button_pressed(device, JOY_BUTTON_A) or \
					Input.is_joy_button_pressed(device, JOY_BUTTON_X) \
						or Input.is_joy_button_pressed(device, JOY_BUTTON_Y) \
				or Input.is_joy_button_pressed(device, JOY_BUTTON_B):
						start = true
			if start:
				set_phase(Phase.PRE_PERIOD_LERP)
		Phase.PRE_PERIOD_LERP:
			if phase_timer <= 0:
				# Move to next period
				manager.current_period += 1
				manager.time_remaining = Globals.period_length
				set_phase(Phase.FACE_OFF)
		Phase.PRE_PENALTY_SKATE:
			if phase_timer <= 0:
				set_phase(Phase.PRE_PENALTY_LERP)
		Phase.PRE_PENALTY_LERP:
			if phase_timer <= 0:
				set_phase(Phase.PLAYING)
				#set_phase(Phase.FACE_OFF)
		Phase.FACE_OFF:
			if phase_timer <= 1.0 and phase_timer + delta > 1.0:
				var referees = get_tree().get_nodes_in_group("referees")
				for ref in referees:
					if ref.has_method("shake"):
						ref.shake()

			if phase_timer <= 0:
				var pucks = get_tree().get_nodes_in_group("pucks")
				for p in pucks:
					p.freeze = false

func set_phase(new_phase: Phase) -> void:
	current_phase = new_phase

	var skaters = get_tree().get_nodes_in_group("skaters")
	var pucks = get_tree().get_nodes_in_group("pucks")

	match current_phase:
		Phase.PRE_GAME_SKATE:
			phase_timer = 3.0
			var circle = true
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = "skating_circle" if circle else "skating_figure8"
					circle = not circle
			for p in pucks:
				p.visible = false
				p.freeze = true
				if "colidable" in p:
					p.colidable = false

		Phase.PRE_GAME_LERP:
			phase_timer = 1.5
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = "lerping"

		Phase.REPLAY:
			if manager and manager.has_method("start_replay"):
				manager.start_replay()

		Phase.PLAYING:
			($"../../Boards/BoardsCollision").disabled = false
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = ""
					if "base_initial_position" in s:
						s.initial_position = s.base_initial_position

			var referees = get_tree().get_nodes_in_group("referees")
			for ref in referees:
				if "anim_state" in ref:
					ref.anim_state = ""

			for p in pucks:
				p.visible = true
				if "colidable" in p:
					p.colidable = true

		Phase.FACE_OFF:
			phase_timer = randf_range(5.0, 10.0)
			if manager:
				for child in manager.get_children():
					if child is Goalie and child.pulled:
						child.return_to_net()
			skaters = get_tree().get_nodes_in_group("skaters") # refresh in case extra attackers were removed
			var team_has_penalty = false
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						team_has_penalty = true
						continue
					s.anim_state = "face_off"
			for p in pucks:
				p.visible = true
				p.freeze = true
				if "colidable" in p:
					p.colidable = true
				p.home()
				# Set puck to center of the rink
				if team_has_penalty:
					# Find penalized skater and set faceoff position based on their team
					var penalized_skater = null
					for s in skaters:
						if "penalty_time" in s and s.penalty_time > 0:
							penalized_skater = s
							break
					if penalized_skater:
						if penalized_skater.home_team:
							p.global_position = Vector2(590, 282) # Home side defensive zone faceoff dot
						else:
							p.global_position = Vector2(1600, 720) # Away side defensive zone faceoff dot
					else:
						p.global_position = Vector2(1005.5, 509)
				else:
					p.global_position = Vector2(1005.5, 509)

			var faceoff_pos = Vector2(1005.5, 509)
			if pucks.size() > 0:
				faceoff_pos = pucks[0].global_position

			var referees = get_tree().get_nodes_in_group("referees")
			for ref in referees:
				if "anim_state" in ref:
					ref.anim_state = "skate_to"
					ref.target_pos = faceoff_pos

			var home_skaters = []
			var away_skaters = []
			for s in skaters:
				if "anim_state" in s and s.anim_state == "face_off":
					if s.home_team:
						home_skaters.append(s)
					else:
						away_skaters.append(s)

			var radius = 150.0

			for i in range(home_skaters.size()):
				var s = home_skaters[i]
				if i == 0:
					s.initial_position = faceoff_pos + Vector2(-60, 0)
				else:
					var num_arc = max(1, home_skaters.size() - 1)
					var angle = PI/2 + PI * (float(i - 1) / max(1, num_arc - 1))
					s.initial_position = faceoff_pos + Vector2(cos(angle) * radius, sin(angle) * radius)
				s.puck = null
				if "statbook" in s and s.statbook != null:
					s.health = s.statbook.max_health
				if "penalty_time" in s:
					s.penalty_time = 0.0
				if "needs_reset" in s:
					s.needs_reset = false

			for i in range(away_skaters.size()):
				var s = away_skaters[i]
				if i == 0:
					s.initial_position = faceoff_pos + Vector2(60, 0)
				else:
					var num_arc = max(1, away_skaters.size() - 1)
					var angle = -PI/2 + PI * (float(i - 1) / max(1, num_arc - 1))
					s.initial_position = faceoff_pos + Vector2(cos(angle) * radius, sin(angle) * radius)
				s.puck = null
				if "statbook" in s and s.statbook != null:
					s.health = s.statbook.max_health
				if "penalty_time" in s:
					s.penalty_time = 0.0
				if "needs_reset" in s:
					s.needs_reset = false
		Phase.POST_GOAL_SKATE:
			phase_timer = 2.0
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = "skating_around"

		Phase.POST_GOAL_LERP:
			phase_timer = 1.5
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = "lerping"
			for p in pucks:
				p.visible = false
				p.freeze = true
				if "colidable" in p:
					p.colidable = false

		Phase.POST_PERIOD_SKATE_OUT:
			phase_timer = 2.5
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = "skating_out"
			($"../../Boards/BoardsCollision").disabled = true
			for p in pucks:
				p.visible = false
				p.freeze = true
				if "colidable" in p:
					p.colidable = false

		Phase.POST_PERIOD_WAIT:
			phase_timer = 3.5
			# Wait a bit before coming back

		Phase.PRE_PERIOD_SKATE:
			phase_timer = 4.0
			var circle = true
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = "skating_circle" if circle else "skating_figure8"
					circle = not circle

		Phase.PRE_PERIOD_LERP:
			phase_timer = 1.5
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "in_penalty" or \
					s.anim_state == "entering_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = "lerping"
		Phase.PRE_PENALTY_SKATE:
			phase_timer = 2.0
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "entering_penalty" or \
					s.anim_state == "in_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						continue
					s.anim_state = "skating_around"
			for p in pucks:
				p.visible = false
				p.freeze = true
				if "colidable" in p:
					p.colidable = false
		Phase.PRE_PENALTY_LERP:
			phase_timer = 1.5
			var team_has_penalty = false
			for s in skaters:
				if "anim_state" in s:
					if s.anim_state == "entering_penalty" or \
					s.anim_state == "in_penalty" or \
										s.anim_state == "leaving_penalty" or \
																				s.anim_state == "return_from_penalty":
						team_has_penalty = true
						continue
					s.anim_state = "lerping"
			for p in pucks:
				p.visible = false
				p.freeze = true
				if "colidable" in p:
					p.colidable = false
				if team_has_penalty:
					# Find penalized skater and set faceoff position based on their team
					var penalized_skater = null
					for s in skaters:
						if "penalty_time" in s and s.penalty_time > 0:
							penalized_skater = s
							break
					if penalized_skater:
						if penalized_skater.home_team:
							p.global_position = Vector2(400, 300) # Home side defensive zone faceoff dot
						else:
							p.global_position = Vector2(1600, 700) # Away side defensive zone faceoff dot
					else:
						p.global_position = Vector2(1005.5, 509)
				else:
					p.global_position = Vector2(1005.5, 509)

			var faceoff_pos = Vector2(1005.5, 509)
			if pucks.size() > 0:
				faceoff_pos = pucks[0].global_position

			var referees = get_tree().get_nodes_in_group("referees")
			for ref in referees:
				if "anim_state" in ref:
					ref.anim_state = "skate_to"
					ref.target_pos = faceoff_pos

			for s in skaters:
				if "anim_state" in s \
				and not (s.anim_state in ["in_penalty", "entering_penalty"]) \
				and not (s.anim_state in ["leaving_penalty", "return_from_penalty"]) \
				and s.has_method("home") \
				and "initial_position" in s:
					var x_offset = 0
					if pucks.size() > 0:
						x_offset = pucks[0].global_position.x - 1005.5

					# Create a temporary modified "initial_position" for the home method
					if x_offset != 0 and abs(x_offset) > 10:
						if not s.has_meta("base_initial_position"):
							s.set_meta("base_initial_position", s.initial_position)
						var target_x = clamp(s.get_meta("base_initial_position").x + x_offset, 350, 1650)
						# BAD CODE BAD LLM!
						#s.initial_position = Vector2(target_x, s.get_meta("base_initial_position").y + 200)
					elif s.has_meta("base_initial_position"):
						pass
						#s.initial_position = s.get_meta("base_initial_position")


func on_goal_scored() -> void:
	if current_phase == Phase.PLAYING:
		set_phase(Phase.POST_GOAL_SKATE)

func on_period_end() -> void:
	if current_phase == Phase.PLAYING:
		set_phase(Phase.POST_PERIOD_SKATE_OUT)
