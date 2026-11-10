extends Node
## Playing together over the home Wi-Fi (autoload "Remote"): this tablet is
## the host, and others join it.
##
## Phones: the game serves a page on the Wi-Fi. A phone that opens it (scan
## the QR code on the PLAY TOGETHER screen) gets two big buttons, BOUNCE and
## JUMP, and becomes the next player. The page is web/controller.html; it
## talks back over a WebSocket on the next port up.
##
## Tablets: another tablet running the game finds this one on the Wi-Fi (a
## beacon every second) and joins over the same WebSocket with one or two
## players of its own. It is sent the game's picture (Main's stage, packed and
## sent twenty or thirty times a second), where the music is, and every sound,
## so it shows and plays the same game; its players' presses come back like a
## phone's (ui/mirror.gd is the joining side).
##
## Up to four players in all: this tablet's own first (none, one or two), then
## the phones' and the other tablets' in the order they joined.
##
## Rhythm survives the Wi-Fi: each phone or tablet keeps its clock in step
## with this one's (it pings, and trusts the quickest round trip), stamps
## every press with the moment the finger landed, and the game judges the
## press at that moment however late the message arrives.

signal pressed(player: int, action: bool, at: float)
signal released(player: int, action: bool, at: float)
signal changed                          ## someone joined, left, or changed hot dog
signal ran(player: int, side: int, at: float)   ## a RUN button, in a button-bash race

const PORTS := [8642, 8652, 8662, 8672]  ## the page's port; the WebSocket's is one up
const BEACON_PORT := 8640               ## where a joining tablet listens for games
const MAX_PLAYERS := 4
const MAX_AGE := 0.35                   ## a press stamped older than this means a bad clock: take it as fresh
const DEFAULT_AGE := 0.04               ## the lag assumed until a clock is in step
const LET_GO := 15.0                    ## seconds a phone can be gone on the join screen before its place goes
const GRACE := 0.12                     ## extra time a remote player's landing waits for a late message
const SEND_AHEAD := 400000              ## bytes waiting to go to a tablet before its pictures are skipped

var running := false
var port := 0
var addresses: PackedStringArray = []   ## this device's addresses on the local network, best first
var address_i := 0
var screen_players := -1                ## players on this tablet's own buttons (-1: as Profile.players says)
## Everyone who joined: [{id, kind: phone or tablet, slot (a tablet's 0 or 1),
## look, sock: WebSocketPeer or null, gone: seconds, fake, cal}]. A tablet's
## second player shares its first's socket.
var phones: Array = []
var lobby := false                      ## the join screen is up (phones that leave lose their place)
var in_event := false                   ## an event is on (a joined tablet shows its buttons)
var paused := false
var bash := false                       ## a button-bash race is on: two RUN buttons and JUMP
var run_word := "RUN"
var bind := "*"                         ## where to listen: everywhere, or "127.0.0.1" (tests, shots)
var verbose := false                    ## print who joins and every press (godot -- --remote-log)
var stage: Viewport                     ## the picture joined tablets are sent (Main's)

var _http: TCPServer
var _ws: TCPServer
var _asking: Array = []                 ## [{peer: StreamPeerTCP, buf: PackedByteArray, age}]
var _closing: Array = []                ## [{peer, age}] answered, closing in a moment
var _hello: Array = []                  ## [{ws: WebSocketPeer, age}] not yet said who they are
var _page := ""
var _screen := {"title": "HOTDOG SPORTS DAY", "hint": "", "play": false}
var _turns: Array = []                  ## players whose go it is
var _beat := {}                         ## the beat now, in host milliseconds: {ms, bounce, t0}
var _dogs := {}                         ## look key -> PNG bytes
var _beacon: PacketPeerUDP
var _beacon_t := 0.0
var _music_sent := {}
var _music_t := 0.0
var _frame_task := -1
var _frame_out := PackedByteArray()
var _frame_n := 0
var _frame_every := 2
var frames_sent := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Open the doors. Returns false if no port would open.
func start() -> bool:
	if running:
		return true
	_page = _load_page()
	for p in PORTS:
		var h := TCPServer.new()
		var w := TCPServer.new()
		if h.listen(p, bind) == OK and w.listen(p + 1, bind) == OK:
			_http = h
			_ws = w
			port = p
			running = true
			break
		h.stop()
		w.stop()
	refresh_addresses()
	return running


