extends Control

var home_team: int = -1
var away_team: int = -1
var is_season_over: bool = false

@onready var standings_container = %StandingsContainer
@onready var matchup_label = %MatchupLabel
@onready var matchup_title = %Title

func _ready() -> void:
	Season.season_on = true
	$VBoxContainer/Buttons/Play.grab_focus()
	update_standings()
	update_matchup()
	update_schedule()

func update_schedule() -> void:
	var schedule_container = %ScheduleContainer
	for child in schedule_container.get_children():
		child.queue_free()

	var player_team = int(Season.season_data["player_team"])
	var schedule = Season.season_data["schedule"]

	for w in range(schedule.size()):
		var matches = schedule[w]
		var opp = -1
		var is_home = false

		for m in matches:
			var h = int(m[0])
			var a = int(m[1])
			if h == player_team:
				opp = a
				is_home = true
				break
			elif a == player_team:
				opp = h
				is_home = false
				break

		if opp != -1:
			var lbl = Label.new()
			var opp_name = StatBook.TEAMS[opp]["name"]
			if is_home:
				lbl.text = "Week %d: vs %s (Home)" % [w + 1, opp_name]
			else:
				lbl.text = "Week %d: @ %s (Away)" % [w + 1, opp_name]

			if w < int(Season.season_data["current_week"]):
				lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			elif w == int(Season.season_data["current_week"]):
				lbl.add_theme_color_override("font_color", Color(1, 1, 0))

			schedule_container.add_child(lbl)

func update_standings() -> void:
	for child in standings_container.get_children():
		child.queue_free()

	var teams_records = []
	var standings = Season.season_data["standings"]

	for team_id_str in standings:
		var w = standings[team_id_str]["wins"]
		var l = standings[team_id_str]["losses"]
		var ties = standings[team_id_str].get("ties", 0)
		teams_records.append({
			"id": int(team_id_str),
			"wins": w,
			"losses": l,
			"ties": ties,
			"pts": w * 2 + ties
		})

	teams_records.sort_custom(func(a, b): return a["pts"] > b["pts"])

	var divisions = {
		"city": [],
		"coastal": [],
		"ocean": [],
		"middle": []
	}
	for i in range(teams_records.size()):
		var tr = teams_records[i]
		var team_data = StatBook.TEAMS[tr["id"]]
		var division = team_data.get("division", "")
		if divisions.has(division):
			divisions[division].append({"record": tr, "rank": i + 1, "name": team_data["name"]})

	for div_name in ["city", "coastal", "ocean", "middle"]:
		if divisions[div_name].is_empty():
			continue

		var div_header = Label.new()
		div_header.text = "-- " + div_name.capitalize() + " Division --"
		div_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		div_header.add_theme_color_override("font_color", Color(0.6, 0.6, 1.0))
		standings_container.add_child(div_header)

		var div_rank = 1
		for team in divisions[div_name]:
			var lbl = Label.new()
			var r = team["record"]
			var rank = team["rank"]
			var t_name = team["name"]

			if Season.season_data["standings"][str(r["id"])].has("ties"):
				lbl.text = "%d. %s - %d W, %d L, %d T (%d PTS) (%d)" % [
					div_rank, t_name, r["wins"], r["losses"], r["ties"], r["pts"], rank
				]
			else:
				lbl.text = "%d. %s - %d W, %d L (%d PTS) (%d)" % [
					div_rank, t_name, r["wins"], r["losses"], r["pts"], rank
				]

			if r["id"] == int(Season.season_data["player_team"]):
				lbl.add_theme_color_override("font_color", Color(1, 1, 0))

			standings_container.add_child(lbl)
			div_rank += 1

func update_matchup() -> void:
	var week = int(Season.season_data["current_week"])
	if week >= Season.season_data["schedule"].size():
		is_season_over = true
		matchup_title.text = "Season Finished!"
		matchup_label.text = "All 28 weeks completed."
		%Play.visible = false
		return

	matchup_title.text = "Week %d Matchup" % (week + 1)

	var matches = Season.season_data["schedule"][week]
	var player_team = int(Season.season_data["player_team"])

	for m in matches:
		var h = int(m[0])
		var a = int(m[1])
		if h == player_team or a == player_team:
			home_team = h
			away_team = a
			break

	var h_name = StatBook.TEAMS[home_team]["name"]
	var a_name = StatBook.TEAMS[away_team]["name"]
	matchup_label.text = "%s (Away)\nvs\n%s (Home)" % [a_name, h_name]

func _on_back_pressed() -> void:
	Season.season_on = false
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")

func _on_play_pressed() -> void:
	if is_season_over:
		return

	Globals.home_team_index = home_team
	Globals.away_team_index = away_team

	var player_team = int(Season.season_data["player_team"])
	var good_teams = Season.season_data["good_teams"]

	if home_team == player_team:
		Globals.home_ai_difficulty = 0 # Doesn't matter, player controls
		if away_team in good_teams:
			Globals.away_ai_difficulty = 2
		else:
			var standings = Season.season_data["standings"][str(away_team)]
			Globals.away_ai_difficulty = 0 if standings["losses"] > standings["wins"] else 1
		for i in range(Globals.player_teams.size()):
			Globals.player_teams[i] = 0
	else:
		if home_team in good_teams:
			Globals.home_ai_difficulty = 2
		else:
			var standings = Season.season_data["standings"][str(home_team)]
			Globals.home_ai_difficulty = 0 if standings["losses"] > standings["wins"] else 1
		Globals.away_ai_difficulty = 0
		for i in range(Globals.player_teams.size()):
			Globals.player_teams[i] = 1

	Globals.update_team_textures()
	get_tree().change_scene_to_file("res://objects/environment/match_rink.tscn")

func _on_reset_pressed() -> void:
	var dir = DirAccess.open("user://")
	if dir.file_exists("season.json"):
		dir.remove("season.json")
	Season.season_on = false
	Season.season_data.clear()
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")
