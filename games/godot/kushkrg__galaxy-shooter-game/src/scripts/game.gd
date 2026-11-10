extends Node2D
## Galaxy Shooter — the game scene.
## Owns the run: levels & waves, spawning, collisions, score/combo,
## HUD, pause, game over and score submission (online + local).

enum State { BANNER, PLAYING, LEVEL_CLEAR, GAME_OVER }

const VIEW_FALLBACK := Vector2(720, 1280)

var _state: int = State.BANNER
var _player: Player
var _enemies: Array = []
var _p_bullets: Array = []
var _e_bullets: Array = []
var _powerups: Array = []

var _level := 1
var _score := 0
var _combo := 0
var _combo_timer := 0.0
var _multiplier := 1

var _spawn_left := 0
var _spawn_timer := 0.0
var _spawn_interval := 1.0
var _boss_level := false
var _boss_spawned := false
var _state_timer := 0.0
var _submitted := false

# HUD nodes
var _score_label: Label
var _level_label: Label
var _combo_label: Label
var _hp_bar: ProgressBar
var _banner_label: Label
var _overlay_layer: CanvasLayer
var _pause_panel: PanelContainer
var _over_panel: PanelContainer
var _over_stats: Label
var _over_status: Label
var _over_board: Label

func _view() -> Vector2:
	var s := get_viewport_rect().size
	return s if s.x > 0 else VIEW_FALLBACK

func _ready() -> void:
	var view := _view()
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.016, 0.043)
	bg.size = view + Vector2(400, 0)
	add_child(bg)
	var stars := Starfield.new()
	add_child(stars)
	_build_hud()
	_player = Player.new()
	_player.position = Vector2(view.x * 0.5, view.y - 170)
	_player.fired.connect(_on_player_fired)
	_player.health_changed.connect(_on_health_changed)
	_player.died.connect(_on_player_died)
	add_child(_player)
	_on_health_changed(_player.hp, _player.max_hp)
	_start_level(1)

# ---------------------------------------------------------------- HUD
func _mk_label(text: String, size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.07, 0.14, 0.95)
	s.border_color = Color(0.2, 0.85, 1.0, 0.8)
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.set_content_margin_all(22)
	return s

func _mk_button(text: String, min_w: float = 210) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 52)
	b.add_theme_font_size_override("font_size", 21)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.12, 0.24, 0.95)
	normal.border_color = Color(0.2, 0.85, 1.0, 0.65)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.13, 0.3, 0.45, 0.98)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	return b

func _build_hud() -> void:
	var view := _view()
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14
	top.offset_top = 10
	top.offset_right = -14
	top.add_theme_constant_override("separation", 16)
	layer.add_child(top)
	_score_label = _mk_label("SCORE 0", 24, Color(0.65, 0.95, 1.0))
	top.add_child(_score_label)
	_level_label = _mk_label("LEVEL 1", 24, Color(1.0, 0.85, 0.45))
	top.add_child(_level_label)
	_combo_label = _mk_label("", 24, Color(1.0, 0.45, 0.75))
	top.add_child(_combo_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var pause_btn := _mk_button("II", 54)
	pause_btn.custom_minimum_size = Vector2(54, 44)
	pause_btn.pressed.connect(_toggle_pause)
	top.add_child(pause_btn)
	_hp_bar = ProgressBar.new()
	_hp_bar.min_value = 0
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_hp_bar.show_percentage = false
	_hp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hp_bar.offset_left = 14
	_hp_bar.offset_top = 62
	_hp_bar.offset_right = -14
	_hp_bar.offset_bottom = 76
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.55)
	bg_style.set_corner_radius_all(7)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.95, 0.45)
	fill_style.set_corner_radius_all(7)
	_hp_bar.add_theme_stylebox_override("background", bg_style)
	_hp_bar.add_theme_stylebox_override("fill", fill_style)
	layer.add_child(_hp_bar)
	_banner_label = _mk_label("", 54, Color(0.65, 0.95, 1.0))
	_banner_label.set_anchors_preset(Control.PRESET_CENTER)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.offset_left = -view.x * 0.5
	_banner_label.offset_right = view.x * 0.5
	_banner_label.offset_top = -160
	layer.add_child(_banner_label)
	_build_overlays()