func stop() -> void:
	if not running:
		return
	for ph in phones:
		if ph.sock:
			(ph.sock as WebSocketPeer).close()
	_http.stop()
	_ws.stop()
	running = false


func refresh_addresses() -> void:
	addresses = lan_addresses(IP.get_local_addresses())
	address_i = clampi(address_i, 0, maxi(0, addresses.size() - 1))


## The local network addresses worth trying, most likely first: home routers
## hand out 192.168.x.x; virtual machines' adapters (192.168.56.x) come last.
static func lan_addresses(all: PackedStringArray) -> PackedStringArray:
	var ranked: Array = []
	for a in all:
		if a.contains(":") or a.begins_with("127.") or a.begins_with("169.254."):
			continue
		var parts := a.split(".")
		if parts.size() != 4:
			continue
		var rank := 9
		if a.begins_with("192.168."):
			rank = 5 if parts[2] in ["56", "137"] else 0
		elif a.begins_with("10."):
			rank = 1
		elif a.begins_with("172.") and int(parts[1]) >= 16 and int(parts[1]) <= 31:
			rank = 3
		ranked.append([rank, a])
	ranked.sort_custom(func(x, y): return int(x[0]) < int(y[0]))
	var out := PackedStringArray()
	for r in ranked:
		out.append(String(r[1]))
	return out


## The address to show (the QR code's), or "" with no network.
func url() -> String:
	if not running or addresses.is_empty():
		return ""
	return "http://%s:%d/" % [addresses[address_i], port]


## Try the next address (a PC with more than one network).
func next_address() -> void:
	refresh_addresses()
	if not addresses.is_empty():
		address_i = (address_i + 1) % addresses.size()


## What a joining tablet's list calls this game.
func host_name() -> String:
	var who := String(Profile.athlete(0).get("name", "HotDog")).to_upper()
	var model := OS.get_model_name()
	if model == "" or model == "GenericDevice":
		return "%s'S GAME" % who
	return "%s'S GAME  ·  %s" % [who, model.to_upper()]


# -- who's playing -------------------------------------------------------------------------

func screen_count() -> int:
	var n: int = Profile.players if screen_players < 0 else screen_players
	if n == 0 and phones.is_empty():
		n = 1
	return clampi(n, 0, MAX_PLAYERS)


func total() -> int:
	return mini(MAX_PLAYERS, screen_count() + phones.size())


## The player number of the k-th joined player.
func player_of(k: int) -> int:
	return screen_count() + k


func phone_of(player: int) -> int:
	var k := player - screen_count()
	return k if k >= 0 and k < phones.size() else -1


## A player on a phone or another tablet (their presses come over the Wi-Fi).
func is_phone(player: int) -> bool:
	return phone_of(player) >= 0


func has_tablets() -> bool:
	for ph in phones:
		if ph.get("kind", "phone") == "tablet" and ph.sock != null:
			return true
	return false


## The looks of every player, this tablet's first.
func looks() -> Array:
	var out: Array = []
	for i in screen_count():
		out.append(Profile.athlete(i))
	for k in phones.size():
		if out.size() >= MAX_PLAYERS:
			break
		out.append(phones[k].look)
	return out


## A pretend phone, for the bot and the tests.
func add_fake(look := {}) -> void:
	phones.append({"id": "fake%d" % phones.size(), "kind": "phone", "slot": 0,
		"look": look if not look.is_empty() else _free_look(), "sock": null, "gone": 0.0, "fake": true})
	changed.emit()


func clear_fakes() -> void:
	phones = phones.filter(func(ph): return not ph.get("fake", false))
	changed.emit()


## Let a player go (a tablet's other player goes with it).
func remove(k: int) -> void:
	if k < 0 or k >= phones.size():
		return
	var id := String(phones[k].id)
	var sock: WebSocketPeer = phones[k].sock
	if sock:
		_send(sock, {"t": "bye"})
		sock.close()
	phones = phones.filter(func(ph): return String(ph.id) != id)
	_tell_everyone()
	changed.emit()


