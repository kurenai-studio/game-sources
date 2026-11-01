extends PanelScreen
## Badges: every badge, earned ones solid with a check and the date, locked ones outlined with a
## lock and the word LOCKED. Needs an account; offline it says so. Badges earned since the last
## visit are named in one plain line (they are remembered by PlayerResults until shown).

var _state := "loading"
var _message := ""
var _items: Array = []
var _fresh: Array[String] = []


func _caption_text() -> String:
	return "YOUR ACCOUNT"


func _title_text() -> String:
	return "BADGES"


func _build() -> void:
	if not app.signed_in():
		navigate.emit.call_deferred("sign_in", {"back": "home"})
		return
	super._build()
	_fresh = app.progress.results.take_badges()
	if not _fresh.is_empty():
		app.progress.results.save()
	_load()


func go_back() -> void:
	navigate.emit(str(args.get("back", "account")), args.get("back_args", {}))


func _load() -> void:
	_state = "loading"
	_populate()
	var result := await app.social.achievements()
	if not is_inside_tree():
		return
	if result["ok"]:
		_items = result["data"]["items"]
		_state = "ready"
	else:
		_state = "offline" if result.get("error") == "offline" else "error"
		_message = str(result["message"])
	_populate()


func _populate() -> void:
	_clear_list()
	var width := _content_width()
	if not _fresh.is_empty():
		var named := ", ".join(_fresh).to_upper()
		_list.add_child(UiRows.note("NEW: %s" % named, 16, Palette.INK, width))
	_set_action(_primary)
	if _state != "ready":
		var text := "LOADING" if _state == "loading" else _message
		_list.add_child(UiRows.note(text, 16, Palette.INK, width))
		_set_action(_primary, "" if _state == "loading" else "TRY AGAIN", _load)
		return
	if _items.is_empty():
		_list.add_child(UiRows.note("NO BADGES ARE DEFINED YET", 16, Palette.INK, width))
		return
	var earned := 0
	for item: Dictionary in _items:
		if not str(item["earnedAt"]).is_empty():
			earned += 1
	var summary := "%02d OF %02d EARNED" % [earned, _items.size()]
	_list.add_child(UiRows.note(summary, 14, Palette.MUTE, width))
	for item: Dictionary in _items:
		var row := BadgeRow.new()
		row.title = str(item["title"])
		row.description = str(item["description"])
		row.earned_on = str(item["earnedAt"]).substr(0, 10)
		var state := "earned" if not row.earned_on.is_empty() else "locked"
		row.tooltip_text = "%s, %s" % [row.title, state]
		_list.add_child(row)
