class_name Manager extends Node2D

signal shot(team: bool, position: Vector2, vector: Vector2)

const FAN_SCENE = preload("res://objects/environment/fan.tscn")

@export var is_practice: bool = false
var home_score: int = 0
var away_score: int = 0
var current_period: int = 1

var time_remaining: float = 0.0

var ui_layer: CanvasLayer
var score_label: Label
var timer_label: Label
var period_label: Label
var anim_manager: AnimationManager
var main_camera: Camera2D

var replay_buffer: Array = []
var is_replay: bool = false
var replay_index: int = 0
var replay_label: Label = null


func _enter_tree() -> void:
	Globals.manager = self


func _ready() -> void:
	# Create a new detached Camera for the Manager
	main_camera = Camera2D.new()
	add_child(main_camera)
	main_camera.make_current()

	setup_multiplayer()

	# Find and remove any existing Camera2D nodes from Player ghosts
	var ghosts_node = get_node_or_null("Ghosts")
	if ghosts_node:
		for child in ghosts_node.get_children():
			if child.name.begins_with("Player"):
				var cam = child.get_node_or_null("Camera2D")
				if cam:
					child.remove_child(cam)
					cam.queue_free()
	if not is_practice:
		anim_manager = AnimationManager.new()
		add_child(anim_manager)
		time_remaining = Globals.period_length
		setup_ui()
		Globals.scorer_stats.clear()
		Globals.assist_stats.clear()
		Globals.shot_stats.clear()
		Globals.faceoff_won_stats.clear()
		Globals.penalty_stats.clear()
		Globals.check_stats.clear()
		Globals.hit_stats.clear()
		Globals.down_stats.clear()
		var lights = %Lights.get_children()
		lights[0].color = StatBook.TEAMS[Globals.home_team_index]["body_color"]
		lights[0].color.v = 1
		lights[1].color = StatBook.TEAMS[Globals.home_team_index]["head_color"]
		lights[1].color.v = 1
		lights[2].color = StatBook.TEAMS[Globals.home_team_index]["foot_color"]
		lights[2].color.v = 1
		var home_logo = StatBook.TEAMS[Globals.home_team_index]["logo"]
		var home_logo_type = StatBook.TEAMS[Globals.home_team_index]["logo_style"]
		var logo_texture = load("res://sprites/logos/Clip {0}.png".format([home_logo]))
		if home_logo_type == 2:
			var logol = get_node_or_null("Logo2L")
			var logor = get_node_or_null("Logo2R")
			if logol: 
				logol.visible = true
				logol.texture = logo_texture
			if logor:
				logor.visible = true
				logor.texture = logo_texture
		elif home_logo_type == 1:
			var logoc = get_node_or_null("Logo1C")
			if logoc:
				logoc.visible = true
				logoc.texture = logo_texture
	for y in range(0, 4):
		for x in range(0, 2000, 50):
			var path: int = x + y * 50
			@warning_ignore("integer_division")
			if int(path / 150) % 3 == 0:
				continue
			var fan = FAN_SCENE.instantiate()
			add_child(fan)
			fan.global_position = Vector2(x + y * 20, 50 + y * -50)

			if x > 900 and x < 1120 and y == 0:  # no people near penalty box
				continue
			var fan2: Fan = FAN_SCENE.instantiate()
			add_child(fan2)
			fan2.global_position = Vector2(x + y * 20, y * 50 + 1024)
			fan2.scale.y = -1
			fan2.z_index = -y
	for x in range(0, 4):
		for y in range(0, 1024, 50):
			var path: int = y + x * 50
			@warning_ignore("integer_division")
			if int(path / 150) % 3 == 0:
				continue
			var fan = FAN_SCENE.instantiate()
			fan.side = true
			add_child(fan)
			fan.global_position = Vector2(x * -50, y + x * 20)

			var fan2: Fan = FAN_SCENE.instantiate()
			fan2.side = true
			add_child(fan2)
			fan2.global_position = Vector2(x * 50 + 2048, y + x * 20)
			fan2.scale.x = -1


func setup_multiplayer() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_players()


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_players()