## The hot dogs a phone can be: the dressing room's, then the spares, with
## the ones already playing left out.
func _candidates() -> Array:
	var out: Array = []
	for a in Profile.athletes:
		out.append(a)
	for i in 4:
		var d: Dictionary = Profile.default_athlete(i)
		var seen := false
		for a in out:
			if String(a.get("name", "")) == String(d.name):
				seen = true
		if not seen:
			out.append(d)
	return out


func _in_use(skip_phone := -1) -> Dictionary:
	var used := {}
	for i in screen_count():
		used[String(Profile.athlete(i).get("name", ""))] = true
	for k in phones.size():
		if k != skip_phone:
			used[String(phones[k].look.get("name", ""))] = true
	return used


func _free_look(skip_phone := -1, after := "") -> Dictionary:
	var c := _candidates()
	var used := _in_use(skip_phone)
	var start := 0
	for i in c.size():
		if String(c[i].get("name", "")) == after:
			start = i + 1
	for n in c.size():
		var a: Dictionary = c[(start + n) % c.size()]
		if not used.has(String(a.get("name", ""))):
			return a
	return Profile.default_athlete(2 + phones.size() % 2)


## Player k wants a different hot dog.
func next_look(k: int) -> void:
	if k < 0 or k >= phones.size():
		return
	phones[k].look = _free_look(k, String(phones[k].look.get("name", "")))
	_tell(k)
	changed.emit()


# -- what the phones and tablets are told -------------------------------------------------------

## What the phones show at the top: what's on, and a hint.
func set_screen(title: String, hint := "", play := false) -> void:
	_screen = {"title": title, "hint": hint, "play": play}
	_tell_everyone()


## Whose go it is (players); their phones say so and buzz.
func set_turns(players: Array) -> void:
	_turns = players.duplicate()
	_tell_everyone()


func set_event(on: bool) -> void:
	in_event = on
	_tell_everyone()


func set_bash(on: bool, word := "RUN") -> void:
	bash = on
	run_word = word
	_words.clear()
	_tell_everyone()


var _words := {}                 ## player -> [BOUNCE word, JUMP word, lit], as last told


## What a player's buttons do right now, and which to press next (lit:
## 0 BOUNCE or RUN, 1 JUMP, -1 none): told to their phone or tablet when it changes.
func set_words(player: int, bounce_word: String, jump_word: String, lit: int) -> void:
	var w := [bounce_word, jump_word, lit]
	if _words.get(player, []) == w:
		return
	_words[player] = w
	var k := phone_of(player)
	if k < 0:
		return
	var msg := {"t": "words", "p": player, "b": bounce_word, "j": jump_word, "l": lit}
	var ph: Dictionary = phones[k]
	if ph.get("kind", "phone") == "tablet":
		# a tablet's players share its first connection
		for j in phones.size():
			if String(phones[j].id) == String(ph.id) and phones[j].sock != null:
				_send(phones[j].sock, msg)
				return
	elif ph.sock:
		_send(ph.sock, msg)


func set_paused(on: bool) -> void:
	paused = on
	_tell_everyone()


## The beat the music is on, so the phones' hot dogs bounce in time.
func set_beat(b: Beat) -> void:
	if b == null:
		_beat = {}
	else:
		var now_ms := Time.get_ticks_usec() / 1000.0
		_beat = {"ms": b.beat_len() * 1000.0, "bounce": b.bounce_len() * 1000.0,
			"t0": now_ms - (Sound.song_time() - b.time_of_beat(0)) * 1000.0}
	_tell_everyone()


## A grade for one player's phone to flash (perfect, good, ok, miss, fumble).
func tell_grade(player: int, grade: String) -> void:
	var k := phone_of(player)
	if k >= 0 and phones[k].sock and phones[k].get("kind", "phone") == "phone":
		_send(phones[k].sock, {"t": "grade", "g": grade})


## A sound effect, for the joined tablets to play too.
func sfx(name: String, volume: float, pitch: float) -> void:
	if not running:
		return
	var msg := {"t": "sfx", "n": name, "v": snappedf(volume, 0.01), "p": snappedf(pitch, 0.001)}
	for s in _tablet_socks():
		_send(s, msg)


