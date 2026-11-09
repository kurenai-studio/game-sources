extends "res://scripts/game/game_modes.gd"
## Pixel-art 3D table tennis: entry point. Startup (command-line debug flags),
## input, and the per-frame loops; everything else lives in scripts/game/.


var cam_arg := -1   # --cam=N for this run
var lang_arg := ""  # --lang=en|zh|ja for this run
var nohud := false  # --nohud: just the 3D scene, for promo shots
var hud_arg := ""   # --hud=simple|full for this run
var shot_on_fx := ""  # --shot-on-fx=name[:ms]: screenshot that long after that skill sound
var shot_fx_delay := 150
var perf_log := false  # --perf (or ?perf on the web page): frame times every 3 s


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autoplay":
			autoplay = true
		elif a.begins_with("--screenshot="):
			screenshot_path = a.trim_prefix("--screenshot=")
			autoplay = true
		elif a.begins_with("--shot-on-style="):
			shot_on_style = a.trim_prefix("--shot-on-style=")
		elif a == "--shot-on-var":
			shot_on_var = true
		elif a == "--serve-demo":
			serve_demo = true
		elif a == "--shot-on-heavy":
			shot_on_heavy = true
		elif a.begins_with("--watch-level="):
			watch_level = clampi(int(a.trim_prefix("--watch-level=")), 0, LEVELS.size() - 1)
		elif a.begins_with("--level="):
			level_idx = clampi(int(a.trim_prefix("--level=")), 0, LEVELS.size() - 1)
		elif a.begins_with("--cam="):
			cam_arg = int(a.trim_prefix("--cam="))
		elif a.begins_with("--ui="):
			ui_page = a.trim_prefix("--ui=")
		elif a == "--tie-auto":
			tie_auto = true
		elif a.begins_with("--gear="):
			gear_debug = a.trim_prefix("--gear=")
		elif a.begins_with("--drill-auto="):
			drill_auto = a.trim_prefix("--drill-auto=")
		elif a == "--skill":
			skill_debug = true
		elif a.begins_with("--lang="):
			lang_arg = a.trim_prefix("--lang=")
		elif a == "--run-auto":
			run_auto = true
		elif a.begins_with("--loadout="):
			loadout_arg = Array(a.trim_prefix("--loadout=").split(","))
		elif a == "--spells":
			spells_debug = true
		elif a == "--clean":
			clean = true
		elif a == "--perf":
			perf_log = true
		elif a.begins_with("--shot-on-fx="):
			var bits := a.trim_prefix("--shot-on-fx=").split(":")
			shot_on_fx = bits[0]
			if bits.size() > 1:
				shot_fx_delay = int(bits[1])
		elif a.begins_with("--hud="):
			hud_arg = a.trim_prefix("--hud=")
		elif a == "--nohud":
			nohud = true
		elif a == "--human-sim":
			human_sim = true
		elif a == "--nosave":
			no_save = true
		elif a.begins_with("--boss-auto="):
			boss_auto = a.trim_prefix("--boss-auto=")
	if OS.has_feature("web") and str(JavaScriptBridge.eval("location.search")).contains("perf"):
		perf_log = true
	randomize()
	build_viewport()
	build_world()
	build_hud()
	vp.audio_listener_enable_3d = true     # the active camera hears the 3D sounds
	sfx = Sfx.new()
	add_child(sfx)
	sfx.setup(world)
	get_viewport().size_changed.connect(apply_pixel_scale)
	apply_pixel_scale()
	# English and Japanese (the text in the code is Chinese); settings pick one
	TranslationServer.add_translation(load("res://scripts/i18n.gd").new("en"))
	TranslationServer.add_translation(load("res://scripts/i18n.gd").new("ja"))
	load_settings()
	if lang_arg != "":
		settings.lang = lang_arg
		apply_settings()
	if hud_arg != "":
		settings.hud = hud_arg
	if cam_arg >= 0:
		cam_mode = cam_arg   # the command line beats the saved default view
	if skill_debug:
		settings.skill_mode = true
	tour = Tour.new()
	prewarm_fx()
	var direct := autoplay or serve_demo or shot_on_heavy or shot_on_var or shot_on_style != ""
	if gear_debug != "":
		tour.mine().players[0]["gear"] = {"blade": "wood5", "fh": gear_debug, "bh": gear_debug}
	if drill_auto != "":
		start_drill(drill_auto, tour.mine().players[0], false)
	elif run_auto:
		shift_run = ShiftRun.new(Roster.CLUBS[0].players[0].duplicate(true), settings.loadout)
		play_run(false)
	elif boss_auto != "":
		play_boss(boss_auto, Roster.CLUBS[0].players[0], false, 3)
	elif tie_auto:
		begin_tie(Roster.CLUBS[1].id, Roster.CLUBS[0].players.slice(0, 3), Tour.BEST_OF)
		play_tie_match(false)
	elif ui_page == "coach":
		begin_tie(Roster.CLUBS[1].id, Roster.CLUBS[0].players.slice(0, 3), Tour.BEST_OF)
		play_tie_match(false)
		games[PLAYER] = 1
		game_scores = ["11:7"]
		break_kind = "game"
		open_break()
	elif ui_page != "" or not direct:
		if ui_page == "run":
			shift_run = ShiftRun.new(Roster.CLUBS[0].players[0].duplicate(true), settings.loadout)
			shift_run.resolve(true, "7:4", SKILL_SLOTS.map(func(s): return s.id))
		if ui_page == "tie":
			begin_tie(Roster.CLUBS[1].id, Roster.CLUBS[0].players.slice(0, 3), Tour.BEST_OF)
		open_menu(ui_page if ui_page != "" else "title")
	else:
		new_game()


