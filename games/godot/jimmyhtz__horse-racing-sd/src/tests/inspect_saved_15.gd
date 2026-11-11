extends SceneTree
func _initialize() -> void:
	var path := OS.get_environment("SD_CHECK_SAVE")
	var raw: Dictionary = bytes_to_var(Marshalls.base64_to_raw(JSON.parse_string(FileAccess.get_file_as_string(path)).payload))
	var game: Dictionary = raw.session
	var prefs: Dictionary = raw.settings.values
	var report := {"phase":game.phase,"round":game.round,"race_count":game.race_logs.size(),"audit_count":game.audit.size(),"photo_threshold":prefs.get("photo_threshold"),"replay_seconds":prefs.get("replay_seconds"),"recent":[]}
	for race in game.race_logs.slice(maxi(0,game.race_logs.size()-8)):
		report.recent.append({"round":race.round,"pair":race.pair,"margin_second_third":race.margin,"first_time":race.get("first_time"),"second_time":race.get("second_time"),"crossings":race.get("crossings"),"positions":race.positions})
	print(JSON.stringify(report))
	quit()
