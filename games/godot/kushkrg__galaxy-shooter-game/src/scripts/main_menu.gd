extends Control
## Galaxy Shooter — main menu.
## Play (offline or online), account login / register / guest,
## global leaderboard, how-to-play and settings — all in one screen
## flow, styled in code so there are no fragile scene files.

const LOGO := preload("res://assets/logo.svg")

var _pilot_label: Label
var _account_btn: Button
var _logout_btn: Button
var _server_label: Label

var _auth_panel: PanelContainer
var _auth_title: Label
var _auth_status: Label
var _user_edit: LineEdit
var _pass_edit: LineEdit
var _name_edit: LineEdit
var _name_row: HBoxContainer
var _auth_mode := "login"   # login | register

var _board_panel: PanelContainer
var _board_text: Label
var _board_status: Label

var _help_panel: PanelContainer
var _settings_panel: PanelContainer
var _api_edit: LineEdit

func _style_btn(b: Button, accent: bool = false) -> void:
	b.custom_minimum_size = Vector2(300, 56)
	b.add_theme_font_size_override("font_size", 22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.85, 0.3, 0.45, 0.98) if accent else Color(0.08, 0.12, 0.24, 0.95)
	normal.border_color = Color(1.0, 0.6, 0.7, 0.9) if accent else Color(0.2, 0.85, 1.0, 0.65)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.4, 0.55, 1.0) if accent else Color(0.13, 0.3, 0.45, 0.98)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)

func _mk_button(text: String, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	_style_btn(b, accent)
	return b

func _mk_label(text: String, size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.07, 0.14, 0.97)
	s.border_color = Color(0.2, 0.85, 1.0, 0.8)
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.set_content_margin_all(22)
	return s

func _mk_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -285
	p.offset_right = 285
	p.offset_top = -330
	p.offset_bottom = 330
	p.visible = false
	add_child(p)
	return p

func _mk_edit(placeholder: String, secret: bool = false) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.secret = secret
	e.custom_minimum_size = Vector2(420, 48)
	e.add_theme_font_size_override("font_size", 19)
	return e

func _close_all_panels() -> void:
	for p in [_auth_panel, _board_panel, _help_panel, _settings_panel]:
		p.visible = false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.016, 0.043)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	add_child(Starfield.new())
	_build_main()
	_build_auth_panel()
	_build_board_panel()
	_build_help_panel()
	_build_settings_panel()
	_refresh_pilot()
	ApiClient.ping(func(res: Dictionary) -> void:
		_server_label.text = "Server online — global leaderboard available" if res["ok"] else "Server offline — scores stay on this device"
		_server_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55) if res["ok"] else Color(1.0, 0.6, 0.45))
	)

func _build_main() -> void:
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -260
	center.offset_right = 260
	center.offset_top = -560
	center.offset_bottom = 560
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 13)
	add_child(center)
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.custom_minimum_size = Vector2(168, 168)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var logo_wrap := CenterContainer.new()
	logo_wrap.add_child(logo)
	center.add_child(logo_wrap)
	var title := _mk_label("GALAXY SHOOTER", 54, Color(0.55, 0.95, 1.0))
	center.add_child(title)
	center.add_child(_mk_label("Blast through the galaxy — level by level.", 19, Color(0.8, 0.85, 0.95)))
	_pilot_label = _mk_label("", 19, Color(1.0, 0.85, 0.45))
	center.add_child(_pilot_label)
	var play := _mk_button("PLAY", true)
	play.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/game.tscn"))
	center.add_child(play)
	_account_btn = _mk_button("Login / Register / Guest")
	_account_btn.pressed.connect(func() -> void:
		_close_all_panels()
		_auth_panel.visible = true
	)
	center.add_child(_account_btn)
	var board := _mk_button("Global Leaderboard")
	board.pressed.connect(func() -> void:
		_close_all_panels()
		_board_panel.visible = true
		_load_board()
	)
	center.add_child(board)
	var help_btn := _mk_button("How to Play")
	help_btn.pressed.connect(func() -> void:
		_close_all_panels()
		_help_panel.visible = true
	)
	center.add_child(help_btn)
	var settings := _mk_button("Settings")
	settings.pressed.connect(func() -> void:
		_close_all_panels()
		_api_edit.text = Session.api_url
		_settings_panel.visible = true
	)
	center.add_child(settings)
	_logout_btn = _mk_button("Logout")
	_logout_btn.pressed.connect(func() -> void:
		Session.logout()
		_refresh_pilot()
	)
	center.add_child(_logout_btn)
	_server_label = _mk_label("Checking server…", 15, Color(0.6, 0.65, 0.75))
	center.add_child(_server_label)
	center.add_child(_mk_label("v1.0.0 · Web & Mobile · by Coding Cush", 14, Color(0.45, 0.5, 0.62)))

