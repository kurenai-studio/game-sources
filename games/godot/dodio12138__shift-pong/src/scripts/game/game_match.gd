extends "res://scripts/game/game_arena.gd"
## Layer 3: the rules and the match engine: points and games, serves, ball
## flight and bounces, strokes and spin, AI choices and footwork.


# ---------------------------------------------------------------- game flow

## A fresh match: games, stamina and fatigue, what the AI has learned about you.
func new_game() -> void:
	# whatever was being reviewed belongs to the old match
	var_call = {}
	pending_var = {}
	end_replay()
	mstats = {"rally_n": 0, "rally_sum": 0, "rally_max": 0}
	for sd in [PLAYER, AI]:
		mstats[sd] = {"pts": 0, "winners": 0, "errors": 0, "serve_n": 0, "serve_w": 0, "recv_n": 0, "recv_w": 0}
	games = {PLAYER: 0, AI: 0}
	game_scores = []
	timeouts = {PLAYER: 1, AI: 1}
	timeout_req = 0
	break_kind = ""
	on_break = false
	match_first_server = PLAYER if randf() < 0.5 or not in_tie_match else AI
	stamina = {PLAYER: 100.0, AI: 100.0}
	max_stamina = {PLAYER: 100.0, AI: 100.0}
	weak = {PLAYER: {"fh": 0.0, "bh": 0.0}, AI: {"fh": 0.0, "bh": 0.0}}
	if not in_tie_match:
		grip[AI] = Tech.GRIP_ORDER.pick_random()
	pick_loadouts()
	start_game()


## The four skills each side takes into this match: yours from the settings,
## the AI's drawn at random (one or two spells among them).
func pick_loadouts() -> void:
	var all: Array = SKILL_SLOTS.map(func(s): return s.id)
	var mine: Array = (shift_run.loadout if run_match else settings.get("loadout", [])).filter(func(id): return all.has(id))
	loadout[PLAYER] = mine.slice(0, LOADOUT_SIZE)
	var theirs: Array = STROKE_SKILLS.duplicate()
	theirs.shuffle()
	var spells: Array = HEX_SKILLS + ["wall"]
	spells.shuffle()
	loadout[AI] = theirs.slice(0, 2 if randf() < 0.5 else 3) + spells.slice(0, 2)
	loadout[AI] = loadout[AI].slice(0, LOADOUT_SIZE)
	if not loadout_arg.is_empty():
		loadout[PLAYER] = loadout_arg.duplicate()
		loadout[AI] = loadout_arg.duplicate()
	skill_wheel.slots = loaded(PLAYER)
	if skill_on() and is_human(PLAYER):
		flash("对方携带：%s" % "、".join(PackedStringArray(loaded(AI).map(func(s): return s.name))))


## A fresh game within the match: the score, who serves first (it alternates
## game by game), focus cards (five per game).
func start_game() -> void:
	score = {PLAYER: 0, AI: 0}
	game_over = false
	first_server = match_first_server if (games[PLAYER] + games[AI]) % 2 == 0 else -match_first_server
	press_count = {PLAYER: 0, AI: 0}
	errors = {PLAYER: 0, AI: 0}
	run = {PLAYER: 0, AI: 0}
	focus_cards = 0
	focus_granted = 0
	challenges = {PLAYER: CHALLENGES, AI: CHALLENGES}
	skill_armed = ""
	gstats = {"pos": {PLAYER: [], AI: []}, "land": {PLAYER: [], AI: []}, "shots": {PLAYER: {}, AI: {}},
			"wing": {PLAYER: {"fh": 0, "bh": 0}, AI: {"fh": 0, "bh": 0}},
			"timing": {PLAYER: {"early": 0, "peak": 0, "late": 0}, AI: {"early": 0, "peak": 0, "late": 0}},
			"speed": {PLAYER: [], AI: []}, "spin": {PLAYER: [], AI: []}, "flow": [], "skills": {PLAYER: 0, AI: 0},
			"lost": {}, "out_by": {}}
	adapt = adapt_carry if adapt_on() else 0.0
	clear_hexes()
	wall_armed = {PLAYER: false, AI: false}
	if skill_on():   # 技能乒乓球: five focus cards a game for each side
		focus_cards = FOCUS_MAX
		focus_granted = FOCUS_MAX
		ai_focus = FOCUS_MAX
	lose_streak = 0
	end_focus()
	banner_label.text = ""
	start_point()


func start_point() -> void:
	decoy = {}
	trick = {}
	if skill_on() and drill.is_empty():
		# the AI sometimes opens a point with a spell (two cards)
		for sd in [AI, PLAYER]:
			if sd == PLAYER and is_human(PLAYER) or lv_of(sd).get("gentle", false):
				continue
			var cards: int = ai_focus if sd == AI else focus_cards
			var spells: Array = loadout[sd].filter(func(id): return id in HEX_SKILLS or id == "wall")
			if not spells.is_empty() and (cards >= 2 or spells_debug) and randf() < (0.6 if spells_debug or skill_test else 0.12):
				if sd == AI:
					ai_focus -= 2
				else:
					focus_cards -= 2
				var pick: String = spells.pick_random()
				if pick == "wall":
					wall_armed[sd] = true   # quietly waits for the other side's stroke
				else:
					cast_hex(pick, sd)
	server = compute_server()
	waiting_serve = true
	ball_live = false
	point_over = false
	last_hitter = 0
	bounced_receiver = false
	serve_bounce_pending = false
	missed = {PLAYER: false, AI: false}
	hit_pred = {PLAYER: {"ok": false}, AI: {"ok": false}}
	plan = {PLAYER: {}, AI: {}}
	serve_timer = randf_range(1.0, 1.6)
	serve_hold = 0.0
	serve_held = Vector2i.ZERO
	serve_armed = false
	serve_preview = Vector3.ZERO
	serve_meter.visible = false
	serve_phase = 0.0
	serve_zone_t = randf() * TAU
	ai_serve_attack = randf() < float(lv_of(server).tactic) or (orders[server] == "serve_attack" and randf() < 0.8) \
			or (has_trait(server, "third") and randf() < 0.85)
	ai_serve_kind = "back" if ai_serve_attack else ["top", "back", "none"].pick_random()
	ai_serve_side = randf_range(-150.0, 150.0) * (1.5 if ai_serve_attack else 1.0)
	var gentle: bool = lv_of(server).get("gentle", false)
	if gentle:   # 休闲: plain, readable serves
		ai_serve_attack = false
		ai_serve_kind = ["top", "none"].pick_random()
		ai_serve_side = randf_range(-40.0, 40.0)
	# a feint: the serving motion shows one spin and the ball gets another;
	# good servers and tactical players use it more
	var fake_p := 0.06 + 0.3 * float(lv_of(server).tactic) * float(lv_of(server).get("serve_q", 0.86)) + (0.1 if has_trait(server, "third") else 0.0)
	serve_fake = {PLAYER: false, AI: false}
	serve_fake[server] = (server == AI or autoplay) and not gentle and randf() < fake_p
	ai_tell_kind = ai_serve_kind
	ai_tell_side = ai_serve_side
	if serve_fake[server]:
		ai_tell_kind = {"back": ["top", "none"].pick_random(), "top": "back", "none": "back"}[ai_serve_kind]
		ai_tell_side = -ai_serve_side
	read_true = true
	serve_x = randf_range(-0.5, 0.5)
	rally = 0
	banner_label.text = ""
	if server == PLAYER and not autoplay and (serve_hints > 0 or not drill.is_empty() or hud_full()):
		serve_hints -= 1   # the keys for a serve, only the first few times
		rich(tip_label, [{"key": "Q"}, {"key": "W"}, {"key": "E"}, Icons.spin("top"), "    ", {"key": "A"}, {"key": "S"}, {"key": "D"},
				Icons.spin("back"), "    ", Icons.hold_release(), "      ", {"key": "空格"}, Icons.spin("none")])
	else:
		tip_label.clear()


func compute_server() -> int:
	var total: int = score[PLAYER] + score[AI]
	var deuce := 2 * (game_to - 1)
	var n: int = total / 2 if total < deuce else deuce / 2 + (total - deuce)
	return first_server if n % 2 == 0 else -first_server


func award(winner: int, reason: String) -> void:
	if not drill.is_empty():
		if not drill.resolved:
			drill_missed(winner == PLAYER)
		return
	if point_over:
		return
	point_over = true
	# a close one: the umpire calls it, and the call can be challenged
	if not var_flag.is_empty() and var_flag.t >= last_hit_t - 0.001 and var_flag.type in ["擦边球", "压线争议"]:
		_open_call(winner, reason)
		return
	_score_point(winner, reason)


