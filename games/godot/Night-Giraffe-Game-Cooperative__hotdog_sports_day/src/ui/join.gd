class_name JoinGame
extends Control
## Joining another tablet's game: the games on this Wi-Fi (each host sends a
## beacon every second), how many play on this tablet, and two ways in if the
## beacon doesn't get through: SCAN ITS CODE with this tablet's camera (the QR
## code on the other tablet's PLAY TOGETHER screen; ui/qr_scanner.gd), or type
## its short code (the last number of its address, "23" for 192.168.1.23).

signal chosen(host: String, ws_port: int, players: int)
signal back

const FORGET := 4.0               ## seconds without a beacon before a game leaves the list

var loopback := false             ## listen on this computer only (two copies side by side)
var _listen: PacketPeerUDP
var _games := {}                  ## "ip:port" -> {ip, port, name, room, seen}
var _list: VBoxContainer
var _looking: Label
var _players_btn: Button
var _addr: LineEdit
var _n := 1
var _t := 0.0
var _shown := ""
var stadium: StadiumView


func _ready() -> void:
	Kit.fill(self)
	_n = clampi(Profile.players, 1, 2)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = 30.0
	stadium.excite = 0.4
	_listen = PacketPeerUDP.new()
	_listen.set_broadcast_enabled(true)
	_listen.bind(Remote.BEACON_PORT, "127.0.0.1" if loopback else "*")
	var panel := Kit.panel(Color("2a1e3e"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size = Vector2(300, 0)
	panel.add_child(box)
	var title := Kit.label("JOIN A GAME", "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var how := Kit.label("On the other tablet: PLAY TOGETHER. Its game shows up here.", "small", Kit.GREY)
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size = Vector2(296, 0)
	box.add_child(how)
	_looking = Kit.label("LOOKING ON THE WI-FI...", "small", Kit.AMBER)
	_looking.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_looking)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	box.add_child(_list)
	var scan := Kit.small_button("SCAN ITS CODE", Color("7a3ad2"), 296)
	scan.custom_minimum_size.y = 22
	scan.pressed.connect(_scan)
	box.add_child(scan)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_addr = LineEdit.new()
	_addr.placeholder_text = "OR TYPE ITS CODE"
	_addr.custom_minimum_size = Vector2(190, 18)
	_addr.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	_addr.add_theme_font_size_override("font_size", 9)
	_addr.text_submitted.connect(func(_t): _join_typed())
	row.add_child(_addr)
	var go := Kit.small_button("JOIN", Kit.KETCHUP, 50)
	go.pressed.connect(_join_typed)
	row.add_child(go)
	box.add_child(row)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 4)
	_players_btn = Kit.small_button("", Color("2a5a7a"), 190)
	_players_btn.pressed.connect(func():
		_n = 2 if _n == 1 else 1
		_refresh_players())
	foot.add_child(_players_btn)
	var bk := Kit.small_button("BACK", Color("4e4a62"), 56)
	bk.pressed.connect(func(): back.emit())
	foot.add_child(bk)
	box.add_child(foot)
	add_child(panel)
	_panel = panel
	_refresh_players()
	Sound.music("title")


var _panel: Control


func _exit_tree() -> void:
	if _listen:
		_listen.close()


func _refresh_players() -> void:
	_players_btn.text = "PLAYERS ON THIS TABLET: %d" % _n


func _process(delta: float) -> void:
	_t += delta
	stadium.beat = _t * 1.4
	_panel.position = ((get_viewport_rect().size - _panel.get_combined_minimum_size()) / 2.0).round()
	while _listen.get_available_packet_count() > 0:
		var pkt := _listen.get_packet()
		var ip := _listen.get_packet_ip()
		var m: Variant = JSON.parse_string(pkt.get_string_from_utf8())
		if not m is Dictionary or int(m.get("hotdog", 0)) != 1:
			continue
		if Remote.running and (ip in Remote.addresses or ip.begins_with("127.")) and not loopback:
			continue                       # this tablet's own game
		var key := "%s:%d" % [ip, int(m.get("port", 8642))]
		_games[key] = {"ip": ip, "port": int(m.get("port", 8642)), "name": String(m.get("name", "A GAME")),
			"room": int(m.get("room", 0)), "seen": _t}
	for k in _games.keys():
		if _t - float(_games[k].seen) > FORGET:
			_games.erase(k)
	var sig := ""
	for k in _games:
		sig += "%s|%s|%d;" % [k, _games[k].name, int(_games[k].room)]
	if sig != _shown:
		_shown = sig
		_fill_list()


func _fill_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	for k in _games:
		var g: Dictionary = _games[k]
		var full := int(g.room) < _n
		var b := Kit.small_button("%s  %s" % [String(g.name), "(FULL)" if full else ""], Color("1e8a8a"), 296)
		b.disabled = full
		b.pressed.connect(func(): chosen.emit(String(g.ip), int(g.port) + 1, _n))
		_list.add_child(b)
	_looking.text = "LOOKING ON THE WI-FI..." if _games.is_empty() else "TAP A GAME TO JOIN IT"


## A code typed in: the short code (23: the other tablet's address is this
## one's with its last number changed), or a whole address (192.168.1.23,
## with its port if it isn't the usual one: 192.168.1.23:8642).
func _join_typed() -> void:
	var t := _addr.text.strip_edges().trim_prefix("http://").trim_suffix("/")
	if t == "":
		return
	var p := int(t.get_slice(":", 1)) if t.contains(":") else Remote.PORTS[0]
	var ip := JoinGame.expand(t.get_slice(":", 0), Remote.lan_addresses(IP.get_local_addresses()))
	if ip == "":
		_looking.text = "THAT CODE ISN'T RIGHT, OR NO WI-FI"
		return
	chosen.emit(ip, p + 1, _n)


## A short code into an address: its numbers replace the last numbers of this
## tablet's own address on the Wi-Fi ("23" with 192.168.1.40 is 192.168.1.23;
## "1.23" is 192.168.1.23 too). A whole address stays as it is. "" if it can't.
static func expand(code: String, own: PackedStringArray) -> String:
	var parts := code.split(".", false)
	if parts.is_empty() or parts.size() > 4:
		return ""
	for q in parts:
		if not q.is_valid_int() or int(q) < 0 or int(q) > 255:
			return ""
	if parts.size() == 4:
		return code
	if own.is_empty():
		return ""
	var mine := own[0].split(".")
	if mine.size() != 4:
		return ""
	for i in parts.size():
		mine[4 - parts.size() + i] = parts[i]
	return ".".join(mine)


## SCAN ITS CODE: this tablet's camera reads the QR code on the other one.
func _scan() -> void:
	var sc := QRScanner.new()
	sc.z_index = 20
	add_child(sc)
	Kit.centre(sc)
	sc.found.connect(func(host: String, port: int):
		chosen.emit(host, port + 1, _n))
	sc.closed.connect(sc.queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back.emit()