func _tell_everyone() -> void:
	for k in phones.size():
		_tell(k)


func _tell(k: int) -> void:
	var ph: Dictionary = phones[k]
	if ph.sock == null:
		return
	if ph.get("kind", "phone") == "tablet":
		if int(ph.get("slot", 0)) == 0:
			_tell_tablet(k)
		return
	var player := player_of(k)
	var look: Dictionary = ph.look
	var msg := {"t": "you", "player": player, "playing": player < MAX_PLAYERS,
		"name": String(look.get("name", "")), "colour": Kit.player_colour(player).to_html(false),
		"dog": "/dog/%s.png" % _dog_key(look), "title": _screen.title, "hint": _screen.hint,
		"play": _screen.play, "turn": player in _turns, "lobby": lobby, "beat": _beat, "bash": bash and in_event,
		"run": run_word}
	if in_event and _words.has(player):
		var w: Array = _words[player]
		msg["words"] = {"b": w[0], "j": w[1], "l": w[2]}
	_send(ph.sock, msg)


func _tell_tablet(k: int) -> void:
	var ph: Dictionary = phones[k]
	var players: Array = []
	var names: Array = []
	for j in phones.size():
		if String(phones[j].id) == String(ph.id):
			players.append(player_of(j))
			names.append(String(phones[j].look.get("name", "")))
	_send(ph.sock, {"t": "you", "kind": "tablet", "players": players, "names": names,
		"title": _screen.title, "hint": _screen.hint, "event": in_event, "paused": paused,
		"turns": _turns, "lobby": lobby, "host": host_name(), "beat": _beat, "bash": bash and in_event,
		"run": run_word})


func _send(sock: WebSocketPeer, msg: Dictionary) -> void:
	if sock and sock.get_ready_state() == WebSocketPeer.STATE_OPEN:
		sock.send_text(JSON.stringify(msg))


func _tablet_socks() -> Array:
	var out: Array = []
	for ph in phones:
		if ph.get("kind", "phone") == "tablet" and int(ph.get("slot", 0)) == 0 and ph.sock != null:
			out.append(ph.sock)
	return out


static func _dog_key(look: Dictionary) -> String:
	return str(hash(JSON.stringify(look, "", true)))


# -- each frame ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not running:
		return
	_serve_pages(delta)
	_greet(delta)
	var dropped := false
	for k in range(phones.size() - 1, -1, -1):
		if k >= phones.size():
			continue
		var ph: Dictionary = phones[k]
		if ph.get("fake", false) or int(ph.get("slot", 0)) != 0:
			continue
		if ph.sock:
			var s: WebSocketPeer = ph.sock
			s.poll()
			while s.get_available_packet_count() > 0:
				_heard(k, s.get_packet().get_string_from_utf8())
				if k >= phones.size() or phones[k] != ph:
					break
			if s.get_ready_state() == WebSocketPeer.STATE_CLOSED:
				for other in phones:
					if String(other.id) == String(ph.id):
						other.sock = null
						other.gone = 0.0
				changed.emit()
		else:
			ph.gone = float(ph.gone) + delta
			if lobby and ph.gone > LET_GO:
				var id := String(ph.id)
				phones = phones.filter(func(o): return String(o.id) != id)
				dropped = true
	if dropped:
		_tell_everyone()
		changed.emit()
	_beacon_t -= delta
	if _beacon_t <= 0.0:
		_beacon_t = 1.0
		_send_beacon()
	if has_tablets():
		_send_music(delta)
		_send_frames()


func _greet(delta: float) -> void:
	while _ws.is_connection_available():
		var w := WebSocketPeer.new()
		w.outbound_buffer_size = 1 << 21        # room for the game's pictures
		w.accept_stream(_ws.take_connection())
		_hello.append({"ws": w, "age": 0.0})
	for h in _hello.duplicate():
		var w: WebSocketPeer = h.ws
		w.poll()
		h.age = float(h.age) + delta
		while w.get_available_packet_count() > 0:
			var m: Variant = JSON.parse_string(w.get_packet().get_string_from_utf8())
			if m is Dictionary and String(m.get("t", "")) == "hello":
				_hello.erase(h)
				_join(w, m)
				break
			elif m is Dictionary and String(m.get("t", "")) == "ping":
				_pong(w, m)
		if w.get_ready_state() == WebSocketPeer.STATE_CLOSED or float(h.age) > 20.0:
			_hello.erase(h)