## The umpire's call on a close one. Sometimes wrong: an edge ball called out,
## or a ball that just missed called an edge. The side it went against gets a
## few seconds to challenge (V); the AI decides on its own.
func _open_call(winner: int, reason: String) -> void:
	var wrong := randf() < UMP_ERR
	var cw := -winner if wrong else winner
	var cr := reason
	if wrong:
		cr = "出界" if var_flag.type == "擦边球" else "擦边球"
	var_call = {"w": cw, "r": cr, "tw": winner, "tr": reason, "flag": var_flag.duplicate(), "by": -cw, "wrong": wrong,
			"wait": 3.0 if is_human(-cw) else 0.9, "review": false}
	var_flag = {}
	banner_label.text = "裁判：%s 得分 · %s" % [pname[cw], cr]
	if is_human(-cw) and challenges[PLAYER] > 0:
		banner_label.text += "\n有争议？按 V 挑战（还剩 %d 次）" % challenges[PLAYER]


## Settles the call: unchallenged it stands; challenged, the VAR replay runs
## and on_var_done scores the point as it really was.
func close_call(challenge: bool) -> void:
	var c := var_call
	if c.is_empty() or c.review:
		return
	if not challenge:
		var_call = {}
		_score_point(c.w, c.r)
		return
	c.review = true
	var f: Dictionary = c.flag
	var truth := str(pname[c.tw])
	var verdict := ""
	if c.wrong:
		verdict = "改判！%s  →  %s 得分" % ["擦边有效" if f.type == "擦边球" else "出界 · 差 %.1f cm" % (f.miss * 100.0), truth]
	else:
		verdict = "维持原判  ·  %s  →  %s 得分" % ["擦边有效" if f.type == "擦边球" else "出界 · 差 %.1f cm" % (f.miss * 100.0), truth]
	pending_var = f.duplicate()
	pending_var.verdict = verdict
	pending_var.trigger = rec.clock + 0.9
	banner_label.text = "%s 挑战！VAR 检查中…" % pname[c.by]
	mv_log("challenge")


func on_var_done() -> void:
	var c := var_call
	if c.is_empty() or not c.review:
		return
	var_call = {}
	if not c.wrong:
		challenges[c.by] = maxi(int(challenges[c.by]) - 1, 0)   # a failed challenge is used up
	_score_point(c.tw, c.tr)
	banner_label.text = ("挑战成功，改判 · " if c.wrong else "挑战失败，维持原判 · ") + banner_label.text


## Called every physics frame while a call waits: runs out the challenge window,
## and lets the AI decide when the call went against it.
func tick_call(delta: float) -> void:
	if var_call.is_empty() or var_call.review:
		return
	var_call.wait -= delta
	if var_call.wait > 0.0:
		return
	var by: int = var_call.by
	if is_human(by) or challenges[by] <= 0:
		close_call(false)
		return
	# the AI usually sees a bad call; now and then it chances one anyway
	close_call(randf() < (0.75 if var_call.wrong else 0.1))


func _score_point(winner: int, reason: String) -> void:
	point_timer = 1.8
	score[winner] += 1
	_tick_hexes()
	lower_wall()
	if not gstats.is_empty():
		gstats.flow.append(score[PLAYER] - score[AI])
		if winner == AI and is_human(PLAYER):
			var cat := "net"
			if rally <= 1:
				cat = "serve" if server == PLAYER else "ace"
			elif reason in ["没接到", "二次弹跳"]:
				cat = "reach"
			elif reason == "出界":
				cat = "out"
				var k := str(last_stroke[PLAYER]).trim_prefix("正手").trim_prefix("反手")
				gstats.out_by[k] = int(gstats.out_by.get(k, 0)) + 1
			gstats.lost[cat] = int(gstats.lost.get(cat, 0)) + 1
	if adapt_on():
		# eases off once you're 3+ behind, tightens up a little once you're 5+ ahead
		var gap: int = score[AI] - score[PLAYER]
		var want := (gap - 2) / 6.0 if gap > 2 else ((gap + 4) / 10.0 if gap < -4 else 0.0)
		adapt = clampf(want + adapt_carry, -0.4, 1.0)
	lose_streak = lose_streak + 1 if winner == AI else 0
	# remember which wing the loser dropped the point on (couldn't reach it / hit it out)
	var loser := -winner
	var lost_wing: String = wing_for(loser, bp.x) if reason in ["没接到", "二次弹跳"] else wing[loser]
	weak[loser][lost_wing] += 1.0
	var earned := false
	if lose_streak >= 2 and focus_granted < FOCUS_MAX and not autoplay:
		lose_streak = 0
		focus_granted += 1
		focus_cards += 1
		earned = true
	var who := str(pname[winner])
	if reason in ["出界", "球落在本方台面", "发球须先落本方台面"]:
		errors[loser] += 1
	# technical stats: points won outright vs gifted, on serve and on return
	var ms: Dictionary = mstats
	ms[winner].pts += 1
	if reason in ["没接到", "二次弹跳"]:
		ms[winner].winners += 1
	else:
		ms[loser].errors += 1
	ms[server].serve_n += 1
	ms[-server].recv_n += 1
	if winner == server:
		ms[server].serve_w += 1
	else:
		ms[-server].recv_w += 1
	ms.rally_n += 1
	ms.rally_sum += rally
	ms.rally_max = maxi(ms.rally_max, rally)
	run[winner] += 1
	run[loser] = 0
	banner_label.text = "%s 得分 · %s" % [who, reason]
	if earned:
		banner_label.text += "\n连丢两分 → 获得专注卡  (按 T 放慢时间)"
	mv_log("point %s rally=%d %d:%d %s" % [reason, rally, score[PLAYER], score[AI], "var" if not var_flag.is_empty() else ""])
	print("[point] %s  %s  rally=%d  score %d:%d  stamina %d(max %d)/%d(max %d)" % [who, reason, rally, score[PLAYER], score[AI],
			stamina[PLAYER], max_stamina[PLAYER], stamina[AI], max_stamina[AI]])
	var a: int = score[PLAYER]
	var b: int = score[AI]
	if (a >= game_to or b >= game_to) and absi(a - b) >= 2:
		if adapt_on():
			adapt_carry = clampf((b - a - 4) / 14.0, -0.2, 0.4)   # a heavy defeat eases the next game from the start
		var match_won: bool = best_of <= 1 or games[winner] + 1 > best_of / 2
		if match_won and is_human(PLAYER) and drill.is_empty():
			sfx.fx("win" if winner == PLAYER else "lose", -3.0)
		if best_of <= 1:
			game_over = true
			games[winner] += 1          # a one-game match (a tie's single) still has a winner on the books
			game_scores.append("%d:%d" % [a, b])
			banner_label.text = ("你赢了!" if a > b else "AI 赢了") + "  %d : %d\n点击或按 R 再来一局" % [a, b]
			if clean:
				banner_label.text = "%s 赢下这局  %d : %d" % [pname[PLAYER if a > b else AI], a, b]
			gstats["done"] = true
			if is_human(PLAYER) and drill.is_empty():
				show_analysis()
		else:
			games[winner] += 1
			game_scores.append("%d:%d" % [a, b])
			gstats["done"] = true
			if is_human(PLAYER) and not in_tie_match:
				show_analysis()   # how that game went
			print("[game] %s wins %d:%d  games %d:%d" % [who, a, b, games[PLAYER], games[AI]])
			if games[winner] > best_of / 2:
				game_over = true
				banner_label.text = "%s 获胜!  局分 %d : %d" % [who, games[PLAYER], games[AI]]
			else:
				break_kind = "game"
				banner_label.text = "%s 拿下第 %d 局  %d : %d" % [who, games[PLAYER] + games[AI], a, b]
	elif in_tie_match and timeout_req == 0 and timeouts[AI] > 0 and run[PLAYER] >= 3 \
			and score[PLAYER] - score[AI] >= 3 and score[PLAYER] >= 5:
		timeout_req = AI   # the other bench stops your run
		banner_label.text += "\n对方叫暂停"
	if skill_on() and not game_over and (a + b) % RULE_SHIFT_EVERY == 0:
		rule_shift()
	last_rally = {"from": rally_start_t, "to": rec.clock + 0.8}
	if rally >= 10 and not game_over:
		banner_label.text += "\n好球!" if clean else "\n好球!  按 B 回放"
	var_flag = {}


