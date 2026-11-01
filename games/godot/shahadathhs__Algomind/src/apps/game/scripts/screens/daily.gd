extends PanelScreen
## Daily: today's challenge, played from the copy on the device, so it works offline. Shows the
## level's name, difficulty, par and limit, the player's result and streak, and the next days.
## The one primary action is Play. Signed in, the server's result and streak are fetched too.

## "loading" until the first refresh ends, then "ready"; `_offline` when the refresh failed.
var _state := "loading"
var _offline := false
var _server_result: Dictionary = {}


func _caption_text() -> String:
	return "TODAY"


func _title_text() -> String:
	return app.daily.today()


func _build() -> void:
	super._build()
	_populate()
	_refresh()


func go_back() -> void:
	navigate.emit("home", {})


func _refresh() -> void:
	var result := await app.refresh_daily()
	if not is_inside_tree():
		return
	_offline = result["status"] in ["offline", "disabled", "invalid"]
	_state = "ready"
	_title.text = app.daily.today()
	_populate()
	if app.signed_in() and app.social != null and not _offline:
		var mine := await app.social.daily_me()
		if not is_inside_tree() or not mine["ok"]:
			return
		var data: Dictionary = mine["data"]
		if data["date"] == app.daily.today():
			_server_result = data["result"]
		app.progress.results.streak = data["streak"]
		app.progress.results.save()
		_populate()


func _populate() -> void:
	_clear_list()
	var width := _content_width()
	var date: String = app.daily.today()
	var info: Dictionary = app.daily.day(date)
	var playable := app.daily.is_playable(date)
	_set_action(_secondary)
	_set_action(_tertiary)
	if info.is_empty() or not playable:
		var text := "LOADING TODAY'S DAILY" if _state == "loading" else _missing_text()
		_list.add_child(UiRows.note(text, 16, Palette.INK, width))
		_set_action(_primary, "PLAY" if _state == "loading" else "TRY AGAIN", _retry)
		_primary.set_disabled(_state == "loading")
		return
	_list.add_child(UiKit.label(str(info["title"]).to_upper(), 30, Palette.INK, 1))
	var facts := (
		"%s. PAR %d COMMANDS. LIMIT %d COMMANDS."
		% [str(info["difficulty"]).to_upper(), int(info["par"]), int(info["maxCommands"])]
	)
	_list.add_child(UiRows.note(facts, 15, Palette.MUTE, width))
	if _offline:
		var offline := "OFFLINE. THE SAVED DAILY STILL PLAYS."
		_list.add_child(UiRows.note(offline, 14, Palette.MUTE, width))
	_list.add_child(UiRows.gap(4.0))
	_list.add_child(UiRows.caption("YOUR RESULT"))
	_list.add_child(UiRows.note(_result_text(date, info), 18, Palette.INK, width))
	_list.add_child(UiRows.caption("STREAK"))
	_list.add_child(UiRows.note(_streak_text(), 18, Palette.INK, width))
	var later := app.daily.upcoming(date)
	if not later.is_empty():
		_list.add_child(UiRows.gap(4.0))
		_list.add_child(UiRows.caption("NEXT DAYS"))
		for day: Dictionary in later:
			var line := (
				"%s   %s   %s"
				% [day["date"], str(day["title"]).to_upper(), str(day["difficulty"]).to_upper()]
			)
			_list.add_child(UiRows.note(line, 15, Palette.MUTE, width))
	_set_action(_primary, "PLAY", _play)
	_primary.set_disabled(false)
	_set_action(_secondary, "TODAY'S BOARD", _open_board)


func _missing_text() -> String:
	if _offline:
		return (
			"NO DAILY IS SAVED ON THIS DEVICE YET AND THE SERVER CANNOT BE REACHED. "
			+ "CONNECT ONCE TO LOAD IT."
		)
	return "TODAY'S DAILY IS NOT AVAILABLE. TRY AGAIN LATER."


func _result_text(date: String, info: Dictionary) -> String:
	var best: Dictionary = app.progress.results.daily_best.get(date, {})
	var slots := int(_server_result.get("slots", 0))
	if slots <= 0 and not best.is_empty():
		slots = int(best["slots"])
	if slots <= 0:
		return "NOT SOLVED YET"
	var stars := int(_server_result.get("stars", 0))
	if stars <= 0:
		var par := {
			"commands": int(info["par"]), "steps": int(app.daily.level(date)["par"].get("steps", 0))
		}
		stars = LevelStars.provisional(par, str(info["difficulty"]), slots)
	var line := "SOLVED IN %d COMMANDS" % slots
	if stars > 0:
		line += ". %d / 3 STARS" % stars
	return line


func _streak_text() -> String:
	if not app.signed_in():
		return "SIGN IN TO KEEP A STREAK AND APPEAR ON THE DAILY BOARD"
	var streak: Dictionary = app.progress.results.streak
	if streak.is_empty():
		return "NOT KNOWN YET"
	return "CURRENT %s. BEST %s" % [_days(int(streak["current"])), _days(int(streak["best"]))]


static func _days(count: int) -> String:
	return "%d DAY%s" % [count, "" if count == 1 else "S"]


func _retry() -> void:
	_state = "loading"
	_populate()
	_refresh()


func _play() -> void:
	navigate.emit("play", {"daily": app.daily.today()})


func _open_board() -> void:
	navigate.emit("leaderboard", {"scope": "daily", "key": app.daily.today(), "back": "daily"})
