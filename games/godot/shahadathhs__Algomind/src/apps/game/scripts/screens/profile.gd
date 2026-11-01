extends PanelScreen
## Profile: the display name, whether to appear on leaderboards, hiding the name, and the rank.
## It needs an account and a connection; offline it says so. The server has the last word on a
## name, and its reason is shown as it is.

var _state := "loading"
var _message := ""
var _profile: Dictionary = {}
var _opt_in := false
var _hide := false
var _name_text := ""
var _name: TextField
var _busy := false


func _caption_text() -> String:
	return "YOUR ACCOUNT"


func _title_text() -> String:
	return "PROFILE"


func _build() -> void:
	if not app.signed_in():
		navigate.emit.call_deferred("sign_in", {"back": "home"})
		return
	super._build()
	_populate()
	_load()


func go_back() -> void:
	navigate.emit(str(args.get("back", "account")), args.get("back_args", {}))


func _load() -> void:
	_state = "loading"
	_populate()
	var result := await app.social.profile()
	if not is_inside_tree():
		return
	if result["ok"]:
		_take(result["data"])
		_state = "ready"
	else:
		_state = "offline" if result.get("error") == "offline" else "error"
		_message = str(result["message"])
	_populate()


func _take(profile: Dictionary) -> void:
	_profile = profile
	_opt_in = bool(profile["optIn"])
	_hide = bool(profile["hideName"])
	_name_text = str(profile["displayName"])


func _populate() -> void:
	if is_instance_valid(_name):
		_name_text = _name.text
	_clear_list()
	_name = null
	var width := _content_width()
	_set_action(_secondary)
	_set_action(_tertiary)
	if _state != "ready":
		var text := "LOADING" if _state == "loading" else _message
		_list.add_child(UiRows.note(text, 16, Palette.INK, width))
		_set_action(_primary, "" if _state == "loading" else "TRY AGAIN", _load)
		return
	_list.add_child(UiRows.caption("DISPLAY NAME"))
	_name = TextField.new()
	_name.placeholder = "3 to 20 characters"
	_name.accessible_label = "Display name"
	_name.custom_minimum_size = Vector2(0, 52)
	_list.add_child(_name)
	_name.text = _name_text
	_list.add_child(UiRows.gap(4.0))
	_list.add_child(UiRows.toggle_row("SHOW ME ON LEADERBOARDS", _opt_in, _flip.bind("opt")))
	_list.add_child(UiRows.toggle_row("HIDE MY NAME", _hide, _flip.bind("hide")))
	var hint := "A HIDDEN NAME SHOWS AS ANONYMOUS."
	_list.add_child(UiRows.note(hint, 13, Palette.MUTE, width))
	_list.add_child(UiRows.caption("RANK"))
	var rank: Dictionary = _profile["rank"]
	_list.add_child(UiKit.label(str(rank["name"]).to_upper(), 30, Palette.INK, 1))
	var points := "%d POINTS" % int(_profile["total"])
	var next: Dictionary = rank["next"]
	if next.is_empty():
		points += ". THE HIGHEST RANK"
	else:
		points += ". NEXT: %s AT %d" % [str(next["name"]).to_upper(), int(next["at"])]
	_list.add_child(UiRows.note(points, 15, Palette.MUTE, width))
	_list.add_child(UiRows.note(_message, 14, Palette.INK, width))
	_set_action(_primary, "SAVE", _save)
	_set_action(_tertiary, "BADGES", _open_badges)


func _flip(which: String) -> void:
	if which == "opt":
		_opt_in = not _opt_in
	else:
		_hide = not _hide
	_message = ""
	_populate()


func _open_badges() -> void:
	navigate.emit("badges", {"back": "profile", "back_args": args.get("back_args", {})})


func _save() -> void:
	if _busy:
		return
	_busy = true
	_message = "SAVING"
	var text := _name.text.strip_edges() if is_instance_valid(_name) else _name_text
	var changes := {
		"displayName": text if not text.is_empty() else null,
		"leaderboardOptIn": _opt_in,
		"hideName": _hide,
	}
	_populate()
	var result := await app.social.save_profile(changes)
	_busy = false
	if not is_inside_tree():
		return
	if result["ok"]:
		_take(result["data"])
		_message = "SAVED"
	else:
		_name_text = text
		_message = str(result["message"])
	_populate()
