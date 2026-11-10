class_name Pad
extends Control
## The players' buttons: BOUNCE and JUMP, on the screen and on the keys.
##
## On a touch screen the whole screen is buttons: with one player, the left
## half is BOUNCE and the right half is JUMP, so a thumb can't miss; with two,
## each player has a half, BOUNCE on its outer quarter and JUMP on its inner
## one. The drawn buttons sit in their zones and light up when pressed.
##
## Button bash (`bash`, the races): two RUN buttons side by side to tap in
## turn, and JUMP. One player: the left half is the two RUNs (a quarter each),
## the right half JUMP. Two: each half in three, RUN, RUN and JUMP inwards.
## The two RUN buttons are drawn close together, near the line between their
## zones, so two fingers can drum on them.
##
## Three or four players on one tablet: the screen in a strip each, left to
## right, BOUNCE then JUMP (or RUN, RUN, JUMP), with each strip's player
## named above its buttons.
##
## Keys: one player: Space, Z, A or Left to bounce; Enter, X, S, Right or Up to
## jump. Two players: A and S for the first, K and L (or Left and Right) for
## the second; U and I the third; 4 and 5 on the number pad the fourth. A
## game pad's bottom button bounces and its right button jumps.
## Bashing: Z/A/Left and X/S/Right run, Space/Enter/Up jumps; two players
## A, S run and D jumps, J, K run and L jumps; U, I, O and 4, 5, 6.
##
## With everyone on their phones (ui/remote.gd) there are no players here, and
## the pad draws nothing.
##
## Every press is stamped with the song clock the moment it arrives.

signal pressed(player: int, action: bool, at: float)
signal released(player: int, action: bool, at: float)
signal ran(player: int, side: int, at: float)   ## a RUN button (bashing): side 0 or 1

const BOUNCE := 0                ## the button kinds: BOUNCE (or the first RUN), JUMP, the second RUN
const JUMP := 1
const RUN2 := 2

const FACES := [[Color("e0383a"), Color("6aa2e2")], [Color("6ec040"), Color("d6b52a")],
	[Color("3a7ae0"), Color("f08a3a")], [Color("d84aa8"), Color("8a5ae0")]]   ## each player's BOUNCE/RUN and JUMP

var players := 1
var labels := ["BOUNCE", "JUMP"]
var run_word := "RUN"
var show_action := true
var bash := false
var active: Array = []          ## whose go it is (players); the others' buttons are dimmed. Empty: everyone
var quiet := false              ## don't draw the buttons (the scoreboard's up); a tap still counts
var _down := {}                 ## "p:kind" -> true while held
var _touches := {}              ## touch index -> [player, kind]
var _glow := {}                 ## "p:kind" -> seconds of light left
var holes: Array = []           ## controls a touch goes through to (the pause button)
## What each player's buttons do right now (ui/controls.gd): player ->
## [BOUNCE or RUN word, JUMP word]; and which to press next, which lights up:
## player -> BOUNCE (both RUN buttons, when running), JUMP or -1.
var words := {}
var lit := {}
var _t := 0.0


func _ready() -> void:
	Kit.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or players <= 0:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			for h in holes:
				if is_instance_valid(h) and (h as Control).visible and (h as Control).get_global_rect().grow(6.0).has_point(st.position):
					return
			var z := _zone(st.position)
			_touches[st.index] = z
			_press(z[0], z[1])
		elif _touches.has(st.index):
			var z: Array = _touches[st.index]
			_touches.erase(st.index)
			_release(z[0], z[1])
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and not event.echo:
		var k := event as InputEventKey
		var m := _key(k.physical_keycode if k.physical_keycode != 0 else k.keycode)
		if m.is_empty():
			return
		if k.pressed:
			_press(m[0], m[1])
		else:
			_release(m[0], m[1])
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton:
		var j := event as InputEventJoypadButton
		var p := clampi(j.device, 0, players - 1)
		var kind := -1
		if j.button_index == JOY_BUTTON_A:
			kind = BOUNCE
		elif bash and j.button_index == JOY_BUTTON_B:
			kind = RUN2
		elif j.button_index in [JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER]:
			kind = JUMP
		if kind < 0:
			return
		if j.pressed:
			_press(p, kind)
		else:
			_release(p, kind)


