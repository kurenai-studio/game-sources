class_name Hud
extends CanvasLayer
## In-run HUD: animated health bar, XP, wave progress, boss bar, combo meter,
## cooldowns, minimap, off-screen enemy indicators, banners and screen FX.

var game: Node
var _hp_bar: ProgressBar
var _hp_lag: ProgressBar
var _hp_text: Label
var _xp_bar: ProgressBar
var _level: Label
var _wave: Label
var _wave_bar: ProgressBar
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _boss_lag: ProgressBar
var _boss_phase: Label
var _score: Label
var _coins: Label
var _time: Label
var _combo_box: VBoxContainer
var _combo: Label
var _combo_bar: ProgressBar
var _dash: Widgets.RadialCooldown
var _ability: Widgets.RadialCooldown
var _banner: Label
var _banner_sub: Label
var _screen_fx: ColorRect
var _fx_mat: ShaderMaterial
var _minimap: Minimap
var _indicators: OffscreenIndicators
var _flash: float = 0.0
var _shown_score: float = 0.0


func setup(g: Node) -> void:
	game = g
	layer = 10
	_screen_fx = ColorRect.new()
	UiKit.full_rect(_screen_fx)
	_screen_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_mat = ShaderMaterial.new()
	_fx_mat.shader = preload("res://shaders/screen_fx.gdshader")
	_screen_fx.material = _fx_mat
	add_child(_screen_fx)

	_indicators = OffscreenIndicators.new()
	_indicators.game = g
	add_child(_indicators)

	var root := Control.new()
	UiKit.full_rect(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Top-left: character + health + cooldowns
	var tl := PanelContainer.new()
	tl.theme_type_variation = "CardPanel"
	tl.position = Vector2(18, 16)
	root.add_child(tl)
	var tl_row := HBoxContainer.new()
	tl_row.add_theme_constant_override("separation", 12)
	tl.add_child(tl_row)
	var ch: CharacterData = g.character
	tl_row.add_child(Widgets.ShapeIcon.new(ch.shape_sides, ch.color, 58))
	var tl_col := VBoxContainer.new()
	tl_col.add_theme_constant_override("separation", 4)
	tl_row.add_child(tl_col)
	var name_row := HBoxContainer.new()
	name_row.add_child(UiKit.label(ch.name_key, "AccentLabel", 16))
	_hp_text = UiKit.label("", "MutedLabel", 15)
	_hp_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_row.add_child(_hp_text)
	tl_col.add_child(name_row)
	var hp_stack := Control.new()
	hp_stack.custom_minimum_size = Vector2(260, 18)
	tl_col.add_child(hp_stack)
	_hp_lag = _bar(Color(1, 1, 1, 0.75))
	_hp_bar = _bar(UiTheme.SUCCESS)
	for b in [_hp_lag, _hp_bar]:
		UiKit.full_rect(b)
		hp_stack.add_child(b)
	_hp_lag.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	var cd_row := HBoxContainer.new()
	cd_row.add_theme_constant_override("separation", 8)
	_dash = Widgets.RadialCooldown.new(UiTheme.ACCENT, tr("HUD_DASH"))
	_ability = Widgets.RadialCooldown.new(ch.color, tr("HUD_SKILL"))
	_level = UiKit.label("", "HudLabel", 20)
	_level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cd_row.add_child(_dash)
	cd_row.add_child(_ability)
	cd_row.add_child(_level)
	tl_col.add_child(cd_row)

	# Top-center: wave + progress / boss bar
	var tc := VBoxContainer.new()
	tc.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tc.position = Vector2(-200, 14)
	tc.custom_minimum_size = Vector2(400, 0)
	tc.add_theme_constant_override("separation", 4)
	root.add_child(tc)
	_wave = UiKit.label("", "HudLabel", 26, HORIZONTAL_ALIGNMENT_CENTER)
	tc.add_child(_wave)
	_wave_bar = _bar(UiTheme.ACCENT)
	_wave_bar.custom_minimum_size = Vector2(400, 8)
	tc.add_child(_wave_bar)
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_box.position = Vector2(-260, 70)
	_boss_box.custom_minimum_size = Vector2(520, 0)
	root.add_child(_boss_box)
	var boss_row := HBoxContainer.new()
	var boss_name := UiKit.label("ENEMY_BOSS", "HudLabel", 20)
	boss_name.add_theme_color_override("font_color", UiTheme.DANGER)
	boss_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_row.add_child(boss_name)
	_boss_phase = UiKit.label("", "HudLabel", 18)
	boss_row.add_child(_boss_phase)
	_boss_box.add_child(boss_row)
	var boss_stack := Control.new()
	boss_stack.custom_minimum_size = Vector2(520, 16)
	_boss_box.add_child(boss_stack)
	_boss_lag = _bar(Color(1, 0.85, 0.6, 0.8))
	_boss_bar = _bar(UiTheme.DANGER)
	for b in [_boss_lag, _boss_bar]:
		UiKit.full_rect(b)
		boss_stack.add_child(b)
	_boss_lag.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_boss_box.hide()

	# Top-right: score, coins, time, combo
	var tr_box := VBoxContainer.new()
	tr_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tr_box.position = Vector2(-260, 14)
	tr_box.custom_minimum_size = Vector2(240, 0)
	root.add_child(tr_box)
	_score = UiKit.label("0", "HudLabel", 32, HORIZONTAL_ALIGNMENT_RIGHT)
	tr_box.add_child(_score)
	var meta_row := HBoxContainer.new()
	meta_row.alignment = BoxContainer.ALIGNMENT_END
	meta_row.add_theme_constant_override("separation", 16)
	_time = UiKit.label("0:00", "MutedLabel", 18)
	_coins = UiKit.label("◆ 0", "GoldLabel", 20)
	meta_row.add_child(_time)
	meta_row.add_child(_coins)
	tr_box.add_child(meta_row)
	_combo_box = VBoxContainer.new()
	_combo_box.add_theme_constant_override("separation", 2)
	_combo = UiKit.label("", "HudLabel", 26, HORIZONTAL_ALIGNMENT_RIGHT)
	_combo.add_theme_color_override("font_color", UiTheme.ACCENT_2)
	_combo_box.add_child(_combo)
	_combo_bar = _bar(UiTheme.ACCENT_2)
	_combo_bar.custom_minimum_size = Vector2(240, 6)
	_combo_box.add_child(_combo_bar)
	_combo_box.modulate.a = 0.0
	tr_box.add_child(_combo_box)

	# Bottom: XP bar
	_xp_bar = _bar(Color("5dffd0"))
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_xp_bar.offset_top = -10
	_xp_bar.add_theme_stylebox_override("background", UiTheme.box(Color(0, 0, 0, 0.5), Color.TRANSPARENT, 0, 0, Vector4.ZERO))
	_xp_bar.add_theme_stylebox_override("fill", UiTheme.box(Color("5dffd0"), Color.TRANSPARENT, 0, 0, Vector4.ZERO))
	root.add_child(_xp_bar)

	# Bottom-right: minimap
	_minimap = Minimap.new()
	_minimap.game = g
	_minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_minimap.position = Vector2(-228, -168)
	_minimap.size = Vector2(210, 140)
	root.add_child(_minimap)

	# Center banner
	_banner = UiKit.label("", "TitleLabel", 54, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.position = Vector2(-500, -170)
	_banner.size = Vector2(1000, 80)
	_banner.pivot_offset = Vector2(500, 40)
	_banner.modulate.a = 0.0
	root.add_child(_banner)
	_banner_sub = UiKit.label("", "AccentLabel", 22, HORIZONTAL_ALIGNMENT_CENTER)
	_banner_sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner_sub.position = Vector2(-500, -95)
	_banner_sub.size = Vector2(1000, 30)
	_banner_sub.modulate.a = 0.0
	root.add_child(_banner_sub)

	EventBus.player_damaged.connect(_on_damaged)
	EventBus.player_healed.connect(_on_healed)
	EventBus.screen_flash.connect(_on_screen_flash)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_phase_changed.connect(_on_boss_phase)
	_set_health(g.player.health_int(), g.player.max_health(), false)


func _bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.min_value = 0.0
	b.max_value = 1.0
	b.step = 0.0
	b.value = 1.0
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("fill", UiTheme.box(color, Color.TRANSPARENT, 0, 6, Vector4.ZERO))
	return b


func _set_health(current: int, maximum: int, animate: bool = true) -> void:
	var ratio := clampf(float(current) / maxf(1.0, maximum), 0.0, 1.0)
	_hp_text.text = "%d / %d" % [current, maximum]
	var col := UiTheme.SUCCESS if ratio > 0.5 else (UiTheme.GOLD if ratio > 0.25 else UiTheme.DANGER)
	_hp_bar.add_theme_stylebox_override("fill", UiTheme.box(col, Color.TRANSPARENT, 0, 6, Vector4.ZERO))
	_fx_mat.set_shader_parameter("low_health", 1.0 if ratio <= 0.25 else 0.0)
	if not animate:
		_hp_bar.value = ratio
		_hp_lag.value = ratio
		return
	var tw := _hp_bar.create_tween()
	tw.tween_property(_hp_bar, "value", ratio, 0.12)
	if ratio < _hp_lag.value:
		var lag := _hp_lag.create_tween()
		lag.tween_interval(0.35)
		lag.tween_property(_hp_lag, "value", ratio, 0.5).set_trans(Tween.TRANS_CUBIC)
	else:
		_hp_lag.value = ratio


func _on_damaged(_amount: int, current: int, maximum: int) -> void:
	_set_health(current, maximum)
	_fx_mat.set_shader_parameter("flash_color", UiTheme.DANGER)
	_flash = 1.0


func _on_screen_flash(c: Color) -> void:
	_fx_mat.set_shader_parameter("flash_color", c)
	_flash = 1.0


func _on_boss_spawned(_b: Node) -> void:
	_boss_box.show()
	_boss_bar.value = 1.0
	_boss_lag.value = 1.0
	UiKit.animate_in(_boss_box, 0.0, 0.8)


func _on_boss_phase(p: int) -> void:
	banner(tr("BOSS_PHASE") % p, tr("BOSS_PHASE_SUB"), UiTheme.DANGER)


func _on_healed(current: int, maximum: int) -> void:
	_set_health(current, maximum)


func banner(text: String, sub: String = "", color: Color = Color.WHITE) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_sub.text = sub
	_banner.scale = Vector2(1.6, 1.6)
	var tw := _banner.create_tween().set_parallel(true)
	tw.tween_property(_banner, "modulate:a", 1.0, 0.15)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_banner_sub, "modulate:a", 1.0, 0.25).set_delay(0.1)
	tw.chain().tween_interval(1.3)
	tw.chain().tween_property(_banner, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(_banner_sub, "modulate:a", 0.0, 0.4)


func combo_pop() -> void:
	_combo.pivot_offset = _combo.size * Vector2(1.0, 0.5)
	_combo.scale = Vector2(1.3, 1.3)
	_combo.create_tween().tween_property(_combo, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	if game == null or game.player == null:
		return
	var p: Player = game.player
	_dash.ratio = p.dash_ready_ratio()
	_ability.ratio = p.ability_ready_ratio()
	_dash.queue_redraw()
	_ability.queue_redraw()
	_level.text = tr("HUD_LEVEL") % game.progression.level
	_xp_bar.value = lerpf(_xp_bar.value, game.progression.progress_ratio(), minf(1.0, delta * 10.0))
	_wave.text = (tr("HUD_BOSS_WAVE") if WaveDirector.is_boss_wave(game.wave) else tr("HUD_WAVE")) % game.wave
	_wave_bar.value = lerpf(_wave_bar.value, game.wave_progress(), minf(1.0, delta * 8.0))
	_shown_score = lerpf(_shown_score, float(game.scores.score), minf(1.0, delta * 12.0))
	_score.text = str(int(round(_shown_score)))
	_coins.text = "◆ %d" % game.run["coins"]
	_time.text = ResultsScreen.format_time(game.run["time"])
	var combo: int = game.scores.combo
	_combo_box.modulate.a = lerpf(_combo_box.modulate.a, 1.0 if combo >= 2 else 0.0, minf(1.0, delta * 10.0))
	if combo >= 2:
		_combo.text = tr("HUD_COMBO") % [combo, game.scores.multiplier()]
		_combo_bar.value = game.scores.combo_time_ratio()
	var boss: Enemy = game.boss
	if boss and is_instance_valid(boss) and boss.is_alive():
		var r := boss.health / boss.max_health
		_boss_bar.value = r
		_boss_lag.value = maxf(r, lerpf(_boss_lag.value, r, minf(1.0, delta * 3.0)))
		_boss_phase.text = "◆".repeat(boss.phase) + "◇".repeat(3 - boss.phase)
	elif _boss_box.visible:
		_boss_box.hide()
	_flash = maxf(0.0, _flash - delta * 3.0)
	_fx_mat.set_shader_parameter("flash_amount", _flash * 0.6)
	_minimap.queue_redraw()
	_indicators.queue_redraw()


## Corner minimap of the whole arena.
class Minimap extends Control:
	var game: Node

	func _draw() -> void:
		if game == null or game.layout.is_empty():
			return
		var arena: Vector2 = game.layout["size"]
		var k := minf(size.x / arena.x, size.y / arena.y)
		draw_rect(Rect2(Vector2.ZERO, arena * k), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(Vector2.ZERO, arena * k), Color(UiTheme.ACCENT, 0.5), false, 1.5)
		for h: Dictionary in game.layout["hazards"]:
			var r: Rect2 = h["rect"]
			draw_rect(Rect2(r.position * k, r.size * k), Color(1, 0.5, 0.3, 0.25))
		for o: Rect2 in game.layout["obstacles"]:
			draw_rect(Rect2(o.position * k, o.size * k), Color(1, 1, 1, 0.3))
		for e: Enemy in game.living_enemies():
			draw_circle(e.global_position * k, 5.0 if e.is_boss() else 2.0, e.data.color)
		var view := game.get_viewport().get_visible_rect().size
		var cam: Vector2 = game.camera.get_screen_center_position()
		draw_rect(Rect2((cam - view / 2.0) * k, view * k), Color(1, 1, 1, 0.35), false, 1.0)
		if game.player:
			draw_circle(game.player.global_position * k, 3.5, game.character.color)


## Edge-of-screen arrows pointing at enemies outside the camera view.
class OffscreenIndicators extends Control:
	var game: Node

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if game == null:
			return
		var xf := game.get_viewport().get_canvas_transform()
		var rect := Rect2(Vector2.ZERO, size).grow(-34.0)
		var center := size / 2.0
		var shown := 0
		for e: Enemy in game.living_enemies():
			var sp: Vector2 = xf * e.global_position
			if rect.grow(30.0).has_point(sp):
				continue
			var dir := (sp - center).normalized()
			var t := INF
			if dir.x != 0.0:
				t = minf(t, absf((rect.size.x / 2.0) / dir.x))
			if dir.y != 0.0:
				t = minf(t, absf((rect.size.y / 2.0) / dir.y))
			var p := center + dir * t
			var s := 13.0 if e.is_boss() else 8.0
			var pts := PackedVector2Array([p + dir * s, p + dir.orthogonal() * s * 0.7, p - dir.orthogonal() * s * 0.7])
			draw_colored_polygon(pts, Color(e.data.color, 0.85))
			shown += 1
			if shown >= 30:
				break
