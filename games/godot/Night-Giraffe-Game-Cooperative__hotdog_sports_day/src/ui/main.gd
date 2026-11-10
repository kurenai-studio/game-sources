extends Node
## The front door and the running order: the Night Giraffe splash, the title,
## practice, the championship (six events, the medal table between them, the
## podium at the end), the dressing room, records and settings.
##
## Also the harness for checking the game by eye and by bot:
##   godot -- --shots            screenshots of every screen into res://shots/
##   godot -- --shots --only=hurdles   just one event's
##   godot -- --play             the bot has a go at every event, then quits
##   godot -- --play --champ     the bot plays a whole championship
##   godot -- --event=long_jump  straight into one event's practice
##   godot -- --play --players=4 the bot, four players on this screen (--phones=2: two pretend phones)
##   godot -- --together --loopback   the join screen, listening on this computer only
##   godot -- --event=sprint --wait-phones=1   the event once a phone has joined
##   godot -- --join=127.0.0.1    join another copy's game (--join alone: the list of games;
##                                --auto-tap taps on the beat; --snap=name saves the screen every 2s)
## The checking runs (--shots, --play, --auto-tap) are silent; add --sound to hear them.

const SHOTS_DIR := "res://shots"

var screen: Node
var layer: CanvasLayer
var stage: SubViewport           ## the game's picture, which a joined tablet is sent
var overlay: CanvasLayer         ## on top and not sent: the players' buttons, the splash
var champ: Championship
var bot := false
var _args: PackedStringArray
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	get_window().title = "HotDog Sports Day"
	layer = CanvasLayer.new()
	add_child(layer)
	var box := SubViewportContainer.new()
	box.stretch = true
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Kit.fill(box)
	layer.add_child(box)
	stage = SubViewport.new()
	stage.snap_2d_transforms_to_pixel = true
	stage.snap_2d_vertices_to_pixel = true
	stage.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	box.add_child(stage)
	overlay = CanvasLayer.new()
	overlay.layer = 10
	add_child(overlay)
	Remote.stage = stage
	_rng.randomize()
	_args = OS.get_cmdline_user_args()
	bot = "--play" in _args
	if ("--shots" in _args or bot or "--auto-tap" in _args) and not "--sound" in _args:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	if "--fast" in _args:
		Engine.time_scale = 4.0
	if "--loopback" in _args or "--shots" in _args or bot:
		Remote.bind = "127.0.0.1"
	Remote.verbose = "--remote-log" in _args
	if _arg("--snap=") != "":
		_snap_every(_arg("--snap="))
	for a in _args:
		if a.begins_with("--players="):
			Profile.players = clampi(int(a.trim_prefix("--players=")), 1, 4)
		if a.begins_with("--phones="):
			for k in clampi(int(a.trim_prefix("--phones=")), 0, 3):
				Remote.add_fake(Profile.default_athlete(2 + k % 2))
	var only := ""
	for a in _args:
		if a.begins_with("--event="):
			only = a.trim_prefix("--event=")
	if "--shots" in _args:
		_take_shots.call_deferred()
	elif bot:
		_bot_play.call_deferred()
	elif only != "" and _arg("--wait-phones=") != "":
		_wait_for_phones(int(_arg("--wait-phones=")), only)
	elif only != "":
		_run_event(only, true)
	elif "--together" in _args:
		_together()
	elif _arg("--join") != "" or "--join" in _args:
		var to := _arg("--join=")
		var n := clampi(int(_arg("--join-players=")), 1, 2) if _arg("--join-players=") != "" else Profile.players
		if to == "":
			_join_game()
		else:
			_mirror(to.get_slice(":", 0), (int(to.get_slice(":", 1)) if to.contains(":") else Remote.PORTS[0]) + 1, n)
	else:
		_splash()


## The Android back button: in an event it pauses (the event handles it);
## elsewhere it goes back to the title, and from the title it closes the game.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if screen is EventScreen or screen is Splash or screen is Mirror:
		return
	if screen is Title:
		get_tree().quit()
	else:
		_title()


## Show a screen: on the stage (what a joined tablet sees), or over it.
func _swap(node: Node, on_top := false) -> void:
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = node
	(overlay if on_top else stage).add_child(node)


func _arg(prefix: String) -> String:
	for a in _args:
		if a.begins_with(prefix):
			return a.trim_prefix(prefix)
	return ""


## For trying phones by hand: the join screen until enough have joined, then the event.
func _wait_for_phones(n: int, id: String) -> void:
	_together()
	while Remote.phones.size() < n:
		await get_tree().create_timer(0.25).timeout
	_run_event(id, true)


