class_name Mirror
extends Control
## A tablet that has joined another's game over the Wi-Fi. It shows that
## game's picture as it is sent (ui/remote.gd packs it), plays its music in
## step and its sounds, and has buttons for its own one or two players. Their
## presses go back stamped with the moment they happened on the host's clock,
## which this keeps in step by pinging, so they are judged on the beat.
##
## Between events (and while paused) a tap on the picture is a tap on the
## host's screen, so the menus work from either tablet.

signal left

const RETRY := 1.5

var host := ""
var ws_port := 8643
var local_players := 1
var frames := 0                   ## pictures shown
var _ws: WebSocketPeer
var _greeted := false
var _view: TextureRect
var _tex: ImageTexture
var _pad: Pad
var _status: Label
var _names: Label
var _leave: Button
var _you := {}
var _synced := false
var _offset := 0.0                ## the host's clock less this one's (ms)
var _samples: Array = []
var _ping_t := 0.0
var _pings := 0
var _retry := 0.0
var _stopped := false
var _id := ""
var auto_tap := false              ## for trying it by hand: tap BOUNCE on every bounce of the host's beat
var verbose := false               ## print pictures a second and how far the music is from the host's
var _stat_t := 0.0
var _stat_frames := 0
var _music := {}                   ## the last word on the host's music, with when it came
var _next_tap := 0.0


func setup(p_host: String, p_ws_port: int, p_players: int) -> void:
	host = p_host
	ws_port = p_ws_port
	local_players = clampi(p_players, 1, 2)


func _ready() -> void:
	Kit.fill(self)
	_id = "tablet-%d" % (hash(OS.get_unique_id() + str(Time.get_unix_time_from_system())) & 0x7fffffff)
	var bg := ColorRect.new()
	bg.color = Kit.INK
	Kit.fill(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_view = TextureRect.new()
	Kit.fill(_view)
	_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_status = Kit.label("", "big", Kit.MUSTARD)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Kit.fill(_status)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)
	_names = Kit.label("", "small", Kit.PAPER)
	_names.add_theme_stylebox_override("normal", Kit.box(Color(Kit.INK, 0.75), Kit.INK, 0, 0))
	_names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_names.z_index = 60
	add_child(_names)
	_pad = Pad.new()
	_pad.players = local_players
	_pad.z_index = 50
	_pad.visible = false
	add_child(_pad)
	_pad.pressed.connect(func(p: int, a: bool, _at: float): _press(p, a, true))
	_pad.released.connect(func(p: int, a: bool, _at: float): _press(p, a, false))
	_pad.ran.connect(func(p: int, side: int, _at: float):
		_send({"t": "tap", "p": p, "a": 0, "s": side, "d": 1, "h": host_now()}))
	_leave = Kit.small_button("LEAVE", Color("6a2a3a"), 44)
	_leave.z_index = 70
	_leave.focus_mode = Control.FOCUS_NONE
	_leave.pressed.connect(_leave_now)
	add_child(_leave)
	Sound.follow("", 0.0, false)
	_connect()


func _exit_tree() -> void:
	if _ws:
		_ws.close()
	Sound.unfollow()


func _connect() -> void:
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 22          # room for the game's pictures
	_ws.outbound_buffer_size = 1 << 16
	_greeted = false
	_synced = false
	_samples = []
	_pings = 0
	_ping_t = 0.0
	if _ws.connect_to_url("ws://%s:%d/" % [host, ws_port]) != OK:
		_ws = null
		_retry = RETRY
	_status.text = "JOINING THE GAME..." if frames == 0 else ""


func _leave_now() -> void:
	_stopped = true
	if _ws:
		_ws.close()
	Sound.unfollow()
	left.emit()