func _key(code: int) -> Array:
	if bash:
		return _bash_key(code)
	if players == 1:
		if code in [KEY_SPACE, KEY_Z, KEY_A, KEY_LEFT]:
			return [0, BOUNCE]
		if code in [KEY_ENTER, KEY_KP_ENTER, KEY_X, KEY_S, KEY_RIGHT, KEY_UP]:
			return [0, JUMP]
		return []
	if code in [KEY_A, KEY_Z]:
		return [0, BOUNCE]
	if code in [KEY_S, KEY_X]:
		return [0, JUMP]
	if code in [KEY_K, KEY_LEFT]:
		return [1, BOUNCE]
	if code in [KEY_L, KEY_RIGHT]:
		return [1, JUMP]
	if players >= 3 and code == KEY_U:
		return [2, BOUNCE]
	if players >= 3 and code == KEY_I:
		return [2, JUMP]
	if players >= 4 and code == KEY_KP_4:
		return [3, BOUNCE]
	if players >= 4 and code == KEY_KP_5:
		return [3, JUMP]
	return []


func _bash_key(code: int) -> Array:
	if players == 1:
		if code in [KEY_Z, KEY_A, KEY_LEFT]:
			return [0, BOUNCE]
		if code in [KEY_X, KEY_S, KEY_RIGHT]:
			return [0, RUN2]
		if code in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_UP]:
			return [0, JUMP]
		return []
	var keys := {KEY_A: [0, BOUNCE], KEY_S: [0, RUN2], KEY_D: [0, JUMP],
		KEY_J: [1, BOUNCE], KEY_K: [1, RUN2], KEY_L: [1, JUMP],
		KEY_LEFT: [1, BOUNCE], KEY_RIGHT: [1, RUN2], KEY_UP: [1, JUMP],
		KEY_U: [2, BOUNCE], KEY_I: [2, RUN2], KEY_O: [2, JUMP],
		KEY_KP_4: [3, BOUNCE], KEY_KP_5: [3, RUN2], KEY_KP_6: [3, JUMP]}
	var k: Array = keys.get(code, [])
	return k if not k.is_empty() and int(k[0]) < players else []


## Which button a point on the screen is: [player, kind].
func _zone(p: Vector2) -> Array:
	var s := get_viewport_rect().size
	if bash:
		return Pad.zone_bash(s, players, p)
	var z := Pad.zone_in(s, players, show_action, p)
	return [z[0], JUMP if z[1] else BOUNCE]


## Which button a point is (BOUNCE and JUMP): [player, action].
func zone(p: Vector2) -> Array:
	return Pad.zone_in(get_viewport_rect().size, players, show_action, p)


static func zone_in(s: Vector2, n: int, with_action: bool, p: Vector2) -> Array:
	if n <= 0:
		return [-1, false]
	if n == 1:
		return [0, p.x >= s.x * 0.5 and with_action]
	if n >= 3:
		var w := s.x / n
		var strip := clampi(int(p.x / w), 0, n - 1)
		return [strip, p.x - strip * w >= w * 0.5 and with_action]
	var player := 0 if p.x < s.x * 0.5 else 1
	var inner := p.x >= s.x * 0.25 and p.x < s.x * 0.75
	return [player, inner and with_action]


