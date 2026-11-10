class_name EventScreen
extends Control
## Plays one event: its card (what it is, how to play, the mark to beat), then
## the event itself in the stadium (or the pool), then the scoreboard.
##
## Races run every lane at once. In the jumps, the high jump and the dive the
## players' attempts are played out and the computer's are posted on the board
## as they happen. The music's beat drives everything: the song clock (Sound)
## is the time every bounce and tap is judged by.

signal finished(meet: Meet)
signal quit                      ## left from the pause menu, unfinished

const PX_Y := StadiumView.PX_UP  ## pixels per metre upward
const PLACES := ["1ST", "2ND", "3RD", "4TH"]

var meet: Meet
var beat: Beat
var stadium: StadiumView
var pool: PoolView
var gym: GymView
var stage_view: StageView
var street: StreetView
var snow: SnowView
var sled: SledView
var mc: AthleteView              ## breaking: the MC who dances the patterns
var actors: Node2D
var fx: Fx
var hud: Control
var pad: Pad
var views := {}                  ## entrant -> AthleteView
var race: Race
var attempt: Variant             ## the Jump, High or Dive being played
var turn := -1
var stage := "card"              ## card, play, after, board
var stage_t := 0.0
var players := 1
var bot := false                 ## the computer plays the players' parts (tests, shots)
var ticker: Array = []           ## the board's latest postings: [{text, col, age}]
var said: Array = []             ## big words in the middle: {text, col, age, life}
var lanes := {}                  ## entrant -> lane
var _card: Control
var _board: Control
var _last_count := 0
var _gun_done := false
var _seen := 0
var _lift := {}
var _cam := 0.0
var _mark_text := ""
var _salt := 0
var _fresh_track := false
var teammates := {}              ## relay: lane's entrant -> [AthleteView] waiting (and done) teammates
var _tag_spots := {}             ## relay: entrant -> [x where each leg handed over]
var ball: Sprite2D               ## the meatball, in the meatball put
var paused := false
var timing := TapTiming.new()    ## learns this screen's lag from the players' taps
var _calibration_was := 0.0
var _pause_btn: Button
var _pause_panel: Control
var lesson := ""                 ## LEARN TO PLAY: the lesson this is (the coach always talks)
var _coach: PanelContainer       ## the coach's words, at the top: what to press, and when
var _coach_label: Label