func _join(w: WebSocketPeer, m: Dictionary) -> void:
	var id := String(m.get("id", ""))
	var kind := "tablet" if String(m.get("kind", "phone")) == "tablet" else "phone"
	var mine: Array = []
	for k in phones.size():
		if String(phones[k].id) == id and id != "":
			mine.append(k)
	if not mine.is_empty():
		var old: WebSocketPeer = phones[mine[0]].sock
		if old and old != w:
			old.close()
		for k in mine:
			phones[k].sock = w
			phones[k].gone = 0.0
		_tell(mine[0])
		changed.emit()
		return
	var want := 1
	var asked: Array = m.get("players", []) if m.get("players") is Array else []
	if kind == "tablet":
		want = clampi(asked.size(), 1, 2)
	var room := MAX_PLAYERS - total()
	if room <= 0:
		_send(w, {"t": "full"})
		w.close()
		return
	want = mini(want, room)
	for slot in want:
		var look: Dictionary = {}
		if slot < asked.size() and asked[slot] is Dictionary:
			look = asked[slot]
		if look.is_empty() or _in_use().has(String(look.get("name", ""))):
			look = _free_look()
		phones.append({"id": id, "kind": kind, "slot": slot, "look": look, "sock": w, "gone": 0.0,
			"fake": false, "cal": float(m.get("cal", 0.0))})
		if verbose:
			print("remote: P%d joined (%s) as %s" % [player_of(phones.size() - 1) + 1, kind, look.get("name", "?")])
	_tell(phones.size() - want)
	_music_sent = {}
	changed.emit()
	Sound.play("click", 0.8)


func _heard(k: int, text: String) -> void:
	var m: Variant = JSON.parse_string(text)
	if not m is Dictionary:
		return
	var ph: Dictionary = phones[k]
	var tablet: bool = ph.get("kind", "phone") == "tablet"
	match String(m.get("t", "")):
		"ping":
			_pong(ph.sock, m)
		"tap":
			var j := _slot_of(k, int(m.get("p", 0)))
			var player := player_of(j)
			if player >= MAX_PLAYERS:
				return
			var age := press_age(Time.get_ticks_usec() / 1000.0, float(m.get("h", -1.0)))
			# a phone hears this tablet's speaker; a tablet its own, with its own calibration
			var at: float = (Sound.song_time() - float(ph.get("cal", 0.0)) if tablet else Sound.tap_time()) - age
			var action := int(m.get("a", 0)) == 1
			if verbose:
				print("remote: P%d %s %s, %.0fms old" % [player + 1, "JUMP" if action else "BOUNCE",
					"down" if int(m.get("d", 1)) == 1 else "up", age * 1000.0])
			if m.has("s") and not action:
				if int(m.get("d", 1)) == 1:
					ran.emit(player, int(m.get("s", 0)), at)
			elif int(m.get("d", 1)) == 1:
				pressed.emit(player, action, at)
			else:
				released.emit(player, action, at)
		"next":
			if not _screen.play:
				next_look(_slot_of(k, int(m.get("p", 0))))
		"click":
			if tablet:
				_click(Vector2(float(m.get("x", 0)), float(m.get("y", 0))), int(m.get("d", 1)) == 1)
		"back":
			if tablet and in_event:
				get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)


## The entry for slot `slot` of the joiner whose first entry is k.
func _slot_of(k: int, slot: int) -> int:
	if slot <= 0:
		return k
	var id := String(phones[k].id)
	for j in phones.size():
		if String(phones[j].id) == id and int(phones[j].get("slot", 0)) == slot:
			return j
	return k