## Bashing: [player, kind]. One player: RUN, RUN (a quarter each), JUMP (the
## right half). Two: thirds of each half, RUN, RUN, JUMP inwards.
static func zone_bash(s: Vector2, n: int, p: Vector2) -> Array:
	if n <= 0:
		return [-1, BOUNCE]
	if n == 1:
		if p.x >= s.x * 0.5:
			return [0, JUMP]
		return [0, BOUNCE if p.x < s.x * 0.25 else RUN2]
	var kinds := [BOUNCE, RUN2, JUMP]
	if n >= 3:
		var w := s.x / n
		var strip := clampi(int(p.x / w), 0, n - 1)
		return [strip, kinds[clampi(int((p.x - strip * w) / w * 3.0), 0, 2)]]
	var player := 0 if p.x < s.x * 0.5 else 1
	var u := p.x / (s.x * 0.5) if player == 0 else (s.x - p.x) / (s.x * 0.5)   # 0 at the outer edge
	return [player, kinds[clampi(int(u * 3.0), 0, 2)]]


func _press(player: int, kind: int) -> void:
	var key := "%d:%d" % [player, kind]
	if _down.get(key, false):
		return
	_down[key] = true
	_glow[key] = 0.18
	var at := Sound.tap_time()
	if kind == JUMP:
		pressed.emit(player, true, at)
	elif bash:
		ran.emit(player, 0 if kind == BOUNCE else 1, at)
	else:
		pressed.emit(player, false, at)
	queue_redraw()


func _release(player: int, kind: int) -> void:
	var key := "%d:%d" % [player, kind]
	if not _down.get(key, false):
		return
	_down[key] = false
	if kind == JUMP:
		released.emit(player, true, Sound.tap_time())
	elif not bash:
		released.emit(player, false, Sound.tap_time())
	queue_redraw()


func held(player: int, action: bool) -> bool:
	return _down.get("%d:%d" % [player, JUMP if action else BOUNCE], false)


## For the bot and tests: press as if a thumb did.
func poke(player: int, action: bool, down: bool) -> void:
	if down:
		_press(player, JUMP if action else BOUNCE)
	else:
		_release(player, JUMP if action else BOUNCE)


## Say what a player's buttons do now, and light the one to press next.
func set_controls(player: int, bounce_word: String, jump_word: String, light: int) -> void:
	var w := [bounce_word, jump_word]
	if words.get(player, []) != w or int(lit.get(player, -1)) != light:
		words[player] = w
		lit[player] = light
		queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	var any := false
	for p in lit:
		if int(lit[p]) >= 0:
			any = true                 # (the lit button pulses)
	for k in _glow.keys():
		_glow[k] = float(_glow[k]) - delta
		if _glow[k] <= 0.0:
			_glow.erase(k)
		any = true
	if any:
		queue_redraw()


func centre(player: int, action: bool) -> Vector2:
	return Pad.centre_in(get_viewport_rect().size, players, player, action)


## Where a button is drawn: in a bottom corner of its zone.
static func centre_in(s: Vector2, n: int, player: int, action: bool) -> Vector2:
	var r := 22.0
	var y := s.y - r - 8
	if n == 1:
		return Vector2(r + 10, y) if not action else Vector2(s.x - r - 10, y)
	if n >= 3:
		var w := s.x / n
		return Vector2(roundf(w * player + w * (0.75 if action else 0.25)), y)
	if not action:
		return Vector2(r + 10 if player == 0 else s.x - r - 10, y)
	return Vector2(s.x * 0.5 - r - 10 if player == 0 else s.x * 0.5 + r + 10, y).round()


## Bashing, along the bottom: the two RUN buttons close together either side
## of the line between their zones, so two fingers can drum on them (the
## arcade's way), and JUMP in the middle of its own zone.
static func centre_bash(s: Vector2, n: int, player: int, kind: int) -> Vector2:
	var y := s.y - 30.0
	var half := (Pad.radius_for(n, true) * 2.0 + 10.0) / 2.0     # (their rings just touch)
	var side := -half if kind == BOUNCE else half
	if n == 1:
		if kind == JUMP:
			return Vector2(s.x - 32.0, y)
		return Vector2(roundf(s.x * 0.25 + side), y)
	if n >= 3:
		var w := s.x / n
		if kind == JUMP:
			return Vector2(roundf(w * player + w * 2.5 / 3.0), y)
		return Vector2(roundf(w * player + w / 3.0 + side), y)
	# two: each half in three from its outer edge, RUN, RUN, JUMP
	var x := s.x * 2.5 / 6.0 if kind == JUMP else s.x / 6.0 + side
	return Vector2(roundf(x if player == 0 else s.x - x), y)