func _physics_process(delta: float) -> void:
	if not replay.is_empty() or on_break or analysis_panel.visible:
		return                       # the game is paused while a replay runs or the coach talks
	if not pending_var.is_empty() and rec.clock >= pending_var.trigger:
		start_var(pending_var)
		pending_var = {}
		return
	tick_call(delta)
	update_paddle(PLAYER, delta)
	update_paddle(AI, delta)
	var regen := STAMINA_REGEN_RALLY if ball_live and not point_over else STAMINA_REGEN_REST
	for sd in [PLAYER, AI]:
		var r: float = regen + (STAMINA_REGEN_SET if settle[sd] >= 1.0 else 0.0)
		stamina[sd] = minf(stamina[sd] + r * delta, max_stamina[sd])
	if not drill.is_empty():
		drill_tick(delta)
	if waiting_serve:
		var p: Vector3 = paddle_pos[server]
		bp = p + Vector3(0.0, 0.11 + 0.03 * sin(elapsed * 5.0), -0.05 * server)
		bv = Vector3.ZERO
		if server == AI or autoplay:
			serve_timer -= delta
			if serve_timer < SERVE_TELL:
				serve_preview = serve_spin(server, ai_tell_kind, ai_tell_side, 0.8)   # the motion, maybe a feint
			if serve_timer <= 0.0:
				auto_serve(server)
		elif not point_over:
			var hs := held_stroke()
			if not serve_armed:
				serve_armed = hs.x == 0
			elif hs.x != 0:
				# Serve meter: holding longer offers more spin, but the needle swings
				# faster and the sweet zone narrows and drifts faster, so landing the
				# release in it gets harder.
				serve_held = hs
				serve_hold += delta
				var charge := minf(clampf(serve_hold / SERVE_CHARGE_FULL, 0.0, 1.0), power_cap(PLAYER))
				serve_phase += delta * TAU * lerpf(0.5, 3.2, charge)
				serve_zone_t += delta * lerpf(0.6, 3.0, charge)
				var m = serve_meter
				m.visible = true
				m.charge = charge
				m.cap = power_cap(PLAYER)
				m.needle = 0.5 - 0.5 * cos(serve_phase)
				m.zone_w = lerpf(0.34, 0.1, charge)
				m.zone_c = 0.5 + (0.5 - m.zone_w * 0.5) * 0.7 * sin(serve_zone_t)
				serve_preview = serve_spin(PLAYER, "top" if hs.x > 0 else "back", hs.y * SIDE_KEY_SPIN, charge)
			elif serve_held.x != 0:
				player_serve("top" if serve_held.x > 0 else "back", serve_held.y,
						minf(clampf(serve_hold / SERVE_CHARGE_FULL, 0.0, 1.0), power_cap(PLAYER)), serve_quality())
			else:
				serve_preview = Vector3.ZERO
	elif ball_live:
		# the ball moves in 1/480 s steps whatever the tick rate (240 a second,
		# 120 on the web, where the CPU is tighter)
		var sub := maxi(1, 480 / Engine.physics_ticks_per_second)
		for i in sub:
			step_ball(delta / sub)
	if point_over:
		point_timer -= delta
		if game_over:
			if in_tie_match:
				if point_timer < -1.5 and pending_var.is_empty() and var_call.is_empty():
					finish_tie_match()
			elif autoplay and point_timer < -2.0:
				new_game()
		elif point_timer <= 0.0 and pending_var.is_empty() and var_call.is_empty():
			if break_kind != "" or timeout_req != 0:
				open_break()
			else:
				start_point()
	rec.record(delta, bp, bv, bw, paddle_pos[PLAYER], paddle_pos[AI], ball_live)


