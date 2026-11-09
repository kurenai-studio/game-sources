extends "res://scripts/game/game_match.gd"
## Layer 4: game modes around the match engine: club menu flow, team ties,
## boss matches, the coach's breaks, training drills, saved progress.


# ---------------------------------------------------------------- team mode

## Shows the club menu on `page`; behind it the two sides rally on their own.
func open_menu(page: String) -> void:
	skill_test = false
	var_call = {}
	pending_var = {}
	end_replay()
	if tut_level_backup >= 0:
		level_idx = tut_level_backup
		tut_level_backup = -1
	in_tie_match = false
	run_match = false
	game_to = 11
	drill = {}
	if drill_mark != null:
		drill_mark.visible = false
	on_break = false
	clear_players()
	autoplay = true
	best_of = 1
	new_game()
	club_ui.show_page(page)


# ---------------------------------------------------------------- drills

## Starts drill `kind` with `p` at the near end; `human` = you play it.
func start_drill(kind: String, p: Dictionary, human: bool, practice := false) -> void:
	last_drill = [kind, p, human, practice]
	club_ui.visible = false
	in_tie_match = false
	clear_players()
	prof[PLAYER] = Roster.params(Roster.effective(p))
	pname[PLAYER] = p.name
	grip[PLAYER] = p.grip
	pname[AI] = "教练"
	autoplay = not human
	best_of = 1
	new_game()
	waiting_serve = false
	ball_live = false
	drill = {"kind": kind, "player": p, "human": human, "practice": practice, "n": 0, "score": 0, "fh": 0, "bh": 0, "resolved": true, "next_t": 1.2, "target": Vector3.ZERO}
	if drill_mark == null:
		drill_mark = add_disc(world, 0.22, Vector3.ZERO, C_YELLOW)
	drill_mark.visible = false
	banner_label.text = "%s · %s" % [DRILLS[kind].name, p.name]
	print("[drill] %s %s %s" % [kind, p.name, "human" if human else "auto"])


func drill_tick(delta: float) -> void:
	if not drill.resolved:
		return
	drill.next_t -= delta
	if drill.next_t > 0.0:
		return
	if drill.n >= DRILLS[drill.kind].balls:
		finish_drill()
		return
	drill_feed()


## The tutorial: the drill engine with staged feeds and instructions.
func start_tutorial(from := "practice") -> void:
	menu_from = from
	club_ui.visible = false
	in_tie_match = false
	clear_players()
	autoplay = false
	best_of = 1
	tut_level_backup = level_idx
	level_idx = 0   # the most forgiving racket while learning
	new_game()
	waiting_serve = false
	ball_live = false
	drill = {"kind": "tutorial", "player": {}, "human": true, "n": 0, "score": 0, "fh": 0, "bh": 0, "resolved": true,
			"next_t": 2.5, "target": Vector3.ZERO, "stage": 0, "ok": 0}
	if drill_mark == null:
		drill_mark = add_disc(world, 0.22, Vector3.ZERO, C_YELLOW)
	drill_mark.visible = false
	_tutorial_banner()


func _tutorial_banner() -> void:
	var st: Dictionary = TUTORIAL[drill.stage]
	banner_label.text = "第 %d 课 · %s\n%s" % [drill.stage + 1, st.title, st.text]