func step_ball(dt: float) -> void:
	_step_decoy(dt)
	# the raised net comes down once the ball it was waiting for is past (or stopped by it)
	if wall_from != 0 and (signf(bp.z) == -float(wall_from) or bv.z * float(wall_from) > 0.0):
		lower_wall()
	var vy_before := bv.y
	_shift_gravity(last_hitter)
	var r := Sim.advance(bp, bv, bw, _trick_dt(dt))
	bp = r.p
	bv = r.v
	bw = r.w
	_trick_after_step(dt)
	if r.bounce:
		spawn_burst(bp, bv, bw)
		sfx.table(bp, bv.length())
		rec.event("table", bp, bv.length())
	if r.net:
		sfx.net(bp)
		rec.event("net", bp, 0.0)
		if not point_over:
			var_flag = {"type": "擦网", "t": rec.clock, "pos": bp}
	if vy_before < -0.15 and bv.y > 0.0 and bp.y < 0.05:
		sfx.floor_bounce(bp, -vy_before)
		rec.event("floor", bp, -vy_before)
	# a ball that just misses the table: how close was it?
	if not point_over and bv.y < 0.0 and bp.y < Sim.TABLE_Y + Sim.RADIUS and bp.y - bv.y * dt >= Sim.TABLE_Y + Sim.RADIUS \
			and not Sim.on_table(bp):
		# measured from the edge as it is now (缩地成寸 may have pulled it in)
		var edge: float = Sim.HALF_W - (Sim.cut_near if bp.z > 0.0 else Sim.cut_far)
		var miss := maxf(absf(bp.x) - edge, absf(bp.z) - Sim.HALF_L)
		if miss < NEAR_MISS:
			var_flag = {"type": "压线争议", "t": rec.clock, "pos": Vector3(bp.x, Sim.TABLE_Y, bp.z), "miss": miss}
	if point_over:
		return
	if r.bounce:
		on_table_bounce(PLAYER if bp.z > 0.0 else AI)
		if point_over:
			return
	try_hit(-last_hitter)
	var gone := (bp.y < Sim.TABLE_Y - 0.3 and not Sim.on_table(bp)) or absf(bp.z) > 4.5 or absf(bp.x) > 3.5
	if gone:
		if bounced_receiver:
			award(last_hitter, "没接到")
		else:
			award(-last_hitter, "出界")


## How you read the AI's serve: your receive against its serve. Fooled by a
## feint, you see the spin its motion showed; otherwise the real spin, blurred,
## and side spin lost when you read poorly. You see the truth once it bounces
## on your side (unless you read really badly).
func _read_serve(w: Vector3) -> void:
	read_clarity = clampf(float(lv_of(PLAYER).ai_read) * 1.2 - (float(lv_of(AI).get("serve_q", 0.86)) - 0.86) * 2.0 - 0.25, 0.15, 0.95)
	read_true = false
	if serve_fake[AI] and randf() > read_clarity * 0.7:
		read_w = serve_spin(AI, ai_tell_kind, ai_tell_side, 0.8)
	else:
		read_w = w * randf_range(1.0 - 0.5 * (1.0 - read_clarity), 1.0 + 0.5 * (1.0 - read_clarity))
		if read_clarity < 0.5:
			read_w.y = 0.0


## The decoy flies like a ball but lands dead: no bounce, it lies flat, fades.
func _step_decoy(dt: float) -> void:
	if decoy.is_empty():
		return
	if decoy.landed:
		decoy.dead_t += dt
		if decoy.dead_t > 0.7:
			decoy = {}
		return
	var r := Sim.advance(decoy.p, decoy.v, decoy.w, dt)
	decoy.p = r.p
	decoy.v = r.v
	decoy.w = r.w
	if r.bounce or r.net or decoy.p.y < Sim.TABLE_Y - 0.3:
		decoy.landed = true
		decoy.revealed = true
		decoy.p.y = maxf(decoy.p.y, Sim.TABLE_Y + 0.008) if Sim.on_table(decoy.p) else decoy.p.y
		sfx.net(decoy.p)   # a dull thud instead of a bounce
		_rethink(decoy.recv)


## 金蝉脱壳: alongside the real ball, a decoy with the same pace and spin flies
## to the other side of the table. An AI receiver may follow the decoy.
func _launch_decoy(side: int, target: Vector3, v: Vector3, w: Vector3) -> void:
	sfx.fx("cast")
	var tx: float = -target.x if absf(target.x) > 0.25 else (0.5 if target.x <= 0.0 else -0.5)
	var dt := Vector3(clampf(tx, -0.65, 0.65), 0.0, target.z)
	var dv := Sim.solve_shot(bp, dt, Vector2(v.x, v.z).length(), w)
	var recv := -side
	decoy = {"p": bp, "v": dv, "w": w, "recv": recv, "pred": Sim.predict_path(bp, dv, w, recv, 0), "landed": false,
			"dead_t": 0.0, "revealed": false, "fooled": false}
	flash("金蝉脱壳！")
	if not is_human(recv) and decoy.pred.ok and randf() > 0.35 + 0.4 * float(lv_of(recv).ai_read):
		decoy.fooled = true   # it goes for the decoy
		hit_pred[recv] = decoy.pred
		plan[recv] = plan_return(recv, decoy.pred.pts)
	if autoplay:
		mv_log("skill")
		print("[skill] 金蝉脱壳 by %s, decoy to x=%.2f, receiver fooled=%s" % ["P" if side == PLAYER else "AI", dt.x, decoy.fooled])


## 暗渡陈仓 / 回马枪 / 鬼步变速 on the ball just hit. An AI receiver may be
## taken in: it sets off the wrong way (hook) or late (stealth, change of pace)
## and only sorts itself out when the ball bounces.
## 铜墙铁壁: the other side armed it, so the net shoots up as `side` strikes.
func _check_wall(side: int) -> void:
	if wall_armed[-side]:
		wall_armed[-side] = false
		raise_wall(side)
		if not gstats.is_empty():
			gstats.skills[-side] += 1
		if autoplay:
			mv_log("skill")
		print("[skill] wall by %s" % ("P" if -side == PLAYER else "AI"))


## 重力转移: the ball in flight feels the gravity of the side that hit it.
func _shift_gravity(hitter: int) -> void:
	Sim.g_k = GRAVITY_SHIFT if hitter != 0 and hexes.gravity[hitter] > 0 else 1.0


func _launch_trick(kind: String, side: int, target: Vector3) -> void:
	var recv := -side
	var land := Sim.landing(bp, bv, bw)
	var dir := (-signf(target.x) if absf(target.x) > 0.15 else (1.0 if randf() < 0.5 else -1.0))
	trick = {"kind": kind, "recv": recv, "z0": bp.z, "zl": float(land.pos.z), "xl": float(land.pos.x), "t": 0.0,
			"T": maxf(float(land.t), 0.2), "dir": dir, "off": 0.0, "hidden": false, "fooled": false, "done": false}
	flash({"andu": "暗渡陈仓！", "huima": "回马枪！", "bianshu": "鬼步变速！", "blink": "乾坤挪移！", "flip": "斗转星移！"}[kind])
	if kind != "blink" and kind != "flip":
		sfx.fx("cast")   # those two sound when they happen, not when they're hit
	if not is_human(recv) and randf() > 0.35 + 0.4 * float(lv_of(recv).ai_read):
		trick.fooled = true
		match kind:
			"huima":
				if not plan[recv].is_empty():
					plan[recv].pos += Vector3(dir * HOOK_SWING * 0.8, 0.0, 0.0)   # follows the swing out
			_:
				react_timer[recv] += 0.3   # loses it for a moment
				aim_err[recv] *= 2.5
	if autoplay:
		mv_log("skill")
		print("[skill] %s by %s, receiver fooled=%s" % [kind, "P" if side == PLAYER else "AI", trick.fooled])


## 鬼步变速: the ball's own clock runs slow over the first part of the flight
## and fast after it; same path, different timing.
func _trick_dt(dt: float) -> float:
	if trick.get("kind", "") != "bianshu" or bounced_receiver:
		return dt
	var s := clampf(absf(bp.z - trick.z0) / maxf(absf(trick.zl - trick.z0), 0.1), 0.0, 1.0)
	return dt * (0.35 if s < 0.45 else 1.9)