func _center_panel(panel: PanelContainer) -> void:
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -265
	panel.offset_right = 265
	panel.offset_top = -320
	panel.offset_bottom = 320

func _build_overlays() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 10
	_overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay_layer)
	# Pause panel
	_pause_panel = PanelContainer.new()
	_pause_panel.add_theme_stylebox_override("panel", _panel_style())
	_center_panel(_pause_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	_pause_panel.add_child(pv)
	var pt := _mk_label("PAUSED", 36, Color(0.65, 0.95, 1.0))
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pt)
	var resume := _mk_button("Resume")
	resume.pressed.connect(_toggle_pause)
	pv.add_child(resume)
	var restart := _mk_button("Restart")
	restart.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	pv.add_child(restart)
	var menu := _mk_button("Main Menu")
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	pv.add_child(menu)
	_pause_panel.visible = false
	_overlay_layer.add_child(_pause_panel)
	# Game over panel
	_over_panel = PanelContainer.new()
	_over_panel.add_theme_stylebox_override("panel", _panel_style())
	_center_panel(_over_panel)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 12)
	_over_panel.add_child(ov)
	var ot := _mk_label("GAME OVER", 40, Color(1.0, 0.45, 0.6))
	ot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov.add_child(ot)
	_over_stats = _mk_label("", 22)
	_over_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov.add_child(_over_stats)
	_over_status = _mk_label("", 17, Color(0.65, 0.95, 1.0))
	_over_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov.add_child(_over_status)
	_over_board = _mk_label("", 18, Color(0.85, 0.9, 1.0))
	ov.add_child(_over_board)
	var retry := _mk_button("Play Again")
	retry.pressed.connect(func() -> void: get_tree().reload_current_scene())
	ov.add_child(retry)
	var omenu := _mk_button("Main Menu")
	omenu.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	ov.add_child(omenu)
	_over_panel.visible = false
	_overlay_layer.add_child(_over_panel)

# ---------------------------------------------------------------- levels
func _start_level(level: int) -> void:
	_level = level
	_level_label.text = "LEVEL %d" % level
	_boss_level = level % 5 == 0
	_boss_spawned = false
	if _boss_level:
		_spawn_left = 4 + level
		_spawn_interval = 2.4
	else:
		_spawn_left = 6 + level * 2
		_spawn_interval = maxf(0.45, 1.15 - level * 0.05)
	_spawn_timer = 0.6
	_state = State.BANNER
	_state_timer = 1.5
	_banner_label.text = "LEVEL %d" % level if not _boss_level else "!! BOSS INCOMING !!"
	_banner_label.modulate = Color(1, 1, 1, 1)

func _pick_kind() -> String:
	var r := randf()
	if _level >= 3 and r < 0.15:
		return "tank"
	if _level >= 2 and r < 0.48:
		return "weaver"
	return "drone"

func _spawn_enemy(kind: String, pos: Vector2) -> void:
	var e := Enemy.new()
	e.setup(kind, pos, _level)
	e.player_ref = _player
	e.wants_fire.connect(_on_enemy_fire)
	e.wants_drone.connect(func(p: Vector2) -> void: _spawn_enemy("drone", p))
	e.escaped.connect(func(en: Enemy) -> void: _enemies.erase(en))
	add_child(e)
	_enemies.append(e)

func _on_enemy_fire(from_pos: Vector2, dir: Vector2, speed: float, damage: int) -> void:
	var b := Bullet.new()
	b.setup(from_pos, dir * speed, damage, false)
	add_child(b)
	_e_bullets.append(b)