## Everyone playing: this screen's players, then the phones'.
func _players() -> Array:
	return Remote.looks()


# -- the front door ---------------------------------------------------------------------

func _splash() -> void:
	var s := Splash.new()
	s.finished.connect(_title)
	_swap(s, true)                 # drawn sharp, over the stage


func _title() -> void:
	Remote.set_screen("HOTDOG SPORTS DAY", "ON THE MENU", false)
	var t := Title.new()
	t.chosen.connect(_chosen)
	_swap(t)


func _chosen(what: String) -> void:
	if what.begins_with("dress:"):
		_dress(int(what.trim_prefix("dress:")))
		return
	match what:
		"championship":
			_games()
		"practice":
			_practice()
		"dress":
			_dress()
		"learn":
			_learn()
		"records":
			_records()
		"settings":
			_settings()
		"together":
			_together()


func _practice() -> void:
	var p := Practice.new()
	p.picked.connect(func(id: String): _run_event(id, true))
	p.back.connect(_title)
	_swap(p)


## LEARN TO PLAY: the lessons, and the LEARN MODE switch. `news` is said at
## the top (a lesson done, something unlocked).
func _learn(news := "") -> void:
	Sound.music("title")
	var l := Learn.new()
	l.news = news
	l.picked.connect(_lesson)
	l.back.connect(_title)
	_swap(l)


## A lesson is a real event, the coach talking all the way, against one
## gentle rival.
func _lesson(i: int) -> void:
	var id := String(Learn.LESSONS[i].id)
	var looks := _players()
	var entrants := Championship.entrants_for(id, looks, _rng, looks.size() + 1, "gentle")
	var m := _meet(id, entrants)
	var e := EventScreen.new()
	e.lesson = id
	_swap(e)
	e.start(m, Remote.total(), bot)
	e.quit.connect(func(): _learn())
	e.finished.connect(func(_done: Meet): _learn("" if bot else Learn.finish(id)))
	if bot:
		_bot_tap(e)


func _dress(player := 0) -> void:
	var d := Dressing.new()
	d.player = player
	d.done.connect(_title)
	_swap(d)


func _records() -> void:
	var r := Records.new()
	r.done.connect(_title)
	_swap(r)


func _together() -> void:
	var t := Together.new()
	t.done.connect(_title)
	t.join.connect(func():
		if Remote.phones.is_empty():
			Remote.stop()                  # this one joins; it isn't a host
		_join_game())
	_swap(t)


func _join_game() -> void:
	var j := JoinGame.new()
	j.loopback = Remote.bind == "127.0.0.1"
	j.chosen.connect(func(ip: String, ws_port: int, n: int): _mirror(ip, ws_port, n))
	j.back.connect(_title)
	_swap(j)


## For trying two copies side by side: this one's screen into shots/ now and then.
func _snap_every(name: String) -> void:
	while true:
		await get_tree().create_timer(2.0).timeout
		_shot(name)


## This tablet shows another's game and plays in it.
func _mirror(ip: String, ws_port: int, n: int) -> void:
	var m := Mirror.new()
	m.setup(ip, ws_port, n)
	m.auto_tap = "--auto-tap" in _args
	m.verbose = "--remote-log" in _args
	if _arg("--click-at=") != "":
		var xy := _arg("--click-at=").split(",")
		get_tree().create_timer(5.0).timeout.connect(func():
			m._send({"t": "click", "x": float(xy[0]), "y": float(xy[1]), "d": 1})
			m._send({"t": "click", "x": float(xy[0]), "y": float(xy[1]), "d": 0}))
	m.left.connect(_title)
	_swap(m)


func _settings() -> void:
	var s := Settings.new()
	s.done.connect(_title)
	_swap(s)


# -- events ----------------------------------------------------------------------------

func _meet(id: String, entrants: Array) -> Meet:
	var m := Meet.new()
	m.setup(id, entrants, Profile.level, _rng.randi_range(1, 99999))
	return m


func _run_event(id: String, practice: bool, then: Callable = Callable()) -> void:
	var entrants: Array = champ.entrants() if (not practice and champ) else 		Championship.entrants_for(id, _players(), _rng, 4, Profile.rivals)
	var m := _meet(id, entrants)
	var e := EventScreen.new()
	_swap(e)
	e.start(m, Remote.total(), bot)
	e.quit.connect(func():
		Sound.music("title")
		if practice:
			_practice()
		else:
			_title())
	e.finished.connect(func(done: Meet):
		if then.is_valid():
			then.call(done)
		elif practice:
			_practice()
		else:
			_title())
	if bot:
		_bot_tap(e)