## A tap on a joined tablet's picture of a menu: a click here, as if on this
## screen at that spot (through the input queue, which the stage's buttons
## hear; pushing it into the stage directly doesn't reach them).
func _click(at: Vector2, down: bool) -> void:
	if stage == null or not is_inside_tree():
		return
	var p := get_tree().root.get_final_transform() * at
	if verbose:
		print("remote: a tap from a tablet at %s (%s)" % [at, "down" if down else "up"])
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	Input.parse_input_event(mm)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = down
	mb.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	mb.position = p
	mb.global_position = p
	Input.parse_input_event(mb)


func _pong(w: WebSocketPeer, m: Dictionary) -> void:
	_send(w, {"t": "pong", "c": m.get("c", 0.0), "h": Time.get_ticks_usec() / 1000.0})


## How long ago (seconds) a press stamped `stamped_ms` on the game's clock
## happened, it being `now_ms` now. A phone not yet in step sends -1.
static func press_age(now_ms: float, stamped_ms: float) -> float:
	if stamped_ms <= 0.0:
		return DEFAULT_AGE
	var age := (now_ms - stamped_ms) / 1000.0
	if age < -0.05 or age > MAX_AGE:
		return DEFAULT_AGE
	return maxf(age, 0.0)


# -- for joined tablets: the beacon, the music, the picture --------------------------------------

func _send_beacon() -> void:
	if _beacon == null:
		_beacon = PacketPeerUDP.new()
		_beacon.set_broadcast_enabled(true)
	var msg := JSON.stringify({"hotdog": 1, "name": host_name(), "port": port,
		"room": MAX_PLAYERS - total()}).to_utf8_buffer()
	var targets: Array = []
	if bind == "127.0.0.1":
		targets = ["127.0.0.1"]
	else:
		targets = ["255.255.255.255"]
		for a in addresses:
			var parts := a.split(".")
			targets.append("%s.%s.%s.255" % [parts[0], parts[1], parts[2]])
	for t in targets:
		_beacon.set_dest_address(t, BEACON_PORT)
		_beacon.put_packet(msg)


## Where the music is, so a joined tablet plays it in step: at once when the
## track changes or stops, and every half second besides.
func _send_music(delta: float) -> void:
	_music_t -= delta
	var now: Dictionary = Sound.heard()
	var changed_track: bool = String(now.path) != String(_music_sent.get("path", "")) \
		or bool(now.paused) != bool(_music_sent.get("paused", false))
	if not changed_track and _music_t > 0.0:
		return
	_music_t = 0.5
	_music_sent = now
	var msg := {"t": "music", "path": now.path, "pos": snappedf(float(now.pos), 0.001), "paused": now.paused,
		"h": Time.get_ticks_usec() / 1000.0}
	for s in _tablet_socks():
		_send(s, msg)


## The game's picture, packed on a worker thread and sent when ready; skipped
## for a tablet that hasn't caught up.
func _send_frames() -> void:
	if stage == null:
		return
	if _frame_task >= 0:
		if not WorkerThreadPool.is_task_completed(_frame_task):
			return
		WorkerThreadPool.wait_for_task_completion(_frame_task)
		_frame_task = -1
		broadcast_frame(_frame_out)
	_frame_n += 1
	if _frame_n % _frame_every != 0:
		return
	var t0 := Time.get_ticks_usec()
	var tex := stage.get_texture()
	var img: Image = tex.get_image() if tex else null
	if img == null or img.is_empty():
		return
	# a slow device grabs fewer pictures a second
	var took := (Time.get_ticks_usec() - t0) / 1000.0
	_frame_every = 4 if took > 8.0 else (3 if took > 4.0 else 2)
	_frame_task = WorkerThreadPool.add_task(_pack.bind(img))


## Send a packed picture to every joined tablet that has caught up.
func broadcast_frame(pkt: PackedByteArray) -> void:
	if pkt.is_empty():
		return
	for s in _tablet_socks():
		var sock: WebSocketPeer = s
		if sock.get_current_outbound_buffered_amount() < SEND_AHEAD:
			sock.send(pkt, WebSocketPeer.WRITE_MODE_BINARY)
	frames_sent += 1


func _pack(img: Image) -> void:
	_frame_out = pack_frame(img)