func _update_players() -> void:
	var ghosts_node = get_node_or_null("Ghosts")
	if not ghosts_node:
		return
	var player1 = ghosts_node.get_node_or_null("Player")
	if not player1:
		return

	var active_devices = Globals.player_devices.duplicate()

	if active_devices.size() == 0:
		var joypads = Input.get_connected_joypads()
		for joy_id in joypads:
			if active_devices.size() < 4:
				active_devices.append(joy_id)

		# Ensure at least device -2 is active for keyboard/mouse if no controllers are plugged in
		if active_devices.size() == 0:
			active_devices.append(-2)
		else:
			# Keyboard is not added if fallback triggers with at least 1 controller
			pass

	var current_players = []
	for child in ghosts_node.get_children():
		if child.name.begins_with("Player"):
			current_players.append(child)

	# Add new players
	for i in range(current_players.size(), active_devices.size()):
		var new_player = player1.duplicate()
		new_player.name = "Player" + str(i + 1)

		# Remove camera from duplicate players
		var cam = new_player.get_node_or_null("Camera2D")
		if cam:
			new_player.remove_child(cam)
			cam.queue_free()

		ghosts_node.add_child(new_player)
		current_players.append(new_player)

	# Update device IDs and handle disconnected controllers
	var team1 = get_node_or_null("Team1")
	var team2 = get_node_or_null("Team2")
	var home_skaters = team1.get_children() if team1 else []
	var away_skaters = team2.get_children() if team2 else []

	# Keep track of assigned indices per team so we don't assign multiple players to the same skater
	var home_assigned_count = 0
	var away_assigned_count = 0

	var all_team_skaters = home_skaters + away_skaters
	for child in get_children():
		if child is Goalie:
			all_team_skaters.append(child)

	# First, unassign all ghosts
	for skater in all_team_skaters:
		skater.ghost = null

	for i in range(current_players.size()):
		var p = current_players[i]
		if i < active_devices.size():
			p.device_id = active_devices[i]
			p.player_index = i
			p.set_color(Globals.player_colors[i])
			# Determine which team this player belongs to based on Globals.player_teams
			var team_choice = 0
			if i < Globals.player_teams.size():
				team_choice = Globals.player_teams[i]

			if team_choice == 0:
				if home_assigned_count < home_skaters.size():
					home_skaters[home_assigned_count].ghost = p
					home_assigned_count += 1
			else:
				if away_assigned_count < away_skaters.size():
					away_skaters[away_assigned_count].ghost = p
					away_assigned_count += 1
		else:
			p.device_id = -1


func _process(delta: float) -> void:
	if not is_practice:
		if anim_manager.current_phase == AnimationManager.Phase.PLAYING:
			if current_period <= 3 and (current_period != 3 or time_remaining > 0):
				time_remaining -= delta
				if time_remaining <= 0:
					anim_manager.on_period_end()

		update_ui()

	# Update Camera Position
	if main_camera:
		var target_pos = Vector2.ZERO
		var target_count = 0

		# Add active player positions based on skaters that have ghosts assigned
		var team1 = get_node_or_null("Team1")
		var team2 = get_node_or_null("Team2")
		var all_skaters = []
		if team1:
			all_skaters += team1.get_children()
		if team2:
			all_skaters += team2.get_children()
		for child in get_children():
			if child is Goalie:
				all_skaters.append(child)

		for skater in all_skaters:
			if skater.ghost != null:
				target_pos += skater.global_position
				target_count += 1
		if target_count > 0:
			target_pos /= target_count
		target_count = 1
		var pucks_node = get_node_or_null("Pucks")
		if pucks_node:
			for puck in pucks_node.get_children():
				if puck is Puck:
					target_pos += puck.global_position
					target_count += 1
					break  # Just track the first puck

		if target_count > 0:
			target_pos /= target_count
			if anim_manager:
				var phase = anim_manager.current_phase
				if phase == AnimationManager.Phase.POST_PERIOD_SKATE_OUT:
					target_pos = Vector2(1005.5, 509)
				elif phase == AnimationManager.Phase.POST_PERIOD_WAIT:
					target_pos = Vector2(1005.5, 509)
			main_camera.global_position = main_camera.global_position.lerp(target_pos, 5.0 * delta)


func start_replay() -> void:
	is_replay = true
	replay_index = 0
	if ui_layer and not replay_label:
		replay_label = Label.new()
		replay_label.text = "REPLAY"
		replay_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		replay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		replay_label.add_theme_font_size_override("font_size", 48)
		replay_label.label_settings = LabelSettings.new()
		replay_label.label_settings.outline_size = 6
		replay_label.label_settings.font_size = 64
		replay_label.label_settings.outline_color = Color.BLACK
		replay_label.label_settings.font_color = Color.RED
		replay_label.position = Vector2(0, 100)
		ui_layer.add_child(replay_label)


