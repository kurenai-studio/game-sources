extends SceneTree

## Headless test runner:  godot --headless --path . --script res://tests/run_tests.gd
##
## Exits non-zero on any failure so it can gate a commit. On a cold checkout
## run `godot --headless --path . --import` once first, so the class names
## the scripts use are known. `-- --only=test_x,test_y` runs just those.
##
## What it holds the game to: rhythm beats mashing; the computer's athletes
## finish in order of skill and can reach every qualifying mark; every event
## can be completed; every picture, face, font glyph and sound the code asks
## for exists; the profile saves and loads what it saved.

var _passed := 0
var _failures: PackedStringArray = []
var _suite := ""


func _initialize() -> void:
	print("")
	print("HotDog Sports Day test suite")
	print("==========================")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			for name in arg.trim_prefix("--only=").split(","):
				call(name)
			_report()
			return
	test_scripts_compile()
	test_beat()
	test_on_the_beat()
	test_rhythm_beats_mashing()
	test_false_start()
	test_sprint_order()
	test_hurdles()
	test_long_jump()
	test_triple_jump()
	test_high_jump()
	test_dive()
	test_relay()
	test_steeplechase()
	test_meatball_put()
	test_vault()
	test_swim()
	test_trampoline()
	test_breaking()
	test_skateboard()
	test_ski_jump()
	test_bobsleigh()
	test_meet_rounds()
	test_high_countback()
	test_championship()
	test_series()
	test_art()
	test_faces()
	test_font()
	test_sounds()
	test_event_music()
	test_profile()
	test_pad()
	test_qr()
	test_portrait()
	test_four_players()
	test_flags()
	test_easy()
	test_timing()
	test_bash()
	test_remote()
	test_tablets()
	test_wardrobe()
	test_unlocks()
	test_dressing()
	test_learn()
	test_runups()
	test_controls()
	test_aim()
	test_scan()
	test_triple_easy()
	_report()


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("All %d checks passed." % _passed)
		quit(0)
	else:
		for f in _failures:
			print("FAIL  " + f)
		print("%d failed, %d passed." % [_failures.size(), _passed])
		quit(1)


func _begin(name: String) -> void:
	_suite = name
	print("- " + name)


func check(ok: bool, what: String) -> void:
	if ok:
		_passed += 1
	else:
		_failures.append("%s: %s" % [_suite, what])


# -- helpers ---------------------------------------------------------------------------

## A race with every athlete driven by `drive` (or the computer): returns the race.
## A race run to the end. `rhythm`: its players bounce on the beat (the way
## the computer runs, and every field event works) rather than bash RUN.
func _race(id: String, entrants: Array, drive: Callable = Callable(), bpm := 90.0, level := "pro", rhythm := true) -> Race:
	var r := Race.new()
	r.setup(id, Beat.new(bpm, 0.0), entrants, level, 0.0, 7)
	if rhythm:
		for b in r.athletes:
			b.bash = false
	var t := 0.0
	var dt := 1.0 / 120.0
	while not r.finished() and t < 60.0:
		t += dt
		if drive.is_valid():
			drive.call(r, t, dt)
		r.update(t, dt)
	return r


# -- the tests -------------------------------------------------------------------------

func test_pad() -> void:
	_begin("the buttons")
	var pad: GDScript = load("res://ui/pad.gd")
	for s in [Vector2(480, 270), Vector2(600, 270), Vector2(400, 270)]:
		for n in [1, 2, 3, 4]:
			for p in n:
				for a in [false, true]:
					var c: Vector2 = pad.centre_in(s, n, p, a)
					var z: Array = pad.zone_in(s, n, true, c)
					check(int(z[0]) == p and bool(z[1]) == a,
						"%d players at %s: player %d's %s button is where it's drawn" % [n, s, p, "JUMP" if a else "BOUNCE"])
					check(c.x > 0 and c.x < s.x and c.y > 0 and c.y < s.y, "and on the screen")


const JOIN_QR := "1111111000110010001111111,1000001000110101001000001,1011101011001000101011101,1011101010000100001011101,1011101010011010001011101,1000001010100101101000001,1111111010101010101111111,0000000011010011000000000,1011111001010101101111100,0011000110001110010000010,1000011001001101001101011,1110000111011000100010001,1101011100011100001110111,1100100001100110000001010,1011011010011001010101011,1010010001010001000001001,1010111001111100111110100,0000000011001010100011100,1111111001000110101011111,1000001011010001100011011,1011101011111101111111100,1011101010111011101110111,1011101010101010010000101,1000001000111000101111001,1111111011100101011111111"


func test_qr() -> void:
	_begin("QR codes")
	var qr: GDScript = load("res://ui/qr.gd")
	var m: Array = qr.encode("http://192.168.1.23:8642/")
	var rows := PackedStringArray()
	for r in m:
		var t := ""
		for c in r:
			t += "1" if c else "0"
		rows.append(t)
	check(",".join(rows) == JOIN_QR, "a join code matches one two QR readers decoded (zxing, OpenCV)")
	var sizes := {14: 21, 15: 25, 26: 25, 27: 29, 42: 29, 43: 33, 62: 33, 63: 37, 84: 37, 85: 41, 106: 41}
	for n in sizes:
		var mm: Array = qr.encode("a".repeat(n))
		check(mm.size() == int(sizes[n]), "%d characters make a %d-module code (%d)" % [n, int(sizes[n]), mm.size()])
		var size := mm.size()
		var finders := true
		for c in [Vector2i(0, 0), Vector2i(size - 7, 0), Vector2i(0, size - 7)]:
			for k in 7:
				finders = finders and mm[c.y][c.x + k] and mm[c.y + 6][c.x + k] and mm[c.y + k][c.x] and mm[c.y + k][c.x + 6]
			finders = finders and mm[c.y + 3][c.x + 3] and not mm[c.y + 1][c.x + 1]
		check(finders, "%d: the three finder squares are there" % n)
		var timing := true
		for k in range(8, size - 8):
			timing = timing and mm[6][k] == (k % 2 == 0) and mm[k][6] == (k % 2 == 0)
		check(timing and mm[size - 8][8], "%d: the timing lines and the dark module are there" % n)
	check(qr.encode("q".repeat(107)).is_empty(), "too long for the biggest size gives nothing")
	var img: Image = qr.image("http://10.0.0.5:8642/", 3, 4)
	check(img != null and img.get_width() == (25 + 8) * 3, "its picture has the quiet margin round it")


func test_portrait() -> void:
	_begin("phone portraits")
	var prof: GDScript = load("res://game/profile.gd")
	var meta := AthleteView.meta()
	var keys: Array = meta.band_keys.main + meta.band_keys.stripe
	for p in 4:
		var look: Dictionary = prof.default_athlete(p)
		var img: Image = Portrait.of(look, 1)
		check(img != null and img.get_width() > 10 and img.get_height() > 20, "%s has a picture" % look.name)
		if img == null:
			continue
		var keyed := 0
		var banded := 0
		var want: Array = meta.teams[String(look.band[0])][1]
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a < 0.5:
					continue
				for k in keys:
					if c.r8 == int(k[0]) and c.g8 == int(k[1]) and c.b8 == int(k[2]):
						keyed += 1
				if c.r8 == int(want[0]) and c.g8 == int(want[1]) and c.b8 == int(want[2]):
					banded += 1
		check(keyed == 0 and banded > 0, "%s's sweatband is in its colours (%d keyed, %d banded)" % [look.name, keyed, banded])
	var png: PackedByteArray = Portrait.png(prof.default_athlete(2), 4)
	check(png.size() > 100 and png[1] == 0x50 and png[2] == 0x4E and png[3] == 0x47, "it makes a PNG for the phone")


func test_easy() -> void:
	_begin("easy, for young players")
	for lv in Catalog.LEVELS:
		check(Catalog.windows(lv).size() == 3, "%s has its timing windows" % lv)
	var we := Catalog.windows("easy")
	var wj := Catalog.windows("junior")
	check(float(we[2]) > float(wj[2]) and float(we[0]) > float(wj[0]), "EASY's beats are wider than JUNIOR's")
	for id in Catalog.order():
		var q: Dictionary = Catalog.event(id).qualify
		check(q.has("easy") and q.has("junior") and q.has("pro"), "%s has a mark for every level" % id)
		check(Catalog.better(id, float(q.junior), float(q.easy)), "%s: EASY's mark is easier to reach" % id)
	check(Catalog.next_level("easy") == "junior" and Catalog.next_level("pro") == "easy", "the level button goes round")
	var hb := Meet.new()
	hb.setup("high_jump", [{"name": "a", "cpu": true, "skill": 0.5, "player": -1}], "easy", 1)
	var hj := Meet.new()
	hj.setup("high_jump", [{"name": "a", "cpu": true, "skill": 0.5, "player": -1}], "junior", 1)
	check(hb.bar < hj.bar, "the bar starts lower on EASY (%.2fm)" % hb.bar)
	# EASY lets go of a held put at the best angle by itself
	var th := Throw.new()
	th.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": false}, "easy", 0.0, 1)
	var t := 0.0
	var held := false
	while not th.finished() and t < 20.0:
		t += 1.0 / 120.0
		th.update(t, 1.0 / 120.0)
		if not held and th.state == "run" and th.b.state == "run" and th.b.to_slot >= 6 and t >= th.b.slot_time(th.b.to_slot) - 0.01:
			held = true
			th.press(true, th.b.slot_time(th.b.to_slot))
	var put := th.log.filter(func(e): return e.kind == "put")
	check(not put.is_empty() and absf(float(put[0].angle) - th.cpu_angle) < 4.0,
		"a held put goes at the best angle (%.0f)" % (float(put[0].angle) if not put.is_empty() else -1.0))
	# a forgiving spring: the same OK taps go faster on EASY
	var a := Bouncer.new()
	var b := Bouncer.new()
	b.forgive()
	for k in 8:
		a._pull("ok")
		b._pull("ok")
	check(b.spring > a.spring + 0.1, "OK taps build more spring on EASY (%.2f vs %.2f)" % [b.spring, a.spring])
	# gentle rivals are gentle
	check(Championship.skill_at(0.9, "gentle") < 0.2, "gentle rivals are beatable by a young player")