## The coach sends the next ball: multiball alternates the two wide corners,
## faster every five balls; target practice feeds mixed spin to the middle;
## receive practice is a real serve with its spin shown beforehand.
func drill_feed() -> void:
	var kind: String = drill.kind
	drill.n += 1
	drill.resolved = false
	banner_label.text = ""
	missed = {PLAYER: false, AI: false}
	if kind == "tutorial":
		var st: Dictionary = TUTORIAL[drill.stage]
		_tutorial_banner()
		if st.get("skills", false) and not drill.get("skills", false):
			drill.skills = true          # the wheel opens from here on
			loadout[PLAYER] = TUTORIAL_LOADOUT.duplicate()
			skill_wheel.slots = loaded(PLAYER)
		if drill.get("skills", false):
			focus_cards = FOCUS_MAX      # never short of cards while learning
		if st.get("serve", false):
			start_point()
			server = PLAYER
			_tutorial_banner()
			return
		var w := Sim.topspin_axis(Vector3(0.0, 0.0, 1.0)) * float(st.top) + Vector3.UP * float(st.side) * (1.0 if randf() < 0.5 else -1.0)
		var start := Vector3(randf_range(-0.2, 0.2), Sim.TABLE_Y + 0.3, -1.7)
		var v := Sim.solve_shot(start, Vector3(randf_range(-0.25, 0.25), 0.0, 0.9), 6.0 if float(st.top) < 0.0 else 7.0, w)
		paddle_pos[AI] = start + Vector3(0.0, 0.0, -0.05)
		bp = start
		bv = v
		bw = w
		ball_live = true
		waiting_serve = false
		last_hitter = AI
		serve_bounce_pending = false
		bounced_receiver = false
		rally = 1
		swing[AI] = 0.0
		swing_style[AI] = "快带" if float(st.top) > 0.0 else "搓"
		prepare_receiver(PLAYER, 0)
		sfx.hit(start, "block", v.length(), spin_need(w, v), heavy)
		describe_incoming("喂球")
		return
	if kind == "receive":
		var kinds := ["top", "back", "none", "back"]
		paddle_pos[AI] = Vector3(randf_range(-0.5, 0.5), 1.0, -1.65)
		bp = paddle_pos[AI]
		serve(AI, kinds.pick_random(), randf_range(-200.0, 200.0), randf_range(0.5, 1.0), 1.0)
		return
	var start := Vector3(randf_range(-0.25, 0.25), Sim.TABLE_Y + 0.3, -1.7)
	var target := Vector3(randf_range(-0.2, 0.2), 0.0, 0.85)
	var top := randf_range(150.0, 300.0)
	var speed := 7.0
	if kind == "multi":
		var wide := 1.0 if drill.n % 2 == 1 else -1.0
		target = Vector3(wide * 0.58, 0.0, 0.95)
		speed = 7.0 + 0.8 * float((drill.n - 1) / 5)
	else:
		top = [250.0, -220.0, 120.0].pick_random()
		speed = 6.0 if top < 0.0 else 7.5
		# a fresh target on the far half: a corner, the middle, short or long
		var spots := [Vector3(-0.5, 0, -1.1), Vector3(0.5, 0, -1.1), Vector3(0.0, 0, -1.15), Vector3(-0.5, 0, -0.45),
				Vector3(0.5, 0, -0.45), Vector3(0.0, 0, -0.75)]
		drill.target = spots.pick_random()
		drill_mark.position = drill.target + Vector3(0.0, Sim.TABLE_Y + 0.004, 0.0)
		drill_mark.visible = true
	var w := Sim.topspin_axis(Vector3(0.0, 0.0, 1.0)) * top + Vector3.UP * randf_range(-60.0, 60.0)
	var v := Sim.solve_shot(start, target, speed, w)
	paddle_pos[AI] = start + Vector3(0.0, 0.0, -0.05)
	bp = start
	bv = v
	bw = w
	ball_live = true
	waiting_serve = false
	last_hitter = AI
	serve_bounce_pending = false
	bounced_receiver = false
	rally = 1
	swing[AI] = 0.0
	swing_style[AI] = "快带" if top > 0.0 else "搓"
	prepare_receiver(PLAYER, 0)
	sfx.hit(start, "block", v.length(), spin_need(w, v), heavy)
	describe_incoming("喂球")


## Your return bounced on the far half.
func drill_landed() -> void:
	if drill.kind == "tutorial":
		var st: Dictionary = TUTORIAL[drill.stage]
		if st.get("skills", false) and not drill.get("cast", false):
			drill_done_ball("先按住 Shift 选一个技能，再回球")
			return
		drill.cast = false
		drill.ok += 1
		if drill.ok >= int(st.need):
			drill.stage += 1
			drill.ok = 0
			if drill.stage >= TUTORIAL.size():
				drill = {}
				drill_mark.visible = false
				open_menu("tut_done")
				return
			drill_done_ball("过关！")
			drill.next_t = 2.5
			return
		drill_done_ball("好球！ %d / %d" % [drill.ok, st.need])
		return
	var pts := 1
	var note := "上台"
	match drill.kind:
		"multi":
			if absf(bp.z) > Sim.HALF_L - 0.4:
				pts = 2
				note = "底线!"
		"receive":
			pts = 2
			note = "接住"
		"target":
			if Vector2(bp.x - drill.target.x, bp.z - drill.target.z).length() < 0.24:
				pts = 3
				note = "命中!"
	drill.score += pts
	drill_done_ball("+%d  %s" % [pts, note])