## After each step: 回马枪 pushes the ball out and back along a half sine
## (zero at the hit and at the landing, so it still lands where it was aimed);
## 暗渡陈仓 hides the ball once it has crossed the net; 乾坤挪移 jumps it
## sideways onto another line halfway there (still landing on the table).
func _trick_after_step(dt: float) -> void:
	if trick.is_empty() or bounced_receiver:
		return
	match trick.kind:
		"huima":
			trick.t += dt
			var off: float = HOOK_SWING * trick.dir * sin(PI * clampf(trick.t / trick.T, 0.0, 1.0))
			bp.x += off - float(trick.off)
			trick.off = off
		"andu":
			if not trick.hidden and signf(bp.z) == float(trick.recv):
				trick.hidden = true
		"blink":
			var s := absf(bp.z - trick.z0) / maxf(absf(trick.zl - trick.z0), 0.1)
			if not trick.done and s >= 0.5:
				trick.done = true
				var edge := Sim.HALF_W - 0.12
				var d: float = BLINK_SHIFT * trick.dir
				if absf(trick.xl + d) > edge:
					d = -d if absf(trick.xl - d) <= edge else signf(d) * maxf(edge - absf(trick.xl), 0.0)
				fx_blink(bp, bp + Vector3(d, 0.0, 0.0))
				sfx.fx("blink")
				bp.x += d
				var recv: int = trick.recv
				if not is_human(recv) and not trick.fooled:
					_repredict(recv, 0.1)   # sharp eyes: straight after it

## turns to the real ball from where it is.
func _rethink(side: int) -> void:
	if decoy.is_empty() or not decoy.fooled or is_human(side) or not ball_live or last_hitter != -side:
		return
	decoy.fooled = false
	var pred := Sim.predict_path(bp, bv, bw, side, 0, bounced_receiver)
	if pred.ok:
		hit_pred[side] = pred
		plan[side] = plan_return(side, pred.pts)
		react_timer[side] = 0.15


## A spell cast by `caster` for this point and the next: 偷梁换柱, 重力转移 and
## 视角转移 fall on the other side; 巨灵神拍 is on the caster's racket and
## 缩地成寸 on the caster's own half (where the other side's balls must land).
func cast_hex(kind: String, caster: int, quiet := false) -> void:
	var on: int = -caster if kind in ["spoon", "gravity", "view"] else caster
	var fresh: bool = hexes[kind][on] <= 0
	hexes[kind][on] = HEX_POINTS
	match kind:
		"spoon":
			if fresh:
				fx_spoon(on, true)
		"giant":
			if fresh:
				fx_giant(on, true)
		"gravity":
			fx_gravity(on)
		"view":
			if on == PLAYER and is_human(PLAYER):
				var others := range(CAM_MODES.size()).filter(func(m): return m != cam_mode and m != 1)
				view_cam = others.pick_random()
			fx_view(on)
		_:
			_apply_table_cut()
			fx_narrow(on)
	if quiet:
		return
	sfx.fx(kind if kind in ["gravity", "view"] else "cast")
	flash({"spoon": "偷梁换柱！", "narrow": "缩地成寸！", "giant": "巨灵神拍！", "gravity": "重力转移！", "view": "视角转移！"}[kind])
	if not gstats.is_empty():
		gstats.skills[caster] += 1
	if autoplay:
		mv_log("skill")
		print("[skill] %s by %s" % [kind, "P" if caster == PLAYER else "AI"])


## 规则转移: one spell on both sides at once for the next two points, with a
## big SHIFT! over the table.
func rule_shift() -> void:
	var kind: String = RULE_SHIFTS.keys().pick_random()
	for side in [PLAYER, AI]:
		cast_hex(kind, side, true)
	cam_shake = maxf(cam_shake, 0.5)
	fx_shift()
	sfx.fx("shift", -2.0)
	banner_label.text += "\n规则转移：%s（两分）" % RULE_SHIFTS[kind]
	print("[shift] rule %s" % kind)


func _apply_table_cut() -> void:
	Sim.cut_near = NARROW_CUT if hexes.narrow[PLAYER] > 0 else 0.0
	Sim.cut_far = NARROW_CUT if hexes.narrow[AI] > 0 else 0.0


## A point played: the spells run down; a spoon turns back into a racket.
func _tick_hexes() -> void:
	for side in [PLAYER, AI]:
		if hexes.spoon[side] > 0:
			hexes.spoon[side] -= 1
			if hexes.spoon[side] == 0:
				fx_spoon(side, false)
		if hexes.narrow[side] > 0:
			hexes.narrow[side] -= 1
		if hexes.giant[side] > 0:
			hexes.giant[side] -= 1
			if hexes.giant[side] == 0:
				fx_giant(side, false)
		for k in ["gravity", "view"]:
			hexes[k][side] = maxi(hexes[k][side] - 1, 0)
	_apply_table_cut()


## Clears all spells (a new game or match).
func clear_hexes() -> void:
	for side in [PLAYER, AI]:
		if hexes.spoon[side] > 0:
			fx_spoon(side, false)
		if hexes.giant[side] > 0:
			fx_giant(side, false)
	hexes = {"spoon": {PLAYER: 0, AI: 0}, "narrow": {PLAYER: 0, AI: 0}, "giant": {PLAYER: 0, AI: 0},
			"gravity": {PLAYER: 0, AI: 0}, "view": {PLAYER: 0, AI: 0}}
	_apply_table_cut()


## Where the ball goes now, worked out again by `side` (an AI receiver) after
## a trick changed it, ready to hit `react` seconds later.
func _repredict(side: int, react: float) -> void:
	var pred := Sim.predict_path(bp, bv, bw, side, 0, bounced_receiver)
	hit_pred[side] = pred
	if pred.ok and not is_human(side):
		plan[side] = plan_return(side, pred.pts)
		react_timer[side] = react


func on_table_bounce(side: int) -> void:
	if not trick.is_empty() and side == trick.recv:
		trick.hidden = false   # it shows itself on the bounce
		if trick.kind == "flip":
			bw = -bw            # 斗转星移: the spin turns round off the table
			fx_flip(bp)
			sfx.fx("flip")
			hit_pred[side] = Sim.predict_path(bp, bv, bw, side, 0, true)
			if not is_human(side) and not trick.fooled:
				_repredict(side, 0.12)
		if trick.fooled and not is_human(side):
			trick.fooled = false
			_repredict(side, 0.12)
		trick = {}
	if not decoy.is_empty() and not decoy.revealed and side == decoy.recv:
		decoy.revealed = true   # the real one bounced: now everyone knows
		_rethink(side)
	if not read_true and side == PLAYER and last_hitter == AI and read_clarity >= 0.35:
		read_true = true   # you see how it kicks
		describe_incoming("发球（看清了）")
	if not drill.is_empty():
		if drill.resolved:
			return
		if side == AI and last_hitter == PLAYER:
			drill_landed()
			return
	if serve_bounce_pending:
		if side == last_hitter:
			serve_bounce_pending = false
		else:
			award(-last_hitter, "发球须先落本方台面")
		return
	if not bounced_receiver:
		if side == -last_hitter:
			bounced_receiver = true
			if not gstats.is_empty():
				gstats.land[last_hitter].append(Vector2(bp.x, bp.z))
			if absf(bp.x) > Sim.HALF_W - EDGE_BALL or absf(bp.z) > Sim.HALF_L - EDGE_BALL:
				var_flag = {"type": "擦边球", "t": rec.clock, "pos": bp}
		else:
			award(-last_hitter, "球落在本方台面")
	else:
		award(last_hitter, "二次弹跳")


func try_hit(side: int) -> void:
	if not bounced_receiver or missed[side] or (side == AI and not drill.is_empty()):
		return   # in a drill the feeder never plays the ball back
	var pp: Vector3 = paddle_pos[side]
	var reached := bp.z >= pp.z - 0.02 if side == PLAYER else bp.z <= pp.z + 0.02
	if not reached:
		return
	var off := Vector2(bp.x - pp.x, bp.y - pp.y)
	wing[side] = wing_for(side, bp.x)
	var reach: float = player_reach() if is_human(side) else float(lv_of(side).ai_reach)
	if hexes.spoon[side] > 0:
		reach *= SPOON_REACH   # 偷梁换柱: hitting with a spoon
	if hexes.giant[side] > 0:
		reach *= GIANT_REACH   # 巨灵神拍: a giant racket
	if wing[side] == "bh":
		reach *= Tech.GRIPS[grip[side]].bh_reach
	if off.length() > reach:
		missed[side] = true
		return
	do_hit(side, off)


## Spending stamina also wears the ceiling down a little for the rest of the game.
func spend(side: int, amount: float) -> void:
	amount *= float(lv_of(side).get("tire", 1.0))   # fitter players tire less
	stamina[side] = clampf(stamina[side] - amount, 0.0, 100.0)
	max_stamina[side] = maxf(max_stamina[side] - amount * FATIGUE, MIN_MAX_STAMINA)
	stamina[side] = minf(stamina[side], max_stamina[side])