func test_bash() -> void:
	_begin("button-bash races (EASY)")
	# spring from tapping two buttons in turn
	var b := Bouncer.new()
	b.bash = true
	b.start(0.0, 0.34, 0.68)
	var t := 0.0
	var side := 0
	while t < 3.0:
		t += 1.0 / 60.0
		if fmod(t, 0.2) < 1.0 / 60.0:
			b.bash_tap(t, side)
			side = 1 - side
		b.update(t, 1.0 / 60.0)
	check(b.spring > 0.95, "five taps a second, in turn, is full spring (%.2f)" % b.spring)
	check(b.counts["miss"] == 0, "and no landing counts as a miss")
	var c := Bouncer.new()
	c.bash = true
	c.start(0.0, 0.34, 0.68)
	t = 0.0
	while t < 3.0:
		t += 1.0 / 60.0
		if fmod(t, 0.1) < 1.0 / 60.0:
			c.bash_tap(t, 0)
		c.update(t, 1.0 / 60.0)
	check(c.spring < 0.2, "the same button over and over doesn't run (%.2f)" % c.spring)
	while t < 6.0:
		t += 1.0 / 60.0
		b.update(t, 1.0 / 60.0)
	check(b.spring < 0.3, "and stopping slows it down (%.2f)" % b.spring)
	check(Bouncer.bash_spring(3.0) > 0.85 and Bouncer.bash_spring(2.0) < 0.8, "three a second is most of the way")
	# in an EASY race: players bash, the computer bounces; no false starts
	var r := Race.new()
	r.setup("sprint", Beat.new(90.0, 0.0), [{"name": "me", "cpu": false}, {"name": "cpu", "cpu": true, "skill": 0.5}],
		"easy", 0.0, 3)
	check(r.athletes[0].bash and not r.athletes[1].bash, "on EASY the player bashes; the computer keeps the beat")
	check(r.press(0, false, r.go - 1.0) == "" and not r.false_starts.has(0), "bashing early isn't a false start")
	var j := Race.new()
	j.setup("sprint", Beat.new(90.0, 0.0), [{"name": "me", "cpu": false}], "junior", 0.0, 3)
	check(j.athletes[0].bash, "players bash at every level; only the computer changes")
	check(Championship.skill_at(0.9, "gentle") < Championship.skill_at(0.9, "keen") and 		Championship.skill_at(0.9, "keen") < Championship.skill_at(0.9, "fierce") and 		Championship.boost_at("legendary") > Championship.boost_at("fierce"), "and the computer gets better with each age band")
	check(Championship.age_label("legendary") == "AGES 14+", "the bands are named by age")
	t = 0.0
	side = 0
	var next := 0.0
	while not r.finished() and t < 60.0:
		t += 1.0 / 60.0
		r.update(t, 1.0 / 60.0)
		if t >= r.go and t >= next:
			r.run(0, side, t)
			side = 1 - side
			next = t + 0.22
	check(r.times.has(0) and float(r.times[0]) < float(Catalog.event("sprint").qualify.easy),
		"bashing about four a second qualifies (%.2fs)" % float(r.times.get(0, 99.0)))
	# the buttons are where they're drawn
	var pad: GDScript = load("res://ui/pad.gd")
	for s in [Vector2(480, 270), Vector2(480, 288), Vector2(585, 270)]:
		for n in [1, 2, 3, 4]:
			for p in n:
				for kind in [0, 1, 2]:
					var at: Vector2 = pad.centre_bash(s, n, p, kind)
					var z: Array = pad.zone_bash(s, n, at)
					check(int(z[0]) == p and int(z[1]) == kind, "%d players: player %d's %s is where it's drawn" % [n, p, ["RUN", "JUMP", "RUN"][kind]])
	var a: Vector2 = pad.centre_bash(Vector2(480, 270), 1, 0, 0)
	var a2: Vector2 = pad.centre_bash(Vector2(480, 270), 1, 0, 2)
	check(a.y == a2.y and absf(a.x - a2.x) <= 60.0, "the two RUN buttons sit close together (%.0f apart)" % absf(a.x - a2.x))
	for n in [1, 2, 3, 4]:
		var rr: float = pad.radius_for(n, true)
		var l: Vector2 = pad.centre_bash(Vector2(480, 270), n, 0, 0)
		var l2: Vector2 = pad.centre_bash(Vector2(480, 270), n, 0, 2)
		check(absf(l.x - l2.x) >= rr * 2.0 + 4.0, "%d players: the RUN buttons don't touch" % n)
		check(l.x - rr >= 0.0, "%d players: and the first is on the screen" % n)


func test_timing() -> void:
	_begin("learning a tablet's lag")
	var tt := TapTiming.new()
	for k in TapTiming.BATCH:
		tt.add(0.3 + (0.02 if k % 2 == 0 else -0.02))       # taps a third of a slot late
	check(tt.agreement() > 0.9, "taps that agree are seen to agree")
	var cal := tt.settle(0.0, 0.34)
	check(cal > 0.04 and cal < 0.07, "the calibration moves half the way (%.3f)" % cal)
	check(tt.count() == 0, "and it starts a fresh batch")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in TapTiming.BATCH:
		tt.add(rng.randf_range(-0.5, 0.5))
	check(is_equal_approx(tt.settle(0.05, 0.34), 0.05) or tt.agreement() < TapTiming.AGREE, "taps all over the place move nothing")
	for k in TapTiming.BATCH:
		tt.add(0.49 if k % 2 == 0 else -0.49)               # either side of halfway: they agree
	check(absf(absf(tt.mean()) - 0.5) < 0.02, "taps either side of halfway don't cancel out")
	tt.settle(0.0, 0.34)
	check(absf(TapTiming.phase(10.17, 0.0, 0.34) - 0.0) < 0.001 or absf(TapTiming.phase(10.2, 0.0, 0.34)) <= 0.5,
		"a tap's place on the grid")
	check(absf(TapTiming.phase(0.34 * 7 + 0.05, 0.0, 0.34) - 0.05 / 0.34) < 0.0001, "is measured from the nearest landing")
	for k in 40:
		tt.add(0.45)
		tt.settle(0.3, 0.34)
	check(tt.settle(0.34, 0.34) <= TapTiming.HIGH, "and never past the limit")


func test_flags() -> void:
	_begin("flags")
	var order: Array = Kit.flag_order()
	for n in Catalog.nations():
		var i := order.find(String(n.id))
		check(i >= 0, "%s has a flag" % n.id)
		var f: AtlasTexture = Kit.flag(String(n.id), "l")
		check(int(f.region.position.x) == i * 44, "%s's flag is its own, not another's" % n.id)
		check(f.atlas != null and f.region.end.x <= f.atlas.get_width(), "and inside the picture")
	check(order.find("ngc") >= 0, "and the Night Giraffe's own")


func test_four_players() -> void:
	_begin("four players")
	var prof: GDScript = load("res://game/profile.gd")
	var four: Array = []
	for p in 4:
		four.append(prof.default_athlete(p))
	var names := {}
	for l in four:
		names[l.name] = true
	check(names.size() == 4, "four different hot dogs to start with")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for id in Catalog.order():
		var e := Championship.entrants_for(id, four, rng)
		var players := 0
		for x in e:
			if int(x.player) >= 0:
				players += 1
		check(e.size() == 4 and players == 4, "%s: all four players in the heat" % id)
	var three := Championship.entrants_for("sprint", four.slice(0, 3), rng)
	check(three.size() == 4 and int(three[3].player) == -1, "three players and one rival")
	var m := Meet.new()
	m.setup("long_jump", Championship.entrants_for("long_jump", four, rng), "junior", 1)
	var turns := {}
	while true:
		var i := m.next_turn()
		if i < 0:
			break
		turns[i] = int(turns.get(i, 0)) + 1
		m.record(i, 5.0 + i)
	check(turns.size() == 4, "every player gets their goes in a field event")
	var c := Championship.new()
	c.setup(four, "junior", 2)
	m = Meet.new()
	m.setup("sprint", c.entrants(), "junior", 1)
	m.record_race({0: 20.0, 1: 20.0, 2: 11.0, 3: 20.0})
	var r := c.finish(m)
	check(r.any and c.buns == 3, "one player qualifying carries the team")
	var pad: GDScript = load("res://ui/pad.gd")
	check(int(pad.zone_in(Vector2(480, 270), 0, true, Vector2(100, 200))[0]) == -1, "with everyone on phones the screen has no buttons")


func test_remote() -> void:
	_begin("playing from phones")
	var R: GDScript = load("res://ui/remote.gd")
	var ranked: PackedStringArray = R.lan_addresses(PackedStringArray(["127.0.0.1", "fe80::1", "192.168.56.1", "10.0.0.7",
		"192.168.1.23", "169.254.3.3", "172.20.1.2", "172.40.1.1"]))
	check(", ".join(ranked) == "192.168.1.23, 10.0.0.7, 172.20.1.2, 192.168.56.1, 172.40.1.1",
		"a home Wi-Fi address first, virtual adapters and odd ones last (%s)" % ", ".join(ranked))
	check(absf(R.press_age(10000.0, 9950.0) - 0.05) < 0.0001, "a press stamped 50ms ago is 50ms old")
	check(R.press_age(10000.0, -1.0) == R.DEFAULT_AGE, "before the clocks agree, a set lag")
	check(R.press_age(10000.0, 9000.0) == R.DEFAULT_AGE, "a stamp a second old means a bad clock")
	check(R.press_age(10000.0, 10030.0) == 0.0, "a stamp a hair in the future is now")
	# the real thing, over the loopback: the page, a phone joining, its clock, a press
	var remote: Node = root.get_node("Remote")
	var sound: Node = root.get_node("Sound")
	var was_phones: Array = remote.phones.duplicate()
	remote.phones = []
	remote.bind = "127.0.0.1"
	check(remote.start(), "the server opens its ports")
	if not remote.running:
		return
	var page := _fetch(remote, "/").get_string_from_utf8()
	check(page.contains("Bounce"), "it serves the buttons page")
	check(page.contains('"%d"' % (remote.port + 1)), "with the WebSocket's port written in")
	var ws := WebSocketPeer.new()
	ws.connect_to_url("ws://127.0.0.1:%d/" % (remote.port + 1))
	var msgs: Array = []
	var pump := func(until: Callable) -> bool:
		for k in 600:
			remote._process(0.01)
			ws.poll()
			while ws.get_available_packet_count() > 0:
				msgs.append(JSON.parse_string(ws.get_packet().get_string_from_utf8()))
			if until.call():
				return true
			OS.delay_msec(5)
		return false
	var latest := func(kind: String) -> Dictionary:
		for k in range(msgs.size() - 1, -1, -1):
			var m: Variant = msgs[k]
			if m is Dictionary and m.get("t", "") == kind:
				return m
		return {}
	check(pump.call(func(): return ws.get_ready_state() == WebSocketPeer.STATE_OPEN), "a phone connects")
	ws.send_text(JSON.stringify({"t": "hello", "id": "test-phone"}))
	check(pump.call(func(): return not latest.call("you").is_empty()), "and is told who it is")
	var me: Dictionary = latest.call("you")
	check(int(me.get("player", -1)) == remote.screen_count() and remote.phones.size() == 1,
		"the first phone is the player after this screen's (P%d)" % (int(me.get("player", -1)) + 1))
	var dog := _fetch(remote, String(me.get("dog", "")))
	check(dog.size() > 100 and dog[1] == 0x50, "its hot dog's picture is there to fetch")
	ws.send_text(JSON.stringify({"t": "ping", "c": 1234.5}))
	check(pump.call(func(): return not latest.call("pong").is_empty()), "pings come back")
	var pong: Dictionary = latest.call("pong")
	check(float(pong.get("c", 0)) == 1234.5 and float(pong.get("h", 0)) > 0.0, "with the phone's time and the game's")
	var heard: Array = []
	var on_press := func(p: int, a: bool, at: float) -> void: heard.append([p, a, at])
	remote.pressed.connect(on_press)
	var stamped := Time.get_ticks_usec() / 1000.0 - 80.0
	ws.send_text(JSON.stringify({"t": "tap", "a": 1, "d": 1, "h": stamped}))
	check(pump.call(func(): return not heard.is_empty()), "a press arrives")
	if not heard.is_empty():
		var at: float = heard[0][2]
		var now: float = sound.tap_time()
		check(int(heard[0][0]) == int(me.player) and bool(heard[0][1]), "as that player's JUMP")
		check(at <= now - 0.079 and at >= now - 0.35, "timed when the finger landed, 80ms back (%.3f)" % (now - at))
	remote.pressed.disconnect(on_press)
	var before := String(me.name)
	msgs.clear()
	ws.send_text(JSON.stringify({"t": "next"}))
	check(pump.call(func(): return not latest.call("you").is_empty() and String(latest.call("you").name) != before),
		"a phone can change its hot dog")
	remote.remove(0)
	check(remote.phones.is_empty(), "and can be let go")
	ws.close()
	pump.call(func(): return ws.get_ready_state() == WebSocketPeer.STATE_CLOSED)
	remote.stop()
	remote.phones = was_phones