func stop_replay() -> void:
	is_replay = false
	if replay_label:
		replay_label.queue_free()
		replay_label = null


func _physics_process(_delta: float) -> void:
	if not is_replay:
		var frame_data = {}

		# Skaters and Goalies
		var skaters = get_tree().get_nodes_in_group("skaters")
		var referees = get_tree().get_nodes_in_group("referees")
		var all_skaters = skaters + referees
		for s in all_skaters:
			var sprite = s.get_node_or_null("Sprite")
			if sprite:
				frame_data[s.get_instance_id()] = {
					"type": "skater",
					"position": s.global_position,
					"rotation": s.rotation,
					"z_index": s.z_index,
					"texture": sprite.texture,
					"sprite_pos": sprite.position,
					"region_rect": sprite.region_rect,
					"flip_h": sprite.flip_h,
					"modulate": sprite.modulate
				}

		# Pucks
		var pucks = get_tree().get_nodes_in_group("pucks")
		for p in pucks:
			frame_data[p.get_instance_id()] = {
				"type": "puck",
				"position": p.global_position,
				"rotation": p.rotation,
				"visible": p.visible
			}

		replay_buffer.append(frame_data)
		if replay_buffer.size() > 600:
			replay_buffer.pop_front()
	else:
		if replay_buffer.size() > 0:
			var frame_data = replay_buffer[replay_index]
			for id in frame_data:
				var node = instance_from_id(id)
				if node:
					var data = frame_data[id]
					if data["type"] == "skater":
						node.global_position = data["position"]
						node.rotation = data["rotation"]
						node.z_index = data["z_index"]
						var sprite = node.get_node_or_null("Sprite")
						if sprite:
							sprite.texture = data["texture"]
							sprite.position = data["sprite_pos"]
							sprite.region_rect = data["region_rect"]
							sprite.flip_h = data["flip_h"]
							sprite.modulate = data["modulate"]
					elif data["type"] == "puck":
						if node.posessor:
							node.posessor.puck = null
						node.posessor = null
						node.global_position = data["position"]
						node.rotation = data["rotation"]
						node.visible = data["visible"]

			replay_index += 1
			if replay_index >= replay_buffer.size():
				replay_index = 0

func setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	score_label = Label.new()
	score_label.text = "0 - 0"
	score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.label_settings = LabelSettings.new()
	score_label.label_settings.outline_size = 6
	score_label.label_settings.font_size = 64
	score_label.label_settings.outline_color = Color.BLACK
	ui_layer.add_child(score_label)

	period_label = Label.new()
	period_label.text = "Period 1"
	period_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	period_label.add_theme_font_size_override("font_size", 32)
	period_label.position = Vector2(20, 20)
	period_label.label_settings = LabelSettings.new()
	period_label.label_settings.outline_size = 6
	period_label.label_settings.font_size = 32
	period_label.label_settings.outline_color = Color.BLACK
	ui_layer.add_child(period_label)

	timer_label = Label.new()
	timer_label.text = "2:00"
	timer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.label_settings = period_label.label_settings
	timer_label.position = Vector2(-20, 20)
	timer_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ui_layer.add_child(timer_label)


func update_ui() -> void:
	score_label.text = "%d - %d" % [home_score, away_score]
	period_label.text = "Period %d" % current_period

	var mins = int(time_remaining / 60)
	var secs = int(time_remaining) % 60
	timer_label.text = "%d:%02d" % [mins, secs]


func goal_scored(goal_name: String, scorer: String = "", assister: String = "") -> void:
	if anim_manager.current_phase != AnimationManager.Phase.PLAYING:
		return
	if goal_name == "HomeGoal":
		away_score += 1
		Globals.play_sound_at("GoalAway", global_position,	 false)
	elif goal_name == "AwayGoal":
		home_score += 1
		Globals.play_sound_at("GoalHome", global_position, false)

	if scorer != "":
		if not Globals.scorer_stats.has(scorer):
			Globals.scorer_stats[scorer] = 0
		Globals.scorer_stats[scorer] += 1

	if assister != "":
		if not Globals.assist_stats.has(assister):
			Globals.assist_stats[assister] = 0
		Globals.assist_stats[assister] += 1