func start(m: Meet, p_players := 1, p_bot := false) -> void:
	meet = m
	players = p_players
	bot = p_bot
	_calibration_was = Profile.calibration
	Kit.fill(self)
	if meet.kind == "dive":
		pool = PoolView.new()
		add_child(pool)
	elif meet.kind == "tramp":
		gym = GymView.new()
		add_child(gym)
	elif meet.kind == "battle":
		stage_view = StageView.new()
		add_child(stage_view)
	elif meet.kind == "skate":
		street = StreetView.new()
		add_child(street)
	elif meet.kind == "skijump":
		snow = SnowView.new()
		add_child(snow)
	elif meet.kind == "bob":
		sled = SledView.new()
		add_child(sled)
	else:
		stadium = StadiumView.new()
		add_child(stadium)
	actors = Node2D.new()
	add_child(actors)
	fx = Fx.new()
	fx.z_index = 60
	add_child(fx)
	hud = Control.new()
	Kit.fill(hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	hud.z_index = 100
	add_child(hud)
	_build_coach()
	pad = Pad.new()
	pad.players = mini(players, Remote.screen_count())
	pad.bash = bashing()
	pad.run_word = "SWIM" if int(meet.info.get("breath", 0)) > 0 else "RUN"
	pad.z_index = 120
	_pad_layer().add_child(pad)
	pad.pressed.connect(_on_press)
	pad.released.connect(_on_release)
	pad.ran.connect(_on_run)
	Remote.pressed.connect(_on_press)
	Remote.released.connect(_on_release)
	Remote.ran.connect(_on_run)
	Remote.set_bash(bashing(), pad.run_word)
	Remote.set_event(true)
	for i in meet.entrants.size():
		var v := AthleteView.new()
		v.set_look(meet.entrants[i].get("look", {}))
		actors.add_child(v)
		views[i] = v
		lanes[i] = 3 - i
		v.visible = meet.kind == "race"
		if int(meet.info.get("legs", 1)) > 1:
			var mates: Array = []
			for k in int(meet.info.legs) - 1:
				var mate := AthleteView.new()
				mate.set_look(meet.entrants[i].get("look", {}))
				actors.add_child(mate)
				mates.append(mate)
			teammates[i] = mates
			_tag_spots[i] = []
	if meet.kind == "battle":
		mc = AthleteView.new()
		mc.set_look({"sausage": "frank", "bun": "sesame", "toppings": ["mustard", "ketchup"], "band": ["black", "gold"],
			"specs": "shades", "hair": "flattop", "tache": "none"})
		actors.add_child(mc)
	if meet.kind == "throw":
		ball = Sprite2D.new()
		ball.texture = load("res://assets/art/stadium/meatball.png")
		ball.z_index = 40
		ball.visible = false
		actors.add_child(ball)
	_dress_venue()
	_show_card()
	Sound.music("stadium")
	_pause_btn = Kit.small_button("II", Color("4e4a62"), 26)
	_pause_btn.custom_minimum_size.y = 18
	_pause_btn.set_meta("quiet", true)
	_pause_btn.z_index = 130
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.pressed.connect(toggle_pause)
	add_child(_pause_btn)
	pad.holes = [_pause_btn]


# -- the venue ---------------------------------------------------------------------

func _dress_venue() -> void:
	if stadium == null:
		return
	stadium.excite = 0.25
	stadium.venue = String(meet.info.get("venue", "track" if meet.kind == "race" else "field"))
	if meet.kind == "race":
		var dist := float(meet.info.get("distance", 100.0))
		stadium.lines = [{"x": 0.0, "kind": "start"}, {"x": dist, "kind": "finish"}]
		for m in range(10, int(dist) + 1, 10):
			stadium.markers.append({"x": float(m), "m": m})
		stadium.cam = -6.0
		if meet.info.has("hurdles"):
			var hs: Dictionary = meet.info.hurdles
			var spots: Array = hs.get("at", [])
			if spots.is_empty():
				for h in int(hs.count):
					spots.append(float(hs.first) + h * float(hs.gap))
			var barrier := bool(hs.get("barrier", false))
			for lane in 4:
				for x in spots:
					stadium.props.append({"name": "barrier" if barrier else "hurdle", "x": float(x), "lane": float(lane),
						"foot": Vector2(7, 44 if barrier else 42)})
		for w in meet.info.get("water", []):
			stadium.pits.append({"from": float(w.x), "to": float(w.x) + float(w.len), "tex": "water_pit"})
		var legs := int(meet.info.get("legs", 1))
		for k in range(1, legs):
			var ex := dist / legs * k
			stadium.lines.append({"x": ex - Race.BOX_BEFORE, "kind": "box"})
			stadium.lines.append({"x": ex + Race.BOX_AFTER, "kind": "box"})
	elif meet.kind == "jump":
		var pit_from := 1.0 if meet.id == "long_jump" else 9.0
		stadium.pit = {"from": pit_from, "to": pit_from + 11.0}
		stadium.runways = [{"from": -float(meet.info.get("run_up", 34.0)) - 12.0, "to": pit_from, "far": 1.9, "near": 3.1}]
		stadium.lines = [{"x": 0.0, "kind": "board"}]
		for m in range(int(pit_from) + 3, int(pit_from) + 11):
			stadium.markers.append({"x": float(m), "text": "%dm" % m})
		_mark_lines()
		stadium.cam = -float(meet.info.get("run_up", 34.0)) - 6.0
	elif meet.kind == "high":
		var shape: Dictionary = meet.info.get("shape", {})
		stadium.cam = float(shape.get("spot", -1.4)) - float(shape.get("step", 2.0)) * int(meet.info.get("approach", 7)) - 6.0
		if shape.has("mat"):
			# the vault: a runway up to the box
			stadium.runways = [{"from": stadium.cam - 10.0, "to": float(shape.get("spot", -2.4)) + 0.6, "far": 1.9, "near": 3.1}]
		else:
			# the high jump: its fan of tartan, run across to the bar
			stadium.runways = [{"from": stadium.cam - 10.0, "to": 6.5, "far": 1.0, "near": 3.6}]
	elif meet.kind == "throw":
		stadium.sector = true
		stadium.lines = [{"x": 0.0, "kind": "circle"}]
		for m in range(5, 30, 5):
			stadium.lines.append({"x": float(m), "kind": "mark"})
			stadium.markers.append({"x": float(m), "text": "%dm" % m})
		_mark_lines()
		stadium.cam = -8.0


## The marks to beat, painted where they'd land: the world record in gold and
## the qualifying mark in white.
func _mark_lines() -> void:
	var rec := float(Profile.record(meet.id).mark)
	var q := float(meet.info.get("qualify", {}).get(meet.level, 0.0))
	stadium.lines.append({"x": rec, "kind": "record", "label": "WR"})
	stadium.lines.append({"x": q, "kind": "qual", "label": "Q"})


# -- the card ----------------------------------------------------------------------

func _show_card() -> void:
	stage = "card"
	stage_t = 0.0
	_card = Kit.panel(Color("2a1e3e"))
	_card.custom_minimum_size = Vector2(300, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_card.add_child(box)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 8)
	var pic := TextureRect.new()
	pic.texture = Kit.icon(meet.id)
	pic.stretch_mode = TextureRect.STRETCH_KEEP
	head.add_child(pic)
	var title := Kit.label(String(meet.info.get("name", meet.id)).to_upper(), "big", Kit.MUSTARD)
	head.add_child(title)
	box.add_child(head)
	var how := Kit.label(String(meet.info.get("how_easy", meet.info.get("how", ""))), "small", Kit.PAPER)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size = Vector2(284, 0)
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(how)
	var q := float(meet.info.get("qualify", {}).get(meet.level, 0.0))
	var rec := Profile.record(meet.id)
	var marks := Kit.label("TO QUALIFY  %s\nWORLD RECORD  %s%s" % [Catalog.show_mark(meet.id, q),
		Catalog.show_mark(meet.id, float(rec.mark)), ("  " + String(rec.name)) if String(rec.get("name", "")) != "" else ""],
		"small", Kit.AMBER)
	marks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(marks)
	var who := HBoxContainer.new()
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override("separation", 6)
	for i in meet.entrants.size():
		var e: Dictionary = meet.entrants[i]
		who.add_child(Kit.flag_rect(String(e.get("nation", "ngc")), "s"))
		var n := Kit.label(String(e.get("name", "?")).split(" ")[0], "small",
			Kit.player_colour(int(e.get("player", -1))))
		who.add_child(n)
	box.add_child(who)
	var go := Kit.label("TAP TO START", "small", Kit.PAPER)
	go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go.name = "Go"
	box.add_child(go)
	_card.z_index = 110
	add_child(_card)
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.position = (get_viewport_rect().size - _card.get_combined_minimum_size()) / 2.0 - Vector2(0, 20)
	_pad_on_top()
	Remote.set_turns([])
	_tell_phones("TAP TO START", false)


## The buttons go over the game's picture (Main's overlay), so a joined
## tablet is sent the picture without them; on their own (tests), in here.
func _pad_layer() -> Node:
	var main := get_tree().root.get_node_or_null("Main") if is_inside_tree() else null
	if main and main.get("overlay") is CanvasLayer:
		return main.overlay
	return self


func _pad_on_top() -> void:
	if pad.get_parent() == self:
		move_child(pad, get_child_count() - 1)


func _exit_tree() -> void:
	if pad and is_instance_valid(pad) and pad.get_parent() != self:
		pad.queue_free()
	Remote.set_paused(false)
	Remote.set_bash(false)
	Remote.set_event(false)


## What the players' phones show at the top: this event, and what's happening.
func _tell_phones(hint: String, play: bool) -> void:
	_phone_hint = [hint, play]
	Remote.set_screen(String(meet.info.get("name", meet.id)).to_upper(), hint, play)


var _phone_hint: Array = ["", false]


## A phone player's bouncer (and the event's own checks) wait a moment longer
## before a beat counts as missed: the press may still be on its way.
func _give_grace(i: int, obj: Variant) -> void:
	if obj != null and Remote.is_phone(int(meet.entrants[i].get("player", -1))) and "grace" in obj:
		obj.grace = Remote.GRACE


func _begin() -> void:
	if _card:
		_card.queue_free()
		_card = null
	stage = "play"
	stage_t = 0.0
	beat = Sound.begin_beat("events", 90.0)
	Remote.set_beat(beat)
	_fresh_track = true
	if meet.kind == "race":
		_begin_race()
	else:
		_next_turn()


# -- races ---------------------------------------------------------------------------

func _begin_race() -> void:
	race = Race.new()
	var ent: Array = []
	for i in meet.entrants.size():
		var e: Dictionary = meet.entrants[i]
		var human := int(e.get("player", -1)) >= 0
		ent.append({"name": e.get("name", "?"), "cpu": not human or bot, "skill": 0.97 if (human and bot) else e.get("skill", 0.8),
			"lane": lanes[i], "boost": e.get("boost", 0.0)})
	race.setup(meet.id, beat, ent, meet.level, Sound.song_time(), meet.seed)
	_gun_done = false
	_last_count = 0
	_seen = 0
	var running: Array = []
	for i in meet.entrants.size():
		_watch(race.athletes[i], i)
		_give_grace(i, race.athletes[i])
		if int(meet.entrants[i].get("player", -1)) >= 0:
			running.append(int(meet.entrants[i].player))
	Remote.set_turns(running)
	_tell_phones("BOUNCE ON THE BEAT!", true)


func _watch(b: Bouncer, i: int) -> void:
	b.listeners.append(func(e: Dictionary) -> void: _heard(e, i))


# -- field events: turns -------------------------------------------------------------

func _next_turn() -> void:
	for v in views.values():
		v.visible = false
	var guard := 0
	while guard < 200:
		guard += 1
		turn = meet.next_turn()
		if turn < 0:
			_show_board()
			return
		var e: Dictionary = meet.entrants[turn]
		if int(e.get("player", -1)) >= 0:
			_play_turn(turn)
			return
		# the computer's go, posted on the board
		_salt += 1
		var v := meet.sim(turn, beat, _salt)
		var bar := meet.bar
		meet.record(turn, v)
		_post_cpu(turn, v, bar)


func _post_cpu(i: int, v: float, bar: float) -> void:
	var e: Dictionary = meet.entrants[i]
	var name := String(e.get("name", "?"))
	var text := ""
	match meet.kind:
		"high":
			text = "%s  %.2fm  %s" % [name, bar, "CLEAR" if v > 0.5 else "X"]
		"dive":
			text = "%s  %.1f" % [name, v]
		_:
			text = "%s  %s" % [name, "FOUL" if v < 0.0 else Catalog.show_mark(meet.id, v)]
	ticker.append({"text": text, "col": Kit.AMBER, "age": 0.0, "nation": e.get("nation", "ngc")})
	if ticker.size() > 4:
		ticker.pop_front()


func _play_turn(i: int) -> void:
	# the event's own track, for every go: on from where it's got to, or
	# from the top if it's nearly done
	if not _fresh_track:
		beat = Sound.begin_beat("events", 90.0, true)
		Remote.set_beat(beat)
	_fresh_track = false
	var e: Dictionary = meet.entrants[i]
	var who := {"name": e.get("name", "?"), "cpu": bot, "skill": 0.97, "band": Profile.rivals}
	var now := Sound.song_time()
	_salt += 1
	match meet.kind:
		"jump":
			var j := Jump.new()
			j.setup(meet.id, beat, who, meet.level, now, meet.seed * 100 + _salt)
			attempt = j
			_watch(j.b, i)
		"high":
			var h := High.new()
			h.setup(beat, who, meet.level, meet.bar, now, meet.seed * 100 + _salt, meet.id)
			attempt = h
			_watch(h.b, i)
			stadium.props = _high_props(meet.bar, false)
		"throw":
			var th := Throw.new()
			th.setup(beat, who, meet.level, now, meet.seed * 100 + _salt)
			attempt = th
			_watch(th.b, i)
			ball.visible = false
		"battle":
			var bt := Battle.new()
			bt.setup(beat, who, meet.level, now, meet.seed, meet.seed * 100 + _salt)
			attempt = bt
		"skate":
			var sk := Skate.new()
			sk.setup(beat, who, meet.level, now, meet.seed, meet.seed * 100 + _salt)
			attempt = sk
			street.course = sk.course
		"bob":
			var bo := Bob.new()
			bo.setup(beat, who, meet.level, now, meet.seed, meet.seed * 100 + _salt)
			attempt = bo
			_watch(bo.b, i)
		"skijump":
			var sj := SkiJump.new()
			sj.setup(beat, who, meet.level, now, meet.seed * 100 + _salt)
			attempt = sj
			_watch(sj.b, i)
			snow.cam = Vector2.ZERO
		"tramp":
			var tr := Tramp.new()
			tr.setup(beat, who, meet.level, now, meet.seed * 100 + _salt)
			attempt = tr
			_watch(tr.b, i)
			gym.marks = []
		"dive":
			var d := Dive.new()
			d.setup(beat, who, meet.level, now, meet.seed * 100 + _salt)
			attempt = d
			_watch(d.b, i)
			pool.marks = []
	turn = i
	_give_grace(i, attempt)
	if attempt != null and "b" in attempt:
		_give_grace(i, attempt.b)
	Remote.set_turns([int(e.get("player", -1))])
	pad.active = [int(e.get("player", -1))]
	pad.queue_redraw()
	_tell_phones("%s'S GO" % String(e.get("name", "?")).split(" ")[0].to_upper(), true)
	views[i].visible = true
	views[i].mood = "ready"
	_seen = 0
	stage = "play"
	stage_t = 0.0
	_last_count = 0
	_gun_done = false
	_mark_text = ""


func _high_props(bar: float, down: bool) -> Array:
	var p := {"kind": "high", "bar": bar, "down": down}
	var shape: Dictionary = meet.info.get("shape", {})
	if shape.has("mat"):
		p["mat_from"] = float(shape.mat[0])
		p["mat_h"] = float(shape.mat[1])
		p["mat_to"] = float(shape.mat[0]) + 5.5
	if shape.get("board", false):
		p["board_x"] = float(shape.get("spot", -1.4))
	return [p]


# -- input -----------------------------------------------------------------------------

func _on_press(player: int, action: bool, at: float) -> void:
	if paused:
		return
	if stage == "play" and not bot and beat != null and player < pad.players:
		_learn_timing(at)
	match stage:
		"card":
			if stage_t > 0.3:
				_begin()
			return
		"board":
			if stage_t > 0.8:
				_leave_board()
			return
		"after":
			if stage_t > 0.6:
				_next_turn()
			return
	if bot:
		return
	var i := meet.entrant_of(player)
	if i < 0:
		return
	if race != null:
		var g := race.press(i, action, at)
		if g == "false":
			return
	elif attempt != null and turn == i:
		attempt.press(action, at)


## Speed and power come from two RUN buttons, tapped in turn as fast as you
## can, the Track & Field way: the races, the run-ups of the long, triple and
## high jump and the vault, the put's spin-up and the bobsleigh's push.
## Elsewhere BOUNCE on the beat builds the spring (the dive's board, the ski
## jump's in-run) or is the game (the trampoline, breaking, the skateboard).
const BASH_KINDS := ["race", "jump", "high", "throw", "bob"]


func bashing() -> bool:
	return meet.kind in BASH_KINDS


## A RUN button: in the race it's a step; on the card or the scoreboard it's
## a tap like any other.
func _on_run(player: int, side: int, at: float) -> void:
	if paused:
		return
	if stage != "play":
		_on_press(player, false, at)
		return
	if bot:
		return
	var i := meet.entrant_of(player)
	if i < 0:
		return
	if race != null:
		race.run(i, side, at)
	elif attempt != null and turn == i and attempt.has_method("run"):
		attempt.run(side, at)
	elif attempt != null and turn == i:
		attempt.press(false, at)


func _on_release(player: int, action: bool, at: float) -> void:
	if bot or stage != "play" or not action:
		return
	var i := meet.entrant_of(player)
	if attempt != null and turn == i and attempt.has_method("release"):
		attempt.release(at)


# -- each frame ----------------------------------------------------------------------

## The pause menu: the music and its clock stop where they are, and pick up
## again from there. It opens at any point in the event (on the card, between
## goes, on the scoreboard), so there's always a way out.
func toggle_pause() -> void:
	if (stage == "done" or bot) and not paused:
		return
	paused = not paused
	pad.set_process_input(not paused)
	Remote.set_paused(paused)
	if paused:
		Remote.set_screen(String(meet.info.get("name", meet.id)).to_upper(), "PAUSED", false)
	else:
		Remote.set_screen(String(meet.info.get("name", meet.id)).to_upper(), String(_phone_hint[0]), bool(_phone_hint[1]))
	if paused:
		Sound.pause_beat()
		_pause_panel = Kit.panel(Color("1a1424"))
		_pause_panel.z_index = 140
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		_pause_panel.add_child(box)
		var t := Kit.label("PAUSED", "big", Kit.MUSTARD)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(t)
		var go_on := Kit.button("CARRY ON", Kit.RELISH.darkened(0.2), "small", 120)
		go_on.pressed.connect(toggle_pause)
		box.add_child(go_on)
		var leave := Kit.button("LEAVE THE EVENT", Kit.KETCHUP, "small", 120)
		leave.pressed.connect(func():
			paused = false
			pad.set_process_input(true)
			Sound.resume_beat()
			Sound.end_beat()
			quit.emit())
		box.add_child(leave)
		add_child(_pause_panel)
		go_on.grab_focus.call_deferred()
	else:
		Sound.resume_beat()
		if _pause_panel:
			_pause_panel.queue_free()
			_pause_panel = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var sz := get_viewport_rect().size
	if _pause_btn:
		_pause_btn.position = Vector2(roundf(sz.x / 2 + 64), 6)
		_pause_btn.visible = stage != "done" and not bot
	if _pause_panel:
		_pause_panel.position = ((sz - _pause_panel.get_combined_minimum_size()) / 2.0).round()
	if paused:
		return
	stage_t += delta
	for tk in ticker:
		tk.age += delta
	for s in said:
		s.age += delta
	said = said.filter(func(s): return s.age < s.life)
	if stage == "play":
		var t := Sound.song_time()
		if race != null:
			_race_frame(t, delta)
		elif attempt != null:
			_attempt_frame(t, delta)
	if stadium:
		stadium.beat = beat.beat_at(Sound.song_time()) if beat else stage_t * 1.5
	if pool:
		pool.beat = beat.beat_at(Sound.song_time()) if beat else stage_t * 1.5
	if gym:
		gym.beat = beat.beat_at(Sound.song_time()) if beat else stage_t * 1.5
	if stage_view:
		stage_view.beat = beat.beat_at(Sound.song_time()) if beat else stage_t * 1.5
	if street:
		street.beat = beat.beat_at(Sound.song_time()) if beat else stage_t * 1.5
	if snow:
		snow.beat = beat.beat_at(Sound.song_time()) if beat else stage_t * 1.5
	if sled:
		sled.beat = beat.beat_at(Sound.song_time()) if beat else stage_t * 1.5
	hud.queue_redraw()
	_update_coach()
	_update_controls()
	if stage == "card" and _card and _card.has_node("VBoxContainer/Go"):
		pass


# -- what the buttons do ------------------------------------------------------------------

var _controls_on := false


## What each player's buttons do right now and which to press next
## (ui/controls.gd): on this tablet's buttons, and told to the phones and
## joined tablets. Back to plain BOUNCE (or RUN) and JUMP off the field.
func _update_controls() -> void:
	var play := stage == "play" and not paused
	if not play and not _controls_on:
		return
	_controls_on = play
	# the bobsleigh: two RUN buttons to push, then two buttons, LOW and HIGH, for the bends
	var want_bash := bashing() and not (attempt is Bob and not String(attempt.state) in ["set", "push"])
	if pad.bash != want_bash:
		pad.bash = want_bash
		pad.queue_redraw()
		Remote.set_bash(want_bash, pad.run_word)
	var t := Sound.song_time()
	for h in meet.humans():
		var player := int(meet.entrants[h].get("player", -1))
		var c: Dictionary = Controls.of(self, h, t) if play else \
			{"b": "RUN" if bashing() else "BOUNCE", "j": "JUMP", "lit": Controls.NONE}
		if player >= 0 and player < pad.players:
			pad.set_controls(player, String(c.b), String(c.j), int(c.lit))
		if player >= 0:
			Remote.set_words(player, String(c.b), String(c.j), int(c.lit))


# -- the coach (LEARN MODE) --------------------------------------------------------------

const COACH_Y := 30.0


func coaching() -> bool:
	return lesson != "" or (Profile.learn and not bot)


func _build_coach() -> void:
	_coach = Kit.panel(Color("2a1e3e"), Kit.MUSTARD)
	_coach.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coach.z_index = 105
	_coach_label = Kit.label("", "small", Kit.PAPER)
	_coach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coach.add_child(_coach_label)
	_coach.visible = false
	add_child(_coach)


## The coach's words for now: what to press, and when (or nothing).
func coach_text() -> String:
	if stage != "play" or paused:
		return ""
	for c in fx.cues:
		if c.has("aim"):
			var a: Dictionary = c.aim
			if float(a.angle) < float(a.lo):
				return "HOLD IT... LET GO IN THE GREEN!"
			return "LET GO NOW!" if float(a.angle) <= float(a.hi) else "TOO HIGH! LET GO!"
		if c.has("hold"):
			return "KEEP HOLDING JUMP!" if float(c.hold) < 1.0 else "GO!"
		if bool(c.get("now", false)):
			return "JUMP NOW!"
		return "JUMP BY THE LINE, WHEN THE CIRCLE IS SMALL" if meet.kind in ["jump", "high"] else \
			"WAIT... JUMP WHEN THE CIRCLE IS SMALL"
	var t := Sound.song_time()
	if race != null:
		if not _gun_done:
			return "GET READY TO TAP RUN!"
		for h in meet.humans():
			var b: Bouncer = race.athletes[h]
			if b.state != "run" or b.coasting:
				continue
			if b.bash:
				return _run_words(b, t)
			return "TAP BOUNCE EACH TIME YOU LAND"
		return ""
	if attempt != null and turn >= 0 and meet.humans().has(turn):
		if attempt.has_method("run_up") and attempt.run_up():
			var b: Bouncer = attempt.b
			if String(attempt.state) == "set":
				return "GET READY TO TAP RUN!"
			return _run_words(b, t)
		if "b" in attempt and not attempt.has_method("run_up"):
			var b: Bouncer = attempt.b
			if "state" in attempt and String(attempt.state) == "set":
				return "TAP BOUNCE TO START"
			if b.state == "run" and not b.coasting:
				return "TAP BOUNCE EACH TIME YOU LAND"
	return ""


## What the coach says while a player taps RUN: faster, or well done.
func _run_words(b: Bouncer, t: float) -> String:
	if b.sizzling():
		return "WOW! YOU'RE SIZZLING!"
	var rate := b.bash_rate(t)
	if rate < 2.0:
		return "TAP RUN, RUN, RUN!  LEFT, RIGHT, LEFT, RIGHT!"
	return "FASTER! FASTER!" if rate < 4.0 else "BRILLIANT RUNNING!"


func _update_coach() -> void:
	if _coach == null:
		return
	var text := coach_text() if coaching() else ""
	_coach.visible = text != "" and _board == null
	if text == "":
		return
	if _coach_label.text != text:
		_coach_label.text = text
		_coach.size = _coach.get_combined_minimum_size()
	var s := get_viewport_rect().size
	var pulse := text.ends_with("NOW!") or text == "GO!"
	_coach_label.add_theme_color_override("font_color", Kit.MUSTARD if pulse else Kit.PAPER)
	# under the scoreboard; lower with three or four players (their boxes are up there too)
	_coach.position = Vector2(roundf((s.x - _coach.size.x) / 2.0), COACH_Y + (20.0 if meet.humans().size() > 2 else 0.0))


func _race_frame(t: float, delta: float) -> void:
	race.update(t, delta)
	# the count-in and the gun
	var c := race.count(t)
	if c != _last_count and c > 0:
		_last_count = c
		Sound.play("tick", 0.8, 1.0 if c < 4 else 1.25)
	if not _gun_done and t >= race.go:
		_gun_done = true
		Sound.play("gun")
		_say("GO!", Kit.MUSTARD, 0.6)
		stadium.excite = 0.55
	while _seen < race.log.size():
		_race_log(race.log[_seen])
		_seen += 1
	for i in meet.entrants.size():
		_place(i, race.athletes[i], float(lanes[i]))
		if teammates.has(i):
			_place_teammates(i, t)
	# follow the players (or the leader)
	var xs: Array = []
	for h in meet.humans():
		xs.append(race.athletes[h].x)
	if xs.is_empty():
		for b in race.athletes:
			xs.append(b.x)
	var want := float(xs.max()) - 7.0
	_cam = lerpf(_cam, maxf(want, -6.0), clampf(delta * 5.0, 0.0, 1.0))
	stadium.cam = _cam
	_update_rings()
	if race.finished() and stage == "play":
		if stage_t > 0.0 and not race.times.is_empty():
			meet.record_race(race.times)
			Remote.set_turns([])
			_tell_phones("FINISHED!", false)
			stage = "after"
			stage_t = 0.0
			get_tree().create_timer(2.2).timeout.connect(func():
				if stage == "after":
					_show_board())


func _attempt_frame(t: float, delta: float) -> void:
	attempt.update(t, delta)
	var b: Bouncer = attempt.b
	var a_state := String(attempt.state)
	if a_state == "set":
		var bar_start: float = attempt.go - beat.bar_len()
		if t >= bar_start:
			var c := int(floor((t - bar_start) / beat.beat_len())) + 1
			if c != _last_count and c >= 1 and c <= 4:
				_last_count = c
				Sound.play("tick", 0.8, 1.0 if c < 4 else 1.25)
	elif not _gun_done:
		_gun_done = true
		_say("GO!", Kit.MUSTARD, 0.5)
	while _seen < attempt.log.size():
		_attempt_log(attempt.log[_seen])
		_seen += 1
	if meet.kind == "dive":
		pool.place(views[turn], attempt)
		pool.cam_follow(attempt, delta)
	elif meet.kind == "tramp":
		gym.place(views[turn], attempt)
		gym.cam_follow(attempt, delta)
	elif meet.kind == "skate":
		_ride(attempt as Skate, t)
	elif meet.kind == "skijump":
		_fly(attempt as SkiJump, t, delta)
	elif meet.kind == "bob":
		_sled(attempt as Bob, t)
	elif meet.kind == "battle":
		var bt: Battle = attempt
		var fy := stage_view.floor_y()
		_dance(views[turn], bt.move, bt.move_at, t, Vector2(stage_view.spot(1), fy), bt.b.y * 18.0)
		views[turn].mood = bt.b.mood
		_dance(mc, bt.mc_move, bt.mc_move_at, t, Vector2(stage_view.spot(0), fy), bt.b.y * 18.0)
		mc.mood = "happy" if bt.state == "call" else "ready"
		stage_view.excite = 0.4 + 0.5 * clampf(bt.score / maxf(1.0, bt.max_score()), 0.0, 1.0)
	else:
		_place(turn, b, 2.5)
		var want := b.x - 7.0
		if b.state == "air" or attempt.state == "landed":
			want = b.x - 9.0
		if attempt is Throw:
			var th: Throw = attempt
			want = -8.0
			if th.state != "run" and th.state != "set":
				want = maxf(-8.0, th.ball.x - 12.0)
			_place_ball(th)
		_cam = lerpf(_cam, want, clampf(delta * 5.0, 0.0, 1.0))
		stadium.cam = _cam
		# rise with a high vault, so the hot dog stays on screen
		var top := stadium.lane_y(2.5) - stadium.cam_y - b.y * PX_Y - 70.0
		var want_y := maxf(0.0, 24.0 - top)
		stadium.cam_y = lerpf(stadium.cam_y, want_y, clampf(delta * 6.0, 0.0, 1.0))
		_place(turn, b, 2.5)
		if meet.kind == "high":
			stadium.props = _high_props(meet.bar, attempt.knocked and attempt.state != "run")
	_update_rings()
	if attempt.finished():
		_attempt_done()


## The relay's other three: the ones still to run wait at their changeover,
## bobbing to the beat; the ones who've run stand where they tagged, pleased.
func _place_teammates(i: int, t: float) -> void:
	var legs := int(meet.info.legs)
	var leg_len := float(meet.info.distance) / legs
	var lane := float(lanes[i])
	var y := stadium.lane_y(lane)
	var mates: Array = teammates[i]
	var on: int = race.leg[i]
	var spots: Array = _tag_spots[i]
	var ph := fposmod(beat.beat_at(t), 1.0) if beat else 0.0
	for k in mates.size():
		var v: AthleteView = mates[k]
		var x := 0.0
		if k < on:
			# this one has run and handed over: it stands where it tagged
			x = float(spots[k]) if k < spots.size() else leg_len * (k + 1)
			v.mood = "joy"
			v.lift = 0.0
			v.squash = 1.0
		else:
			x = leg_len * (k + 1) - 0.5
			v.mood = "ready" if k > on else "push"
			v.lift = 3.0 * 4.0 * ph * (1.0 - ph) if k == on else 0.0
			v.squash = 0.86 if ph < 0.1 else 1.0
		v.position = Vector2(stadium.screen_x(x, y), y).round()
		v.angle = 0.0
		v.z_index = int(lane * 10) - 1
		v.visible = true


## A dancer's pose for its latest move: toprock is a hop with a sway, a spin
## is upside down on its head, twice round, and a freeze is a pose held at the
## end of a round.
func _dance(v: AthleteView, move: String, at: float, t: float, spot: Vector2, bob: float) -> void:
	v.position = spot.round()
	v.lift = bob
	v.angle = 0.0
	v.twist = 0.0
	v.squash = 1.0
	v.ground_shadow = 1.0
	v.visible = true
	var p := t - at
	match move:
		"top":
			if p < 0.32:
				var k := p / 0.32
				v.lift = bob + 10.0 * sin(PI * k)
				v.angle = (12.0 if int(at * 7.0) % 2 == 0 else -12.0) * sin(PI * k)
				v.squash = 0.8 if k < 0.15 else 1.1
		"spin":
			if p < 0.5:
				var k := p / 0.5
				v.angle = 180.0 + 720.0 * k
				v.lift = 6.0 * sin(PI * k)
		"freeze":
			if p < 0.8:
				v.angle = 90.0
				v.lift = 4.0
				v.mood = "wink"


## The ski jumper: crouched down the in-run, leaning into the air in a V,
## upright (one knee forward, if it's a telemark) on the snow.
func _fly(sj: SkiJump, t: float, delta: float) -> void:
	snow.follow(sj.x, sj.y + 3.0, delta)
	var v: AthleteView = views[turn]
	var at := snow.to_screen(sj.x, sj.y)
	v.position = at.round()
	v.lift = 0.0
	v.ground_shadow = 0.0
	v.twist = 0.0
	v.mood = sj.b.mood
	var slope := 0.0
	match sj.state:
		"set", "inrun":
			slope = rad_to_deg(atan(0.6 * tan(deg_to_rad(35.0))))
			v.angle = slope + 4.0
			v.squash = 0.78 if fposmod(sj.beat.beat_at(t), 1.0) < 0.15 else 0.84
			snow.skis = {"x": at.x, "y": at.y - 1.0, "angle": slope, "v": 0.0}
		"flight":
			v.angle = 58.0 + (1.0 - sj.balance) * 12.0 * sin(t * 9.0)
			v.squash = 1.0
			snow.skis = {"x": at.x + 4.0, "y": at.y - 2.0, "angle": -14.0 + (1.0 - sj.balance) * 8.0, "v": 1.0}
		_:
			var dx := 1.0
			slope = -rad_to_deg(atan2(SkiJump.hill(sj.x + dx) - SkiJump.hill(sj.x), dx))
			v.angle = slope * 0.5
			v.squash = 0.86 if sj.landing == "telemark" else 1.0
			snow.skis = {"x": at.x, "y": at.y - 1.0, "angle": slope, "v": 0.0}
			if sj.landing == "wobbly":
				v.angle = 70.0


## The bobsleigh: pushing the bun, then sitting in it, leaning with the bends.
func _sled(bo: Bob, t: float) -> void:
	sled.d = bo.d
	sled.v = bo.v
	sled.lean = bo.lean
	sled.cues = bo.coming(t)
	var v: AthleteView = views[turn]
	v.ground_shadow = 0.0
	v.twist = 0.0
	v.mood = bo.b.mood
	var sp := sled.sled_pos()
	if bo.state == "set" or bo.state == "push":
		v.position = Vector2(sp.x - 40.0, sled.floor_y() + 8.0).round()
		v.lift = bo.b.y * PX_Y
		v.squash = bo.b.squash
		v.angle = 20.0
	else:
		v.position = Vector2(sp.x + 2.0, sp.y + 12.0).round()
		v.lift = 0.0
		v.squash = 0.86
		v.angle = rad_to_deg(bo.lean * 0.12) + 6.0


## The skater on its board: the street scrolls under it.
func _ride(sk: Skate, t: float) -> void:
	street.cam = sk.x - StreetView.RIDER_X / StreetView.PX
	var v: AthleteView = views[turn]
	var fy := street.floor_y() + 8.0
	var deck_y := fy - sk.y * StreetView.PX - 4.0
	v.position = Vector2(StreetView.RIDER_X, roundf(deck_y - 2.0))
	v.lift = 0.0
	v.ground_shadow = 0.0
	v.mood = sk.b.mood
	v.twist = 0.0
	v.squash = 1.0
	var bl := sk.beat.beat_len()
	var flip := 0.0
	var spin := 0.0
	var p := t - sk.trick_at
	if sk.trick == "kickflip" and p < bl:
		flip = p / bl
	elif sk.trick == "spin" and p < bl:
		spin = p / bl
		v.twist = spin
	match sk.pose:
		"bail":
			v.angle = 90.0
			v.position.y = fy - 6.0
		"grind":
			v.angle = 8.0
		"air":
			v.angle = -10.0
		_:
			v.angle = 0.0
			var ph := fposmod((t - sk.go) / bl, 1.0)
			v.squash = 0.9 if ph < 0.1 else 1.0
	street.board = {"x": StreetView.RIDER_X, "y": deck_y + 3.0, "flip": flip, "spin": spin} if sk.pose != "bail" \
		else {"x": StreetView.RIDER_X + 30.0, "y": fy + 2.0, "flip": 0.5, "spin": 0.0}


func _place_ball(th: Throw) -> void:
	var y := stadium.lane_y(2.5)
	if th.state == "run" or th.state == "set":
		# balanced on the hot dog's head
		var v: AthleteView = views[turn]
		ball.position = v.position + Vector2(1, -v.lift - 44.0 * th.b.squash - 3.0)
		ball.visible = true
		ball.rotation = 0.0
		return
	ball.visible = true
	ball.position = Vector2(stadium.screen_x(th.ball.x, y), y - th.ball.y * PX_Y - 4.0).round()
	ball.rotation = deg_to_rad(roundf(th.ball_spin / 90.0) * 90.0)


func _place(i: int, b: Bouncer, lane: float) -> void:
	var v: AthleteView = views[i]
	var y := stadium.lane_y(lane)
	v.position = Vector2(stadium.screen_x(b.x, y), y).round()
	v.scroll = -stadium.cam * StadiumView.PX
	v.lift = b.y * PX_Y
	v.squash = b.squash
	v.lean = clampf((b.vx - 6.0) / 3.0, 0.0, 1.0) if b.state == "run" else 0.0
	v.angle = b.angle + (14.0 * v.lean if b.state == "run" else 0.0)
	v.mood = "sizzle" if b.sizzling() and b.state == "run" else b.mood
	v.z_index = int(lane * 10)
	# a sizzling hot dog leaves a little trail of flame
	if b.sizzling() and b.state == "run" and int(meet.entrants[i].get("player", -1)) >= 0 and randf() < 0.6:
		fx.burst("flame", v.position + Vector2(-8, -v.lift - 14), 1, 1.0)
	if stadium.venue == "pool":
		# swimming: lying forward along the water, nodding with each stroke
		v.ground_shadow = 0.0
		v.lean = 0.0
		v.angle = 90.0 - b.y * 40.0
		v.lift = -16.0 + b.y * PX_Y * 0.6
		v.squash = 1.0


const CUE_LEAD := 0.9            ## seconds the JUMP cue takes to close in


## The JUMP cue, always shown: a circle round each player's hot dog that
## shrinks onto it at the moment to press JUMP; while JUMP is held (the long
## jump, the high jump, the vault, the put), a ring that fills until the hot
## dog lets go by itself.
func _update_cues() -> void:
	fx.cues = []
	var t := Sound.song_time()
	for h in meet.humans():
		var b: Bouncer = null
		if race != null:
			b = race.athletes[h]
		elif attempt != null and turn == h and "b" in attempt:
			b = attempt.b
		if b == null or not views.has(h):
			continue
		var v: AthleteView = views[h]
		var centre := v.position + Vector2(0, -v.lift - 24)
		var hold := _hold_progress(b, t)
		if hold >= 0.0:
			var cue := {"p": centre, "hold": hold, "h": h}
			if attempt != null and attempt.has_method("aim"):
				cue["aim"] = attempt.aim(t)         # the needle and the green (game/aim.gd)
			fx.cues.append(cue)
			continue
		# the put: the circle closes as the spring builds (or as time runs out)
		if attempt is Throw and b.bash and b.state == "run":
			var by_spring := clampf((b.spring - 0.5) / 0.4, 0.0, 1.0)
			var by_time := clampf(float(b.to_slot - 4) / float(Throw.MAX_BOUNCES - 9), 0.0, 1.0)
			var k := maxf(by_spring, by_time)
			if k > 0.0:
				fx.cues.append({"p": centre, "k": k, "now": k >= 1.0, "h": h})
			continue
		var when := _next_jump_time(h, b)
		if when < 0.0:
			continue
		var left := when - t
		if left > CUE_LEAD or left < -0.15:
			continue
		fx.cues.append({"p": centre, "k": clampf(1.0 - left / CUE_LEAD, 0.0, 1.0), "now": absf(left) < 0.1, "h": h})


## When this player should next press JUMP (song time), or -1 for not soon.
func _next_jump_time(h: int, b: Bouncer) -> float:
	if attempt is Bob:
		var bo: Bob = attempt
		return bo.hop_time() if bo.state == "push" else -1.0
	if attempt is SkiJump:
		var sj: SkiJump = attempt
		return sj.edge_time() if sj.state == "inrun" else -1.0
	if b.state != "run" or b.coasting:
		return -1.0
	# a player's take-off is timed to its line, not a landing: when it'll get there
	var line := NAN
	if attempt is Jump and (attempt as Jump).phase_i == 0 and not b.cpu:
		line = Jump.IDEAL
	elif attempt is High and not b.cpu:
		line = (attempt as High).SPOT
	if not is_nan(line):
		if b.x > line + 0.5:
			return -1.0
		return Sound.song_time() + (line - b.x) / maxf(b.vx, 0.5)
	for s in range(b.to_slot, b.to_slot + 4):
		var want := false
		if race != null:
			if race.hurdles[h].size() > 0:
				want = race.good_take_off(h, s)
			elif race.legs > 1:
				want = race.good_tag(h, s)
			elif race.breath > 0:
				want = race.is_breath(s)
		elif attempt is Jump:
			want = (attempt as Jump).wants_action(s)
		elif attempt is High:
			want = s == (attempt as High).approach
		elif attempt is Throw:
			want = s >= 5
		elif attempt is Dive:
			want = s >= 4
		elif attempt is Tramp:
			want = s == Tramp.WARMUP + Tramp.SKILLS + 1
		if want:
			return b.slot_time(s)
	return -1.0


## How far through a hold the player is (0..1: 1 is the top of the green), or -1.
func _hold_progress(b: Bouncer, t: float) -> float:
	if b.state != "hold" or attempt == null or not attempt.has_method("aim"):
		return -1.0
	var a: Dictionary = attempt.aim(t)
	return clampf((float(a.angle) - float(a.start)) / maxf(float(a.hi) - float(a.start), 1.0), 0.0, 1.0)


func _update_rings() -> void:
	_update_cues()
	fx.rings = []
	if not Profile.assist or bot:
		return
	for h in meet.humans():
		var b: Bouncer
		var lane := 2.5
		if race != null:
			b = race.athletes[h]
			lane = float(lanes[h])
		elif attempt != null and turn == h:
			b = attempt.b
		else:
			continue
		if b.state != "run" or b.coasting:
			continue
		var t := Sound.song_time()
		var span := (b.to_slot - b.from_slot) * b.slot_len
		var k := clampf(1.0 - (b.slot_time(b.to_slot) - t) / span, 0.0, 1.0)
		var col := Kit.PAPER
		var jump := false
		if race != null and race.hurdles[h].size() > 0:
			jump = race.good_take_off(h, b.to_slot)
		elif race != null and race.legs > 1:
			jump = race.good_tag(h, b.to_slot)
		elif race != null and race.breath > 0:
			jump = race.is_breath(b.to_slot)
		elif attempt is Throw:
			jump = b.to_slot >= 5 and b.spring > 0.8
		elif attempt is Dive:
			jump = b.to_slot >= 4 and b.spring > 0.8
		elif attempt is Tramp:
			jump = b.to_slot == Tramp.WARMUP + Tramp.SKILLS + 1
		elif attempt is Jump:
			jump = (attempt as Jump).wants_action(b.to_slot)
		elif attempt is High:
			jump = b.to_slot == (attempt as High).approach
		if b.bash:
			continue                   # bashing: no beat to show (the JUMP cue says when)
		var y := 0.0
		var x := 0.0
		if stadium:
			y = stadium.lane_y(lane)
			x = stadium.screen_x(b.predict_x(b.slot_time(b.to_slot)), y)
		elif views.has(h):
			# off the track (the pool, the stage, the street): round the athlete
			var va: AthleteView = views[h]
			x = va.position.x
			y = va.position.y
		if sled and attempt is Bob:
			var vb: AthleteView = views[h]
			x = vb.position.x
			y = vb.position.y
			if b.to_slot * b.slot_len >= Bob.PUSH_BEATS * b.beat_len - 0.01:
				jump = true
				col = Kit.SKY
		if snow and attempt is SkiJump:
			var sjp: SkiJump = attempt
			var vv: AthleteView = views[h]
			x = vv.position.x
			y = vv.position.y
			if sjp.state == "inrun" and b.to_slot >= SkiJump.INRUN_BEATS:
				jump = true
				col = Kit.SKY
		if gym:
			x = gym.centre_x()
			y = gym.bed_y()
			# and a second ring up top: the beat for a trick
			if attempt is Tramp and (attempt as Tramp).state == "routine":
				var top: float = (attempt as Tramp).top_time()
				var kt := clampf(1.0 - (top - t) / b.beat_len, 0.0, 1.0) if t < top else 0.0
				if kt > 0.0:
					var v2: AthleteView = views[h]
					fx.rings.append({"p": v2.position + Vector2(0, -v2.lift - 22), "k": kt, "col": Kit.MUSTARD})
		fx.rings.append({"p": Vector2(x, y), "k": k, "col": col})


# -- what happened ---------------------------------------------------------------------

func _heard(e: Dictionary, i: int) -> void:
	var human := int(meet.entrants[i].get("player", -1)) >= 0
	var v: AthleteView = views[i]
	var head := v.position + Vector2(0, -v.lift - 50)
	match String(e.kind):
		"grade":
			var g := String(e.grade)
			if human:
				Remote.tell_grade(int(meet.entrants[i].player), g)
				Sound.play("bounce_" + g, 0.9)
				fx.word(Kit.GRADE_WORDS.get(g, g), head, Kit.GRADE_COLOURS.get(g, Kit.PAPER), false, 0.6, "grade%d" % i)
				if g == "perfect":
					fx.burst("spark", head + Vector2(0, 14), 5)
					v.flash = 0.35
					if not bot:
						Wardrobe.count("perfects")
		"land":
			if stadium and stadium.venue == "pool":
				fx.burst("water", v.position + Vector2(-8, 0), 4 if human else 2, 0.35)
			else:
				fx.burst("dust", v.position, 3 if human else 2, 0.6)
		"sizzle":
			if human:
				fx.word("SIZZLING!", head + Vector2(0, -10), Kit.KETCHUP, true, 1.0)
				Sound.play("sizzle")
				if not bot:
					Wardrobe.count("sizzles")
			if stadium:
				stadium.excite = 0.9
		"cool":
			if stadium:
				stadium.excite = 0.55
		"big":
			if human:
				Sound.play("boing_big", 0.8)
		"hold":
			if human:
				Sound.play("squash", 0.8)
		"launch":
			Sound.play("whoosh", 0.8)


func _race_log(e: Dictionary) -> void:
	var i: int = e.get("who", -1)
	match String(e.kind):
		"false_start":
			_say("FALSE START!", Kit.KETCHUP, 1.2)
			Sound.play("wobble")
		"tag":
			_tag_spots[i].append(float(e.x))
			if int(meet.entrants[i].get("player", -1)) >= 0:
				var g := String(e.grade)
				fx.word("TAG! " + Kit.GRADE_WORDS.get(g, g).trim_suffix("!"), views[i].position + Vector2(0, -58),
					Kit.GRADE_COLOURS.get(g, Kit.PAPER), false, 0.8, "tag%d" % i)
				Sound.play("tag")
		"missed_tag":
			if int(meet.entrants[i].get("player", -1)) >= 0:
				_say("MISSED THE TAG!", Kit.KETCHUP, 1.0)
				Sound.play("wobble")
		"gulp":
			if int(meet.entrants[i].get("player", -1)) >= 0:
				fx.word("GULP!", views[i].position + Vector2(0, -40), Kit.SKY, false, 0.8, "grade%d" % i)
				Sound.play("bounce_miss")
		"breath":
			if int(meet.entrants[i].get("player", -1)) >= 0:
				Sound.play("swish", 0.5)
		"barrier_hit":
			Sound.play("clonk", 0.9)
			if int(meet.entrants[i].get("player", -1)) >= 0:
				fx.word("CLAMBER!", views[i].position + Vector2(0, -56), Kit.KETCHUP)
		"splash":
			fx.burst("water", views[i].position, 12, 0.8)
			Sound.play("splash", 0.5)
		"hurdle_hit":
			Sound.play("clonk", 0.8)
			var lane: int = lanes[i]
			for p in stadium.props:
				if p.get("name", "") == "hurdle" and int(p.lane) == lane and absf(float(p.x) - float(e.x)) < 0.1:
					p["name"] = "hurdle_down"
					p["foot"] = Vector2(7, 42)
			if int(meet.entrants[i].get("player", -1)) >= 0:
				fx.word("OOF!", views[i].position + Vector2(0, -56), Kit.KETCHUP)
		"finish":
			var place := int(e.place)
			var human := int(meet.entrants[i].get("player", -1)) >= 0
			if human:
				_say(PLACES[clampi(place - 1, 0, 3)] + "!", Kit.MUSTARD if place == 1 else Kit.PAPER, 1.4)
				if place == 1:
					fx.burst("confetti", views[i].position + Vector2(0, -60), 40)
			if place == 1:
				Sound.play("finish")
				stadium.excite = 1.0
			_mark_text = Catalog.show_mark(meet.id, float(e.time))


func _attempt_log(e: Dictionary) -> void:
	var b: Bouncer = attempt.b
	var v: AthleteView = views[turn]
	if e.has("grade") and String(e.kind) != "grade":
		var pg := String(e.grade)
		Remote.tell_grade(int(meet.entrants[turn].get("player", -1)), "fumble" if pg in ["wrong", "late"] else pg)
	match String(e.kind):
		"foul":
			_say(String(e.get("why", "foul")).to_upper() + "!", Kit.KETCHUP, 1.2)
			Sound.play("wobble")
		"hurry":
			_say("JUMP NOW!", Kit.SKY, 1.0)
		"hop", "skip":
			fx.word(String(e.kind).to_upper() + "!", v.position + Vector2(0, -60), Kit.SKY)
		"land":
			fx.burst("sand", v.position, 18, 1.2)
			Sound.play("sand")
			if String(e.foul) == "":
				_mark_text = Catalog.show_mark(meet.id, float(e.mark))
				stadium.excite = 0.8 if float(e.mark) >= float(meet.info.qualify.get(meet.level, 0.0)) else 0.4
		"arch":
			var g := String(e.grade)
			fx.word(Kit.GRADE_WORDS.get(g, g.to_upper()), v.position + Vector2(0, -v.lift - 50), Kit.GRADE_COLOURS.get(g, Kit.PAPER))
			Sound.play("swish")
		"clear":
			Sound.play("cheer")
			stadium.excite = 0.9
		"knock":
			Sound.play("clonk")
			stadium.excite = 0.3
		"balk":
			_say("UNDER THE BAR!", Kit.KETCHUP, 1.2)
		"mat":
			fx.burst("dust", v.position, 10, 1.5)
			Sound.play("flump")
		"flip", "twist":
			var g2 := String(e.grade)
			fx.word(String(e.kind).to_upper() + " " + Kit.GRADE_WORDS.get(g2, g2.to_upper()).trim_suffix("!"),
				v.position + Vector2(0, -v.lift - 50), Kit.GRADE_COLOURS.get(g2, Kit.PAPER))
			Sound.play("swish")
		"take_off":
			Sound.play("boing_big")
		"push":
			Sound.play("bounce_" + String(e.grade), 0.6)
		"balance":
			Sound.play("bounce_" + String(e.grade), 0.7)
		"hop_in":
			var hg := String(e.grade)
			fx.word("IN!" if hg in ["perfect", "good", "ok"] else "LATE!", v.position + Vector2(0, -56),
				Kit.GRADE_COLOURS.get(hg, Kit.KETCHUP), false, 0.8, "grade")
			Sound.play("boing_big", 0.7)
		"bend":
			var bg := String(e.grade)
			Sound.play("tag" if bool(e.high) else "bounce_perfect", 0.7)
			fx.word(Kit.GRADE_WORDS.get(bg, bg), v.position + Vector2(0, -50), Kit.GRADE_COLOURS.get(bg, Kit.PAPER), false, 0.5, "grade")
		"scrape":
			Sound.play("clonk", 0.8)
			fx.burst("spark", v.position + Vector2(-16, 6), 8)
			fx.word("SCRAPE!", v.position + Vector2(0, -50), Kit.KETCHUP, false, 0.6, "grade")
		"finish":
			if attempt is Bob:
				_mark_text = Catalog.show_mark(meet.id, float(e.time))
				Sound.play("finish")
		"wobble":
			fx.word("WOBBLE!", v.position + Vector2(0, -56), Kit.KETCHUP, false, 0.6, "grade")
			Sound.play("bounce_fumble", 0.7)
		"touch":
			fx.burst("dust", v.position, 14, 1.5)
			Sound.play("sand")
			_mark_text = "%.1fm" % float(e.distance)
		"landing":
			var how := String(e.how)
			var hc := Kit.RELISH if how == "telemark" else (Kit.PAPER if how == "two feet" else Kit.KETCHUP)
			fx.word(how.to_upper() + "!", v.position + Vector2(0, -60), hc, true, 1.2)
			_mark_text = "%.1fm  %.0f" % [float(e.distance), float(e.points)]
			if snow:
				pass
		"ollie", "launch", "grind":
			if e.has("grade"):
				Sound.play("boing_big", 0.6)
				fx.word(String(e.kind).to_upper() + "!", v.position + Vector2(0, -60), Kit.GRADE_COLOURS.get(String(e.grade), Kit.PAPER),
					false, 0.7, "trick")
		"kickflip", "spin":
			Sound.play("swish")
			var nm := "KICKFLIP!" if String(e.kind) == "kickflip" else "360!"
			fx.word(nm, v.position + Vector2(0, -70), Kit.GRADE_COLOURS.get(String(e.grade), Kit.PAPER), true, 0.8, "trick")
		"off":
			var gg := String(e.grade)
			if gg in ["perfect", "good", "ok"]:
				Sound.play("bounce_" + gg)
				fx.word("GRIND %d!" % int(e.beats), v.position + Vector2(0, -60), Kit.GRADE_COLOURS.get(gg, Kit.PAPER), false, 0.8, "trick")
			else:
				fx.word(gg.to_upper() + " OFF", v.position + Vector2(0, -60), Kit.KETCHUP, false, 0.8, "trick")
		"landed":
			Sound.play("flump", 0.7)
			fx.burst("dust", v.position, 6, 0.8)
		"bail":
			Sound.play("clonk")
			fx.word("BAIL!", v.position + Vector2(0, -50), Kit.KETCHUP, true, 0.8, "trick")
			fx.burst("dust", v.position, 10, 1.2)
		"call":
			_say("WATCH THE MC!", Kit.SKY, 1.0)
		"answer":
			_say("YOUR TURN!", Kit.MUSTARD, 0.8)
		"mc":
			Sound.play("tag" if bool(e.action) else "bounce_perfect", 0.7)
		"move":
			var g3 := String(e.grade)
			if g3 == "miss":
				Sound.play("bounce_miss")
			elif g3 == "wrong":
				Sound.play("bounce_fumble")
			else:
				Sound.play("tag" if bool(e.action) else "bounce_perfect", 0.9)
			var words := {"wrong": "WRONG MOVE"}
			fx.word(String(words.get(g3, Kit.GRADE_WORDS.get(g3, g3))), v.position + Vector2(0, -60),
				Kit.GRADE_COLOURS.get(g3, Kit.KETCHUP), false, 0.6, "grade")
		"extra":
			fx.word("WOBBLE!", v.position + Vector2(0, -60), Kit.KETCHUP, false, 0.6, "grade")
		"round_end":
			Sound.play("cheer", 0.6)
		"done":
			_mark_text = "%d" % int(e.score)
		"sloppy", "crooked":
			fx.word(String(e.kind).to_upper() + "!", v.position + Vector2(0, -v.lift - 56), Kit.KETCHUP, false, 0.7, "trick")
			Sound.play("bounce_fumble", 0.6)
		"stick_now":
			_say("STICK IT!", Kit.SKY, 0.8)
		"stick":
			if String(e.grade) != "":
				fx.word("STUCK IT!", v.position + Vector2(0, -60), Kit.GRADE_COLOURS.get(String(e.grade), Kit.PAPER), true, 1.2)
				Sound.play("cheer")
			_mark_text = "%.1f" % float(e.score)
			if gym:
				gym.marks = (attempt as Tramp).marks
		"put":
			Sound.play("whoosh")
			Sound.play("boing_big", 0.6)
		"thud":
			var bp := ball.position + Vector2(0, 4)
			fx.burst("dust", bp, 10, 1.4)
			Sound.play("flump")
			_mark_text = Catalog.show_mark(meet.id, float(e.mark))
			stadium.excite = 0.8 if float(e.mark) >= float(meet.info.qualify.get(meet.level, 0.0)) else 0.4
		"splash":
			Sound.play("splash", 0.6 + float(e.size) * 0.6)
			if pool:
				pool.splash(float(e.size))
				pool.marks = (attempt as Dive).marks
			_mark_text = "%.1f" % float(e.score)


func _attempt_done() -> void:
	var value := 0.0
	match meet.kind:
		"jump":
			value = (attempt as Jump).result()
		"throw":
			value = (attempt as Throw).result()
		"tramp":
			value = (attempt as Tramp).score
		"battle":
			value = (attempt as Battle).score
		"skate":
			value = (attempt as Skate).score
		"skijump":
			value = (attempt as SkiJump).points
		"bob":
			value = (attempt as Bob).result()
		"high":
			value = 1.0 if (attempt as High).cleared else 0.0
		"dive":
			value = (attempt as Dive).score
	var bar := meet.bar
	meet.record(turn, value)
	var e: Dictionary = meet.entrants[turn]
	var text := ""
	match meet.kind:
		"high":
			text = "%.2fm  %s" % [bar, "CLEAR!" if value > 0.5 else "KNOCKED"]
		"dive":
			text = "%.1f POINTS" % value
		_:
			text = "FOUL" if value < 0.0 else Catalog.show_mark(meet.id, value)
	ticker.append({"text": "%s  %s" % [String(e.get("name", "?")), text], "col": Kit.MUSTARD, "age": 0.0,
		"nation": e.get("nation", "ngc")})
	if ticker.size() > 4:
		ticker.pop_front()
	attempt = null
	stage = "after"
	stage_t = 0.0
	Remote.set_turns([])
	_tell_phones("TAP FOR THE NEXT GO", false)
	if bot:
		get_tree().create_timer(0.4).timeout.connect(func():
			if stage == "after":
				_next_turn())


func _say(text: String, col: Color, life := 1.0) -> void:
	said.append({"text": text, "col": col, "age": 0.0, "life": life})


# -- the scoreboard --------------------------------------------------------------------

## A press from this screen: where it fell from the nearest landing, and,
## after a batch, the calibration moved toward where the taps really land.
func _learn_timing(at: float) -> void:
	timing.add(TapTiming.phase(at, beat.time_of_beat(0), beat.bounce_len()))
	if timing.count() >= TapTiming.BATCH:
		Profile.calibration = timing.settle(Profile.calibration, beat.bounce_len())


func _show_board() -> void:
	stage = "board"
	stage_t = 0.0
	if absf(Profile.calibration - _calibration_was) > 0.001 and not bot:
		Profile.save()
	Remote.set_beat(null)
	Remote.set_turns([])
	_tell_phones("TAP TO CARRY ON", false)
	Sound.end_beat()
	Sound.music("stadium")
	if stadium:
		stadium.excite = 0.7
	var records := 0
	for h in meet.humans():
		if bot:
			break                     # the bot's marks don't go in the record books
		var mark := meet.best(h)
		var low := String(meet.info.get("better", "high")) == "low"
		if (meet.kind == "race" and not meet.times.has(h)) or (low and mark >= 98.0) or mark <= 0.0:
			continue
		var set: Array = Profile.offer(meet.id, mark, meet.entrants[h])
		if "record" in set:
			records += 1
			_say("WORLD RECORD!", Kit.MUSTARD, 3.0)
			fx.burst("confetti", Vector2(get_viewport_rect().size.x / 2.0, 40), 60)
			Sound.play("fanfare")
		elif "best" in set:
			_say("PERSONAL BEST!", Kit.RELISH, 2.0)
			Sound.play("finish", 0.7)
	# what playing has unlocked in the dressing room (for everyone)
	var got: Array = [] if bot else Wardrobe.after_event(meet, records)
	if not got.is_empty():
		Sound.play("fanfare", 0.8)
		fx.burst("confetti", Vector2(get_viewport_rect().size.x / 2.0, 30), 30)
	_board = Results.board(meet, got)
	pad.quiet = true                   # the scoreboard needs the room; any tap goes on
	pad.queue_redraw()
	_board.z_index = 110
	add_child(_board)
	_pad_on_top()
	if bot:
		get_tree().create_timer(0.6).timeout.connect(_leave_board)


## Off the scoreboard, once (a tap and the bot's timer can both ask).
func _leave_board() -> void:
	if stage != "board":
		return
	stage = "done"
	finished.emit(meet)


# -- the heads-up display -----------------------------------------------------------------

func _draw_hud() -> void:
	var s := get_viewport_rect().size
	var big := Kit.font("big")
	var small := Kit.font("small")
	var led := Kit.font("led")
	if stage == "card":
		return
	# the scoreboard at the top
	var title := String(meet.info.get("name", "")).to_upper()
	var t := Sound.song_time()
	var led_text := ""
	match meet.kind:
		"race":
			if race != null:
				var since := maxf(0.0, t - race.go)
				var best := INF
				for h in meet.humans():
					if race.times.has(h):
						best = minf(best, float(race.times[h]))
				if best < INF:
					since = best
				elif not meet.humans().is_empty() or race.times.size() < race.athletes.size():
					since = since
				led_text = "%05.2f" % since
		"jump", "throw":
			led_text = _mark_text if _mark_text != "" else ("ROUND %d" % (meet.round_i + 1))
		"high":
			led_text = "BAR %.2fm" % meet.bar
		"dive":
			led_text = _mark_text if _mark_text != "" else ("DIVE %d" % (meet.round_i + 1))
		"tramp":
			led_text = _mark_text if _mark_text != "" else ("ROUTINE %d" % (meet.round_i + 1))
		"bob":
			if attempt is Bob and (attempt as Bob).state == "run":
				var bob_: Bob = attempt
				led_text = "%05.2f" % maxf(0.0, t - bob_.hop_time())
			else:
				led_text = _mark_text if _mark_text != "" else ("RUN %d" % (meet.round_i + 1))
		"skijump":
			if attempt is SkiJump and (attempt as SkiJump).state == "flight":
				led_text = "%.1fm" % maxf(0.0, (attempt as SkiJump).x)
			else:
				led_text = _mark_text if _mark_text != "" else ("JUMP %d" % (meet.round_i + 1))
		"skate":
			if attempt is Skate:
				var skt: Skate = attempt
				led_text = "%d" % int(skt.score)
			else:
				led_text = _mark_text
		"battle":
			if attempt is Battle:
				var btl: Battle = attempt
				led_text = "%d" % int(btl.score) if btl.state != "set" else "ROUND 1/3"
				if btl.state == "call" or btl.state == "answer":
					led_text = "R%d  %d" % [btl.round_i + 1, int(btl.score)]
			else:
				led_text = _mark_text
	var w := maxf(led.get_string_size(led_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 16, 110)
	var box := Rect2(roundf(s.x / 2 - w / 2), 4, roundf(w), 30)
	hud.draw_rect(Rect2(box.position + Vector2(2, 2), box.size), Color(Kit.INK, 0.7))
	hud.draw_rect(box, Color("1a1424"))
	hud.draw_rect(box, Kit.INK, false, 1)
	var tw := small.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	hud.draw_string(small, Vector2(roundf(s.x / 2 - tw / 2), 12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Kit.GREY)
	var lw := led.get_string_size(led_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	hud.draw_string(led, Vector2(roundf(s.x / 2 - lw / 2), 15 + 14), led_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.AMBER)
	if attempt is Battle and stage == "play":
		_draw_highway(attempt as Battle, t)
	if attempt is Skate and stage == "play":
		_draw_flow(attempt as Skate, t)
	if attempt is SkiJump and stage == "play" and (attempt as SkiJump).state == "flight":
		_air_cues(attempt as SkiJump, t)
	# each player's tag: flag, name, spring
	for h in meet.humans():
		var p := int(meet.entrants[h].get("player", 0))
		var b: Bouncer = null
		if race != null:
			b = race.athletes[h]
		elif attempt != null and turn == h:
			b = attempt.b
		_draw_tag(h, p, b)
	# the board's postings
	var ty := 40.0
	for h in meet.humans():
		if int(meet.entrants[h].get("player", 0)) >= 3:
			ty = 70.0                  # below the fourth player's tag
	for tk in ticker:
		var a := clampf(1.0 - (float(tk.age) - 5.0) / 1.0, 0.0, 1.0)
		if a <= 0.0:
			continue
		var tex := Kit.flag(String(tk.nation), "s")
		var txt := String(tk.text)
		var ww := small.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 22
		var x := s.x - ww - 6
		hud.draw_rect(Rect2(x - 2, ty - 1, ww + 4, 13), Color(Kit.INK, 0.65 * a))
		hud.draw_texture(tex, Vector2(x, ty + 1), Color(1, 1, 1, a))
		hud.draw_string(small, Vector2(x + 18, ty + 9), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(tk.col, a))
		ty += 14
	# the count-in
	if stage == "play":
		var phase := ""
		var count := 0
		if race != null:
			phase = race.phase(t)
			count = race.count(t)
		elif attempt != null and String(attempt.state) == "set":
			phase = "set"
			var bs: float = attempt.go - beat.bar_len()
			count = int(floor((t - bs) / beat.beat_len())) + 1 if t >= bs else 0
		if phase == "marks" or phase == "intro":
			_centre_word(big, "ON YOUR MARKS", Kit.PAPER, s.y * 0.38)
		elif phase == "set":
			_centre_word(big, "SET", Kit.PAPER, s.y * 0.34)
			for k in 4:
				var lit := k < count
				var c := Vector2(s.x / 2 - 27 + k * 18, s.y * 0.34 + 26)
				hud.draw_rect(Rect2(c - Vector2(5, 5), Vector2(10, 10)), Kit.INK)
				hud.draw_rect(Rect2(c - Vector2(4, 4), Vector2(8, 8)), Kit.MUSTARD if lit else Color("3a2a4a"))
	# (the aim's dial is drawn by fx: ui/fx.gd _dial)
	for sd in said:
		var k := float(sd.age) / float(sd.life)
		var a2 := 1.0 if k < 0.8 else (1.0 - k) / 0.2
		_centre_word(big, String(sd.text), Color(sd.col, a2), s.y * 0.3 - 6.0 * minf(k * 4.0, 1.0))
	if stage == "after" and stage_t > 0.6 and not bot and meet.kind != "race":
		_centre_word(small, "TAP FOR THE NEXT GO", Kit.PAPER, s.y * 0.62)


func _draw_tag(i: int, player: int, b: Bouncer) -> void:
	var s := get_viewport_rect().size
	var small := Kit.font("small")
	var e: Dictionary = meet.entrants[i]
	var x := 6.0 if player % 2 == 0 else s.x - 100.0
	var y := 6.0 + float(player / 2) * 30.0
	hud.draw_rect(Rect2(x - 2, y - 2, 98, 28), Color(Kit.INK, 0.6))
	hud.draw_texture(Kit.flag(String(e.get("nation", "ngc")), "s"), Vector2(x, y))
	var name := String(e.get("name", "?"))
	hud.draw_string(small, Vector2(x + 18, y + 8), ("P%d " % (player + 1)) + name.split(" ")[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		Kit.player_colour(player))
	# spring: ten lights
	var spring := b.spring if b != null else 0.0
	var hot := b != null and b.sizzling()
	for k in 10:
		var lit := spring * 10.0 > k + 0.2
		var col := Color("3a2a4a")
		if lit:
			col = Kit.KETCHUP if k < 3 else (Kit.MUSTARD if k < 7 else Kit.RELISH)
			if hot and int(Time.get_ticks_msec() / 90) % 2 == 0:
				col = Kit.PAPER
		hud.draw_rect(Rect2(x + k * 9, y + 13, 8, 8), Kit.INK)
		hud.draw_rect(Rect2(x + k * 9 + 1, y + 14, 6, 6), col)


func _centre_word(f: Font, text: String, col: Color, y: float) -> void:
	var s := get_viewport_rect().size
	var fs := 18 if f == Kit.font("big") else 9
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2(roundf(s.x / 2 - w / 2), roundf(y))
	Kit.outlined(hud, f, p, text, fs, col)


## Breaking's note highway: the moves of the round sliding in from the right
## to the hit line. During the call they cross the line as the MC dances them;
## during the answer they're yours to hit there.
func _draw_highway(bt: Battle, t: float) -> void:
	var s := get_viewport_rect().size
	var y := 44.0
	var x0 := 96.0
	var speed := 64.0 / bt.beat.beat_len()        # pixels a second: a beat is 64 pixels
	hud.draw_rect(Rect2(0, y - 12, s.x, 24), Color(Kit.INK, 0.72))
	hud.draw_rect(Rect2(0, y - 12, s.x, 1), Color("7a3ad2"))
	hud.draw_rect(Rect2(0, y + 11, s.x, 1), Color("7a3ad2"))
	# beat lines
	var b0 := floorf(bt.beat.beat_at(t))
	for k in range(-2, 10):
		var bt_t := bt.beat.time_of_beat(b0 + k)
		var x := x0 + (bt_t - t) * speed
		if x > -4 and x < s.x:
			hud.draw_rect(Rect2(roundf(x), y - 10, 1, 20), Color(1, 1, 1, 0.12 if int(b0 + k) % 4 != 0 else 0.3))
	var answering := bt.state == "answer"
	hud.draw_rect(Rect2(x0 - 1, y - 12, 3, 24), Kit.MUSTARD if answering else Kit.SKY)
	var small := Kit.font("small")
	hud.draw_string(small, Vector2(4, y + 3), "YOU" if answering else "MC", HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		Kit.MUSTARD if answering else Kit.SKY)
	for n in bt.highway():
		var x := x0 + (float(n.at) - t) * speed
		if x < -10 or x > s.x + 10:
			continue
		if not answering and float(n.at) > t + 0.02:
			continue                      # the MC's moves appear as they're danced
		var g := String(n.grade)
		var col: Color = Kit.KETCHUP if not bool(n.action) else Kit.SKY
		if g == "miss":
			col = Kit.GREY
		var c := Vector2(roundf(x), y)
		hud.draw_circle(c, 7.0, Kit.INK)
		hud.draw_circle(c, 6.0, col.darkened(0.2))
		hud.draw_circle(c + Vector2(0, -1), 5.0, col)
		var letter := "J" if bool(n.action) else "B"
		hud.draw_string(small, c + Vector2(-2, 4), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Kit.PAPER)
		if g != "" and g != "miss":
			hud.draw_rect(Rect2(c + Vector2(-7, -9), Vector2(14, 1)), Kit.GRADE_COLOURS.get(g, Kit.KETCHUP))


## Skateboarding: the flow meter and combo, and what's coming up on the
## course, as cue cards that close in on their beat.
func _draw_flow(sk: Skate, t: float) -> void:
	var small := Kit.font("small")
	var x := 6.0
	var y := 38.0
	hud.draw_rect(Rect2(x - 2, y - 2, 98, 18), Color(Kit.INK, 0.6))
	hud.draw_string(small, Vector2(x, y + 8), "FLOW", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Kit.GREY)
	for k in 10:
		var lit := sk.flow * 10.0 > k + 0.2
		hud.draw_rect(Rect2(x + 26 + k * 6, y + 1, 5, 7), Kit.MUSTARD if lit else Color("3a2a4a"))
	if sk.combo > 1:
		hud.draw_string(small, Vector2(x, y + 24), "COMBO x%d" % sk.combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Kit.RELISH)
	# what's next, and on which beat
	var n := sk.now_beat(t)
	for f in sk.course:
		var d := float(f.at) - n
		if d < -0.3 or d > 4.0:
			continue
		var label: String = {"cone": "JUMP: OLLIE", "rail": "JUMP: GRIND", "ramp": "JUMP: AIR"}.get(String(f.kind), "")
		var col := Kit.SKY if d > 0.0 else Kit.MUSTARD
		var px := street.screen_x(float(f.at) * sk.SPEED)
		var w := small.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		var ring := clampf(1.0 - d / 4.0, 0.0, 1.0)
		Kit.outlined(hud, small, Vector2(roundf(px - w / 2), roundf(street.floor_y() - 70)), label, 9, Color(col, 0.4 + 0.6 * ring))



## The ski jump's beats in the air (a ring round the jumper closing on each
## beat) and the landing cue.
func _air_cues(sj: SkiJump, t: float) -> void:
	if not Profile.assist or bot:
		return
	var v: AthleteView = views[turn]
	var ph := fposmod(sj.beat.beat_at(t), 1.0)
	fx.rings.append({"p": v.position + Vector2(0, -10), "k": ph, "col": Kit.MUSTARD})
	var gap := sj.y - SkiJump.hill(sj.x)
	if gap < 5.0 and sj.vy < 0.0:
		var small := Kit.font("small")
		Kit.outlined(hud, small, (v.position + Vector2(-12, 14)).round(), "LAND!", 9, Kit.SKY)