func _refresh_pilot() -> void:
	if Session.is_logged_in():
		var kind := "Guest" if bool(Session.user.get("is_guest", false)) else "Pilot"
		_pilot_label.text = "%s: %s" % [kind, Session.display_name()]
		_account_btn.text = "Account: %s" % Session.display_name()
		_logout_btn.visible = true
	else:
		_pilot_label.text = "Not signed in — play offline, or sign in for the global leaderboard."
		_account_btn.text = "Login / Register / Guest"
		_logout_btn.visible = false

# ---------------------------------------------------------------- auth
func _build_auth_panel() -> void:
	_auth_panel = _mk_panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 11)
	_auth_panel.add_child(v)
	_auth_title = _mk_label("LOGIN", 30, Color(0.55, 0.95, 1.0))
	v.add_child(_auth_title)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)
	var login_tab := _mk_button("Login")
	login_tab.custom_minimum_size = Vector2(150, 46)
	login_tab.pressed.connect(func() -> void: _set_auth_mode("login"))
	tabs.add_child(login_tab)
	var reg_tab := _mk_button("Register")
	reg_tab.custom_minimum_size = Vector2(150, 46)
	reg_tab.pressed.connect(func() -> void: _set_auth_mode("register"))
	tabs.add_child(reg_tab)
	_user_edit = _mk_edit("Username")
	v.add_child(_user_edit)
	_pass_edit = _mk_edit("Password", true)
	v.add_child(_pass_edit)
	_name_row = HBoxContainer.new()
	_name_edit = _mk_edit("Display name (shown on the leaderboard)")
	_name_row.add_child(_name_edit)
	v.add_child(_name_row)
	var go := _mk_button("Login", true)
	go.pressed.connect(_on_auth_go)
	v.add_child(go)
	_auth_status = _mk_label("", 16, Color(1.0, 0.7, 0.5))
	v.add_child(_auth_status)
	var divider := _mk_label("— or —", 15, Color(0.55, 0.6, 0.7))
	v.add_child(divider)
	var guest := _mk_button("Play as Guest")
	guest.pressed.connect(_on_guest)
	v.add_child(guest)
	var close := _mk_button("Close")
	close.pressed.connect(func() -> void: _auth_panel.visible = false)
	v.add_child(close)
	_set_auth_mode("login")

func _set_auth_mode(mode: String) -> void:
	_auth_mode = mode
	_auth_title.text = "LOGIN" if mode == "login" else "CREATE ACCOUNT"
	_name_row.visible = mode == "register"
	_auth_status.text = ""

func _on_auth_go() -> void:
	var username := _user_edit.text.strip_edges()
	var password := _pass_edit.text
	if username == "" or password == "":
		_auth_status.text = "Enter a username and password."
		return
	_auth_status.text = "Please wait…"
	if _auth_mode == "login":
		ApiClient.login(username, password, _on_auth_result)
	else:
		ApiClient.register(username, password, _name_edit.text.strip_edges(), _on_auth_result)

func _on_guest() -> void:
	_auth_status.text = "Creating your guest pilot…"
	var name := _name_edit.text.strip_edges()
	if name == "":
		name = "Guest Pilot"
	ApiClient.guest(name, _on_auth_result)

func _on_auth_result(res: Dictionary) -> void:
	if res["ok"] and typeof(res["data"]) == TYPE_DICTIONARY:
		Session.set_user(res["data"]["user"], str(res["data"]["token"]))
		_auth_status.text = "Welcome, %s!" % Session.display_name()
		_refresh_pilot()
		_auth_panel.visible = false
	else:
		_auth_status.text = str(res["error"])