func _on_player_fired(pos: Vector2, dir: Vector2, damage: int) -> void:
	var b := Bullet.new()
	b.setup(pos, dir * 640.0, damage, true)
	add_child(b)
	_p_bullets.append(b)

# ---------------------------------------------------------------- loop
func _process(delta: float) -> void:
	if get_tree().paused:
		return
	match _state:
		State.BANNER:
			_state_timer -= delta
			_banner_label.modulate.a = clampf(_state_timer, 0.0, 1.0)
			if _state_timer <= 0:
				_banner_label.text = ""
				_state = State.PLAYING
		State.PLAYING:
			_update_spawning(delta)
			_update_collisions()
			_update_combo(delta)
			if _spawn_left <= 0 and _enemies.is_empty() and _player.alive:
				_level_cleared()
		State.LEVEL_CLEAR:
			_state_timer -= delta
			if _state_timer <= 0:
				_banner_label.text = ""
				_start_level(_level + 1)
		State.GAME_OVER:
			_state_timer -= delta
			if _state_timer <= 0 and not _over_panel.visible:
				_show_game_over()

func _update_spawning(delta: float) -> void:
	if _boss_level and not _boss_spawned:
		_boss_spawned = true
		_spawn_enemy("boss", Vector2(_view().x * 0.5, -120))
		return
	if _spawn_left <= 0:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_timer = _spawn_interval * randf_range(0.75, 1.25)
		_spawn_left -= 1
		var x := randf_range(55.0, _view().x - 55.0)
		_spawn_enemy(_pick_kind(), Vector2(x, -55))

func _update_combo(delta: float) -> void:
	if _combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0:
			_combo = 0
			_multiplier = 1
			_combo_label.text = ""

func _add_score(base: int) -> void:
	_combo += 1
	_combo_timer = 2.0
	_multiplier = clampi(1 + _combo / 8, 1, 5)
	_score += base * _multiplier
	_score_label.text = "SCORE %s" % _score
	_combo_label.text = "x%d COMBO" % _multiplier if _multiplier > 1 else ""

func _dist2(a: Vector2, b: Vector2) -> float:
	return a.distance_squared_to(b)

func _update_collisions() -> void:
	# Player bullets vs enemies.
	for b in _p_bullets.duplicate():
		if not is_instance_valid(b):
			_p_bullets.erase(b)
			continue
		for e in _enemies.duplicate():
			if _dist2(b.position, e.position) < pow(b.radius + e.radius, 2.0):
				_p_bullets.erase(b)
				b.queue_free()
				if e.take_damage(b.damage):
					_kill_enemy(e)
				break
	# Enemy bullets vs player.
	if _player.alive:
		for b in _e_bullets.duplicate():
			if not is_instance_valid(b):
				_e_bullets.erase(b)
				continue
			if _dist2(b.position, _player.position) < pow(b.radius + _player.radius, 2.0):
				_e_bullets.erase(b)
				b.queue_free()
				_player.take_damage(b.damage)
		# Enemies vs player (ramming).
		for e in _enemies.duplicate():
			if _dist2(e.position, _player.position) < pow(e.radius + _player.radius - 6.0, 2.0):
				_player.take_damage(e.contact_damage)
				if e.kind != "boss":
					_kill_enemy(e, false)
		# Powerups vs player.
		for p in _powerups.duplicate():
			if not is_instance_valid(p):
				_powerups.erase(p)
				continue
			if _dist2(p.position, _player.position) < pow(p.radius + _player.radius + 8.0, 2.0):
				_powerups.erase(p)
				_player.apply_powerup(p.kind)
				p.queue_free()
	else:
		for b in _e_bullets.duplicate():
			if not is_instance_valid(b):
				_e_bullets.erase(b)
	for arr in [_p_bullets, _e_bullets]:
		for b in arr.duplicate():
			if not is_instance_valid(b):
				arr.erase(b)