# ---------------------------------------------------------------- shots

func do_hit(side: int, off: Vector2) -> void:
	var t0 := Time.get_ticks_usec()
	read_true = true
	# a receiver fooled by a feinted serve reads its spin badly
	var fooled: bool = rally == 1 and serve_fake[-side] and not is_human(side)
	var out_dir := Vector3(0.0, 0.0, -side)
	var d_in := Vector3(bv.x, 0.0, bv.z).normalized()
	var a_in := Sim.topspin_axis(d_in)
	var s_in := bw.dot(a_in)          # incoming topspin (+) / backspin (-) seen by this racket
	var side_in := bw.y

	var shot: int
	var tx: float
	var aggressive := false
	tactic_name = ""
	if is_human(side):
		shot = player_shot_choice()
		tx = clampf(bp.x * 0.3 + off.x / player_reach() * 0.8, -0.65, 0.65)   # hit it off-centre to angle it
	elif human_sim and side == PLAYER:
		# debug: a casual player's keys and contact: loops most balls, pushes
		# some, blocks the rest; meets the ball anywhere on the racket
		var r := randf()
		shot = Shot.LOOP if r < 0.55 else (Shot.PUSH if r < 0.8 else Shot.BLOCK)
		if shot == Shot.LOOP and bp.y > Sim.TABLE_Y + 0.45:
			shot = Shot.SMASH
		tx = clampf(bp.x * 0.3 + randf_range(-1.0, 1.0) * 0.8, -0.65, 0.65)
	else:
		shot = plan[side].get("shot", ai_shot_choice(s_in))
		# playing style and the coach's instruction lean the choice
		var bias: float = float(lv_of(side).get("loop", 0.0)) + (0.3 if orders[side] == "attack" else 0.0) \
				- (0.15 if orders[side] == "steady" else 0.0)
		if bias > 0.0 and (shot == Shot.BLOCK or shot == Shot.PUSH) and s_in > -250.0 and randf() < bias:
			shot = Shot.LOOP
		elif bias < 0.0 and shot == Shot.LOOP and randf() < -bias:
			shot = Shot.BLOCK
		if bp.y > Sim.TABLE_Y + 0.5 and shot != Shot.PUSH:
			shot = Shot.SMASH
		if shot == Shot.SMASH and lv_of(side).get("gentle", false):
			shot = Shot.LOOP   # 休闲: never puts one away
		tx = randf_range(-0.68, 0.68)
		# tactics (how often depends on level): attack the third ball after a short
		# backspin serve, and pounce when the opponent was rushed, is tired or sent a soft ball
		var opp := -side
		var t: float = lv_of(side).tactic
		var soft := bv.length() < 5.0 and absf(s_in) < 150.0
		if serve_attack[side] and rally == 2 and shot != Shot.SMASH and randf() < t:
			shot = Shot.LOOP
			aggressive = true
			tactic_name = "发球抢攻"
		elif (passive_at_hit[opp] or stamina[opp] < 40.0 or soft) and shot != Shot.SMASH \
				and (shot == Shot.BLOCK or shot == Shot.PUSH) and randf() < t:
			shot = Shot.LOOP
			aggressive = true
			tactic_name = "抓机会"
		serve_attack[side] = false

	var timing := "peak"
	if bv.y > 0.4:
		timing = "early"
	elif bv.y < -0.4:
		timing = "late"
	var my_wing: String = wing[side]
	var flick := false
	if has_trait(side, "twist") and my_wing == "bh" and absf(bp.z) < Sim.HALF_L and shot != Shot.SMASH and randf() < 0.85:
		shot = Shot.LOOP
		flick = true
		timing = "peak" if timing == "late" else timing
		tactic_name = "霸王拧"
	# traditional penholders rarely loop off the backhand: they push-block instead
	if not is_human(side) and grip[side] == "pen" and my_wing == "bh" and shot == Shot.LOOP and randf() < 0.65:
		shot = Shot.BLOCK

	var windup: float = hold_power() if is_human(side) else settle[side]
	if aggressive:
		windup = maxf(windup, 0.95)              # going for it: full swing
	windup = minf(windup, power_cap(side))     # tired = can't swing as hard
	var st := Tech.stroke({
		"shot": shot, "grip": grip[side], "wing": my_wing, "timing": timing,
		"s_in": s_in, "in_speed": bv.length(), "over_table": absf(bp.z) < Sim.HALF_L, "far": absf(bp.z) > 1.9,
		"low": bp.y < Sim.TABLE_Y + 0.08, "settle": settle[side], "windup": windup,
		# a flat drive needs the ball above the net with a little room; lower balls get looped
		"drive_ok": bp.y > Sim.TABLE_Y + Sim.NET_H + 0.04 and absf(bp.z) < 2.6, "flick": flick})
	var speed: float = st.speed
	var top: float = st.top
	var depth: float = st.depth
	var k_top: float = st.k_top
	var k_back: float = st.k_back

	# timing: on the rise (close to the table) is faster but more at the mercy of
	# the incoming spin; late and low (backed off) needs more arc and more spin
	if timing == "early":
		speed *= 1.12
		if not has_trait(side, "early"):   # a rising-ball specialist isn't thrown by the spin
			k_top *= 1.3
			k_back *= 1.3
	elif timing == "late" and shot == Shot.LOOP:
		top += 120.0
		speed *= 0.95
	if absf(bp.z) > 1.9 and shot != Shot.PUSH:
		speed *= 1.0 + (absf(bp.z) - 1.9) * 0.25   # more swing from further back

	# right-hander's flick and sidespin from brushing across the ball
	var side_spin: float = st.side * (1.0 if my_wing == "bh" else -1.0) * hand(side) + randf_range(-80.0, 80.0)
	if is_human(side):
		var pv: Vector3 = paddle_vel[PLAYER]
		side_spin = st.side * (1.0 if my_wing == "bh" else -1.0) * hand(side) + clampf(-pv.x * 80.0, -250.0, 250.0) \
				+ held_stroke().y * SIDE_KEY_SPIN
	var stroke_name: String = st.name
	passive_at_hit[side] = settle[side] < 0.4
	var notes: String = " · ".join(PackedStringArray(st.notes))

	# difficulty: faster, spinnier table tennis at higher levels
	speed *= lv_of(side).speed * float(lv_of(side).get("pow_" + my_wing, 1.0)) * lerpf(0.9, 1.0, stamina[side] / 100.0)
	var steady: bool = orders[side] == "steady" and not is_human(side)
	if steady:
		speed *= 0.93
	top *= lv_of(side).spin
	side_spin *= lv_of(side).spin

	# boss signatures
	var sig_prec := 1.0
	var cloud := has_trait(side, "cloud") and my_wing == "fh" and shot == Shot.LOOP and absf(bp.z) > 1.8
	if cloud:
		# 云手: a long forehand arm from off the table, hooking with heavy sidespin
		side_spin += -260.0 * hand(side)
		speed *= 1.08
		top *= 1.1
		tactic_name = "云手"
	if has_trait(side, "fighter") and (score[-side] - score[side] >= 2 or score[-side] >= 10):
		speed *= 1.08
		sig_prec = 0.85
		tactic_name = "藏獒" if tactic_name == "" else tactic_name + "·藏獒"
	if has_trait(side, "heavy") and shot != Shot.BLOCK:
		top *= 1.18
		speed *= 1.05
	if has_trait(side, "grind") and rally >= 6:
		speed *= 1.04
		sig_prec *= 0.85
		tactic_name = "相持" if tactic_name == "" else tactic_name + "·相持"
	# weak spots (短板)
	if has_trait(side, "weak_bh") and my_wing == "bh":
		sig_prec *= 1.3
	if has_trait(side, "poor_recv") and rally == 1:
		sig_prec *= 1.35        # the return of serve
		speed *= 0.95
	if has_trait(side, "soft") and (shot == Shot.BLOCK or shot == Shot.PUSH):
		speed *= 0.88
	if has_trait(side, "hothead") and score[-side] - score[side] >= 3:
		speed *= 1.05
		sig_prec *= 1.2
		tactic_name = "急躁" if tactic_name == "" else tactic_name + "·急躁"
	if has_trait(side, "fragile") and run[-side] >= 3:
		sig_prec *= 1.25
	if has_trait(side, "slow_start") and score[side] + score[-side] < 4:
		sig_prec *= 1.2
	# equipment: the blade's pace and feel, the rubber on this wing
	var gr := gear(side)
	var rb: Dictionary = gr[my_wing]
	var bl: Dictionary = gr.blade
	speed *= float(bl.speed) * float(rb.speed)
	top *= float(rb.spin)
	side_spin *= float(rb.spin)
	k_top *= float(rb.kick)
	k_back *= float(rb.kick)
	if rb.has("reverse"):
		top += -s_in * float(rb.reverse)   # long pips send the incoming spin back the other way round
	var gear_ctrl: float = float(bl.ctrl) * float(rb.ctrl)
	if drill.get("kind", "") == "target" and side == PLAYER:
		drill[my_wing] += 1
	var w := Sim.topspin_axis(out_dir) * top + Vector3.UP * side_spin
	depth += randf_range(-0.12, 0.05) if is_human(side) else randf_range(-0.1, 0.15)
	if not is_human(side):
		var tac := ai_target(side, shot)
		if not tac.is_empty():
			tx = tac.tx
			depth = tac.get("depth", depth)
			tactic_name = tac.name if tactic_name == "" else tactic_name + "·" + tac.name
	if not is_human(side) and lv_of(side).get("gentle", false):
		# 休闲: back to where you are, give or take
		tx = clampf((paddle_pos[-side] as Vector3).x * 0.6 + randf_range(-0.2, 0.2), -0.45, 0.45)
	if cloud:
		tx = (0.66 if tx >= 0.0 else -0.66) if randf() < 0.65 else tx   # huge angles
	if hexes.giant[side] > 0:
		# 巨灵神拍: more pace and the angles open right up
		speed *= GIANT_POWER
		tx = clampf((tx if absf(tx) > 0.1 else signf(randf() - 0.5) * 0.3) * GIANT_ANGLE, -0.72, 0.72)
	if drill.get("kind", "") == "target" and not is_human(side):
		tx = drill.target.x              # a player practising on their own aims for the target
		depth = absf(drill.target.z)
	var target := Vector3(tx, 0.0, -side * depth)
	# how unsteady the stroke is: faster strokes are less precise
	var wobble := (0.05 + 0.03 * speed) * float(st.wobble) * float(lv_of(side).get("prec_" + my_wing, lv_of(side).precision)) \
			* pressure(side) * sig_prec / gear_ctrl * (0.8 if steady else 1.0) * (1.1 if orders[side] == "attack" and not is_human(side) else 1.0)
	var flat: bool = st.net_margin >= 0.0
	if flat:
		# a flat drive or smash misses its spot rather than the table: the error
		# moves where it is aimed (wider, shorter, longer), not its launch
		target.x = clampf(target.x + randf_range(-1.0, 1.0) * wobble * 0.22, -0.74, 0.74)
		target.z += -side * randf_range(-1.0, 1.0) * wobble * 0.25
	# drives and smashes skim the net; everything else arcs as the speed allows
	var v := Sim.solve_drive(bp, target, speed * float(st.boost), w, float(st.net_margin)) if st.net_margin >= 0.0 \
			else Sim.solve_shot(bp, target, speed, w)

	# Cancelling the incoming spin. Spin you don't cancel kicks the ball off the
	# racket (topspin throws it up, backspin drags it into the net, side spin throws
	# it sideways). How hard you hit — how long the key was held — has to match how
	# much the ball spins: too soft and the spin wins, too hard and it flies off the
	# other way. Side spin has to be met with the opposite side spin; adding the
	# same side spin makes it worse. A plain block soaks up a little and never
	# over-hits.
	var need := spin_need(bw, bv)
	var given: float
	var side_dir: int
	if is_human(side):
		given = windup if shot != Shot.BLOCK else minf(0.35, need)
		side_dir = held_stroke().y
	elif human_sim and side == PLAYER:
		# debug: hit like a person who just holds the key for a while, unread
		given = minf(randf_range(0.0, 1.0), power_cap(side)) if shot != Shot.BLOCK else minf(0.35, need)
		side_dir = 0
	else:
		# the AI reads spin with level-dependent accuracy
		given = minf(need * (1.0 + randf_range(-1.0, 1.0) * float(lv_of(side).ai_err) * pressure(side) * (2.2 if fooled else 1.0)), power_cap(side))
		side_dir = -int(signf(side_in)) if randf() < float(lv_of(side).ai_read) * (0.4 if fooled else 1.0) else 0
	var counter_dir := -int(signf(side_in))
	if shot == Shot.PUSH:
		given = lerpf(given, need, 0.7)   # a push soaks up most of the spin by itself
	# 0 perfect, + too soft, - too hard; over-hitting a light spin forgives more
	var fit := clampf((need - given) / maxf(need, 0.35), -1.0, 1.0)
	var side_fit := 1.0
	if absf(side_in) > MIN_SPIN:
		if side_dir == counter_dir:
			side_fit = fit
		elif side_dir != 0:
			side_fit = 1.0 + given
	var kick_y: float = s_in * (k_top if s_in > 0.0 else k_back) * lv_of(side).kick * fit
	var kick: Vector3 = Vector3.UP * kick_y - a_in * side_in * 0.0012 * lv_of(side).kick * side_fit
	# faster strokes are less precise
	# the launch itself wobbles too (for flat shots only a little: their error
	# already went into the aim above)
	var shake: float = wobble * (0.2 if flat else 1.0)
	v += kick + Vector3(randf_range(-1.0, 1.0) * shake, randf_range(-1.0, 1.0) * shake * (0.5 if flat else 1.0), 0.0)

	bv = v
	bw = w
	last_hitter = side
	bounced_receiver = false
	missed = {PLAYER: false, AI: false}
	rally += 1
	if not gstats.is_empty():
		var pp: Vector3 = paddle_pos[side]
		gstats.pos[side].append(Vector2(pp.x, pp.z))
		var kind := stroke_name.trim_prefix("正手").trim_prefix("反手")
		gstats.shots[side][kind] = int(gstats.shots[side].get(kind, 0)) + 1
		gstats.wing[side][my_wing] += 1
		gstats.timing[side][timing] += 1
		gstats.speed[side].append(v.length())
		gstats.spin[side].append(w.length() * RAD_TO_RPM)
	swing[side] = 0.0
	swing_style[side] = swing_key(stroke_name)
	last_stroke[side] = stroke_name
	# big swings cost stamina; heavy balls and smashes cost extra
	var cost := 0.5
	match shot:
		Shot.LOOP:
			cost = 1.5 + windup * 4.0
		Shot.SMASH:
			cost = 4.0 + windup * 5.0
		Shot.PUSH:
			cost = 1.0
	if spin_need(w, v) >= HEAVY_NEED:
		cost += 3.0
	spend(side, cost)
	if is_human(side):
		windup_hold = 0.0   # recover, then backswing again for the next ball
	prepare_receiver(-side, 0)
	_check_wall(side)
	decoy = {}
	trick = {}
	if skill_on():
		var use := ""
		if is_human(side):
			if STROKE_SKILLS.has(skill_armed) and focus_cards > 0:
				use = skill_armed
				focus_cards -= 1
				skill_armed = ""
		elif shot in [Shot.LOOP, Shot.SMASH] and not lv_of(side).get("gentle", false) and randf() < (0.45 if skill_test else 0.18):
			# the AI picks its moments on attacking strokes, and any trick it took in
			var tricks: Array = loadout[side].filter(func(id): return STROKE_SKILLS.has(id))
			if not tricks.is_empty() and side == AI and ai_focus > 0:
				ai_focus -= 1
				use = tricks.pick_random()
			elif not tricks.is_empty() and side == PLAYER and focus_cards > 0:
				focus_cards -= 1
				use = tricks.pick_random()
		if use != "" and not gstats.is_empty():
			gstats.skills[side] += 1
		if use != "" and drill.get("kind", "") == "tutorial":
			drill.cast = true
		if use == "jinchan":
			_launch_decoy(side, target, v, w)
		elif use != "":
			_launch_trick(use, side, target)
	sfx.hit(bp, ["block", "loop", "push", "smash"][shot], v.length(), spin_need(w, v), heavy)
	rec.event("hit", bp, v.length(), ["block", "loop", "push", "smash"][shot])
	last_hit_t = rec.clock

	if autoplay:
		print("[hit] %s %s %s %s [%s]%s net+%.2f z=%.2f y=%.2f  in-spin %d rpm  out-spin %d rpm  kick %.2f  solve %d us" % [
				"P" if side == PLAYER else "AI", grip[side], stroke_name, timing, notes,
				(" <" + tactic_name + ">") if tactic_name != "" else "", Sim.net_clearance(bp, v, w), bp.z, bp.y,
				int(s_in * RAD_TO_RPM), int(top * RAD_TO_RPM), kick_y, Time.get_ticks_usec() - t0])
	if side == PLAYER and not shot_readout():
		info_label.clear()
		if not coaching():
			tip_label.clear()
	if side == PLAYER and shot_readout():
		rich(info_label, [str(pname[PLAYER]) + "  ", [stroke_name + (("  【%s】" % tactic_name) if tactic_name != "" else ""), C_YELLOW], " · " + TIMING_NAMES[timing],
				[(" · " + notes) if notes != "" else "", C_PALE], ["  重球!" if heavy else "", C_RED], "   →  "] + spin_parts(w, v))
		# feedback: hold strength against the spin it had to cancel, side spin met the right way
		var verdict := []
		if need > 0.15:
			verdict += [Icons.strength(given, need), Icons.ok() if absf(fit) < 0.3 else Icons.no()]
		if absf(side_in) > MIN_SPIN:
			verdict += ["     ", Icons.spin("side_l" if side_in > 0.0 else "side_r"), "  →  ",
					{"key": "E D" if side_in > 0.0 else "Q A"}, Icons.ok() if side_dir == counter_dir else Icons.no()]
		if settle[side] < 0.4:
			verdict += ["     ", Icons.mouse("move"), " ", Icons.ready_bar(false), Icons.no()]
		if verdict.is_empty() or autoplay:
			tip_label.clear()
		else:
			rich(tip_label, verdict)
	else:
		describe_incoming("%s · %s%s" % [stroke_name, TIMING_NAMES[timing], ("  【%s】" % tactic_name) if tactic_name != "" else ""])