## The ball went wrong: a feed that missed the table is fed again; anything
## else is a miss for you.
func drill_missed(feed_fault: bool) -> void:
	if drill.kind == "tutorial":
		drill_done_ball("再试一次" if not (feed_fault and last_hitter == AI) else "")
		return
	if feed_fault and last_hitter == AI:
		drill.n -= 1
		drill_done_ball("")
		return
	drill_done_ball("失误")


func drill_done_ball(msg: String) -> void:
	drill.resolved = true
	drill.next_t = 0.75 if drill.kind == "multi" else 1.2
	banner_label.text = msg


## Grade the drill.
func finish_drill() -> void:
	var d: Dictionary = DRILLS[drill.kind]
	var pct: float = float(drill.score) / float(d.balls * d.max)
	var grade := "S" if pct >= 0.85 else ("A" if pct >= 0.7 else ("B" if pct >= 0.5 else ("C" if pct >= 0.3 else "D")))
	var attr: String = d.attr if d.attr != "" else ("fh" if drill.fh >= drill.bh else "bh")
	var mult := lerpf(0.4, 2.2, pct)
	if not drill.human:
		mult = minf(mult, 1.0)   # practising alone is ordinary training; coached in person counts more
	var p: Dictionary = drill.player
	drill_result = {"kind": drill.kind, "name": p.name, "score": drill.score, "max": d.balls * d.max, "grade": grade,
			"attr": attr, "mult": mult}
	print("[drill] done %s %d/%d grade %s attr %s x%.2f" % [drill.kind, drill.score, d.balls * d.max, grade, attr, mult])
	drill_result["practice"] = drill.get("practice", false)
	drill = {}
	drill_mark.visible = false
	if drill_auto != "":
		get_tree().quit()
		return
	open_menu("drill_done")


# ---------------------------------------------------------------- settings

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		for k in settings:
			settings[k] = cf.get_value("settings", k, settings[k])
	apply_settings()


func save_settings() -> void:
	if no_save:
		return
	var cf := ConfigFile.new()
	for k in settings:
		# the --skill debug switch is for that run only, never saved
		cf.set_value("settings", k, false if k == "skill_mode" and skill_debug else settings[k])
	cf.save(SETTINGS_PATH)


func apply_settings() -> void:
	TranslationServer.set_locale(str(settings.get("lang", "en")))
	get_window().title = "SHIFT PONG"
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(float(settings.volume) / 10.0, 0.0001)))
	AudioServer.set_bus_mute(master, int(settings.volume) == 0)
	pixel_scale_idx = int(settings.pixel)
	cam_mode = int(settings.cam)
	if controls_bar != null:
		controls_bar.visible = bool(settings.legend)
	if vp != null:
		apply_pixel_scale()


func clear_players() -> void:
	prof = {PLAYER: {}, AI: {}}
	pname = {PLAYER: "你", AI: "AI"}
	orders = {PLAYER: "", AI: ""}


## Quick play: the old single game against the difficulty levels.
func quick_play(from := "practice") -> void:
	skill_test = false
	menu_from = from
	_quick_match()


## 技能对轰: quick play with endless focus for both sides, the AI casting freely.
func skill_test_play(from := "practice") -> void:
	skill_test = true
	menu_from = from
	_quick_match()


## 快速开始 from the title screen: straight into one game to 7 with skills.
func quick_start() -> void:
	skill_test = false
	menu_from = "title"
	game_to = 7
	_quick_match()


func _quick_match() -> void:
	club_ui.visible = false
	in_tie_match = false
	clear_players()
	autoplay = false
	best_of = 1
	new_game()