# -- each frame ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	var s := get_viewport_rect().size if is_inside_tree() else Vector2(480, 270)
	_leave.position = Vector2(s.x - 50, 4)
	_names.position = Vector2(2, s.y - 18)
	if _stopped:
		return
	if _ws == null:
		_retry -= delta
		if _retry <= 0.0:
			_connect()
		return
	_ws.poll()
	var st := _ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		if not _greeted:
			_greeted = true
			var mine: Array = []
			for i in local_players:
				mine.append(Profile.athlete(i))
			_send({"t": "hello", "id": _id, "kind": "tablet", "players": mine, "cal": Profile.calibration})
		_ping_t -= delta
		if _ping_t <= 0.0:
			_pings += 1
			_ping_t = 0.12 if _pings < 12 else 2.0
			_send({"t": "ping", "c": Time.get_ticks_usec() / 1000.0})
		var picture := PackedByteArray()
		while _ws.get_available_packet_count() > 0:
			var pkt := _ws.get_packet()
			if _ws.was_string_packet():
				_heard(pkt.get_string_from_utf8())
			else:
				picture = pkt                      # only the newest is worth drawing
		if not picture.is_empty():
			_show(picture)
	elif st == WebSocketPeer.STATE_CLOSED:
		_ws = null
		_retry = RETRY
		_pad.visible = false
		if not _stopped:
			_status.text = "LOOKING FOR THE GAME..."
	_leave.visible = not (_pad.visible)
	if auto_tap and _pad.visible and _synced:
		_auto_tap(delta)
	if verbose:
		_stat_t += delta
		if _stat_t >= 5.0:
			var here: Dictionary = Sound.heard()
			var there := float(_music.get("pos", 0.0)) + (host_now() - float(_music.get("h", 0.0))) / 1000.0
			print("mirror: %.1f pictures/s; music %s here %.3f, host %.3f (%+.0fms)" % [(frames - _stat_frames) / _stat_t,
				String(here.path).get_file(), float(here.pos), there, (float(here.pos) - there) * 1000.0])
			_stat_t = 0.0
			_stat_frames = frames


func _show(pkt: PackedByteArray) -> void:
	var img := Remote.unpack_frame(pkt)
	if img == null:
		return
	if _tex == null or _tex.get_size() != Vector2(img.get_size()):
		_tex = ImageTexture.create_from_image(img)
		_view.texture = _tex
	else:
		_tex.update(img)
	frames += 1
	if _status.text != "":
		_status.text = ""


func _heard(text: String) -> void:
	var m: Variant = JSON.parse_string(text)
	if not m is Dictionary:
		return
	match String(m.get("t", "")):
		"pong":
			_pong(m)
		"you":
			_you = m
			_pad.visible = bool(m.get("event", false)) and not bool(m.get("paused", false))
			if _pad.bash != bool(m.get("bash", false)) or not bool(m.get("event", false)):
				_pad.words.clear()
				_pad.lit.clear()
			_pad.bash = bool(m.get("bash", false))
			_pad.run_word = String(m.get("run", "RUN"))
			_pad.queue_redraw()
			var tags := PackedStringArray()
			var players: Array = m.get("players", [])
			var names: Array = m.get("names", [])
			for i in players.size():
				tags.append("P%d %s" % [int(players[i]) + 1, String(names[i] if i < names.size() else "").to_upper()])
			_names.text = "   ".join(tags)
		"words":
			# what one of this tablet's players' buttons do now
			var mine: Array = _you.get("players", [])
			var local := mine.find(int(m.get("p", -1)))
			if local >= 0:
				_pad.set_controls(local, String(m.get("b", "BOUNCE")), String(m.get("j", "JUMP")), int(m.get("l", -1)))
		"music":
			_music = m
			var age := (host_now() - float(m.get("h", 0.0))) / 1000.0 if _synced else 0.03
			Sound.follow(String(m.get("path", "")), float(m.get("pos", 0.0)) + clampf(age, 0.0, 0.5),
				bool(m.get("paused", false)))
		"sfx":
			Sound.play(String(m.get("n", "")), float(m.get("v", 1.0)), float(m.get("p", 1.0)))
		"full":
			_stopped = true
			_status.text = "THAT GAME IS FULL"
		"bye":
			_stopped = true
			_status.text = "YOU'VE LEFT THAT GAME"