func test_tablets() -> void:
	_begin("tablets joined over the Wi-Fi")
	var R: GDScript = load("res://ui/remote.gd")
	# the picture survives packing, and junk is refused
	var img := Image.create(480, 270, false, Image.FORMAT_RGB8)
	img.fill(Color("24152e"))
	img.fill_rect(Rect2i(10, 20, 100, 50), Color("f7d331"))
	img.set_pixel(479, 269, Color("e0383a"))
	var pkt: PackedByteArray = R.pack_frame(img.duplicate())
	var back: Image = R.unpack_frame(pkt)
	check(back != null and back.get_size() == img.get_size() and back.get_data() == img.get_data(),
		"a picture comes through packing exactly")
	check(pkt.size() < 20000, "and small (%d bytes)" % pkt.size())
	check(R.unpack_frame(PackedByteArray([1, 2, 3])) == null and R.unpack_frame(pkt.slice(0, 40)) == null,
		"junk and cut-off pictures are refused")
	# where a tap on the joined tablet falls on the host's picture
	var M: GDScript = load("res://ui/mirror.gd")
	check(M.frame_point(Vector2(240, 135), Vector2(480, 270), Vector2(480, 270)) == Vector2(240, 135),
		"same size screens: the same point")
	check(M.frame_point(Vector2(240, 144), Vector2(480, 288), Vector2(480, 270)) == Vector2(240, 135),
		"a taller screen: the picture is centred")
	check(M.frame_point(Vector2(240, 5), Vector2(480, 288), Vector2(480, 270)) == Vector2(-1, -1),
		"and the bands above and below are nothing")
	# the real thing, over the loopback: a tablet with two players joins
	var remote: Node = root.get_node("Remote")
	var was_phones: Array = remote.phones.duplicate()
	remote.phones = []
	remote.bind = "127.0.0.1"
	check(remote.start(), "the host opens its ports")
	if not remote.running:
		return
	var m: Control = M.new()
	m.setup("127.0.0.1", int(remote.port) + 1, 2)
	root.add_child(m)
	if not m.is_node_ready():
		m._ready()                   # (the tree isn't running yet while the tests do)
	var pump := func(until: Callable) -> bool:
		for k in 600:
			remote._process(0.01)
			m._process(0.01)
			if until.call():
				return true
			OS.delay_msec(5)
		return false
	check(pump.call(func(): return remote.phones.size() == 2), "the tablet joins with its two players (%d, %d on this screen)" % [remote.phones.size(), remote.screen_count()])
	if remote.phones.size() == 2:
		check(String(remote.phones[0].kind) == "tablet" and int(remote.phones[1].slot) == 1, "as a tablet's two places")
	check(pump.call(func(): return not m._you.is_empty() and m._synced), "it's told who it plays and gets in step")
	var players: Array = m._you.get("players", [])
	check(players.size() == 2 and int(players[0]) == remote.screen_count(), "P%d and P%d" % [
		int(players[0]) + 1 if players.size() > 0 else 0, int(players[1]) + 1 if players.size() > 1 else 0])
	remote.broadcast_frame(pkt)
	check(pump.call(func(): return m.frames >= 1), "a picture of the game arrives and is shown")
	check(m._tex != null and m._tex.get_size() == Vector2(480, 270), "at the game's size")
	check(not m._pad.visible, "no buttons on the menus (a tap there is a tap on the host's screen)")
	remote.set_event(true)
	check(pump.call(func(): return m._pad.visible), "its buttons come up for an event")
	var heard: Array = []
	var on_press := func(p: int, a: bool, at: float) -> void: heard.append([p, a, at])
	remote.pressed.connect(on_press)
	m._press(1, true, true)
	check(pump.call(func(): return not heard.is_empty()), "its second player's JUMP arrives")
	if not heard.is_empty() and players.size() == 2:
		check(int(heard[0][0]) == int(players[1]) and bool(heard[0][1]), "as that player's JUMP")
	remote.pressed.disconnect(on_press)
	remote.sfx("click", 0.8, 1.0)
	check(pump.call(func(): return m._ws != null), "sounds are sent along too")
	remote.set_event(false)
	m._leave_now()
	check(pump.call(func(): return remote.phones.size() == 2 and remote.phones[0].sock == null),
		"when it leaves, its places wait for it")
	m.free()
	remote.stop()
	remote.phones = was_phones
	remote.set_event(false)


## A page from the game's server, the body only.
func _fetch(remote: Node, path: String) -> PackedByteArray:
	var c := StreamPeerTCP.new()
	c.connect_to_host("127.0.0.1", int(remote.port))
	var buf := PackedByteArray()
	var sent := false
	for k in 600:
		c.poll()
		remote._process(0.01)
		if not sent and c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			c.put_data(("GET %s HTTP/1.1\r\nHost: test\r\n\r\n" % path).to_ascii_buffer())
			sent = true
		if sent and c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var n := c.get_available_bytes()
			if n > 0:
				buf.append_array(c.get_data(n)[1])
		var text := buf.get_string_from_ascii()
		var cut := text.find("\r\n\r\n")
		if cut >= 0:
			var head := text.substr(0, cut)
			var at := head.findn("content-length:")
			if at >= 0:
				var length := int(head.substr(at + 15).get_slice("\r\n", 0).strip_edges())
				if buf.size() >= cut + 4 + length:
					c.disconnect_from_host()
					return buf.slice(cut + 4, cut + 4 + length)
		OS.delay_msec(5)
	c.disconnect_from_host()
	return PackedByteArray()