## Where a tactical AI aims (empty = just play it anywhere; how often it bothers
## is the level's `tactic`). Right-handed opponents: the backhand corner is on
## their left. Options: press the backhand (more so against a penholder or a
## backhand that has been losing points), switch to the wide forehand after two
## balls to the backhand, hit the open side when they're stranded, or jam them at
## the body. Then front/back: drop it short if they're far back, long if they crowd the table.
## The coach's one-line takeaway for the analysis panel: where you dropped most
## of this game's points and what to try about it.
func coach_tip() -> String:
	var lost: Dictionary = gstats.get("lost", {})
	var best := ""
	var n := 0
	for k in lost:
		if int(lost[k]) > n:
			best = k
			n = int(lost[k])
	var tip := ""
	match best:
		"reach":
			tip = "这局 %d 分是没跑到位：球一过网就把鼠标往黄圈的方向挪，别等它弹起来再动" % n
		"ace":
			tip = "被发球直接拿了 %d 分：先看来球颜色，下旋（蓝）轻按 S 搓，上旋（红）按住 W 拉" % n
		"serve":
			tip = "自己发球丢了 %d 分：发球条上的指针停在黄色区段里再松手" % n
		"out":
			var by: Dictionary = gstats.get("out_by", {})
			var worst := ""
			for k in by:
				if worst == "" or int(by[k]) > int(by[worst]):
					worst = k
			tip = "打出界 %d 分%s：力度弧到绿色就松手，红了是用力过头" % [n, ("（多是%s）" % worst) if worst != "" else ""]
		"net":
			tip = "下网或落在本方台面 %d 分：接下旋别平挡，按 S 搓或按住 W 拉起来" % n
	if n < 3:
		tip = "这局没有明显的短板，保持住"
	if int(settings.get("help", 1)) >= 2 and score[AI] - score[PLAYER] >= 6:
		tip += "\n觉得难的话，设置里把「操作辅助」调到新手或休闲"
	return tip