# ---------------------------------------------------------------- input / visuals

## The club menu lives in the HUD's own viewport, so it gets its input passed on.
func _input(event: InputEvent) -> void:
	if club_ui == null or not club_ui.visible:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		club_ui.back()
		return
	hud_vp.push_input(event)


func _unhandled_input(event: InputEvent) -> void:
	# the analysis panel: I opens / closes it, Esc, space or a click close it
	if analysis_panel.visible:
		if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_I, KEY_ESCAPE, KEY_SPACE]) \
				or (event is InputEventMouseButton and event.pressed):
			hide_analysis()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I and not gstats.is_empty():
		show_analysis()
		return
	if not replay.is_empty():
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_B, KEY_SPACE, KEY_ESCAPE]:
			end_replay()
			return
		# restarting or leaving cuts the replay short instead of waiting it out
		var restart: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_R, KEY_M]
		var click: bool = event is InputEventMouseButton and event.pressed and game_over
		if not (restart or click):
			return
		end_replay()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		if not last_rally.is_empty() and (point_over or waiting_serve):
			start_replay("highlight", maxf(last_rally.from - 0.3, rec.earliest()), minf(last_rally.to, rec.clock), {})
		return
	# 技能乒乓球: hold Shift (or the middle button) for the skill wheel, let go
	# to cast; a click in slowed time sees through a 金蝉脱壳. While you hold a
	# serve, Shift is still the feint.
	if skill_on() and is_human(PLAYER):
		var wheel_key: bool = event is InputEventKey and event.keycode == KEY_SHIFT and not event.echo \
				and not (waiting_serve and server == PLAYER and serve_hold > 0.0)
		var wheel_btn: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE
		if wheel_key or wheel_btn:
			if event.pressed and not skill_wheel.visible:
				skill_wheel.cards = focus_cards
				skill_wheel.open(get_viewport().get_mouse_position())
				if focus_until_ms <= 0:
					Engine.time_scale = WHEEL_SCALE
			elif not event.pressed and skill_wheel.visible:
				if focus_until_ms <= 0:
					Engine.time_scale = 1.0
				_use_skill(skill_wheel.close())
			return
		if event is InputEventMouseMotion and skill_wheel.visible:
			skill_wheel.point(event.position)
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and try_reveal(event.position):
			return
	if event is InputEventMouseButton and event.pressed:
		if game_over and not in_tie_match:
			new_game()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if STROKE_KEYS.has(k):
			return   # strokes are read as held keys; serves fire on release
		# 技能乒乓球: number keys 1-4 are the loaded skills, in order
		var slot := (k - KEY_1) if k >= KEY_1 and k <= KEY_9 else (9 if k == KEY_0 else -1)
		if skill_on() and is_human(PLAYER) and slot >= 0 and slot < loadout[PLAYER].size():
			_use_skill(loadout[PLAYER][slot])
			return
		if k >= KEY_1 and k <= KEY_5:
			pixel_scale_idx = k - KEY_1
			apply_pixel_scale()
			return
		match k:
			KEY_SPACE:
				if game_over and not in_tie_match:
					new_game()
				elif waiting_serve and server == PLAYER and not autoplay:
					player_serve("none", 0, 0.5)
			KEY_T:
				use_focus()
			KEY_V when not var_call.is_empty() and is_human(var_call.by):
				if challenges[PLAYER] > 0:
					close_call(true)
				else:
					flash("没有挑战机会了")
			KEY_C, KEY_V:
				cam_mode = (cam_mode + (1 if k == KEY_C else -1) + CAM_MODES.size()) % CAM_MODES.size()
				flash("视角 %d/%d: %s" % [cam_mode + 1, CAM_MODES.size(), CAM_MODES[cam_mode]])
			KEY_TAB:   # 界面信息: simple <-> full
				settings.hud = "simple" if hud_full() else "full"
				save_settings()
				layout_hud()
				controls_bar.queue_redraw()
				flash("界面信息：%s" % ("详细" if hud_full() else "简洁"))
			KEY_P:
				post_mode = (post_mode + 1) % 3
				post_mat.set_shader_parameter("mode", post_mode)
			KEY_O:
				outline_on = not outline_on
				outline_mat.set_shader_parameter("enabled", outline_on)
			KEY_H:
				assist = not assist
			KEY_L:
				level_idx = (level_idx + 1) % LEVELS.size()
				flash("难度: %s" % lv().name)
			KEY_K:
				watch_level = (watch_level + 1) % LEVELS.size()
				flash("观战 下方 AI 难度: %s" % LEVELS[watch_level].name)
			KEY_G:
				var i := Tech.GRIP_ORDER.find(grip[PLAYER])
				grip[PLAYER] = Tech.GRIP_ORDER[(i + 1) % Tech.GRIP_ORDER.size()]
				flash("握拍: %s\n%s" % [Tech.GRIPS[grip[PLAYER]].name, Tech.GRIPS[grip[PLAYER]].desc])
			KEY_F:
				autoplay = not autoplay
			KEY_R:
				if not in_tie_match:
					new_game()
			KEY_Y:
				if in_tie_match and timeouts[PLAYER] > 0 and timeout_req == 0 and not game_over:
					timeout_req = PLAYER
					flash("已申请暂停 · 这一分结束后生效")
			KEY_M, KEY_ESCAPE:
				if not drill.is_empty():
					var back: String = menu_from if drill.kind == "tutorial" else "practice"
					drill = {}
					drill_mark.visible = false
					open_menu(back)
				elif in_tie_match:
					in_tie_match = false   # walk out: the match is replayed from the start
					open_menu("run" if run_match else ("cup" if cup_solo_match else ("boss" if boss_id != "" else "tie")))
					boss_id = ""
					cup_solo_match = false
				else:
					open_menu(menu_from)   # quick play: back where it was started (the training ground)