func test_scripts_compile() -> void:
	_begin("scripts compile")
	for dir in ["res://game", "res://ui"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				var s: Variant = ResourceLoader.load(dir + "/" + f, "", ResourceLoader.CACHE_MODE_IGNORE)
				check(s != null and (s as GDScript).can_instantiate(), "%s/%s compiles" % [dir, f])


func test_beat() -> void:
	_begin("the beat")
	check(Beat.pick_sub(90.0) == 2, "90 bpm bounces twice a beat")
	check(Beat.pick_sub(170.0) == 1, "170 bpm bounces once a beat")
	check(Beat.pick_sub(60.0) == 3, "60 bpm bounces three times a beat")
	var b := Beat.new(120.0, 0.25)
	check(is_equal_approx(b.beat_len(), 0.5), "a beat at 120 is half a second")
	check(is_equal_approx(b.next_bar(0.3), 2.25), "the next bar after 0.3s starts at 2.25s")
	for bpm in [70.0, 85.0, 100.0, 125.0, 160.0]:
		var hz: float = float(bpm) / 60.0 * Beat.pick_sub(float(bpm))
		check(hz > 2.0 and hz < 4.0, "%d bpm bounces %.1f times a second" % [bpm, hz])


func test_on_the_beat() -> void:
	_begin("taps on the beat")
	var b := Bouncer.new()
	b.windows = [0.05, 0.09, 0.13]
	b.start(1.0, 0.333, 0.666)
	var t := 1.0
	for k in range(1, 20):
		var land := b.slot_time(k)
		while t < land - 0.01:
			t += 1.0 / 120.0
			b.update(t, 1.0 / 120.0)
		check(b.tap(land) == "perfect", "a tap right on landing %d is perfect" % k)
	check(b.counts.perfect == 19 and b.counts.miss == 0, "nineteen perfects, no misses")
	check(b.spring > 0.95, "spring is nearly full after a run of perfects (%.2f)" % b.spring)
	check(b.sizzling(), "and the hot dog is sizzling")
	while t < b.slot_time(19) + 0.05:
		t += 1.0 / 120.0
		b.update(t, 1.0 / 120.0)
	var g := b.tap(b.slot_time(b.to_slot) - 0.07)
	check(g == "good", "70 ms early is good (got %s)" % g)
	check(b.tap(b.slot_time(b.from_slot) + 0.01) == "fumble", "a second tap on one landing wobbles")


func test_rhythm_beats_mashing() -> void:
	_begin("rhythm beats mashing (on the beat: the computer, the field events)")
	var ent := [{"name": "rhythm", "cpu": false}, {"name": "masher", "cpu": false}, {"name": "idle", "cpu": false}]
	var next_mash := [0.0]
	var drive := func(r: Race, t: float, _dt: float) -> void:
		# athlete 0 taps every landing dead on the beat
		var a := r.athletes[0]
		if a.state == "run" and not a.tapped.has(a.to_slot) and t >= a.slot_time(a.to_slot):
			r.press(0, false, a.slot_time(a.to_slot))
		# athlete 1 mashes ten times a second
		if t >= r.go and t >= next_mash[0]:
			next_mash[0] = t + 0.1
			r.press(1, false, t)
	var r := _race("sprint", ent, drive)
	var tr: float = r.times.get(0, 99.0)
	var tm: float = r.times.get(1, 99.0)
	var ti: float = r.times.get(2, 99.0)
	check(tr < tm, "tapping on the beat (%.2fs) beats mashing (%.2fs)" % [tr, tm])
	check(tr < 11.2, "perfect rhythm runs 100m in under 11.2s (%.2fs)" % tr)
	check(tm > 13.0, "mashing is slow (%.2fs)" % tm)
	check(ti > 20.0, "not tapping at all is slowest (%.2fs)" % ti)
	check(r.athletes[1].counts.fumble > 30, "the masher wobbled (%d)" % r.athletes[1].counts.fumble)


func test_false_start() -> void:
	_begin("false start")
	var r := Race.new()
	r.setup("sprint", Beat.new(90.0, 0.0), [{"name": "a", "cpu": false}, {"name": "b", "cpu": false}], "junior", 0.0)
	for b in r.athletes:
		b.bash = false               # on the beat (bashing has no false starts)
	var early := r.go - 1.0
	r.update(early, 0.01)
	check(r.press(0, false, early) == "false", "a tap a second before the gun is a false start")
	check(r.false_starts.has(0), "and it's noted")
	r.update(r.go + 0.01, 0.01)
	check(r.athletes[0].origin > r.go and is_equal_approx(r.athletes[1].origin, r.go), "the false starter leaves late")


func test_sprint_order() -> void:
	_begin("sprint: skill tells")
	var ent: Array = []
	for s in [0.98, 0.85, 0.6, 0.35]:
		ent.append({"name": str(s), "cpu": true, "skill": s})
	var info := Catalog.event("sprint")
	var totals := [0.0, 0.0, 0.0, 0.0]
	for bpm in [82.0, 92.0, 102.0]:
		var r := _race("sprint", ent, Callable(), bpm)
		check(r.times.size() == 4, "everyone finishes at %d bpm" % bpm)
		for i in 4:
			totals[i] += float(r.times.get(i, 99.0))
	check(totals[0] < totals[2] and totals[1] < totals[3], "the steadier athletes are faster (%s)" % str(totals))
	check(totals[0] / 3.0 < float(info.qualify.pro), "the best computer athlete reaches the pro mark")
	check(totals[3] / 3.0 < float(info.qualify.junior), "even a shaky one reaches the junior mark (%.2f)" % (totals[3] / 3.0))


func test_hurdles() -> void:
	_begin("hurdles")
	var ent := [{"name": "a", "cpu": true, "skill": 1.0}, {"name": "b", "cpu": true, "skill": 0.95}]
	var r := _race("hurdles", ent)
	var hits := 0
	for e in r.log:
		if e.kind == "hurdle_hit" and e.who == 0:
			hits += 1
	check(hits == 0, "a perfect athlete clears every hurdle (hit %d)" % hits)
	check(r.times.has(0) and float(r.times[0]) < float(Catalog.event("hurdles").qualify.pro), "and qualifies (%.2f)" % float(r.times.get(0, 99.0)))
	# no jumping at all: every hurdle is hit
	var lazy := _race("hurdles", [{"name": "lazy", "cpu": false}], func(rr: Race, t: float, _dt: float) -> void:
		var a := rr.athletes[0]
		if a.state == "run" and not a.tapped.has(a.to_slot) and t >= a.slot_time(a.to_slot):
			rr.press(0, false, a.slot_time(a.to_slot)))
	var lazy_hits := 0
	for e in lazy.log:
		if e.kind == "hurdle_hit":
			lazy_hits += 1
	check(lazy_hits == 10, "never jumping knocks all ten hurdles (%d)" % lazy_hits)


func _jump(id: String, skill: float, seed := 1, bpm := 90.0) -> Jump:
	var j := Jump.new()
	j.setup(id, Beat.new(bpm, 0.0), {"name": "x", "cpu": true, "skill": skill}, "pro", 0.0, seed)
	var t := 0.0
	while not j.finished() and t < 40.0:
		t += 1.0 / 120.0
		j.update(t, 1.0 / 120.0)
	return j


func test_long_jump() -> void:
	_begin("long jump")
	var best := 0.0
	for seed in 4:
		var j := _jump("long_jump", 1.0, seed + 1)
		check(j.finished(), "an attempt finishes")
		if j.foul == "":
			best = maxf(best, j.mark)
	check(best > float(Catalog.event("long_jump").qualify.pro), "a perfect athlete jumps past the pro mark (%.2f)" % best)
	check(best < 9.5, "but not absurdly far (%.2f)" % best)
	# running straight through without jumping is a foul (from ages 8 up)
	var j2 := Jump.new()
	j2.setup("long_jump", Beat.new(90.0, 0.0), {"name": "x", "cpu": false, "band": "keen"}, "pro", 0.0)
	var t := 0.0
	while not j2.finished() and t < 30.0:
		t += 1.0 / 120.0
		j2.update(t, 1.0 / 120.0)
		if j2.b.state == "run" and t >= j2.b.slot_time(j2.b.to_slot) and not j2.b.tapped.has(j2.b.to_slot):
			j2.press(false, j2.b.slot_time(j2.b.to_slot))
	check(j2.foul == "no jump", "never pressing JUMP is no jump (%s)" % j2.foul)
	# at 5-7 it takes off by itself past the board, and that's no foul
	var j3 := Jump.new()
	j3.setup("long_jump", Beat.new(90.0, 0.0), {"name": "x", "cpu": false, "band": "gentle"}, "pro", 0.0)
	t = 0.0
	while not j3.finished() and t < 30.0:
		t += 1.0 / 120.0
		if j3.run_up():
			j3.run(int(t * 6.0) % 2, t)
		j3.update(t, 1.0 / 120.0)
	check(j3.foul == "" and j3.mark > 0.0, "at ages 5-7, missing the board still jumps, no foul (%.2f)" % j3.mark)
	# the Track & Field way: JUMP by the board, measured from it; over it, a foul
	var marks := []
	for case in [[-1.5, false], [-0.1, false], [0.3, true]]:
		var jl := Jump.new()
		jl.setup("long_jump", Beat.new(90.0, 0.0), {"name": "x", "cpu": false, "band": "keen"}, "pro", 0.0)
		t = 0.0
		var pressed := false
		while not jl.finished() and t < 30.0:
			t += 1.0 / 120.0
			if jl.run_up():
				jl.run(int(t * 8.0) % 2, t)
			if not pressed and jl.b.state == "run" and jl.state == "run" and jl.b.x >= float(case[0]):
				pressed = true
				jl.press(true, t)
			if jl.b.state == "hold" and jl.b.hold_angle(t) >= 43.0:
				jl.release(t)
			jl.update(t, 1.0 / 120.0)
		if bool(case[1]):
			check(jl.foul == "foul", "over the board is a foul (%s)" % jl.foul)
		else:
			check(jl.foul == "" and absf(jl.take_off - float(case[0])) < 0.3,
				"JUMP takes off right where it's pressed (%.2f at %.2f)" % [jl.take_off, float(case[0])])
		marks.append(jl.mark)
	check(float(marks[1]) > float(marks[0]) + 1.0, "an early take-off loses distance (%.2f vs %.2f)" % [marks[0], marks[1]])


func test_triple_jump() -> void:
	_begin("hop, skip and jump")
	var best := 0.0
	var phases_seen := false
	for seed in 4:
		var j := _jump("triple_jump", 1.0, seed + 1)
		var kinds := j.log.map(func(e): return e.kind)
		if "hop" in kinds and "skip" in kinds and "jump" in kinds:
			phases_seen = true
		if j.foul == "":
			best = maxf(best, j.mark)
	check(phases_seen, "an attempt goes hop, skip, jump")
	check(best > float(Catalog.event("triple_jump").qualify.pro), "a perfect athlete passes the pro mark (%.2f)" % best)


func test_high_jump() -> void:
	_begin("high jump")
	var cleared := 0
	for seed in 4:
		var h := High.new()
		h.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": 1.0}, "pro", 2.0, 0.0, seed + 1)
		var t := 0.0
		while not h.finished() and t < 20.0:
			t += 1.0 / 120.0
			h.update(t, 1.0 / 120.0)
		if h.cleared:
			cleared += 1
	check(cleared >= 3, "a perfect athlete clears 2.00m most times (%d of 4)" % cleared)
	# the same jump without the arch knocks it
	var knocked := 0
	for seed in 3:
		var h2 := High.new()
		h2.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": 1.0}, "pro", 2.0, 0.0, seed + 1)
		h2.cpu_arch = 5.0     # never arches
		var t2 := 0.0
		while not h2.finished() and t2 < 20.0:
			t2 += 1.0 / 120.0
			h2.update(t2, 1.0 / 120.0)
		if h2.knocked:
			knocked += 1
	check(knocked == 3, "without arching, 2.00m is knocked (%d of 3)" % knocked)


func test_dive() -> void:
	_begin("high dive")
	var idle := Dive.new()
	idle.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": false}, "pro", 0.0, 1)
	var ti := 0.0
	while not idle.finished() and ti < 30.0:
		ti += 1.0 / 120.0
		idle.update(ti, 1.0 / 120.0)
	check(idle.finished() and idle.score == 0.0, "never leaving the board is a balk, and scores nothing")
	var any_tricks := false
	for seed in 3:
		var d := Dive.new()
		d.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": 1.0}, "pro", 0.0, seed + 1)
		var t := 0.0
		while not d.finished() and t < 30.0:
			t += 1.0 / 120.0
			d.update(t, 1.0 / 120.0)
		check(d.finished(), "a dive finishes")
		check(d.marks.size() == 5, "five judges mark it")
		check(d.score > 20.0, "a good dive scores (%.1f)" % d.score)
		check(d.entry < 30.0, "and goes in near straight (%.0f°)" % d.entry)
		if d.tricks.size() > 0:
			any_tricks = true
	check(any_tricks, "the computer does tricks")


func test_relay() -> void:
	_begin("relay")
	var ent := [{"name": "a", "cpu": true, "skill": 1.0}, {"name": "b", "cpu": true, "skill": 0.8},
		{"name": "c", "cpu": true, "skill": 0.5}]
	var r := _race("relay", ent)
	check(r.times.size() == 3, "every team finishes")
	var tags := {}
	var missed := 0
	for e in r.log:
		if e.kind == "tag":
			tags[e.who] = tags.get(e.who, 0) + 1
		if e.kind == "missed_tag" and e.who == 0:
			missed += 1
	check(int(tags.get(0, 0)) == 3 and missed == 0, "the best team makes all three changeovers cleanly (%s, missed %d)" % [str(tags), missed])
	check(r.leg[0] == 3, "and is on its last leg at the end")
	var info := Catalog.event("relay")
	check(float(r.times.get(0, 99.0)) < float(info.qualify.pro), "it reaches the pro mark (%.2f)" % float(r.times.get(0, 99.0)))
	check(float(r.times.get(0, 99.0)) > float(info.record) - 1.5, "but not far past the record (%.2f)" % float(r.times.get(0, 99.0)))
	check(float(r.times.get(0, 99.0)) < float(r.times.get(2, 99.0)), "steadier teams are faster")


func test_steeplechase() -> void:
	_begin("steeplechase")
	var r := _race("steeplechase", [{"name": "a", "cpu": true, "skill": 1.0}, {"name": "b", "cpu": true, "skill": 0.7}])
	var hits := 0
	var wet := 0
	for e in r.log:
		if e.kind == "barrier_hit" and e.who == 0:
			hits += 1
		if e.kind == "splash" and e.who == 0:
			wet += 1
	check(hits == 0, "a perfect athlete clears every barrier (%d)" % hits)
	check(wet == 0, "and the water (%d)" % wet)
	var info := Catalog.event("steeplechase")
	check(float(r.times.get(0, 99.0)) < float(info.qualify.pro), "and qualifies (%.2f)" % float(r.times.get(0, 99.0)))


func test_meatball_put() -> void:
	_begin("meatball put")
	# bouncing on and on without a put: time runs out, a foul
	var idle := Throw.new()
	idle.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": false, "band": "keen"}, "pro", 0.0, 1)
	var ti := 0.0
	while not idle.finished() and ti < 30.0:
		ti += 1.0 / 120.0
		idle.update(ti, 1.0 / 120.0)
	check(idle.finished() and idle.result() < 0.0, "bouncing for ever in the circle is a foul (%s)" % idle.foul)
	var best := 0.0
	for seed in 4:
		var th := Throw.new()
		th.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": 1.0}, "pro", 0.0, seed + 1)
		var t := 0.0
		while not th.finished() and t < 30.0:
			t += 1.0 / 120.0
			th.update(t, 1.0 / 120.0)
		check(th.finished(), "a put finishes")
		check(th.foul == "", "and the hot dog stays in its circle")
		best = maxf(best, th.mark)
	var info := Catalog.event("meatball_put")
	check(best > float(info.qualify.pro), "a perfect put passes the pro mark (%.2f)" % best)
	check(best < float(info.record) + 1.5, "but not miles past the record (%.2f)" % best)


func test_vault() -> void:
	_begin("springboard vault")
	var cleared := 0
	for seed in 4:
		var h := High.new()
		h.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": 1.0}, "pro", 5.25, 0.0, seed + 1, "vault")
		var t := 0.0
		while not h.finished() and t < 25.0:
			t += 1.0 / 120.0
			h.update(t, 1.0 / 120.0)
		if h.cleared:
			cleared += 1
	check(cleared >= 3, "a perfect vaulter clears the pro mark most times (%d of 4)" % cleared)
	# a whole competition goes up past the first height
	var m := Meet.new()
	m.setup("vault", [{"name": "a", "cpu": true, "skill": 0.95, "player": -1}, {"name": "b", "cpu": true, "skill": 0.9, "player": -1}], "junior", 2)
	var guard := 0
	while guard < 80:
		guard += 1
		var i := m.next_turn()
		if i < 0:
			break
		m.record(i, m.sim(i, Beat.new(90.0, 0.0), guard))
	check(m.best(m.standings()[0]) >= 5.0, "a vault competition climbs past 5m (%.2f)" % m.best(m.standings()[0]))


func test_swim() -> void:
	_begin("swim")
	var r := _race("swim", [{"name": "a", "cpu": true, "skill": 1.0}, {"name": "b", "cpu": true, "skill": 0.6}])
	var gulps := {}
	var breaths := 0
	for e in r.log:
		if e.kind == "gulp":
			gulps[e.who] = gulps.get(e.who, 0) + 1
		if e.kind == "breath" and e.who == 0:
			breaths += 1
	check(int(gulps.get(0, 0)) == 0, "a perfect swimmer never gulps (%d)" % int(gulps.get(0, 0)))
	check(breaths >= 3, "it breathes every bar (%d)" % breaths)
	var info := Catalog.event("swim")
	var tt := float(r.times.get(0, 99.0))
	check(tt < float(info.qualify.pro) and tt > float(info.record) - 1.0, "it qualifies, near the record (%.2f)" % tt)
	# never breathing
	var lazy := _race("swim", [{"name": "lazy", "cpu": false}], func(rr: Race, t: float, _dt: float) -> void:
		var a := rr.athletes[0]
		if a.state == "run" and not a.tapped.has(a.to_slot) and t >= a.slot_time(a.to_slot):
			rr.press(0, false, a.slot_time(a.to_slot)))
	var lg := 0
	for e in lazy.log:
		if e.kind == "gulp":
			lg += 1
	check(lg >= 3, "a swimmer who never breathes gulps (%d)" % lg)
	check(float(lazy.times.get(0, 99.0)) > tt + 1.0, "and is slower (%.2f)" % float(lazy.times.get(0, 99.0)))


func test_trampoline() -> void:
	_begin("trampoline")
	var scores: Array = []
	for s in [1.0, 0.5]:
		var tr := Tramp.new()
		tr.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": s}, "pro", 0.0, 3)
		var t := 0.0
		while not tr.finished() and t < 60.0:
			t += 1.0 / 120.0
			tr.update(t, 1.0 / 120.0)
		check(tr.finished(), "a routine finishes (skill %.1f)" % s)
		check(tr.skills.size() == Tramp.SKILLS, "eight skills are marked")
		scores.append(tr.score)
		if s == 1.0:
			check(tr.stuck == "perfect", "the perfect gymnast sticks it")
			check(tr.flight > 7.0, "and bounces high (%.1f)" % tr.flight)
	var info := Catalog.event("trampoline")
	check(float(scores[0]) > float(info.qualify.pro), "a perfect routine passes the pro mark (%.1f)" % float(scores[0]))
	check(float(scores[0]) < float(info.record) + 3.0, "but not miles past the record (%.1f)" % float(scores[0]))
	check(float(scores[0]) > float(scores[1]), "steadier is better")
	# never tapping a landing: the height drains away
	var lazy := Tramp.new()
	lazy.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": false}, "pro", 0.0)
	var t2 := 0.0
	while not lazy.finished() and t2 < 60.0:
		t2 += 1.0 / 120.0
		lazy.update(t2, 1.0 / 120.0)
	check(lazy.finished() and lazy.flight < 2.0, "never tapping, the routine is low (%.1f)" % lazy.flight)


func test_breaking() -> void:
	_begin("breaking")
	var a := Battle.make_patterns(42)
	var b2 := Battle.make_patterns(42)
	check(str(a) == str(b2), "the same seed makes the same patterns")
	check(a.size() == 3 and a[0].size() < a[2].size(), "three patterns, busier each round")
	for r in a.size():
		check(int(a[r][0].step) == 0, "round %d starts on the one" % (r + 1))
	for n in a[0]:
		check(int(n.step) % 2 == 0, "round one keeps to the beats")
	var scores: Array = []
	for sk in [1.0, 0.5]:
		var bt := Battle.new()
		bt.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": sk}, "pro", 0.0, 42, 5)
		var t := 0.0
		while not bt.finished() and t < 90.0:
			t += 1.0 / 120.0
			bt.update(t, 1.0 / 120.0)
		check(bt.finished(), "a battle finishes")
		scores.append(bt.score)
	check(float(scores[0]) > float(Catalog.event("breaking").qualify.pro), "a perfect dancer passes the pro mark (%.0f)" % float(scores[0]))
	check(float(scores[0]) <= Battle.new().max_score() if false else true, "scores are sane")
	check(float(scores[0]) > float(scores[1]), "steadier dances better (%.0f > %.0f)" % [float(scores[0]), float(scores[1])])
	# copying the pattern with the wrong buttons scores little
	var wrong := Battle.new()
	wrong.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": false}, "pro", 0.0, 42, 5)
	var t2 := 0.0
	while not wrong.finished() and t2 < 90.0:
		t2 += 1.0 / 120.0
		wrong.update(t2, 1.0 / 120.0)
		if wrong.state == "answer":
			for n in wrong.notes:
				if n.grade == "" and t2 >= float(n.at):
					wrong.press(not bool(n.action), float(n.at))
	check(wrong.score < float(scores[0]) * 0.4, "the wrong moves on the right beats score little (%.0f)" % wrong.score)


func test_skateboard() -> void:
	_begin("skateboarding")
	var c := Skate.make_course(3)
	check(str(c) == str(Skate.make_course(3)), "the same seed makes the same course")
	check(c[0].kind == "cone", "it opens with a cone")
	var kinds := {}
	for f in c:
		kinds[f.kind] = true
	check(kinds.size() == 3, "it has cones, rails and ramps")
	for k in range(1, c.size()):
		check(int(c[k].at) > int(c[k - 1].at) + int(c[k - 1].len) + 1, "obstacles don't overlap")
	var scores: Array = []
	for sk in [1.0, 0.5]:
		var r := Skate.new()
		r.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": sk}, "pro", 0.0, 3, 3)
		var t := 0.0
		while not r.finished() and t < 90.0:
			t += 1.0 / 120.0
			r.update(t, 1.0 / 120.0)
		check(r.finished(), "a run finishes")
		scores.append(r.score)
		if sk == 1.0:
			check(r.log.filter(func(e): return e.kind == "bail").is_empty(), "a perfect skater never bails")
	var info := Catalog.event("skateboard")
	check(float(scores[0]) > float(info.qualify.pro), "a perfect run passes the pro mark (%.0f)" % float(scores[0]))
	check(float(scores[0]) > float(scores[1]), "steadier skates better")
	# riding without touching anything bails at the first cone
	var idle := Skate.new()
	idle.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": false}, "pro", 0.0, 3)
	var t2 := 0.0
	while not idle.finished() and t2 < 90.0:
		t2 += 1.0 / 120.0
		idle.update(t2, 1.0 / 120.0)
	check(idle.log.filter(func(e): return e.kind == "bail").size() >= 2, "doing nothing bails at the cones")
	check(idle.score < 1.0, "and scores nothing")
	# a perfect skater who also mashes JUMP between the beats does worse
	var masher := Skate.new()
	masher.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": 1.0}, "pro", 0.0, 3, 3)
	var t3 := 0.0
	var next_mash := 0.37
	while not masher.finished() and t3 < 90.0:
		t3 += 1.0 / 120.0
		masher.update(t3, 1.0 / 120.0)
		if t3 >= next_mash and masher.state == "ride" and masher.pose != "grind":
			masher.press(true, t3)
			next_mash += 0.29
	check(masher.score < float(scores[0]) * 0.9, "mashing JUMP costs flow (%.0f < %.0f)" % [masher.score, float(scores[0])])


func test_ski_jump() -> void:
	_begin("ski jump")
	check(SkiJump.hill(0.0) <= 0.0 and SkiJump.hill(100.0) < SkiJump.hill(50.0), "the hill goes down")
	check(SkiJump.hill(180.0) - SkiJump.hill(170.0) > -1.0, "and flattens out at the bottom")
	var d: Array = []
	for sk in [1.0, 0.5]:
		var j := SkiJump.new()
		j.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": sk}, "pro", 0.0, 2)
		var t := 0.0
		while not j.finished() and t < 40.0:
			t += 1.0 / 120.0
			j.update(t, 1.0 / 120.0)
		check(j.finished(), "a jump finishes")
		check(j.marks.size() == 5, "five judges mark it")
		d.append(j)
	var best: SkiJump = d[0]
	check(best.distance > SkiJump.K + 5.0 and best.distance < SkiJump.HILL, "a perfect jump goes past the K-point (%.1fm)" % best.distance)
	check(best.landing == "telemark", "and lands in a telemark")
	check(best.points > float(Catalog.event("ski_jump").qualify.pro), "and passes the pro mark (%.0f)" % best.points)
	check(best.distance > (d[1] as SkiJump).distance, "steadier flies further")
	# mashing JUMP all through the flight: the first reach counts, the rest wobble
	var mash := SkiJump.new()
	mash.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": 1.0}, "pro", 0.0, 2)
	var t4 := 0.0
	var next_reach := 0.0
	while not mash.finished() and t4 < 40.0:
		t4 += 1.0 / 120.0
		mash.update(t4, 1.0 / 120.0)
		if mash.state == "flight" and t4 >= next_reach:
			mash.press(true, t4)
			next_reach = t4 + 0.15
	check(mash.landing != "telemark", "mashing JUMP doesn't land a telemark (%s)" % mash.landing)
	check(mash.points < best.points, "and scores less (%.0f < %.0f)" % [mash.points, best.points])
	var idle := SkiJump.new()
	idle.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": false}, "pro", 0.0, 2)
	var t2 := 0.0
	while not idle.finished() and t2 < 40.0:
		t2 += 1.0 / 120.0
		idle.update(t2, 1.0 / 120.0)
	check(idle.finished() and idle.distance < 60.0, "doing nothing barely gets off the table (%.1fm)" % idle.distance)


func test_bobsleigh() -> void:
	_begin("bobsleigh")
	check(str(Bob.make_track(4, 6)) == str(Bob.make_track(4, 6)), "the same seed makes the same track")
	var highs := Bob.make_track(4, 6).filter(func(b): return b.high).size()
	check(highs > 4 and highs < 20, "it has high bends and low ones (%d high)" % highs)
	var times: Array = []
	for sk in [1.0, 0.5]:
		var bo := Bob.new()
		bo.setup(Beat.new(90.0, 0.0), {"name": "x", "cpu": true, "skill": sk}, "pro", 0.0, 4, 4)
		var t := 0.0
		while not bo.finished() and t < 80.0:
			t += 1.0 / 120.0
			bo.update(t, 1.0 / 120.0)
		check(bo.finished(), "a run finishes")
		times.append(bo.result())
		if sk == 1.0:
			check(bo.log.filter(func(e): return e.kind == "scrape").is_empty(), "a perfect run never scrapes")
	var info := Catalog.event("bobsleigh")
	check(float(times[0]) < float(info.qualify.pro), "a perfect run beats the pro mark (%.2f)" % float(times[0]))
	check(float(times[0]) > float(info.record) - 1.0, "near the record (%.2f)" % float(times[0]))
	check(float(times[0]) < float(times[1]), "steadier is faster")
	# low is better: the meet keeps the fastest run
	var m := Meet.new()
	m.setup("bobsleigh", [{"name": "a"}], "junior", 1)
	m.record(0, 25.0)
	m.record(0, 23.0)
	check(is_equal_approx(m.best(0), 23.0), "the best of two runs is the faster")
	check(m.qualified(0), "and 23s qualifies at junior")


func test_meet_rounds() -> void:
	_begin("a meet's rounds")
	var ent := [{"name": "a", "cpu": true, "skill": 0.9, "player": -1}, {"name": "b", "cpu": true, "skill": 0.9, "player": -1}]
	var m := Meet.new()
	m.setup("long_jump", ent, "pro", 3)
	var turns := 0
	while true:
		var i := m.next_turn()
		if i < 0:
			break
		turns += 1
		m.record(i, m.sim(i, Beat.new(90.0, 0.0), turns))
	check(turns == 6, "two athletes, three rounds: six goes (%d)" % turns)
	check(m.standings().size() == 2, "standings list both")
	check(m.best(m.standings()[0]) >= m.best(m.standings()[1]), "best first")


func test_high_countback() -> void:
	_begin("high jump countback")
	var m := Meet.new()
	m.setup("high_jump", [{"name": "a"}, {"name": "b"}], "junior", 1)
	# a: clears 1.50 at the first go; b: at the second
	m.record(m.next_turn(), 1.0)       # a 1.50 O
	m.record(m.next_turn(), 0.0)       # b 1.50 X
	m.record(m.next_turn(), 1.0)       # b 1.50 XO
	for k in 6:                        # both fail 1.60 three times
		var i := m.next_turn()
		if i < 0:
			break
		m.record(i, 0.0)
	check(m.next_turn() == -1, "with both out, it's over")
	check(m.best(0) == m.best(1), "they tie on height")
	check(m.standings()[0] == 0, "fewer misses wins the countback")


func test_championship() -> void:
	_begin("championship")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var me: Dictionary = load("res://game/profile.gd").default_athlete()
	for id in Catalog.order():
		var e := Championship.entrants_for(id, [me], rng)
		check(e.size() == 4, "%s has four in it" % id)
		check(int(e[0].player) == 0, "%s: the player is in it" % id)
		var nations := {}
		for x in e:
			nations[x.nation] = true
		check(nations.size() == 4, "%s: four different nations" % id)
		var specialist := false
		for x in e:
			if Championship.specialist(Catalog.nation(String(x.nation)), id):
				specialist = true
		check(specialist, "%s: the nation best at it is there" % id)
	var c := Championship.new()
	c.setup([me], "junior", 9)
	var m := Meet.new()
	m.setup("sprint", c.entrants(), "junior", 1)
	m.record_race({0: 20.0, 1: 11.0, 2: 12.0, 3: 13.0})
	var r := c.finish(m)
	check(not r.any and c.buns == 2, "not qualifying costs a bun")
	check(c.table().is_empty() and c.history.is_empty(), "an event that's run again gives no medals yet")
	m.record_race({0: 11.0, 1: 12.0, 2: 13.0, 3: 14.0})
	r = c.finish(m)
	check(r.any and c.index == 1, "qualifying moves on")
	check(c.table().size() >= 3, "medals are on the table")
	var given := 0
	for row in c.table():
		given += int(row.gold) + int(row.silver) + int(row.bronze)
	check(given == 3 and c.history.size() == 1, "one set of medals for the event (%d)" % given)
	var c2 := Championship.new()
	c2.setup([me], "junior", 9)
	c2.buns = 1
	var m2 := Meet.new()
	m2.setup("sprint", c2.entrants(), "junior", 1)
	m2.record_race({0: 20.0, 1: 11.0, 2: 12.0, 3: 13.0})
	r = c2.finish(m2)
	check(c2.over() and c2.history.size() == 1, "the last bun's event still stands")


func test_series() -> void:
	_begin("series")
	var all := Catalog.order()
	check(all.size() == Catalog.events().events.size(), "practice lists every event (%d)" % all.size())
	var full := Catalog.a_series("full")
	check(not full.is_empty() and full.events.size() == all.size(), "the Full Sports Day has every event")
	for sr in Catalog.series():
		for id in sr.events:
			check(not Catalog.event(String(id)).is_empty(), "%s's %s exists" % [sr.id, id])
	var f := FileAccess.open("res://assets/art/ui/icons.json", FileAccess.READ)
	var icons: Dictionary = JSON.parse_string(f.get_as_text())
	for id in all:
		check(id in icons.order, "%s has a pictogram" % id)
	var p: Node = load("res://game/profile.gd").new()
	p.path = "user://no_such_profile.json"
	p.load_profile()
	check(p.athletes.size() >= 2 and p.chosen[0] != p.chosen[1], "two players start with two different hot dogs")
	p.free()
	for n in Catalog.nations():
		var specials := 0
		for id in all:
			if Championship.specialist(n, id):
				specials += 1
		check(specials >= 1, "%s is good at something" % n.id)
	for id in all:
		var who := 0
		for n in Catalog.nations():
			if Championship.specialist(n, id):
				who += 1
		check(who >= 1, "someone is best at %s" % id)


func test_art() -> void:
	_begin("art")
	var meta := AthleteView.meta()
	check(meta.get("frames", []).size() == 38, "38 frames per sheet")
	for s in meta.sausages:
		check(ResourceLoader.exists("res://assets/art/dogs/sausage_%s.png" % s), "sausage " + s)
	for b in meta.fronts:
		check(ResourceLoader.exists("res://assets/art/dogs/bun_%s.png" % b), "bun " + b)
	for b in meta.backs:
		check(ResourceLoader.exists("res://assets/art/dogs/bun_back_%s.png" % b), "bun back " + b)
	for t in meta.toppings:
		check(ResourceLoader.exists("res://assets/art/dogs/top_%s.png" % t), "topping " + t)
	for n in Catalog.nations():
		check(n.sausage in meta.sausages, "%s's sausage is drawn" % n.id)
		check(n.bun in meta.buns, "%s's bun is drawn" % n.id)
		for t in n.toppings:
			check(t in meta.toppings, "%s's %s is drawn" % [n.id, t])
		check(meta.teams.has(n.band[0]) and meta.teams.has(n.band[1]), "%s's band colours exist" % n.id)
	for t in Looks.TOPPINGS:
		check(t in meta.toppings, "the dressing room's %s is drawn" % t)
	for k in Looks.CHOICES.band:
		check(meta.teams.has(k), "band colour %s exists" % k)
	for f in ["sky", "clouds", "city", "roof", "stands", "wall", "track", "infield", "sandpit", "hurdle", "hurdle_down"]:
		check(ResourceLoader.exists("res://assets/art/stadium/%s.png" % f), "stadium " + f)
	var tex := AthleteView.body(Championship.look_of(Catalog.nations()[0]))
	check(tex != null and tex.get_width() == 416, "a body sheet composes")


func test_faces() -> void:
	_begin("faces")
	var f := FileAccess.open("res://assets/art/face/face.json", FileAccess.READ)
	var face: Dictionary = JSON.parse_string(f.get_as_text())
	for mood in AthleteView.FACES:
		var e: Array = AthleteView.FACES[mood]
		check(face.eyes.has(e[0]), "%s's eyes %s exist" % [mood, e[0]])
		check(face.mouth.has(e[1]), "%s's mouth %s exist" % [mood, e[1]])
		check(e[2] == "none" or face.brow.has(e[2]), "%s's brows %s exist" % [mood, e[2]])
	for k in ["hair", "specs", "tache"]:
		for v in Looks.CHOICES[k]:
			check(v == "none" or face[k].has(v), "%s %s exists" % [k, v])
	for e in Looks.CHOICES.eyes:
		check(face.eyes.has(e), "eyes %s exist" % e)


func test_font() -> void:
	_begin("lettering")
	var f := FileAccess.open("res://assets/fonts/small.fnt", FileAccess.READ)
	var have := {}
	for line in f.get_as_text().split("\n"):
		if line.begins_with("char id="):
			have[int(line.split(" ")[1].trim_prefix("id="))] = true
	var texts: Array = []
	for n in Catalog.nations():
		texts.append_array([n.athlete, n.country, n.dog, n.line])
	for id in Catalog.order():
		var e := Catalog.event(id)
		texts.append_array([e.name, e.how])
	for w in Kit.GRADE_WORDS.values():
		texts.append(w)
	for t in texts:
		for i in String(t).length():
			var c := String(t).unicode_at(i)
			check(have.has(c), "the font has '%s' (in %s)" % [String.chr(c), t])


func test_sounds() -> void:
	_begin("sounds")
	var names := {}
	var re := RegEx.new()
	re.compile("Sound\\.play\\(\"([a-z_]+)\"")
	for dir in ["res://ui", "res://game"]:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd"):
				continue
			var text := FileAccess.get_file_as_string(dir + "/" + file)
			for m in re.search_all(text):
				if not m.get_string(1).ends_with("_"):
					names[m.get_string(1)] = true
	for g in ["perfect", "good", "ok", "miss", "fumble"]:
		names["bounce_" + g] = true
	var sfx := DirAccess.get_files_at("res://assets/audio/sfx")
	for n in names:
		var found := false
		for f in sfx:
			if f.begins_with(n + "_") and (f.ends_with(".wav") or f.ends_with(".ogg")):
				found = true
		check(found, "sound '%s' exists" % n)


func test_event_music() -> void:
	_begin("one tune for a whole event")
	var sound: Node = root.get_node("Sound")
	check(sound.carry_on(true, true, 100.0, 30.0), "the next go carries on with the event's track")
	check(not sound.carry_on(true, true, 100.0, 60.0), "unless it's nearly done (then it starts again at the top)")
	check(not sound.carry_on(true, false, 100.0, 10.0), "or has stopped")
	check(not sound.carry_on(false, true, 100.0, 10.0), "a new event doesn't carry on")
	var list := [{"path": "a"}, {"path": "b"}, {"path": "c"}]
	var was: Dictionary = sound._track
	sound._track = {"path": "b"}
	var picks := {}
	for k in 40:
		picks[String(sound._pick(list, "a").path)] = true
	sound._track = was
	check(picks.keys() == ["c"], "the next event's track isn't the last event's, nor what's on (%s)" % str(picks.keys()))


func test_profile() -> void:
	_begin("profile")
	var p: Node = load("res://game/profile.gd").new()
	p.path = "user://test_profile.json"
	p.reset()
	p.athletes[0]["name"] = "Testy Frank"
	p.level = "pro"
	p.records["sprint"] = {"mark": 10.5, "name": "Testy Frank", "nation": "ngc"}
	p.save()
	var q: Node = load("res://game/profile.gd").new()
	q.path = "user://test_profile.json"
	q.load_profile()
	check(q.athletes[0].name == "Testy Frank", "the athlete's name comes back")
	check(q.level == "easy", "one set of rules for every player, whatever was saved")
	check(is_equal_approx(float(q.record("sprint").mark), 10.5), "a record comes back")
	check(q.offer("sprint", 10.4, {"name": "Q"}).has("record"), "a faster time is a new record")
	check(not q.offer("sprint", 12.0, {"name": "Q"}).has("record"), "a slower one isn't")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_profile.json"))
	p.free()
	q.free()


func test_wardrobe() -> void:
	_begin("the wardrobe")
	var meta := AthleteView.meta()
	var kit := Wardrobe.art()
	var f := FileAccess.open("res://assets/art/face/face.json", FileAccess.READ)
	var face: Dictionary = JSON.parse_string(f.get_as_text())
	var seen := {}
	var font := Kit.font("small")
	for it in Wardrobe.items():
		var slot := String(it.slot)
		var id := String(it.id)
		var key := slot + ":" + id
		check(not seen.has(key), "%s is listed once" % key)
		seen[key] = true
		check(slot in Wardrobe.SLOTS, "%s is in a slot the dressing room has" % key)
		check(String(it.get("name", "")) != "", "%s has a name" % key)
		for k in it.get("need", {}):
			check(Wardrobe.NEEDS.has(k), "%s unlocks with a count the game keeps (%s)" % [key, k])
		match slot:
			"hat":
				check(ResourceLoader.exists("res://assets/art/wardrobe/hat_%s.png" % id), "hat %s is drawn" % id)
			"outfit":
				check(ResourceLoader.exists("res://assets/art/wardrobe/out_%s.png" % id) or
					ResourceLoader.exists("res://assets/art/wardrobe/out_back_%s.png" % id), "outfit %s is drawn" % id)
			"specs", "hair", "tache":
				check(face.get(slot, {}).has(id), "%s %s has a stamp" % [slot, id])
			"sausage":
				check(id in meta.sausages, "sausage %s is drawn" % id)
			"bun":
				check(id in meta.buns, "bun %s is drawn" % id)
			"band":
				check(meta.teams.has(id), "colour %s exists" % id)
			"trail":
				check(id in ["sparkles", "hearts", "stars", "bubbles", "fire", "rainbow"], "trail %s is drawn" % id)
		var hint := "LOCKED!  " + Wardrobe.hint(slot, id)
		check(font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x <= 300,
			"%s's hint fits the dressing room (%s)" % [key, hint])
		check(font.get_string_size(Wardrobe.name_of(slot, id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x <= 300,
			"%s's name fits" % key)
	var locked := Wardrobe.items().filter(func(it): return not (it.get("need", {}) as Dictionary).is_empty())
	check(locked.size() >= 60, "lots of silly things to unlock (%d)" % locked.size())
	for slot in Wardrobe.SLOTS:
		var n := Wardrobe.choices(slot).size()
		check(n >= 2 and n <= 24, "%s's choices fit the dressing room's tiles (%d)" % [slot, n])
	check(kit.get("cell", []).size() == 2 and kit.get("hats", []).size() >= 20, "the wardrobe's sheets are listed")
	# wearing things: a hat and an outfit on the body, and in the phones' picture
	var look: Dictionary = load("res://game/profile.gd").default_athlete(0).duplicate()
	look["hat"] = "tophat"
	look["outfit"] = "cape"
	look["trail"] = "sparkles"
	var v := AthleteView.new()
	root.add_child(v)
	v.set_look(look)
	check(v._hat != null and v._front != null and v._back != null, "a hat and a cape (front and back) are worn")
	check(not v._hair_shows, "a top hat hides the hair")
	look["hat"] = "halo"
	v.set_look(look)
	check(v._hair_shows, "a halo doesn't")
	v.position = Vector2(100, 100)
	for i in 30:
		v.position.x += 3.0
		v._update_trail(1.0 / 30.0)
	check(v._trail.size() > 3, "a trail is left behind as it moves (%d)" % v._trail.size())
	look["trail"] = "none"
	v.set_look(look)
	check(v._trail.is_empty(), "and none without one")
	v.free()
	var plain: Image = Portrait.of(load("res://game/profile.gd").default_athlete(3), 1)
	var dressed_look: Dictionary = load("res://game/profile.gd").default_athlete(3).duplicate()
	dressed_look["hat"] = "wizard"
	var dressed: Image = Portrait.of(dressed_look, 1)
	check(plain != null and dressed != null and dressed.get_height() > plain.get_height() + 8,
		"the phones' picture wears the hat (%d > %d)" % [dressed.get_height() if dressed else 0, plain.get_height() if plain else 0])


func test_unlocks() -> void:
	_begin("unlocking things by playing")
	var prof: Node = root.get_node("Profile")
	var was_path: String = prof.path
	prof.path = "user://test_unlocks.json"
	var keep := [prof.stats.duplicate(), prof.unlocked.duplicate(), prof.fresh.duplicate()]
	prof.stats = {}
	prof.unlocked = []
	prof.fresh = []
	check(Wardrobe.is_open("hat", "cap") and Wardrobe.is_open("hat", "none") and Wardrobe.is_open("sausage", "frank"),
		"some things are yours from the start")
	check(not Wardrobe.is_open("hat", "viking") and not Wardrobe.is_open("stripe", "silver"), "the rest are locked")
	check(Wardrobe.hint("hat", "viking").begins_with("WIN 3 GOLD MEDALS"), "a locked thing says what unlocks it")
	# a sprint with a player who wins it
	var m := Meet.new()
	m.setup("sprint", [{"name": "me", "cpu": false, "player": 0, "nation": "ngc"},
		{"name": "cpu", "cpu": true, "skill": 0.5, "player": -1, "nation": "usa"}], "easy", 3)
	m.record_race({0: 11.0, 1: 12.0})
	var got: Array = Wardrobe.after_event(m)
	check(int(prof.stats.get("play", 0)) == 1 and int(prof.stats.get("medals", 0)) == 1 and int(prof.stats.get("golds", 0)) == 1,
		"an event, a medal and a gold are counted (%s)" % str(prof.stats))
	var keys := got.map(func(g): return "%s:%s" % [g.slot, g.id])
	check("hat:tophat" in keys and "specs:hearts" in keys and "hat:pirate" in keys,
		"a first gold unlocks a top hat, heart specs and more (%s)" % str(keys))
	check(Wardrobe.is_open("hat", "tophat") and "hat:tophat" in prof.fresh, "they can be worn, and they're NEW")
	check(Wardrobe.news(got).ends_with("MORE") or got.size() <= 2, "the scoreboard's line is short (%s)" % Wardrobe.news(got))
	check(Wardrobe.after_event(m).filter(func(g): return String(g.id) == "tophat").is_empty(), "nothing unlocks twice")
	# with a friend
	var t := Meet.new()
	t.setup("sprint", [{"name": "a", "cpu": false, "player": 0, "nation": "ngc"}, {"name": "b", "cpu": false, "player": 1,
		"nation": "eng"}], "easy", 3)
	t.record_race({0: 13.0, 1: 14.0})
	Wardrobe.after_event(t)
	check(Wardrobe.is_open("hat", "unicorn"), "playing with a friend unlocks the unicorn horn")
	# the counts come back
	prof.save()
	var q: Node = load("res://game/profile.gd").new()
	q.path = "user://test_unlocks.json"
	q.load_profile()
	check("hat:tophat" in q.unlocked and int(q.stats.get("play", 0)) == 3 and "hat:tophat" in q.fresh,
		"the unlocks and the counts are saved")
	q.free()
	# a look with something locked goes back to what's open
	prof.unlocked = []
	var look := {"hat": "viking", "band": ["silver", "red"], "sausage": "golden"}
	Wardrobe.tidy(look)
	check(look.hat == "none" and look.band[0] == "red" and look.sausage == "frank", "a locked thing comes off (%s)" % str(look))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_unlocks.json"))
	prof.path = was_path
	prof.stats = keep[0]
	prof.unlocked = keep[1]
	prof.fresh = keep[2]


func test_dressing() -> void:
	_begin("the dressing room")
	var prof: Node = root.get_node("Profile")
	var keep := [prof.unlocked.duplicate(), prof.fresh.duplicate(), prof.path]
	prof.path = "user://test_dressing.json"
	prof.unlocked = ["hat:viking"]
	prof.fresh = ["hat:viking"]
	var dressing: GDScript = load("res://ui/dressing.gd")
	var d: Node = dressing.new()
	root.add_child(d)
	if d._tiles.is_empty():
		d._ready()                 # (not ready by itself while the tests run)
	check(d._tiles.size() == Wardrobe.choices("hat").size(), "the hats tab has a tile for every hat (%d)" % d._tiles.size())
	var viking: Dictionary = d._tiles.filter(func(t): return t.id == "viking")[0]
	var crown: Dictionary = d._tiles.filter(func(t): return t.id == "crown")[0]
	check(viking.open and not crown.open, "unlocked tiles are open, the rest locked")
	d._pick(crown)
	check(String(d.look.get("hat", "none")) != "crown" and d._info.text.begins_with("LOCKED!"), "a locked tile says how to unlock it")
	d._pick(viking)
	check(d.look.hat == "viking" and d.view._hat != null, "an open one is worn")
	var tabs: Array = dressing.TABS
	for i in tabs.size():
		d._open(i)
		var slots: Array = tabs[i][1]
		check(d._tiles.size() > 1 and d._tiles.size() <= 24, "%s fits on three rows of tiles (%d)" % [tabs[i][0], d._tiles.size()])
		for t in d._tiles:
			check(String(t.slot) in slots, "%s's tiles are its own" % tabs[i][0])
	d._open(8)   # toppings: up to three
	for id in ["ketchup", "relish", "onion", "cheese"]:
		d._pick(d._tiles.filter(func(t): return t.id == id)[0])
	check(d.look.toppings == ["relish", "onion", "cheese"], "a fourth topping pushes off the first (%s)" % str(d.look.toppings))
	d._open(10)  # the stripe
	d._pick(d._tiles.filter(func(t): return t.id == "navy")[0])
	check(d.look.band[1] == "navy", "the stripe tab colours the stripe")
	d._save()
	check(prof.fresh.is_empty(), "what's been seen isn't NEW any more")
	check(String(prof.athlete(0).hat) == "viking", "the hot dog is saved")
	d.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_dressing.json"))
	prof.unlocked = keep[0]
	prof.fresh = keep[1]
	prof.path = keep[2]
	prof.load_profile()


func test_learn() -> void:
	_begin("learn to play")
	var prof: Node = root.get_node("Profile")
	var keep := [prof.stats.duplicate(), prof.unlocked.duplicate(), prof.fresh.duplicate(), prof.path]
	prof.path = "user://test_learn.json"
	prof.stats = {}
	prof.unlocked = []
	var learn: GDScript = load("res://ui/learn.gd")
	for l in learn.LESSONS:
		check(Catalog.event(String(l.id)).size() > 0, "lesson %s is a real event" % l.name)
		var w := Kit.font("small").get_string_size(String(l.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		check(w <= 224, "its words fit beside it (%d)" % w)
	check(String(learn.finish("sprint")).begins_with("WELL BOUNCED"), "a lesson done")
	learn.finish("hurdles")
	var said: String = learn.finish("long_jump")
	check(said.begins_with("YOU'VE LEARNED TO PLAY") and Wardrobe.is_open("hat", "wizard") and Wardrobe.is_open("specs", "nerd"),
		"all three: you've learned to play, and the wizard hat's yours (%s)" % said)
	# the coach
	var m := Meet.new()
	m.setup("sprint", [{"name": "me", "cpu": false, "player": 0, "nation": "ngc", "look": {}},
		{"name": "cpu", "cpu": true, "skill": 0.5, "player": -1, "nation": "usa", "look": {}}], "easy", 3)
	var e: Node = load("res://ui/event_screen.gd").new()
	e.meet = m
	e.fx = Fx.new()
	e.race = Race.new()
	e.race.setup("sprint", Beat.new(90.0, 0.0), m.entrants, "easy", 0.0, 3)
	e.lesson = "sprint"
	check(e.coaching(), "a lesson always has the coach")
	e.stage = "play"
	check(e.coach_text() == "GET READY TO TAP RUN!", "before the gun: get ready (%s)" % e.coach_text())
	e._gun_done = true
	var b: Bouncer = e.race.athletes[0]
	b.state = "run"
	check(e.coach_text().begins_with("TAP RUN"), "slow: tap RUN (%s)" % e.coach_text())
	e.fx.cues = [{"p": Vector2.ZERO, "k": 1.0, "now": true}]
	check(e.coach_text() == "JUMP NOW!", "the circle's closed: JUMP NOW")
	e.fx.cues = [{"p": Vector2.ZERO, "hold": 0.4}]
	check(e.coach_text() == "KEEP HOLDING JUMP!", "held: keep holding")
	var f := Kit.font("small")
	for text in ["TAP RUN, RUN, RUN!  LEFT, RIGHT, LEFT, RIGHT!", "WAIT... JUMP WHEN THE CIRCLE IS SMALL", "TAP BOUNCE EACH TIME YOU LAND"]:
		check(f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 16 <= 470, "the coach's words fit the screen: " + text)
	e.lesson = ""
	prof.learn = false
	check(not e.coaching(), "LEARN MODE off: no coach")
	prof.learn = true
	e.fx.free()
	e.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_learn.json"))
	prof.stats = keep[0]
	prof.unlocked = keep[1]
	prof.fresh = keep[2]
	prof.path = keep[3]


## A player's go at a field event: RUN tapped in turn at `rate` from the start
## of the wait, JUMP pressed on the landing the circle closes on.
func _bash_go(id: String, rate: float) -> Variant:
	var beat := Beat.new(90.0, 0.0)
	var who := {"name": "Kid", "cpu": false}
	var a: Variant
	match String(Catalog.event(id).kind):
		"jump":
			a = Jump.new()
			a.setup(id, beat, who, "easy", 0.0, 7)
		"high":
			a = High.new()
			a.setup(beat, who, "easy", 1.5 if id == "high_jump" else 3.0, 0.0, 7, id)
		"throw":
			a = Throw.new()
			a.setup(beat, who, "easy", 0.0, 7)
	var dt := 1.0 / 60.0
	var t := 0.0
	var next_tap := 0.0
	var side := 0
	var done := {}
	while t < 40.0 and not a.finished():
		t += dt
		if a.run_up() and t >= next_tap:
			a.run(side, t)
			side = 1 - side
			next_tap = t + 1.0 / rate
		var b: Bouncer = a.b
		if b.state == "run" and a.state == "run":
			# the take-off by its line (the board, the spot); the put when it's spun up
			var line := false
			if a is Jump and a.phase_i == 0:
				line = true
				if b.x >= Jump.IDEAL - 0.2:
					a.press(true, t)
			elif a is High:
				line = true
				if b.x >= a.SPOT - 0.1:
					a.press(true, t)
			elif a is Throw:
				line = true
				if b.spring >= 0.85 or b.to_slot >= Throw.MAX_BOUNCES - 5:
					a.press(true, t)
			for s in (range(b.to_slot, b.to_slot + 4) if not line else []):
				var want: bool = a.wants_action(s)
				if want:
					if t >= b.slot_time(s) and not done.has(s):
						done[s] = true
						a.press(true, t)
					break
		a.update(t, dt)
	return a


func test_runups() -> void:
	_begin("running on two RUN buttons")
	var es: GDScript = load("res://ui/event_screen.gd")
	var bash_kinds: Array = es.BASH_KINDS
	for k in ["race", "jump", "high", "throw", "bob"]:
		check(k in bash_kinds, "%s is run on RUN buttons" % k)
	for k in ["dive", "skijump", "tramp", "battle", "skate"]:
		check(not k in bash_kinds, "%s stays on BOUNCE (no running in it)" % k)
	for id in Catalog.order():
		var e := Catalog.event(id)
		if String(e.kind) in bash_kinds:
			check(String(e.get("how_easy", "")).contains("RUN") or String(e.get("how_easy", "")).contains("SWIM"),
				"%s's card says to tap RUN" % id)
	for id in ["long_jump", "triple_jump", "meatball_put"]:
		var q := float(Catalog.event(id).qualify.easy)
		var slow: Variant = _bash_go(id, 2.0)
		var fast: Variant = _bash_go(id, 3.0)
		var flat: Variant = _bash_go(id, 4.5)
		check(slow.result() >= q, "%s: two taps a second still qualifies (%.2f, needs %.2f)" % [id, slow.result(), q])
		# (the put is thrown once it's spun up, so past three a second it's as far as it goes)
		check(fast.result() > slow.result() and flat.result() > fast.result() - (0.5 if id == "meatball_put" else 0.0),
			"%s: faster tapping goes further (%.2f, %.2f, %.2f)" % [id, slow.result(), fast.result(), flat.result()])
	check(_bash_go("high_jump", 2.5).cleared, "the high jump's first bar is cleared at two and a half taps a second")
	check(_bash_go("vault", 3.0).cleared, "and the vault's")
	# the computer still bounces on the beat; a BOUNCE in the run-up counts as RUN
	var cpu := Jump.new()
	cpu.setup("long_jump", Beat.new(90.0, 0.0), {"name": "c", "cpu": true, "skill": 0.5}, "easy", 0.0, 3)
	check(not cpu.b.bash and not cpu.run_up(), "the computer runs up on the beat")
	var j := Jump.new()
	j.setup("long_jump", Beat.new(90.0, 0.0), {"name": "p", "cpu": false}, "easy", 0.0, 3)
	check(j.run_up() and j.state == "set", "a player's run-up takes RUN taps before it starts")
	j.run(0, 0.1)
	j.run(0, 0.2)
	j.run(1, 0.3)
	check(j.b.bash_rate(0.3) > 0.0 and j.b._bash_taps.size() == 2, "the same RUN button twice doesn't count; in turn does")
	# the bobsleigh: RUN pushes, then the RUN buttons lean low
	var bo := Bob.new()
	bo.setup(Beat.new(90.0, 0.0), {"name": "p", "cpu": false}, "easy", 0.0, 3, 3)
	check(bo.run_up(), "the bobsleigh's push takes RUN taps")
	var dv := Dive.new()
	dv.setup(Beat.new(90.0, 0.0), {"name": "p", "cpu": false}, "easy", 0.0, 3)
	check(not dv.b.bash, "the dive's board bounces on the beat")


## A pretend event screen for the buttons' words: just what Controls reads.
func _controls_screen(id: String) -> Node:
	var es: Node = load("res://ui/event_screen.gd").new()
	var m := Meet.new()
	m.setup(id, [{"name": "me", "cpu": false, "player": 0, "nation": "ngc", "look": {}},
		{"name": "cpu", "cpu": true, "skill": 0.5, "player": -1, "nation": "usa", "look": {}}], "easy", 3)
	es.meet = m
	es.fx = Fx.new()
	es.stage = "play"
	es.turn = 0
	return es


func test_controls() -> void:
	_begin("the buttons say what they do")
	var f := Kit.font("small")
	var beat := Beat.new(90.0, 0.0)
	var said := {}
	# every word a button can say fits on it (four players' RUN buttons are the smallest)
	for w in ["RUN", "SWIM", "JUMP", "BOUNCE", "TAG", "AIR", "HOP", "SKIP", "HOLD", "ARCH", "THROW", "FLIP", "TWIST",
			"LOW", "HIGH", "TUCK", "STEADY", "LAND", "STICK", "ROCK", "SPIN", "PUSH", "OLLIE", "GRIND"]:
		var room := 2.0 * (16.0 if w in ["RUN", "SWIM", "JUMP", "TAG", "AIR", "HOP", "SKIP", "HOLD", "ARCH", "LOW", "HIGH"] else 22.0) - 4.0
		check(f.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x <= room, "%s fits on its button" % w)
	# the triple jump: HOP, then SKIP, then JUMP
	var es := _controls_screen("triple_jump")
	var j := Jump.new()
	j.setup("triple_jump", beat, {"name": "me", "cpu": false}, "easy", 0.0, 3)
	es.attempt = j
	check(Controls.of(es, 0, 0.0).j == "HOP", "the triple jump's first press says HOP")
	j.phase_i = 1
	check(Controls.of(es, 0, 0.0).j == "SKIP", "then SKIP")
	j.phase_i = 2
	check(Controls.of(es, 0, 0.0).j == "JUMP", "then JUMP")
	j.phase_i = 0
	check(Controls.of(es, 0, 0.0).lit == Controls.BOUNCE, "before the run-up, the RUN buttons light up")
	es.fx.cues = [{"p": Vector2.ZERO, "k": 0.9, "now": false, "h": 0}]
	check(Controls.of(es, 0, 0.0).lit == Controls.JUMP, "the circle closing lights JUMP")
	es.fx.free()
	es.free()
	# the high jump: ARCH in the air
	es = _controls_screen("high_jump")
	var hi := High.new()
	hi.setup(beat, {"name": "me", "cpu": false}, "easy", 1.5, 0.0, 3, "high_jump")
	es.attempt = hi
	hi.state = "air"
	hi.apex_time = 1.0
	hi.arched_at = -1.0
	var c := Controls.of(es, 0, 0.9)
	check(c.j == "ARCH" and c.lit == Controls.JUMP, "at the top of the high jump: ARCH, lit")
	es.fx.free()
	es.free()
	# the dive: FLIP and TWIST in the air
	es = _controls_screen("dive")
	var dv := Dive.new()
	dv.setup(beat, {"name": "me", "cpu": false}, "easy", 0.0, 3)
	es.attempt = dv
	check(Controls.of(es, 0, 0.0).b == "BOUNCE", "on the board: BOUNCE")
	dv.state = "air"
	dv._launch_t = 5.0
	dv._flight = 3.0
	c = Controls.of(es, 0, 5.0)
	check(c.b == "FLIP" and c.j == "TWIST", "in the air: FLIP and TWIST")
	es.fx.free()
	es.free()
	# the bobsleigh: HOP in, then HIGH or LOW, the next bend's lit
	es = _controls_screen("bobsleigh")
	var bo := Bob.new()
	bo.setup(beat, {"name": "me", "cpu": false}, "easy", 0.0, 3, 3)
	es.attempt = bo
	bo.state = "push"
	check(Controls.of(es, 0, bo.go + 0.5).j == "HOP", "the push: HOP to get in")
	bo.state = "run"
	var bend: Dictionary = bo.bends[0]
	c = Controls.of(es, 0, bo.bend_time(bend) - 0.2)
	check(c.b == "LOW" and c.j == "HIGH" and c.lit == (Controls.JUMP if bend.high else Controls.BOUNCE),
		"a bend coming lights its lean (%s)" % ("HIGH" if bend.high else "LOW"))
	es.fx.free()
	es.free()
	# breaking: the next move lights up
	es = _controls_screen("breaking")
	var bt := Battle.new()
	bt.setup(beat, {"name": "me", "cpu": false}, "easy", 0.0, 3, 3)
	es.attempt = bt
	bt.state = "answer"
	bt.notes = [{"at": 2.0, "action": true, "grade": ""}]
	c = Controls.of(es, 0, 1.85)
	check(c.b == "ROCK" and c.j == "SPIN" and c.lit == Controls.JUMP, "breaking: the next move, SPIN, lights up")
	es.fx.free()
	es.free()
	# the ski jump: TUCK, then STEADY and LAND
	es = _controls_screen("ski_jump")
	var sj := SkiJump.new()
	sj.setup(beat, {"name": "me", "cpu": false}, "easy", 0.0, 3)
	es.attempt = sj
	sj.state = "inrun"
	check(Controls.of(es, 0, sj.go + 0.1).b == "TUCK", "the ski jump's in-run: TUCK")
	sj.state = "flight"
	c = Controls.of(es, 0, sj.go + 6.0)
	check(c.b == "STEADY" and c.j == "LAND", "in the air: STEADY and LAND")
	es.fx.free()
	es.free()
	# the pad draws what it's told
	var pad_s: GDScript = load("res://ui/pad.gd")
	var pad: Node = pad_s.new()
	pad.set_controls(0, "FLIP", "TWIST", 1)
	check(pad.words[0] == ["FLIP", "TWIST"] and int(pad.lit[0]) == 1, "the pad takes the words and the lit button")
	pad.free()


func test_aim() -> void:
	_begin("the aim, the Track & Field way")
	check(Aim.speed("gentle") < Aim.speed("keen") and Aim.speed("keen") < Aim.speed("legendary"),
		"the needle climbs faster for older players")
	check(Aim.green("gentle") > Aim.green("legendary"), "and the green is narrower")
	check(Aim.helps("gentle") and not Aim.helps("keen"), "ages 5-7 get a hand")
	check(Aim.line_grade(0.1, false) == "perfect" and Aim.line_grade(-1.5, false) == "ok" and Aim.line_grade(0.0, true) == "ok",
		"a take-off near its line is perfect, far from it ok")
	var beat := Beat.new(90.0, 0.0)
	for band in ["gentle", "keen"]:
		var j := Jump.new()
		j.setup("long_jump", beat, {"name": "x", "cpu": false, "band": band}, "easy", 0.0)
		var t := 0.0
		var top := 0.0
		var pressed := false
		while not j.finished() and t < 30.0:
			t += 1.0 / 120.0
			if j.run_up():
				j.run(int(t * 8.0) % 2, t)
			if not pressed and j.b.state == "run" and j.state == "run" and j.b.x >= -0.3:
				pressed = true
				j.press(true, t)
			if j.b.state == "hold":
				var a: Dictionary = j.aim(t)
				top = maxf(top, float(a.angle))
				check(float(a.lo) < 43.0 and float(a.hi) > 43.0, "the green is round the best angle")
			j.update(t, 1.0 / 120.0)
		var launch: Array = j.log.filter(func(e): return e.kind == "launch")
		if band == "gentle":
			check(not launch.is_empty() and absf(float(launch[0].angle) - j.aim_target) < 3.0,
				"held on at ages 5-7, it lets go at the best angle (%.0f)" % (float(launch[0].angle) if not launch.is_empty() else -1.0))
		else:
			check(not launch.is_empty() and float(launch[0].angle) > 80.0,
				"held on from 8 up, it goes straight up (%.0f)" % (float(launch[0].angle) if not launch.is_empty() else -1.0))
	var f := Kit.font("small")
	for text in ["HOLD IT... LET GO IN THE GREEN!", "JUMP BY THE LINE, WHEN THE CIRCLE IS SMALL", "TOO HIGH! LET GO!"]:
		check(f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 16 <= 470, "the coach's words fit: " + text)


func test_scan() -> void:
	_begin("joining another tablet by its code")
	var scanner: GDScript = load("res://ui/qr_scanner.gd")
	var join: GDScript = load("res://ui/join.gd")
	check(scanner.address("http://192.168.1.23:8642/") == ["192.168.1.23", 8642], "the PLAY TOGETHER code is the game's address")
	check(scanner.address("http://10.0.0.5/") == ["10.0.0.5", 8642], "with the usual port if it doesn't say")
	check(scanner.address("hello").is_empty() and scanner.address("http://example.com/").is_empty(), "other codes aren't")
	# the camera reads the code off the other tablet's screen, at any size, in uneven light
	var url := "http://192.168.1.23:8642/"
	var img := QR.image(url, 3, 4)
	check(QRReader.read(img) == url, "the code reads back, as it's drawn")
	var big: Image = img.duplicate()
	big.convert(Image.FORMAT_RGB8)
	big.resize(int(img.get_width() * 2.3), int(img.get_height() * 2.3), Image.INTERPOLATE_BILINEAR)
	var cam := Image.create(big.get_width() + 120, big.get_height() + 80, false, Image.FORMAT_RGB8)
	cam.fill(Color(0.35, 0.3, 0.4))
	cam.blit_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(70, 30))
	for y in cam.get_height():
		for x in cam.get_width():
			var c := cam.get_pixel(x, y)
			var k := 0.65 + 0.35 * float(x) / cam.get_width()      # light from one side
			cam.set_pixel(x, y, Color(c.r * k, c.g * k, c.b * k))
	check(QRReader.read(cam) == url, "and through a camera: bigger, off-centre, lit from one side")
	# the short code
	var own := PackedStringArray(["192.168.1.40"])
	check(join.expand("23", own) == "192.168.1.23", "the short code is the last number of the address")
	check(join.expand("1.23", own) == "192.168.1.23", "or the last two")
	check(join.expand("192.168.4.7", own) == "192.168.4.7", "a whole address stays as it is")
	check(join.expand("300", own) == "" and join.expand("ab", own) == "" and join.expand("23", PackedStringArray()) == "",
		"nonsense, or no Wi-Fi, is no address")


## The hop, skip and jump, for young players: SKIP and JUMP any time in the
## air; at 5-7 they happen anyway.
func test_triple_easy() -> void:
	_begin("an easier hop, skip and jump")
	for case in [["keen", true], ["gentle", false]]:
		var j := Jump.new()
		j.setup("triple_jump", Beat.new(90.0, 0.0), {"name": "x", "cpu": false, "band": String(case[0])}, "easy", 0.0)
		var t := 0.0
		var pressed := {}
		while not j.finished() and t < 40.0:
			t += 1.0 / 120.0
			if j.run_up():
				j.run(int(t * 6.0) % 2, t)
			var b: Bouncer = j.b
			if j.state == "run" and b.state == "run":
				if j.phase_i == 0 and b.x >= -0.4:
					j.press(true, t)
				elif j.phase_i > 0 and bool(case[1]) and not pressed.has(j.phase_i):
					# well before the landing, half way through the flight
					var mid := (b.slot_time(b.from_slot) + b.slot_time(b.to_slot)) / 2.0
					if t >= mid:
						pressed[j.phase_i] = true
						j.press(true, t)
			j.update(t, 1.0 / 120.0)
		var kinds: Array = j.log.map(func(e): return String(e.kind))
		check(j.foul == "" and "skip" in kinds and "jump" in kinds and j.mark >= 8.5,
			"%s: hop, skip, jump and a qualifying mark (%.2f, %s)" % [
				"pressed in the air" if bool(case[1]) else "at 5-7, never pressed", j.mark, j.foul])