## How big the buttons are: smaller when four share the bottom of the screen.
func radius() -> float:
	return Pad.radius_for(players, bash)


static func radius_for(n: int, bashing: bool) -> float:
	if n >= 3 and bashing:
		return 16.0 if n == 4 else 19.0
	return 22.0


func _draw() -> void:
	if quiet:
		return
	var s := get_viewport_rect().size
	for p in players:
		if players >= 2:
			# whose buttons these are
			var a := Pad.centre_bash(s, players, p, BOUNCE) if bash else Pad.centre_in(s, players, p, false)
			var b := Pad.centre_bash(s, players, p, JUMP) if bash else Pad.centre_in(s, players, p, true)
			var tag := "P%d" % (p + 1)
			var f := Kit.font("small")
			var tw := f.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			var mid := (a.x + b.x) / 2.0
			Kit.outlined(self, f, Vector2(roundf(mid - tw / 2.0), roundf(minf(a.y, b.y) - radius() - 12)), tag, 9,
				Kit.player_colour(p))
		if bash:
			for kind in [BOUNCE, RUN2, JUMP]:
				_button(p, kind)
		else:
			for a in ([false, true] if show_action else [false]):
				_button(p, JUMP if a else BOUNCE)


func _button(player: int, kind: int) -> void:
	var s := get_viewport_rect().size
	var c := Pad.centre_bash(s, players, player, kind) if bash else Pad.centre_in(s, players, player, kind == JUMP)
	var key := "%d:%d" % [player, kind]
	var down: bool = _down.get(key, false) or _glow.has(key)
	var action := kind == JUMP
	var face: Color = FACES[clampi(player, 0, FACES.size() - 1)][1 if action else 0]
	if not active.is_empty() and not player in active:
		face = face.darkened(0.55)                  # not their go
	var r := radius()
	var sink := 2.0 if down else 0.0
	draw_circle(c + Vector2(0, 3), r, Color(Kit.INK, 0.55))
	draw_circle(c + Vector2(0, sink), r, Kit.INK)
	draw_circle(c + Vector2(0, sink), r - 1, face.darkened(0.25))
	draw_circle(c + Vector2(0, sink - 1), r - 2, face if not down else face.lightened(0.2))
	draw_circle(c + Vector2(-r * 0.27, sink - r * 0.36), r * 0.23, Color(1, 1, 1, 0.35))
	var word: String = labels[1] if action else (run_word if bash else labels[0])
	var said: Array = words.get(player, [])
	if said.size() == 2:
		word = String(said[1] if action else said[0])
	var light := int(lit.get(player, -1))
	if (light == JUMP and action) or (light == BOUNCE and not action):
		# the one to press next: a ring that pulses round it
		var pulse := 0.5 + 0.5 * sin(_t * 12.0)
		draw_arc(c + Vector2(0, sink), r + 3.0, 0.0, TAU, 40, Color(Kit.INK, 0.8), 4.0)
		draw_arc(c + Vector2(0, sink), r + 3.0, 0.0, TAU, 40, Kit.MUSTARD.lerp(Kit.PAPER, pulse * 0.6), 2.0)
	var f := Kit.font("small")
	var w := f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(f, (c + Vector2(-w / 2.0 + 1, sink + 5)).round(), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Kit.INK)
	draw_string(f, (c + Vector2(-w / 2.0, sink + 4)).round(), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Kit.PAPER)