## What the skill wheel picked.
func _use_skill(id: String) -> void:
	match id:
		"jinchan", "andu", "huima", "bianshu", "blink", "flip":
			if focus_cards <= 0:
				flash("专注卡不够")
			else:
				skill_armed = id
				flash("%s · 下一板发动" % SKILL_SLOTS.filter(func(s): return s.id == id)[0].name)
		"wall":
			if focus_cards < 2:
				flash("专注卡不够（要 2 张）")
			elif not wall_armed[PLAYER]:
				focus_cards -= 2
				wall_armed[PLAYER] = true
				flash("铜墙铁壁 · 对方下一板发动")
		"spoon", "narrow", "giant", "gravity", "view":
			if focus_cards < 2:
				flash("专注卡不够（要 2 张）")
			else:
				focus_cards -= 2
				cast_hex(id, PLAYER)
		"":
			skill_armed = ""   # let go in the middle: nothing, and any skill held back is off


func _process(delta: float) -> void:
	elapsed += delta
	if perf_log and int(elapsed / 3.0) != int((elapsed - delta) / 3.0):
		var line := "fps %d  process %.1f ms  physics %.1f ms  in_match %s" % [Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				in_tie_match or not club_ui.visible]
		line += "  objects %d  draws %d" % [Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
		print("[perf] ", line)
		if OS.has_feature("web"):   # also to the server's log, for checking a build on another screen
			JavaScriptBridge.eval("fetch('/perf?' + encodeURIComponent(location.search + ' %s')).catch(() => {})" % line)
	if not replay.is_empty():
		update_replay(delta)
	update_camera(delta)
	update_visuals(delta)
	if sfx != null:   # a calm loop on the menus, a faster one in play
		sfx.music("" if not bool(settings.get("music", true)) else ("menu" if club_ui.visible else "match"))
	var_overlay()
	for side in [PLAYER, AI]:
		(board_digits[side] as Label3D).text = str(score[side])
		(board_serve[side] as MeshInstance3D).visible = server == side and not game_over
	# behind the club menu only the rally shows, none of the playing HUD
	var hud_a := 0.0 if club_ui.visible else 1.0
	for c in [info_label, tip_label, spin_gauge, controls_bar, score_bar, side_cards[PLAYER], side_cards[AI], banner_label]:
		(c as CanvasItem).modulate.a = hud_a
	if skill_test:   # 技能对轰: the cards never run out
		focus_cards = FOCUS_MAX
		ai_focus = FOCUS_MAX
	if nohud:
		hud_screen.visible = false
	if clean:   # footage: no key hints anywhere
		controls_bar.modulate.a = 0.0
		tip_label.modulate.a = 0.0
		pname = {PLAYER: "红方", AI: "蓝方"}
	for side in [PLAYER, AI]:
		(board_games[side] as Label3D).text = str(games[side]) if best_of > 1 else ""
	score_label.text = ""
	if not drill.is_empty() and drill.kind == "tutorial":
		score_label.text = "新手教学  第 %d / %d 课 · %s   %d / %d" % [drill.stage + 1, TUTORIAL.size(), TUTORIAL[drill.stage].title,
				drill.ok, TUTORIAL[drill.stage].need]
	elif not drill.is_empty():
		score_label.text = "%s · %s   第 %d / %d 球   得分 %d" % [DRILLS[drill.kind].name, pname[PLAYER], drill.n,
				DRILLS[drill.kind].balls, drill.score]
	elif in_tie_match and boss_id != "":
		score_label.text = "BOSS 战  %s vs %s   局分 %d : %d" % [pname[PLAYER], pname[AI], games[PLAYER], games[AI]]
	elif in_tie_match and run_match:
		score_label.text = "SHIFT RUN  %d / %d   %s" % [shift_run.stage + 1, ShiftRun.STAGES, "♥".repeat(shift_run.hearts)]
	elif in_tie_match and tie == null:
		score_label.text = "%s vs %s   局分 %d : %d" % [pname[PLAYER], pname[AI], games[PLAYER], games[AI]]
	elif in_tie_match:
		score_label.text = "%s %d : %d %s   第 %d 场   局分 %d : %d" % [tie.home.short, tie.wins[1], tie.wins[-1], tie.away.short,
				tie.index() + 1, games[PLAYER], games[AI]]
	if in_tie_match:
		if timeout_req != 0:
			score_label.text += "  [暂停]"
	if hud_full() and is_human(PLAYER) and drill.is_empty() and not game_over:
		score_label.text += "  VAR 挑战 %d" % challenges[PLAYER]
	if hud_full() and skill_on() and drill.is_empty():
		score_label.text += "  技能乒乓球"
	if autoplay:
		score_label.text += "  [教练席]" if in_tie_match else ("" if clean else "  [观战]")
	if skill_test:
		score_label.text += "  [技能对轰 · 无限专注卡]"
	if focus_until_ms > 0:
		var left := (focus_until_ms - Time.get_ticks_msec()) / 1000.0
		if left <= 0.0:
			end_focus()
		else:
			score_label.text += "  [专注 %.1fs]" % left
	if serve_demo and elapsed > 0.4:
		autoplay = false
	if serve_demo and elapsed > 0.8 and not Input.is_key_pressed(KEY_E):
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
	var shot_now := elapsed > 6.0 and not shot_on_heavy and not serve_demo
	if serve_demo:
		shot_now = elapsed > 1.9
	if shot_on_style != "":
		shot_now = false
		for sd in [PLAYER, AI]:
			if swing_style[sd] == shot_on_style and swing[sd] > 0.05:
				shot_now = true
		shot_now = shot_now or elapsed > 120.0
	if shot_on_fx != "":
		shot_now = (sfx.last.name == shot_on_fx and Time.get_ticks_msec() - int(sfx.last.t) >= shot_fx_delay) or elapsed > 150.0
	if shot_on_var:
		shot_now = (not replay.is_empty() and replay.kind == "var" and replay.t >= replay.focus_t) or elapsed > 300.0
	if shot_on_heavy:
		heavy_frames = heavy_frames + 1 if heavy_aura.visible and last_hitter == AI else 0
		shot_now = heavy_frames > 22 or elapsed > 60.0
		if shot_now:
			var bsp := cam.unproject_position(bp) / Vector2(vp.size)
			print("[heavy-shot] need=%.2f ball_uv=%.3f,%.3f" % [spin_need(bw, bv), bsp.x, bsp.y])
	if screenshot_path != "" and shot_now:
		get_viewport().get_texture().get_image().save_png(screenshot_path)
		print("[screenshot] ", screenshot_path)
		screenshot_path = ""
		get_tree().quit()
