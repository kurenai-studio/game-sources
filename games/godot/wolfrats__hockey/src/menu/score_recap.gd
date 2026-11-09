extends Control

@onready var score_label: Label = %ScoreLabel
@onready var stats_container: VBoxContainer = %StatsContainer

func _ready() -> void:
	if Season.season_on:
		$CenterContainer/VBoxContainer/Buttons/Rematch.visible = false
		$CenterContainer/VBoxContainer/Buttons/Menu.visible = false
		$CenterContainer/VBoxContainer/Buttons/Continue.visible = true
		$CenterContainer/VBoxContainer/Buttons/Continue.grab_focus()
	else:
		$CenterContainer/VBoxContainer/Buttons/Rematch.visible = true
		$CenterContainer/VBoxContainer/Buttons/Menu.visible = true
		$CenterContainer/VBoxContainer/Buttons/Continue.visible = false
		$CenterContainer/VBoxContainer/Buttons/Rematch.grab_focus()


	score_label.text = "%d - %d" % [Globals.match_home_score, Globals.match_away_score]

	var all_players = []
	for p in Globals.scorer_stats.keys():
		if not all_players.has(p):
			all_players.append(p)
	for p in Globals.assist_stats.keys():
		if not all_players.has(p):
			all_players.append(p)
	for p in Globals.shot_stats.keys():
		if not all_players.has(p):
			all_players.append(p)
	for p in Globals.faceoff_won_stats.keys():
		if not all_players.has(p):
			all_players.append(p)
	for p in Globals.penalty_stats.keys():
		if not all_players.has(p):
			all_players.append(p)
	for p in Globals.check_stats.keys():
		if not all_players.has(p):
			all_players.append(p)
	for p in Globals.hit_stats.keys():
		if not all_players.has(p):
			all_players.append(p)
	for p in Globals.down_stats.keys():
		if not all_players.has(p):
			all_players.append(p)

	if all_players.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No stats recorded."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(empty_label)
	else:
		for p in all_players:
			var g = 0
			if Globals.scorer_stats.has(p):
				g = Globals.scorer_stats[p]
			var a = 0
			if Globals.assist_stats.has(p):
				a = Globals.assist_stats[p]
			var s = 0
			if Globals.shot_stats.has(p):
				s = Globals.shot_stats[p]
			var f = 0
			if Globals.faceoff_won_stats.has(p):
				f = Globals.faceoff_won_stats[p]
			var pen = 0
			if Globals.penalty_stats.has(p):
				pen = Globals.penalty_stats[p]
			var checks = 0
			if Globals.check_stats.has(p):
				checks = Globals.check_stats[p]
			var hits = 0
			if Globals.hit_stats.has(p):
				hits = Globals.hit_stats[p]
			var downs = 0
			if Globals.down_stats.has(p):
				downs = Globals.down_stats[p]

			var display_name = p
			if display_name == "Player":
				display_name = "Player 1"
			elif display_name.begins_with("Player"):
				display_name = "Player " + display_name.trim_prefix("Player")
			var display_color_code = Globals.player_colors_map.get(display_name, "ffffff")
			var stat_label = RichTextLabel.new()
			stat_label.fit_content = true
			stat_label.bbcode_enabled = true
			stat_label.text = (
				"[color=#%s]%s[/color]: %d Goals, %d Assists, %d Shots, %d Faceoffs Won, " %
				[display_color_code, display_name, g, a, s, f] +
				"%d Penalties, %d Checks, %d Hits, %d Downs" %
				[pen, checks, hits, downs]
			)
			stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stats_container.add_child(stat_label)

func _on_rematch_pressed() -> void:
	Globals.scorer_stats.clear()
	Globals.assist_stats.clear()
	Globals.shot_stats.clear()
	Globals.faceoff_won_stats.clear()
	Globals.penalty_stats.clear()
	Globals.check_stats.clear()
	Globals.hit_stats.clear()
	Globals.down_stats.clear()
	Globals.match_home_score = 0
	Globals.match_away_score = 0
	get_tree().change_scene_to_file("res://objects/environment/match_rink.tscn")

func _on_menu_pressed() -> void:
	Globals.scorer_stats.clear()
	Globals.assist_stats.clear()
	Globals.shot_stats.clear()
	Globals.faceoff_won_stats.clear()
	Globals.penalty_stats.clear()
	Globals.check_stats.clear()
	Globals.hit_stats.clear()
	Globals.down_stats.clear()
	Globals.match_home_score = 0
	Globals.match_away_score = 0
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")

func _on_continue_pressed() -> void:
	Season.record_match(
		Globals.home_team_index,
		Globals.away_team_index,
		Globals.match_home_score,
		Globals.match_away_score
	)
	Season.simulate_other_matches()
	Season.advance_week()

	Globals.scorer_stats.clear()
	Globals.assist_stats.clear()
	Globals.shot_stats.clear()
	Globals.faceoff_won_stats.clear()
	Globals.penalty_stats.clear()
	Globals.check_stats.clear()
	Globals.hit_stats.clear()
	Globals.down_stats.clear()
	Globals.match_home_score = 0
	Globals.match_away_score = 0
	get_tree().change_scene_to_file("res://menu/season_hub.tscn")