func _send(m: Dictionary) -> void:
	if _ws and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(m))


# -- the host's clock -------------------------------------------------------------------------

func _pong(m: Dictionary) -> void:
	var now := Time.get_ticks_usec() / 1000.0
	var rtt := now - float(m.get("c", 0.0))
	if rtt < 0.0 or rtt > 2000.0:
		return
	_samples.append([rtt, float(m.get("h", 0.0)) - (float(m.get("c", 0.0)) + rtt / 2.0)])
	if _samples.size() > 24:
		_samples.pop_front()
	var best: Array = _samples[0]
	for sm in _samples:
		if float(sm[0]) < float(best[0]):
			best = sm
	_offset = float(best[1])
	_synced = true


## Now, on the host's clock (ms), or -1 before the clocks agree.
func host_now() -> float:
	return Time.get_ticks_usec() / 1000.0 + _offset if _synced else -1.0


# -- presses and taps -------------------------------------------------------------------------

func _press(p: int, action: bool, down: bool) -> void:
	_send({"t": "tap", "p": p, "a": 1 if action else 0, "d": 1 if down else 0, "h": host_now()})


func _auto_tap(delta: float) -> void:
	var b: Variant = _you.get("beat", {})
	var now := host_now()
	if not b is Dictionary or (b as Dictionary).is_empty():
		_beat_from = 0.0
		_next_tap -= delta * 1000.0         # no beat (the card, the scoreboard): a tap now and then
		if _next_tap < -1500.0:
			_next_tap = 0.0
			_send({"t": "tap", "p": 0, "a": 0, "d": 1, "h": now})
			_send({"t": "tap", "p": 0, "a": 0, "d": 0, "h": now + 50.0})
		return
	if _beat_from <= 0.0:
		_beat_from = now + float(b.get("ms", 680.0)) * 8.5   # after the count-in (no false starts)
		_next_tap = 0.0
	if now < _beat_from:
		return
	var step := float(b.get("bounce", 357.0))
	if _next_tap <= 0.0 or _next_tap < now - step or _next_tap > now + step * 1.5:
		_next_tap = float(b.t0) + ceilf((now - float(b.t0)) / step) * step
	if now >= _next_tap:
		_send({"t": "tap", "p": 0, "a": 0, "d": 1, "h": _next_tap})
		_send({"t": "tap", "p": 0, "a": 0, "d": 0, "h": _next_tap + 50.0})
		_next_tap += step


var _beat_from := 0.0


## Between events, a tap on the picture is a tap on the host's screen.
func _gui_input(event: InputEvent) -> void:
	if _pad.visible or _tex == null:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var at := frame_point(event.position, size, _tex.get_size())
		if at.x >= 0.0:
			_send({"t": "click", "x": at.x, "y": at.y, "d": 1 if event.pressed else 0})
			accept_event()


## Where a point on this screen falls on the host's picture, shown centred and
## scaled to fit (or (-1, -1) outside it).
static func frame_point(p: Vector2, area: Vector2, frame: Vector2) -> Vector2:
	if frame.x <= 0.0 or frame.y <= 0.0:
		return Vector2(-1, -1)
	var k := minf(area.x / frame.x, area.y / frame.y)
	var off := (area - frame * k) / 2.0
	var q := (p - off) / k
	if q.x < 0.0 or q.y < 0.0 or q.x >= frame.x or q.y >= frame.y:
		return Vector2(-1, -1)
	return q


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()


## Back in an event pauses the game (for everyone); otherwise it leaves.
func _back() -> void:
	if bool(_you.get("event", false)) and _ws:
		_send({"t": "back"})
	else:
		_leave_now()