## A picture for the Wi-Fi: "HDF1", width, height, size, then the pixels
## (RGB) squeezed with zstd. Pixel art squeezes well: about 25KB.
static func pack_frame(img: Image) -> PackedByteArray:
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	var raw := img.get_data()
	var out := PackedByteArray()
	out.resize(12)
	out[0] = 0x48
	out[1] = 0x44
	out[2] = 0x46
	out[3] = 0x31
	out.encode_u16(4, img.get_width())
	out.encode_u16(6, img.get_height())
	out.encode_u32(8, raw.size())
	out.append_array(raw.compress(FileAccess.COMPRESSION_ZSTD))
	return out


static func unpack_frame(pkt: PackedByteArray) -> Image:
	if pkt.size() < 12 or pkt[0] != 0x48 or pkt[1] != 0x44 or pkt[2] != 0x46 or pkt[3] != 0x31:
		return null
	var w := pkt.decode_u16(4)
	var h := pkt.decode_u16(6)
	var n := pkt.decode_u32(8)
	if w <= 0 or h <= 0 or n != w * h * 3:
		return null
	var raw := pkt.slice(12).decompress(n, FileAccess.COMPRESSION_ZSTD)
	if raw.size() != n:
		return null
	return Image.create_from_data(w, h, false, Image.FORMAT_RGB8, raw)


# -- the web pages ---------------------------------------------------------------------------

func _load_page() -> String:
	var f := FileAccess.open("res://web/controller.html", FileAccess.READ)
	return f.get_as_text() if f else "<h1>HotDog Sports Day</h1>"


func _serve_pages(delta: float) -> void:
	while _http.is_connection_available():
		_asking.append({"peer": _http.take_connection(), "buf": PackedByteArray(), "age": 0.0})
	for c in _asking.duplicate():
		var p: StreamPeerTCP = c.peer
		p.poll()
		c.age = float(c.age) + delta
		if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_asking.erase(c)
			continue
		var n := p.get_available_bytes()
		if n > 0:
			var got: Array = p.get_partial_data(n)
			if int(got[0]) == OK:
				var grown: PackedByteArray = c.buf
				grown.append_array(got[1])
				c.buf = grown            # (a packed array in a dictionary is a copy)
		var text := (c.buf as PackedByteArray).get_string_from_ascii()
		if text.contains("\r\n\r\n"):
			_answer(p, text)
			_asking.erase(c)
			_closing.append({"peer": p, "age": 0.0})
		elif float(c.age) > 5.0 or (c.buf as PackedByteArray).size() > 16384:
			p.disconnect_from_host()
			_asking.erase(c)
	for c in _closing.duplicate():
		c.age = float(c.age) + delta
		(c.peer as StreamPeerTCP).poll()
		if float(c.age) > 2.0:
			(c.peer as StreamPeerTCP).disconnect_from_host()
			_closing.erase(c)


func _answer(p: StreamPeerTCP, request: String) -> void:
	var line := request.get_slice("\r\n", 0)
	var path := line.get_slice(" ", 1).get_slice("?", 0)
	var body := PackedByteArray()
	var kind := "text/html; charset=utf-8"
	var status := "200 OK"
	if path == "/" or path == "/index.html":
		body = _page.replace("{{WS_PORT}}", str(port + 1)).to_utf8_buffer()
	elif path.begins_with("/dog/") and path.ends_with(".png"):
		body = _dog_png(path.trim_prefix("/dog/").trim_suffix(".png"))
		kind = "image/png"
		if body.is_empty():
			status = "404 Not Found"
	elif path == "/logo.png":
		var logo: Texture2D = load("res://assets/art/ui/logo.png")
		var img := logo.get_image() if logo else null
		if img:
			if img.is_compressed():
				img.decompress()
			body = img.save_png_to_buffer()
		kind = "image/png"
	else:
		status = "404 Not Found"
		body = "not here".to_utf8_buffer()
		kind = "text/plain"
	var head := "HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n" \
		% [status, kind, body.size()]
	p.put_data(head.to_ascii_buffer() + body)


func _dog_png(key: String) -> PackedByteArray:
	if _dogs.has(key):
		return _dogs[key]
	for look in looks():
		if _dog_key(look) == key:
			var png := Portrait.png(look, 4)
			_dogs[key] = png
			return png
	return PackedByteArray()