# ---------------------------------------------------------------- board
func _build_board_panel() -> void:
	_board_panel = _mk_panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 11)
	_board_panel.add_child(v)
	v.add_child(_mk_label("GLOBAL LEADERBOARD", 28, Color(1.0, 0.85, 0.45)))
	_board_status = _mk_label("", 15, Color(0.6, 0.9, 1.0))
	v.add_child(_board_status)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_board_text = _mk_label("", 19)
	_board_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_board_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_board_text)
	v.add_child(scroll)
	var refresh := _mk_button("Refresh")
	refresh.pressed.connect(_load_board)
	v.add_child(refresh)
	var close := _mk_button("Close")
	close.pressed.connect(func() -> void: _board_panel.visible = false)
	v.add_child(close)

func _load_board() -> void:
	_board_status.text = "Loading…"
	ApiClient.fetch_leaderboard(25, func(res: Dictionary) -> void:
		if res["ok"] and typeof(res["data"]) == TYPE_DICTIONARY:
			var entries: Array = res["data"].get("entries", [])
			if entries.is_empty():
				_board_status.text = "No scores yet — be the first legend of the galaxy."
				_board_text.text = ""
				return
			_board_status.text = "Live from the Galaxy Shooter server"
			var lines: Array[String] = []
			for entry in entries:
				lines.append("#%d  %s\n        %s pts · Level %d · %d games" % [int(entry["rank"]), str(entry["name"]), int(entry["score"]), int(entry["level"]), int(entry["games"])])
			_board_text.text = "\n".join(lines)
		else:
			_board_status.text = "Server offline — showing this device's best scores"
			_board_text.text = _local_board_text()
	)

func _local_board_text() -> String:
	if Session.local_scores.is_empty():
		return "No scores on this device yet.\nPlay a run to set one!"
	var lines: Array[String] = []
	for i in Session.local_scores.size():
		var s: Dictionary = Session.local_scores[i]
		lines.append("#%d  %s — %s (Lv %d)" % [i + 1, str(s["name"]), int(s["score"]), int(s["level"])])
	return "\n".join(lines)

# ---------------------------------------------------------------- misc panels
func _build_help_panel() -> void:
	_help_panel = _mk_panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 11)
	_help_panel.add_child(v)
	v.add_child(_mk_label("HOW TO PLAY", 28, Color(0.55, 0.95, 1.0)))
	var text := _mk_label("Move: WASD / Arrow keys, mouse drag, or touch drag.\nShoot: hold Space, touch, or mouse button.\n\nDestroy enemies to score. Chain kills to raise your COMBO multiplier up to x5.\n\nPick up powerups:\nR — Rapid fire · T — Triple shot · S — Shield · + — Repair 30 HP\nGetting hit lowers your weapon level — protect the triple shot!\n\nClear every wave to finish the level. A BOSS waits every 5th level.\nLog in or play as guest to put your score on the GLOBAL leaderboard.", 18)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(text)
	var close := _mk_button("Close")
	close.pressed.connect(func() -> void: _help_panel.visible = false)
	v.add_child(close)

func _build_settings_panel() -> void:
	_settings_panel = _mk_panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 11)
	_settings_panel.add_child(v)
	v.add_child(_mk_label("SETTINGS", 28, Color(0.55, 0.95, 1.0)))
	v.add_child(_mk_label("Game server URL (for online play & leaderboard)", 15, Color(0.7, 0.75, 0.85)))
	_api_edit = _mk_edit("http://127.0.0.1:8900")
	v.add_child(_api_edit)
	var sound_row := HBoxContainer.new()
	sound_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var sound_check := CheckBox.new()
	sound_check.text = "Sound effects"
	sound_check.button_pressed = Session.sound
	sound_check.add_theme_font_size_override("font_size", 19)
	sound_check.toggled.connect(func(on: bool) -> void:
		Session.sound = on
		Session.save_data()
	)
	sound_row.add_child(sound_check)
	v.add_child(sound_row)
	var save := _mk_button("Save", true)
	save.pressed.connect(func() -> void:
		var url := _api_edit.text.strip_edges()
		if url != "":
			Session.api_url = url.trim_suffix("/")
			Session.save_data()
		_settings_panel.visible = false
		_ready_ping_again()
	)
	v.add_child(save)
	var close := _mk_button("Close")
	close.pressed.connect(func() -> void: _settings_panel.visible = false)
	v.add_child(close)

func _ready_ping_again() -> void:
	ApiClient.ping(func(res: Dictionary) -> void:
		_server_label.text = "Server online — global leaderboard available" if res["ok"] else "Server offline — scores stay on this device"
	)