func begin_tie(away_id: String, line: Array, bo: int, their_line: Array = []) -> void:
	tie = Tie.new()
	tie.setup(tour.mine(), tour.club(away_id), line, bo, their_line)


## Starts the tie's next match with your player on the near side; `human` =
## you play it yourself, otherwise your player is AI-driven and you coach.
func play_tie_match(human: bool) -> void:
	boss_id = ""
	var pr: Array = tie.pair()
	start_duel(pr[0], pr[1], human, tie.best_of)
	banner_label.text = "第 %d 场  %s  vs  %s" % [tie.index() + 1, pr[0].name, pr[1].name]
	print("[tie] match %d  %s (%d) vs %s (%d)  %s  away order %s" % [tie.index() + 1, pr[0].name, Roster.overall(pr[0]),
			pr[1].name, Roster.overall(pr[1]), "human" if human else "coach", orders[AI]])


## Boss challenge: one match against a boss template.
func play_boss(id: String, mine: Dictionary, human: bool, bo: int) -> void:
	boss_id = id
	var b: Dictionary = Roster.boss(id)
	start_duel(mine, b, human, bo)
	banner_label.text = "BOSS 战  ·  %s「%s」" % [b.name, b.title]
	print("[boss] %s vs %s  %s  bo%d" % [mine.name, b.name, "human" if human else "coach", bo])


## A match between two rated players, yours on the near side; `human` = you
## play it yourself, otherwise your player is AI-driven and you coach.
func start_duel(mine: Dictionary, them: Dictionary, human: bool, bo: int) -> void:
	duel = [mine, them]
	club_ui.visible = false
	in_tie_match = true
	for i in 2:
		var side: int = PLAYER if i == 0 else AI
		prof[side] = Roster.params(Roster.effective(duel[i]))   # a tired player plays below their ratings
		pname[side] = duel[i].name
		grip[side] = duel[i].grip
	# how hard unanswered spin throws a return off is the pace of the match, the
	# same for both players (the old levels were always symmetric)
	var kick: float = (float(prof[PLAYER].kick) + float(prof[AI].kick)) * 0.5
	prof[PLAYER].kick = kick
	prof[AI].kick = kick
	autoplay = not human
	best_of = bo
	orders = {PLAYER: str(mine.get("plan", "")), AI: Tie.ai_order({"fh": 0, "bh": 0}, 0, mine)}   # your pre-match plan
	new_game()


## Between games or in a timeout: play stops and the coach panel comes up.
## Both players get their breath back; the other bench rethinks its plan.
func open_break() -> void:
	if break_kind == "":
		break_kind = "timeout"
		timeouts[timeout_req] -= 1
		for sd in [PLAYER, AI]:
			stamina[sd] = minf(stamina[sd] + 15.0, max_stamina[sd])
	else:
		for sd in [PLAYER, AI]:
			stamina[sd] = max_stamina[sd]
	orders[AI] = Tie.ai_order(weak[PLAYER], errors[AI], duel[0])
	on_break = true
	print("[break] %s  games %d:%d  away order %s" % [break_kind, games[PLAYER], games[AI], orders[AI]])
	if tie_auto or boss_auto != "":
		end_break(Tie.ai_order(weak[AI], errors[PLAYER], duel[1]))
		return
	club_ui.show_coach(break_kind, timeout_req)


func end_break(order: String) -> void:
	orders[PLAYER] = order
	club_ui.visible = false
	on_break = false
	var kind := break_kind
	break_kind = ""
	timeout_req = 0
	if kind == "game":
		start_game()
	else:
		banner_label.text = ""
		start_point()


## SHIFT RUN: your match against this stage's opponent, one game to 7.
func play_run(human := true) -> void:
	var opp: Dictionary = shift_run.opponent()
	boss_id = ""
	run_match = true
	game_to = ShiftRun.GAME_TO
	start_duel(shift_run.me, opp, human, 1)
	banner_label.text = "SHIFT RUN %d / %d  ·  %s  vs  %s" % [shift_run.stage + 1, ShiftRun.STAGES, pname[PLAYER], opp.name]


