extends Node

var season_on: bool = false
var season_data: Dictionary = {}
var save_path = "user://season.json"

func has_saved_season() -> bool:
	return FileAccess.file_exists(save_path)

func load_season() -> void:
	if has_saved_season():
		var file = FileAccess.open(save_path, FileAccess.READ)
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		if err == OK:
			season_data = json.data

func save_season() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(season_data))

func new_season(player_team: int) -> void:
	var a = []
	var b = []
	var c = []
	var d = []
	
	for i in range(0, 32):
		var co = Stats.TEAMS[i]["division"]
		if co == "city":
			a.push_back(i)
		elif co == "coastal":
			b.push_back(i)
		elif co == "middle":
			c.push_back(i)
		elif co == "ocean":
			d.push_back(i)

	var good_teams = []
	good_teams.append(a[randi() % 8])
	good_teams.append(b[randi() % 8])
	good_teams.append(c[randi() % 8])
	good_teams.append(d[randi() % 8])

	var standings = {}
	for t in (a + b + c + d):
		standings[str(t)] = {"wins": 0, "losses": 0, "ties": 0}

	var schedule = generate_schedule(a, b, c, d)

	season_data = {
		"player_team": player_team,
		"current_week": 0,
		"good_teams": good_teams,
		"standings": standings,
		"schedule": schedule
	}
	save_season()

func generate_schedule(a: Array, b: Array, c: Array, d: Array) -> Array:
	var sky = a + b
	var earth = c + d
	var schedule = []
	for w in range(8):
		var week = []
		for i in range(8):
			var t1 = sky[i]
			var t2 = earth[(i+w)%8]
			if w < 4:
				week.append([t1, t2])
			else:
				week.append([t2, t1])
		schedule.append(week)
	for w in range(8):
		var week = []
		for i in range(4):
			var t1 = a[i]
			var t2 = b[(i+w)%4]
			if w < 4:
				week.append([t1, t2])
			else:
				week.append([t2, t1])
			t1 = c[i]
			t2 = d[(i+w)%4]
			if w < 4:
				week.append([t1, t2])
			else:
				week.append([t2, t1])
		schedule.append(week)
	var matchups = [[[0,1], [2,3]], [[0,2], [3,1]], [[0,3], [1,2]]]
	for _iter in range(4):
		for r in range(3):
			var week = []
			for div in [a, b, c, d]:
				for pair in matchups[r]:
					var t1 = div[pair[0]]
					var t2 = div[pair[1]]
					if _iter % 2 == 0:
						week.append([t1, t2])
					else:
						week.append([t2, t1])
			schedule.append(week)
	schedule.shuffle()
	return schedule

func record_match(home: int, away: int, home_score: int, away_score: int) -> void:
	if home_score > away_score:
		season_data["standings"][str(home)]["wins"] += 1
		season_data["standings"][str(away)]["losses"] += 1
	elif home_score == away_score:
		if not season_data["standings"][str(away)].has("ties"):
			season_data["standings"][str(away)]["ties"] = 0
		if not season_data["standings"][str(home)].has("ties"):
			season_data["standings"][str(home)]["ties"] = 0
		season_data["standings"][str(away)]["ties"] += 1
		season_data["standings"][str(home)]["ties"] += 1
	else:
		season_data["standings"][str(away)]["wins"] += 1
		season_data["standings"][str(home)]["losses"] += 1

func simulate_other_matches() -> void:
	var week = int(season_data["current_week"])
	if week >= season_data["schedule"].size():
		return

	var matches = season_data["schedule"][week]
	var player_team = int(season_data["player_team"])
	var good_teams = season_data["good_teams"]

	for m in matches:
		var home = int(m[0])
		var away = int(m[1])
		if home == player_team or away == player_team:
			continue

		var home_win_prob = 0.5
		if home in good_teams and not away in good_teams:
			home_win_prob = 0.75
		elif away in good_teams and not home in good_teams:
			home_win_prob = 0.25

		var home_score = 0
		var away_score = 0
		while home_score == away_score:
			if randf() < home_win_prob:
				home_score += 1
			else:
				away_score += 1

		# Adding some random goals for realism
		var extra_goals = randi() % 4
		home_score += randi() % (extra_goals + 1)
		away_score += randi() % (extra_goals + 1)

		record_match(home, away, home_score, away_score)

func advance_week() -> void:
	season_data["current_week"] += 1
	save_season()