## The bot taps through the event's card for itself.
func _bot_tap(e: EventScreen) -> void:
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(e) and e.stage == "card":
			e._on_press(0, false, Sound.tap_time()))


# -- the Games ------------------------------------------------------------------------------

func _games() -> void:
	var g := Games.new()
	g.start.connect(func(order: Array): _championship(order))
	g.back.connect(_title)
	_swap(g)


func _championship(order: Array = []) -> void:
	champ = Championship.new()
	champ.setup(_players(), Profile.level, 0, order)
	champ.rivals = Profile.rivals
	if bot:
		_next_in_championship()
		return
	Remote.set_screen("OPENING CEREMONY", "TAP THE TABLET TO SKIP", false)
	var o := Opening.new()
	o.setup(_players())
	o.done.connect(_next_in_championship)
	_swap(o)


func _next_in_championship() -> void:
	if champ.over():
		_ceremony()
		return
	_run_event(champ.current(), false, func(m: Meet):
		var r := champ.finish(m)
		_between(r))


## Between events: the medal table, the buns left, what's next.
func _between(r: Dictionary) -> void:
	Remote.set_screen("MEDAL TABLE", "BUNS LEFT: %d" % maxi(champ.buns, 0), false)
	var c := Control.new()
	Kit.fill(c)
	var st := StadiumView.new()
	c.add_child(st)
	st.cam = 40.0
	st.excite = 0.5
	var table := Results.table(champ)
	var box: VBoxContainer = table.get_child(0)
	var buns := Kit.label("BUNS LEFT  " + "♥ ".repeat(maxi(champ.buns, 0)).strip_edges(), "small", Kit.KETCHUP)
	buns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(buns)
	var msg := ""
	if not r.get("any", true):
		msg = "NOT QUALIFIED. LOST A BUN!" if champ.buns > 0 else "OUT OF BUNS!"
	elif not champ.over():
		msg = "NEXT: " + String(Catalog.event(champ.current()).get("name", "")).to_upper()
	else:
		msg = "TO THE PODIUM!"
	if not r.get("any", true) and champ.buns > 0:
		msg += "  TRY AGAIN"
	var l := Kit.label(msg, "small", Kit.MUSTARD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	var go := Kit.button("GO ON", Kit.KETCHUP, "small", 90)
	go.pressed.connect(_next_in_championship)
	box.add_child(go)
	c.add_child(table)
	Kit.centre(table)
	_swap(c)
	go.grab_focus.call_deferred()
	if bot:
		get_tree().create_timer(0.8).timeout.connect(func():
			if is_instance_valid(go):
				_next_in_championship())


func _ceremony() -> void:
	Remote.set_screen("CLOSING CEREMONY", "WELL BOUNCED!", false)
	var p := Podium.new()
	p.setup(champ)
	p.done.connect(func():
		if champ.buns > 0 and not bot:
			Profile.championships += 1
			Wardrobe.count("games")
			Wardrobe.check()
			Profile.save()
		if bot:
			print("championship over: ", champ.table())
			get_tree().quit(0)
			return
		_title())
	_swap(p)


# -- the bot -------------------------------------------------------------------------------

func _bot_play() -> void:
	if "--champ" in _args:
		_championship()
		return
	var ids: Array = Catalog.order()
	for a in _args:
		if a.begins_with("--event="):
			ids = Array(a.trim_prefix("--event=").split(","))
	_bot_next(ids, 0)


func _bot_next(ids: Array, k: int) -> void:
	if k >= ids.size():
		print("bot: all events played")
		get_tree().quit(0)
		return
	_run_event(String(ids[k]), true, func(m: Meet):
		var line := "bot: %s " % m.id
		for i in m.standings():
			line += "%s=%s " % [String(m.entrants[i].name).split(" ")[0], Catalog.show_mark(m.id, m.best(i))]
		print(line)
		_bot_next(ids, k + 1))


# -- screenshots ---------------------------------------------------------------------------

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS_DIR))
	img.save_png("%s/%s.png" % [SHOTS_DIR, name])
	var big := img.duplicate()
	big.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	big.save_png("%s/%s_x3.png" % [SHOTS_DIR, name])
	print("shot ", name)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _take_shots() -> void:
	var only := ""
	for a in _args:
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	bot = true
	var want: PackedStringArray = only.split(",", false)
	if want.is_empty() or "title" in want:
		_title()
		await _wait(1.2)
		await _shot("title")
		_practice()
		await _wait(0.5)
		await _shot("practice")
		_dress()
		await _wait(0.5)
		await _shot("dress")
		for t in [3, 6, 8]:
			(screen as Dressing)._open(t)
			await _wait(0.4)
			await _shot("dress_%d" % t)
		# and with everything unlocked (not saved)
		var had: Array = Profile.unlocked
		Profile.unlocked = Wardrobe.items().map(func(it): return "%s:%s" % [it.slot, it.id])
		for t in [0, 1, 2, 4]:
			_dress()
			(screen as Dressing)._open(t)
			await _wait(0.6)
			await _shot("dress_all_%d" % t)
		Profile.unlocked = had
		_learn()
		await _wait(0.5)
		await _shot("learn")
		_games()
		await _wait(0.5)
		await _shot("games")
		_records()
		await _wait(0.5)
		await _shot("records")
		_together()
		await _wait(1.0)
		await _shot("together")
		_settings()
		await _wait(0.5)
		await _shot("settings")
		_join_game()
		await _wait(0.5)
		await _shot("join")
		(screen as JoinGame)._scan()
		await _wait(4.0)
		await _shot("scan")
		# the Games: the medal table between events, and the podium
		champ = Championship.new()
		champ.setup(_players(), Profile.level, 3, ["sprint", "long_jump", "hurdles"])
		var mt := Meet.new()
		mt.setup("sprint", champ.entrants(), Profile.level, 3)
		mt.record_race({0: 11.0, 1: 12.0, 2: 13.0, 3: 14.0})
		_between(champ.finish(mt))
		await _wait(0.6)
		await _shot("between")
		# a scoreboard that unlocked things
		var bc := Control.new()
		Kit.fill(bc)
		var bst := StadiumView.new()
		bc.add_child(bst)
		bc.add_child(Results.board(mt, [{"slot": "hat", "id": "viking", "name": "Viking Helmet"},
			{"slot": "hat", "id": "pirate", "name": "Pirate Hat"}, {"slot": "specs", "id": "hearts", "name": "Heart Specs"}]))
		_swap(bc)
		await _wait(0.4)
		await _shot("board_new")
		var pod := Podium.new()
		pod.setup(champ)
		_swap(pod)
		await _wait(5.0)
		await _shot("podium")
		champ = null
		_title()
		var o := Opening.new()
		o.setup(_players())
		_swap(o)
		await _wait(6.0)
		await _shot("opening")
	if "lesson" in want:
		for i in Learn.LESSONS.size():
			_lesson(i)
			await _wait([7.0, 8.0, 7.0][i])
			await _shot("lesson_%d" % i)
			await _wait(1.2)
			await _shot("lesson_%db" % i)
	for id in Catalog.order():
		if not want.is_empty() and not id in want:
			continue
		var m := _meet(id, Championship.entrants_for(id, _players(), _rng))
		var e := EventScreen.new()
		_swap(e)
		e.start(m, Remote.total(), true)
		await _wait(0.6)
		await _shot(id + "_card")
		e._on_press(0, false, Sound.tap_time())
		var times := {"sprint": [4.0, 7.5], "hurdles": [5.0, 8.4], "long_jump": [6.6, 8.3], "triple_jump": [6.0, 7.6],
			"high_jump": [5.0, 6.2], "dive": [4.5, 6.4], "relay": [7.0, 9.0], "steeplechase": [11.0, 12.6],
			"meatball_put": [6.0, 7.6], "vault": [6.4, 7.2], "swim": [9.0, 12.0], "trampoline": [12.0, 14.3],
			"breaking": [9.5, 13.5], "skateboard": [9.0, 12.5], "ski_jump": [10.0, 12.0], "bobsleigh": [8.5, 11.5]}
		var at: Array = times.get(id, [5.0, 7.0])
		await _wait(float(at[0]))
		await _shot(id + "_play")
		await _wait(float(at[1]) - float(at[0]))
		await _shot(id + "_play2")
		# the aim's dial, if this event has one: the next time a go is held
		if String(Catalog.event(id).kind) in ["jump", "high", "throw"]:
			var wait := 0
			while is_instance_valid(e) and wait < 600 and not (e.attempt != null and "b" in e.attempt 					and e.attempt.b.state == "hold" and e.attempt.b.hold_angle(Sound.song_time()) > 20.0):
				wait += 1
				await get_tree().process_frame
			if is_instance_valid(e):
				await _shot(id + "_aim")
		var guard := 0
		while is_instance_valid(e) and e.stage != "board" and guard < 400:
			guard += 1
			await _wait(0.1)
		await _wait(0.3)
		if is_instance_valid(e):
			await _shot(id + "_board")
	print("shots done")
	get_tree().quit(0)