## Your match in a stand-alone singles cup.
func play_cup_solo(human: bool) -> void:
	var opp: Dictionary = cup_run.opponent()
	boss_id = ""
	start_duel(cup_run.entrants[cup_run.mine], opp, human, cup_run.bo)
	cup_solo_match = true
	banner_label.text = "个人赛 %s  ·  %s  vs  %s" % [cup_run.stage_name(), pname[PLAYER], opp.name]


## Your tie in a stand-alone team cup, with the line-up you picked.
func begin_cup_tie(line: Array, their_line: Array = []) -> void:
	tie = Tie.new()
	tie.setup(cup_run.entrants[cup_run.mine], cup_run.opponent(), line, cup_run.bo, their_line)


## The post-match report the menu shows: score, games, both players' ratings
## and the technical stats of a match played live.
func match_report(title: String, winner: int) -> Dictionary:
	var r := {"winner": 1 if winner == PLAYER else -1, "games": [games[PLAYER], games[AI]], "scores": game_scores.duplicate()}
	return {"title": title, "names": [pname[PLAYER], pname[AI]], "games": r.games, "scores": r.scores, "tech": mstats.duplicate(true),
			"ratings": [Tour.rate(r, 0, duel[0], duel[1]), Tour.rate(r, 1, duel[0], duel[1])]}


func finish_tie_match() -> void:
	in_tie_match = false
	var winner := PLAYER if games[PLAYER] > games[AI] else AI
	if run_match:
		run_match = false
		game_to = 11
		var rep_r := match_report("SHIFT RUN %d / %d" % [shift_run.stage + 1, ShiftRun.STAGES], winner)
		shift_run.resolve(winner == PLAYER, str(game_scores[-1]) if not game_scores.is_empty() else "", SKILL_SLOTS.map(func(s): return s.id))
		if shift_run.is_over():
			var best: int = shift_run.stage
			if best > int(settings.get("run_best", 0)):
				settings["run_best"] = best
				save_settings()
		print("[run] stage %d %s %s  hearts %d  loadout %s  offer %s" % [shift_run.log[-1].stage + 1, "won" if winner == PLAYER else "lost",
				shift_run.log[-1].score, shift_run.hearts, shift_run.loadout, shift_run.offer])
		if run_auto:
			if shift_run.is_over() or shift_run.log.size() >= 3:
				get_tree().quit()
				return
			if not shift_run.offer.is_empty():
				shift_run.take(shift_run.offer[0], 0)
			play_run(false)
			return
		club_ui.show_report(rep_r, "run")
		open_menu("match_report")
		return
	if cup_solo_match:
		cup_solo_match = false
		var rep_c := match_report("个人赛 " + cup_run.stage_name(), winner)
		cup_run.resolve(winner == PLAYER, games[PLAYER], games[AI])
		club_ui.show_report(rep_c, "cup")
		open_menu("match_report")
		return
	if boss_id != "":
		print("[boss] result %s  %d:%d %s" % [pname[winner], games[PLAYER], games[AI], " ".join(PackedStringArray(game_scores))])
		if boss_auto == "" and winner == PLAYER and not boss_id in settings.beaten:
			settings.beaten.append(boss_id)   # the legends you have beaten stay beaten
			save_settings()
		if boss_auto != "":
			get_tree().quit()
			return
		club_ui.boss_result = {"id": boss_id, "won": winner == PLAYER, "games": [games[PLAYER], games[AI]], "scores": game_scores.duplicate()}
		club_ui.show_report(match_report("BOSS 战", winner), "boss")
		boss_id = ""
		open_menu("match_report")
		return
	tie.record(winner, [games[PLAYER], games[AI]], game_scores.duplicate())
	print("[tie] result %s  %d:%d %s  tie %d:%d" % [pname[winner], games[PLAYER], games[AI], " ".join(PackedStringArray(game_scores)),
			tie.wins[1], tie.wins[-1]])
	if tie_auto:
		if tie.is_over():
			get_tree().quit()
		else:
			play_tie_match(false)
		return
	club_ui.show_report(match_report("第 %d 场" % tie.index(), winner), "tie")
	open_menu("match_report")