func ai_target(side: int, shot: int) -> Dictionary:
	var order: String = orders[side]
	if randf() > maxf(float(lv_of(side).tactic), 0.75 if order in ["press_bh", "wide_fh"] else 0.0):
		return {}
	var opp := -side
	var op: Vector3 = paddle_pos[opp]
	var bh_x := -opp * 0.55 * hand(opp)
	var fh_x := opp * 0.65 * hand(opp)
	var w: Dictionary = weak[opp]
	var bh_bias := clampf(0.5 + (0.3 if has_trait(side, "adapt") else 0.1) * (w.bh - w.fh) + (0.2 if grip[opp] == "pen" else 0.0) + (0.3 if order == "press_bh" else 0.0)
			+ (0.2 if has_trait(opp, "weak_bh") else 0.0), 0.1, 0.95)
	var r := randf()
	var res := {}
	if order == "wide_fh" and press_count[side] >= 1 and randf() < 0.6:
		res = {"tx": fh_x, "name": "调动正手"}
	elif press_count[side] >= 2 and randf() < 0.7:
		res = {"tx": fh_x, "name": "变线"}
	elif absf(op.x) > 0.45 and r < 0.4:
		res = {"tx": -signf(op.x) * 0.62, "name": "打空当"}
	elif r < 0.4 + 0.5 * bh_bias:
		res = {"tx": bh_x, "name": "压反手"}
	else:
		res = {"tx": clampf(op.x, -0.35, 0.35), "name": "追身"}
	press_count[side] = press_count[side] + 1 if res.name == "压反手" else 0
	if absf(op.z) > 2.2 and (shot == Shot.BLOCK or shot == Shot.PUSH):
		res.depth = 0.5
		res.name += "·摆短"
	elif absf(op.z) < 1.6 and shot != Shot.PUSH:
		res.depth = 1.15
		res.name += "·压长"
	return res


func player_shot_choice() -> int:
	match held_stroke().x:
		1:
			return Shot.SMASH if bp.y > Sim.TABLE_Y + 0.45 else Shot.LOOP
		-1:
			return Shot.PUSH
	return Shot.BLOCK


func ai_shot_choice(s_in: float) -> int:
	if bp.y > Sim.TABLE_Y + 0.45 and randf() < 0.7:
		return Shot.SMASH
	if s_in < -80.0:
		return Shot.LOOP if randf() < 0.55 else Shot.PUSH
	if s_in > 120.0:
		return Shot.BLOCK if randf() < 0.65 else Shot.LOOP
	return [Shot.BLOCK, Shot.LOOP, Shot.PUSH].pick_random()


func auto_serve(side: int) -> void:
	serve_attack[side] = ai_serve_attack
	var q := 1.0 if prof[side].is_empty() else clampf(float(prof[side].serve_q) + randf_range(-0.12, 0.12), 0.0, 1.0)
	serve(side, ai_serve_kind, ai_serve_side, 0.8, q)


## How well the release landed: 1 inside the sweet zone, falling to 0 as the
## needle ends up further outside it.
func serve_quality() -> float:
	var m = serve_meter
	var outside: float = maxf(absf(m.needle - m.zone_c) - m.zone_w * 0.5, 0.0)
	return clampf(1.0 - outside / 0.3, 0.0, 1.0)


func player_serve(kind: String, side_dir: int, power: float, quality := 1.0) -> void:
	quality = clampf(lerpf(1.0, quality, float(help().serve)), 0.0, 1.0)   # 操作辅助 steadies the release
	# hold Shift on release for a feint: it works as often as your serve is good
	var feint := Input.is_key_pressed(KEY_SHIFT) and kind != "none"
	serve_fake[PLAYER] = feint and randf() < float(lv_of(PLAYER).get("serve_q", 0.86))
	serve(PLAYER, kind, side_dir * SIDE_KEY_SPIN, power * (0.92 if feint else 1.0), quality)
	if feint:
		rich(tip_label, ["假动作发球  ", Icons.ok() if serve_fake[PLAYER] else Icons.no(),
				["  骗到了" if serve_fake[PLAYER] else "  没骗到", C_YELLOW if serve_fake[PLAYER] else C_RED]])
		return
	if kind != "none":
		rich(tip_label, ["发球  ", Icons.ok() if quality >= 0.85 else Icons.no(),
				["  完美" if quality >= 0.85 else "  偏了 %d%%" % int((1.0 - quality) * 100.0), C_YELLOW if quality >= 0.85 else C_RED]])


## Serve spin: kind "top" / "back" / "none" plus side spin (rad/s); `power` 0..1
## comes from how long the key was held (the toss-and-brush wind-up).
func serve_spin(side: int, kind: String, side_spin: float, power: float) -> Vector3:
	var top := 0.0
	match kind:
		"top":
			top = 220.0
		"back":
			top = -300.0
	var k: float = lerpf(0.6, 1.25, power) * lv_of(side).spin * float(lv_of(side).get("serve_spin", 1.0)) * float(gear(side).fh.spin)
	return Sim.topspin_axis(Vector3(0.0, 0.0, -side)) * top * k + Vector3.UP * side_spin * k