func _kill_enemy(e: Enemy, give_score: bool = true) -> void:
	_enemies.erase(e)
	if give_score:
		_add_score(e.score_value)
	var ex := Explosion.new()
	ex.setup(e.position, e.radius + 26.0, Color(1.0, 0.55, 0.25) if e.kind != "boss" else Color(1.0, 0.35, 0.65))
	add_child(ex)
	Sfx.play_explosion()
	if e.kind == "boss" or randf() < 0.12:
		_drop_powerup(e.position)
	e.queue_free()

func _drop_powerup(pos: Vector2) -> void:
	var kinds := ["rapid", "triple", "shield", "life"]
	var weights := [0.32, 0.30, 0.24, 0.14]
	var r := randf()
	var acc := 0.0
	var kind := "rapid"
	for i in kinds.size():
		acc += weights[i]
		if r <= acc:
			kind = kinds[i]
			break
	var p := Powerup.new()
	p.setup(kind, pos)
	add_child(p)
	_powerups.append(p)

func _level_cleared() -> void:
	_state = State.LEVEL_CLEAR
	_state_timer = 1.8
	var bonus := 100 * _level
	_score += bonus
	_score_label.text = "SCORE %s" % _score
	_player.heal(15)
	_banner_label.text = "LEVEL %d CLEAR!  +%d" % [_level, bonus]
	_banner_label.modulate = Color(1, 1, 1, 1)

func _on_health_changed(hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	var fill := _hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null:
		var pct := float(hp) / float(maxi(1, max_hp))
		fill.bg_color = Color(0.3, 0.95, 0.45) if pct > 0.5 else (Color(0.98, 0.8, 0.25) if pct > 0.25 else Color(0.98, 0.35, 0.35))

func _on_player_died() -> void:
	var ex := Explosion.new()
	ex.setup(_player.position, 90.0, Color(0.4, 0.9, 1.0))
	add_child(ex)
	Sfx.play_explosion()
	_state = State.GAME_OVER
	_state_timer = 1.1

func _show_game_over() -> void:
	Session.add_local_score(_score, _level)
	_over_stats.text = "Score: %s\nLevel reached: %d\nYour best: %s" % [_score, _level, maxi(_score, Session.local_best())]
	_over_board.text = "Loading leaderboard…"
	_over_panel.visible = true
	if Session.is_logged_in() and not _submitted:
		_submitted = true
		_over_status.text = "Submitting score as %s…" % Session.display_name()
		ApiClient.submit_score(_score, _level, func(res: Dictionary) -> void:
			if res["ok"]:
				_over_status.text = "Score submitted to the global leaderboard ✓"
			else:
				_over_status.text = "Offline — score saved on this device."
			_load_board()
		)
	else:
		_over_status.text = "Playing offline — score saved on this device.\nLog in from the main menu to join the global leaderboard."
		_load_board()

func _load_board() -> void:
	ApiClient.fetch_leaderboard(8, func(res: Dictionary) -> void:
		if res["ok"] and typeof(res["data"]) == TYPE_DICTIONARY:
			var lines := ["— GLOBAL TOP PILOTS —"]
			for entry in res["data"].get("entries", []):
				lines.append("#%d  %s — %s (Lv %d)" % [int(entry["rank"]), str(entry["name"]), int(entry["score"]), int(entry["level"])])
			_over_board.text = "\n".join(lines)
		else:
			_over_board.text = _local_board_text()
	)

func _local_board_text() -> String:
	if Session.local_scores.is_empty():
		return "No scores yet — be the first!"
	var lines := ["— YOUR DEVICE TOP SCORES —"]
	for i in Session.local_scores.size():
		var s: Dictionary = Session.local_scores[i]
		lines.append("#%d  %s — %s (Lv %d)" % [i + 1, str(s["name"]), int(s["score"]), int(s["level"])])
	return "\n".join(lines)

func _toggle_pause() -> void:
	if _state == State.GAME_OVER:
		return
	get_tree().paused = not get_tree().paused
	_pause_panel.visible = get_tree().paused

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_toggle_pause()
