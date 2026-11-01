extends PanelScreen
## Leaderboard: one screen for the points board (all time, week, month), a level's board, and a
## day's board. `args`: scope = "points" | "level" | "daily", key (the level slug or the date),
## title (the level's title), and back / back_args. Boards need an account and a connection; a
## signed-out player is told so, and one who is not on the board is told how to appear.

const PERIODS: Array[String] = ["all", "week", "month"]
const PERIOD_LABELS: Array[String] = ["ALL TIME", "WEEK", "MONTH"]

var _scope := "points"
var _key := ""
var _period := "all"
## "loading", "ready", "empty", "signed_out", "offline", or "error".
var _state := "loading"
var _message := ""
var _entries: Array = []
var _total := 0
var _me: Dictionary = {}
## False when the player is on no board because they never opted in.
var _opted_in := true
var _reporting: Dictionary = {}
var _busy := false


func _caption_text() -> String:
	match str(args.get("scope", "points")):
		"level":
			return "LEVEL"
		"daily":
			return "DAILY"
	return "POINTS"


func _title_text() -> String:
	match str(args.get("scope", "points")):
		"level":
			return str(args.get("title", args.get("key", ""))).to_upper()
		"daily":
			return str(args.get("key", ""))
	return "LEADERBOARD"


func _build() -> void:
	_scope = str(args.get("scope", "points"))
	_key = str(args.get("key", ""))
	_period = str(args.get("period", "all"))
	super._build()
	_load(true)


func go_back() -> void:
	if not _reporting.is_empty():
		_reporting = {}
		_populate()
		return
	navigate.emit(str(args.get("back", "home")), args.get("back_args", {}))


func _board_key() -> String:
	return _period if _scope == "points" else _key


func _load(first_page: bool) -> void:
	if _busy:
		return
	if not app.signed_in():
		_state = "signed_out"
		_populate()
		return
	_busy = true
	if first_page:
		_state = "loading"
		_populate()
	var offset := 0 if first_page else _entries.size()
	var result := await app.social.board(_scope, _board_key(), offset)
	if not is_inside_tree():
		return
	if not result["ok"]:
		_busy = false
		_state = "offline" if result.get("error") == "offline" else "error"
		_message = str(result["message"])
		_populate()
		return
	var data: Dictionary = result["data"]
	_entries = data["entries"] if first_page else _entries + data["entries"]
	_total = int(data["total"])
	_me = data["me"]
	_state = "ready" if not _entries.is_empty() else "empty"
	if first_page and _me.is_empty():
		var mine := await app.social.profile()
		_opted_in = not mine["ok"] or bool(mine["data"]["optIn"])
	_busy = false
	if is_inside_tree():
		_populate()


func _populate() -> void:
	_clear_list()
	var width := _content_width()
	_set_action(_primary)
	_set_action(_secondary)
	_set_action(_tertiary)
	if _scope == "points":
		_list.add_child(UiRows.segment_row("", PERIODS, _period, _set_period, PERIOD_LABELS))
	if not _reporting.is_empty():
		_populate_report(width)
		return
	match _state:
		"loading":
			_list.add_child(UiRows.note("LOADING", 16, Palette.INK, width))
		"signed_out":
			var text := "BOARDS NEED AN ACCOUNT. SIGN IN TO SEE THEM AND TO APPEAR ON THEM."
			_list.add_child(UiRows.note(text, 16, Palette.INK, width))
			_set_action(_primary, "SIGN IN", _open_sign_in)
		"offline", "error":
			_list.add_child(UiRows.note(_message, 16, Palette.INK, width))
			_set_action(_primary, "TRY AGAIN", _load.bind(true))
		"empty":
			_list.add_child(UiRows.note("NO ONE IS ON THIS BOARD YET.", 16, Palette.INK, width))
			_add_appear_hint(width)
		_:
			_populate_rows(width)


func _populate_rows(width: float) -> void:
	var heading := "POINTS" if _scope == "points" else "COMMANDS / STEPS"
	_list.add_child(UiRows.note("%d PLAYERS. %s" % [_total, heading], 13, Palette.MUTE, width))
	var seen := {}
	for entry: Dictionary in _entries:
		seen[entry["rank"]] = true
		_list.add_child(_row(entry))
	if not _me.is_empty() and not seen.has(_me["entry"]["rank"]):
		_list.add_child(UiRows.caption("YOUR PLACE"))
		for entry: Dictionary in _me["around"]:
			_list.add_child(_row(entry))
	elif _me.is_empty():
		_add_appear_hint(width)
	if _entries.size() < _total:
		_set_action(_secondary, "MORE", _load.bind(false))


func _add_appear_hint(width: float) -> void:
	if _opted_in:
		var text := "YOU ARE NOT ON THIS BOARD YET."
		if _scope != "points":
			text = "YOU HAVE NO RESULT ON THIS BOARD YET."
		_list.add_child(UiRows.note(text, 14, Palette.MUTE, width))
		return
	var how := "TO APPEAR HERE, CHOOSE A NAME AND TURN ON LEADERBOARDS IN YOUR PROFILE."
	_list.add_child(UiRows.note(how, 14, Palette.MUTE, width))
	_set_action(_tertiary, "OPEN PROFILE", _open_profile)


func _row(entry: Dictionary) -> BoardRow:
	var row := BoardRow.new()
	row.entry = entry
	row.can_report = true
	row.report.connect(_ask_report)
	return row


func _populate_report(width: float) -> void:
	var text := (
		"REPORT THE NAME %s? THE NAME IS SENT TO THE MODERATORS TO CHECK." % _reporting["name"]
	)
	_list.add_child(UiRows.note(text.to_upper(), 16, Palette.INK, width))
	_list.add_child(UiRows.note(_message, 14, Palette.INK, width))
	_set_action(_primary, "REPORT NAME", _send_report)
	_set_action(_secondary, "CANCEL", go_back)


func _set_period(period: String) -> void:
	if _busy or period == _period:
		return
	_period = period
	_load(true)


func _ask_report(entry: Dictionary) -> void:
	_reporting = entry
	_message = ""
	_populate()


func _send_report() -> void:
	if _busy:
		return
	_busy = true
	_message = "SENDING"
	_populate()
	var result := await app.social.report(str(_reporting["publicId"]))
	_busy = false
	if not is_inside_tree():
		return
	if result["ok"]:
		_reporting = {}
		_message = ""
	else:
		_message = str(result["message"])
	_populate()


func _open_sign_in() -> void:
	navigate.emit("sign_in", {"back": "home"})


func _open_profile() -> void:
	navigate.emit("profile", {"back": "leaderboard", "back_args": args})