## `quality` (0..1, from the serve meter): a missed release loses spin and sprays the ball.
func serve(side: int, kind: String, side_spin: float, power: float, quality := 1.0) -> void:
	var start := bp
	start.y = maxf(start.y, Sim.TABLE_Y + 0.15)
	start.z = 1.5 * side
	start.x = clampf(start.x, -0.7, 0.7)
	var base := 4.5
	match kind:
		"top":
			base = 5.0
		"back":
			base = 3.2
	base *= sqrt(lv_of(side).speed)
	var w := serve_spin(side, kind, side_spin, power) * lerpf(0.55, 1.0, quality)
	serve_preview = Vector3.ZERO
	serve_meter.visible = false
	var sv := Sim.solve_serve_safe(start, start.x * 0.7, float(side), w, base)
	var v: Vector3 = sv[0]
	w = sv[1]   # eased off if the full spin could not be served legally
	v += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * 0.6 * (1.0 - quality)
	spend(side, 2.0 + power * 6.0)
	bp = start
	bv = v
	bw = w
	ball_live = true
	waiting_serve = false
	last_hitter = side
	serve_bounce_pending = true
	if side == AI and is_human(PLAYER):
		_read_serve(w)
	_check_wall(side)
	bounced_receiver = false
	missed = {PLAYER: false, AI: false}
	rally = 1
	swing[side] = 0.0
	swing_style[side] = "搓" if kind == "back" else "快带"
	prepare_receiver(-side, 1)
	sfx.hit(start, "serve", v.length(), spin_need(w, v), heavy)
	rec.event("hit", start, v.length(), "serve")
	rally_start_t = rec.clock
	last_hit_t = rec.clock
	var_flag = {}
	if side == AI:
		describe_incoming("发球")
	else:
		if shot_readout():
			rich(info_label, [str(pname[PLAYER]) + "  ", ["发球", C_YELLOW], "   →  "] + spin_parts(w, v))
		tip_label.clear()


func prepare_receiver(side: int, skip: int) -> void:
	_shift_gravity(-side)
	hit_pred[side] = Sim.predict_path(bp, bv, bw, side, skip)
	react_timer[side] = randf_range(0.12, 0.22) * (1.25 - 0.15 * level_of(side))
	aim_err[side] = Vector3(randf_range(-0.07, 0.07), randf_range(-0.05, 0.05), 0.0)
	if hexes.view[side] > 0 and not is_human(side):   # 视角转移: it loses its bearings
		react_timer[side] += 0.2
		aim_err[side] *= 3.0
	if not is_human(side) and hit_pred[side].ok:
		plan[side] = plan_return(side, hit_pred[side].pts)
	# heavy balls smoke and glow whoever hit them; when one comes at you it also
	# gets the card with the one key that answers it and how long to hold
	var need := spin_need(bw, bv)
	heavy = need >= HEAVY_NEED
	if side == PLAYER:
		if heavy:
			var top := bw.dot(Sim.topspin_axis(bv))
			var col := -int(signf(bw.y)) if absf(bw.y) > MIN_SPIN else 0
			solve_card.texture = Icons.solution(1 if top >= 0.0 else -1, col, need)


## AI footwork: pick a stroke and *when* to take the ball. Blocks and pushes are
## taken early, close to the table; loops are taken late after backing off, which
## turns topspin exchanges into proper mid-distance 对拉; high balls are smashed
## at the top of the bounce.
func plan_return(side: int, pts: PackedVector3Array) -> Dictionary:
	var top := bw.dot(Sim.topspin_axis(bv))
	var apex := Sim.apex_index(pts)
	var apex_y := pts[apex].y
	var shot: int
	var timing: String
	if apex_y > Sim.TABLE_Y + 0.5 and absf(pts[apex].z) < 2.3 and randf() < 0.6:
		shot = Shot.SMASH; timing = "peak"
	elif top < -80.0:
		if randf() < 0.5:
			shot = Shot.LOOP; timing = ["peak", "late"].pick_random()
		else:
			shot = Shot.PUSH; timing = "early"
	elif top > 120.0:
		# stronger players back off and loop-to-loop more than they block
		if randf() < 0.4 - 0.1 * level_of(side):
			shot = Shot.BLOCK; timing = "early"
		else:
			shot = Shot.LOOP; timing = "late"
	else:
		shot = [Shot.LOOP, Shot.LOOP, Shot.BLOCK].pick_random()
		timing = "peak" if shot == Shot.LOOP else "early"
	if shot == Shot.PUSH and apex_y > Sim.TABLE_Y + 0.3:
		shot = Shot.LOOP; timing = "peak"   # never push a ball that sits up
	if has_trait(side, "early") and shot != Shot.SMASH and timing != "early" and randf() < 0.6:
		timing = "early"   # close to the table, on the rise
	var idx := apex
	match timing:
		"early":
			idx = maxi(apex / 3, 2)
		"late":
			# after the apex, once it has dropped to about table height, but not miles back
			idx = pts.size() - 1
			for i in range(apex, pts.size()):
				if pts[i].y < Sim.TABLE_Y + randf_range(-0.15, 0.05) or absf(pts[i].z) > 2.8:
					idx = i
					break
	idx = clampi(idx, 0, pts.size() - 1)
	return {"shot": shot, "pos": pts[idx], "timing": timing}


# ---------------------------------------------------------------- rackets

func update_paddle(side: int, delta: float) -> void:
	var old: Vector3 = paddle_pos[side]
	var pred: Dictionary = hit_pred[side]
	var incoming: bool = ball_live and not point_over and last_hitter == -side and pred.ok
	if is_human(side):
		# mouse = where you stand (left/right and how far off the table, i.e. which
		# moment of the bounce you take); racket height follows the ball's path
		var x := old.x
		var z := old.z
		var m = mouse_on_floor(Sim.TABLE_Y + 0.1)
		if m != null and not skill_wheel.visible:   # the mouse is choosing a skill
			x = clampf(m.x, -1.6, 1.6)
			z = clampf(m.z, 0.3, 3.0)
		var want_y := Sim.TABLE_Y + 0.2
		if incoming:
			var pts: PackedVector3Array = pred.pts
			# no volleys: you can't meet it before it bounces or after it's gone
			z = clampf(z, pts[0].z + 0.05, maxf(pts[pts.size() - 1].z, pts[0].z + 0.05))
			var at = Sim.point_at_z(pts, z)
			if at != null:
				want_y = at.y
				# 操作辅助: your feet drift toward where the ball is going
				var pull: float = float(help().magnet) + (0.2 * maxf(adapt, 0.0) if adapt_on() else 0.0)
				# (less of it once the camera has risen: the racket has grown already)
				x = lerpf(x, clampf(at.x, -1.6, 1.6), minf(pull / zoom_reach(), 0.85))
		elif waiting_serve and server == side:
			z = 1.5
			want_y = Sim.TABLE_Y + 0.12
		var y := lerpf(old.y, want_y, 1.0 - exp(-18.0 * delta))
		var k := 1.0 - exp(-30.0 * delta)
		paddle_pos[side] = Vector3(lerpf(old.x, x, k), y, lerpf(old.z, z, k))
	else:
		var target := Vector3(0.0, Sim.TABLE_Y + 0.25, 1.9 * side)
		if waiting_serve and server == side:
			target = Vector3(serve_x, Sim.TABLE_Y + 0.12, 1.5 * side)
		elif incoming:
			if react_timer[side] > 0.0:
				react_timer[side] -= delta
				target = old
			elif not plan[side].is_empty():
				target = plan[side].pos + aim_err[side]
		var step := target - old
		var max_step: float = lv_of(side).ai_speed * delta
		if step.length() > max_step:
			step = step.normalized() * max_step
		paddle_pos[side] = old + step
	var vel: Vector3 = (paddle_pos[side] - old) / maxf(delta, 1e-5)
	paddle_vel[side] = (paddle_vel[side] as Vector3).lerp(vel, 0.25)
	track_feet(side, old, delta)
	# feet "set" when the racket stops travelling; running drains it
	var run := Vector2(paddle_vel[side].x, paddle_vel[side].z).length()
	if run > 0.3:
		spend(side, run * delta * STAMINA_RUN)
	if run < 0.5:
		settle[side] = minf(settle[side] + delta / 0.25, 1.0)
	else:
		settle[side] = maxf(settle[side] - delta * run * 1.2, 0.0)
	if is_human(side):
		var holding := held_stroke().x != 0
		windup_hold = windup_hold + delta if holding and not waiting_serve else 0.0
