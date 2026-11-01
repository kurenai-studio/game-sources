# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name BattleHud
extends BattlePanel
## The HUD (RULES 4.7 to 4.9, 9.7): lives, gold, the wave, the speed 1x 2x 3x,
## pause, and the button that starts the next wave. In a build phase it reads
## "Start wave N", in honey: the only honey button here. During a wave it calls the next
## wave early and shows the gold bonus for doing so, updated live, in the plain look. On a
## level whose highlight is this button (2-1) a pulsing ring wears it while it offers an
## early call, until the first early call. Calling works while paused.
##
## A small round button turns the sound on and off: sound effects and music together (the
## master switch, "Sound effects" in Settings). Its icon is a speaker, crossed out when the
## sound is off. It is never dimmed or disabled. It never changes the music setting, so
## turning the sound back on brings back the player's own music choice. Settings holds both
## switches.
##
## The speed and the paused look are only shown here: the screen owns the clock.

## The player picked a speed.
signal speed_selected(speed: int)
## The pause button was tapped while the game runs.
signal pause_requested()
## The pause button was tapped while the game is paused.
signal resume_requested()
## A wave was started or called early. The battle has already started it.
signal wave_started()
## The player tapped the sound button. `on` is what the sound should be now.
signal sound_selected(on: bool)

var lives_label: Label
var gold_label: Label
var wave_label: Label
var pause_button: TapButton
var sound_button: TapButton
var speed_buttons: Array[TapButton] = []
var call_button: TapButton
## The pulsing ring on the call button (RULES 9.6). Visible only on a level whose highlight
## is that button, while the button offers an early call, until the first early call.
var call_ring: CallRing

var speed: int = 1
var paused: bool = false
## Whether the sound (the master switch) is on.
var sound_on: bool = true
## The run around the battle, or null in a campaign level. A run's calls go through it, because
## a draft that is owed blocks the next wave (docs/ARCHITECTURE.md 3.4).
var run: RunSession = null

## How long the lives pulse lasts, how far the heart and number grow at the peak, and
## the tint the pair takes on at the peak.
const PULSE_TIME: float = 0.3
const PULSE_GROW: float = 0.3
const PULSE_TINT: Color = Color(1.0, 0.7, 0.55)
## The font sizes the call button's label may take, biggest first. None is below FONT_SMALL.
const CALL_SIZES: Array[int] = [52, 48, 44, 40]

var _stats: HBoxContainer
var _lives_box: Control
## The lives the HUD last showed, or -1 before the first read. A drop from this value
## starts the pulse, so a restored game (its first read) never pulses.
var _shown_lives: int = -1
## Seconds into the pulse. Negative: no pulse. Driven by advance_pulse, which the screen
## calls only while the clock runs, so a pause or a card never leaves a pulse mid-way.
var _pulse_at: float = -1.0
var _row_top: HBoxContainer
var _row_mid: HBoxContainer
var _row_call: HBoxContainer
var _wide: bool = true
var _call_state: String = ""
## True once the player has called a wave early on this screen. The ring then stays away.
var _called_early: bool = false
## A part that sits in the first row, between the numbers and the pause button: the
## gate chip in portrait. Null for none.
var _gate_slot: Control = null


func _init() -> void:
	super()
	# Snug: the HUD is the one part that takes height from the map.
	add_theme_stylebox_override(&"panel", UiKit.box(Palette.PANEL, Palette.PANEL_EDGE, 3, 34, 10))
	_row_top = HBoxContainer.new()
	_row_top.add_theme_constant_override(&"separation", 12)
	_row_mid = HBoxContainer.new()
	_row_mid.add_theme_constant_override(&"separation", 12)
	_row_call = HBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	column.add_child(_row_top)
	column.add_child(_row_mid)
	column.add_child(_row_call)
	column.add_child(feedback_box)
	_stats = HBoxContainer.new()
	_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats.add_theme_constant_override(&"separation", 10)
	lives_label = _stat(&"heart")
	gold_label = _stat(&"coin")
	wave_label = _stat(&"moon")
	pause_button = UiKit.icon_button(&"pause")
	pause_button.tapped.connect(_on_pause)
	sound_button = UiKit.icon_button(&"speaker")
	sound_button.tapped.connect(_on_sound)
	_round(sound_button)
	for value: int in [1, 2, 3]:
		var b: TapButton = UiKit.button("%dx" % value)
		b.custom_minimum_size = Vector2(Layout.MIN_TOUCH, Layout.MIN_TOUCH)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.tapped.connect(_on_speed.bind(value))
		speed_buttons.append(b)
	call_button = UiKit.wrapped(UiKit.button(""))
	call_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The same height for every label, so the HUD never changes height and the map never
	# moves: two lines at the full size. A longer label takes a smaller size (_fit_call_text).
	call_button.custom_minimum_size.y = call_button_height()
	call_button.resized.connect(_fit_call_text)
	call_button.tapped.connect(_on_call)
	call_ring = CallRing.new()
	call_button.add_child(call_ring)
	_arrange(true)
	_show_speed()


## The call button's fixed height: two lines of the button font, plus the button's padding,
## and never less than a touch target.
static func call_button_height() -> float:
	var lines: float = UiTheme.font(UiTheme.WEIGHT_BOLD).get_height(UiTheme.FONT_BUTTON) * 2.0
	return maxf(Layout.MIN_TOUCH, ceilf(lines) + 2.0 * float(UiTheme.PAD_Y))


## The biggest font size, from the full size down in steps, at which the call button's label
## fits its fixed height. It wraps to the button's width, which is known once the button has
## been laid out; the button calls this again whenever its size changes.
func _fit_call_text() -> void:
	var width: float = call_button.size.x - 2.0 * float(UiTheme.PAD_X)
	if call_button.icon != null:
		width -= float(call_button.icon.get_width()) + 16.0
	if width <= 0.0 or call_button.text.is_empty():
		return
	var room: float = call_button.custom_minimum_size.y - 2.0 * float(UiTheme.PAD_Y)
	var font: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	var chosen: int = CALL_SIZES[CALL_SIZES.size() - 1]
	for size: int in CALL_SIZES:
		if font.get_multiline_string_size(call_button.text, HORIZONTAL_ALIGNMENT_LEFT, width, size).y <= room:
			chosen = size
			break
	if call_button.get_theme_font_size(&"font_size") != chosen:
		call_button.add_theme_font_size_override(&"font_size", chosen)


## True: the portrait arrangement, two rows. False: the narrow side panel of the
## landscape layout, three rows.
func set_wide(value: bool) -> void:
	wide = value
	if value != _wide:
		_arrange(value)


## Puts a part (the gate chip) in the first row of the portrait arrangement, or takes it
## out again with null. The caller removes it from its old parent first.
func set_gate_slot(node: Control) -> void:
	_gate_slot = node
	_arrange(_wide)


## Shows the speed the clock runs at.
func set_speed(value: int) -> void:
	if value >= 1 and value <= 3:
		speed = value
		_show_speed()


## Shows whether the sound is on: the speaker, crossed out when it is off.
func set_sound(on: bool) -> void:
	sound_on = on
	sound_button.icon = IconTex.make(&"speaker" if on else &"speaker_off", 72)


## Shows whether the clock is frozen: the pause button turns into a play button.
func set_paused(value: bool) -> void:
	paused = value
	pause_button.icon = IconTex.make(&"play" if paused else &"pause", 72)


## Reads the Battle: lives, gold, wave and the call button. Pass the Battle on the first call.
func refresh(new_battle: Battle = null) -> void:
	if new_battle != null:
		battle = new_battle
		_shown_lives = -1
		stop_pulse()
	if battle == null:
		return
	if _shown_lives >= 0 and battle.lives < _shown_lives:
		# Restarts the pulse from the start, never stacks.
		_pulse_at = 0.0
		_show_pulse()
	_shown_lives = maxi(battle.lives, 0)
	lives_label.text = BattleText.short_number(battle.lives)
	gold_label.text = BattleText.short_number(battle.gold)
	wave_label.text = "Wave %d/%d" % [BattleText.wave_number(battle), battle.wave_count()]
	_refresh_call()


## True while the lives pulse is playing.
func pulsing() -> bool:
	return _pulse_at >= 0.0


## Moves the lives pulse on by `delta` seconds of running game time.
func advance_pulse(delta: float) -> void:
	if _pulse_at < 0.0:
		return
	_pulse_at += delta
	if _pulse_at >= PULSE_TIME:
		stop_pulse()
	else:
		_show_pulse()


## Ends the pulse and puts the heart and number back at rest.
func stop_pulse() -> void:
	_pulse_at = -1.0
	if _lives_box != null:
		_lives_box.scale = Vector2.ONE
		_lives_box.modulate = Color.WHITE


## Scale and tint follow one half sine, so the pair grows, then settles back. The scale
## is the signal; the tint only warms it. The size and the layout never change: the
## scale turns around the center of the pair.
func _show_pulse() -> void:
	var k: float = sin(PI * clampf(_pulse_at / PULSE_TIME, 0.0, 1.0))
	_lives_box.pivot_offset = _lives_box.size * 0.5
	_lives_box.scale = Vector2.ONE * (1.0 + PULSE_GROW * k)
	_lives_box.modulate = Color.WHITE.lerp(PULSE_TINT, k)


func _stat(glyph: StringName) -> Label:
	var box: HBoxContainer = HBoxContainer.new()
	if glyph == &"heart":
		_lives_box = box
	box.add_theme_constant_override(&"separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(GlyphIcon.new(56.0).show_glyph(glyph))
	var l: Label = UiKit.label("0")
	l.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_BOLD))
	l.add_theme_font_size_override(&"font_size", UiTheme.FONT_BUTTON)
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(l)
	_stats.add_child(box)
	return l


func _arrange(is_wide: bool) -> void:
	_wide = is_wide
	var movers: Array[Control] = [_stats, sound_button, pause_button, call_button]
	if _gate_slot != null:
		movers.append(_gate_slot)
	movers.append_array(speed_buttons)
	for node: Control in movers:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
	_row_top.add_child(_stats)
	if is_wide:
		if _gate_slot != null:
			_row_top.add_child(_gate_slot)
		_row_top.add_child(pause_button)
		for b: TapButton in speed_buttons:
			_row_mid.add_child(b)
		_row_mid.add_child(call_button)
		_row_mid.add_child(sound_button)
		_row_call.visible = false
	else:
		for b: TapButton in speed_buttons:
			_row_mid.add_child(b)
		_row_mid.add_child(pause_button)
		_row_call.add_child(call_button)
		_row_call.add_child(sound_button)
		_row_call.visible = true


func _show_speed() -> void:
	for i: int in speed_buttons.size():
		var chosen: bool = speed == i + 1
		var b: TapButton = speed_buttons[i]
		# The chosen speed has a honey fill, a thick ink border and heavy type:
		# three signals, so color is never the only one.
		var box: StyleBoxFlat = _speed_box(chosen)
		for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
			b.add_theme_stylebox_override(state, box)
		var text_color: Color = Palette.TEXT_DARK if chosen else Palette.TEXT_LIGHT
		for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color"]:
			b.add_theme_color_override(state, text_color)
		b.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_HEAVY if chosen else UiTheme.WEIGHT_REGULAR))


func _speed_box(chosen: bool) -> StyleBoxFlat:
	if chosen:
		return UiKit.box(Palette.HONEY, Palette.INK_LINE, 10, UiTheme.RADIUS, 8)
	return UiKit.box(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 4, UiTheme.RADIUS, 8)


func _refresh_call() -> void:
	var info: Dictionary = battle.next_wave_info()
	var refusal: StringName = info["refusal"]
	var next_number: int = battle.waves_started + 1
	var text: String
	# A card that is owed comes first: the call button says so and wears a lock, and a tap
	# explains (RULES 14.4).
	var owes_card: bool = run != null and refusal != &"over" and refusal != &"no_more_waves" and run.drafts_owed() > 0
	# Honey only for "Start wave N" in a build phase. An early call keeps the plain look with
	# its "+N", so a new player does not take it for the next step (FUN_REVIEW_R1 item 3).
	var primary: bool = false
	var locked: bool = false
	var early: bool = false
	if owes_card:
		text = "Pick a card first" if battle.phase == Battle.Phase.BUILD else "Card due next"
		locked = true
	elif battle.phase == Battle.Phase.BUILD and refusal == &"":
		text = "Start wave %d" % next_number
		primary = true
	elif refusal == &"":
		text = "Call wave %d  +%d" % [next_number, int(info["bonus"])]
		early = true
	elif refusal == &"no_more_waves":
		text = "Last wave is out"
		locked = true
	elif refusal == &"over":
		text = "Battle over"
		locked = true
	else:
		text = "Call wave %d" % next_number
		locked = true
	call_ring.visible = early and not owes_card and not _called_early and battle.level.hint_button == &"call"
	var state: String = "%s|%s" % [text, primary]
	if state == _call_state:
		return
	_call_state = state
	show_call_label(text, primary, locked)


## Puts a label on the call button, in the honey look or the plain one, with the lock when
## the call cannot be made yet. The tests use it to try every label.
func show_call_label(text: String, primary: bool, locked: bool) -> void:
	call_button.text = text
	call_button.theme_type_variation = &"PrimaryButton" if primary else &"Button"
	# A call that cannot be made yet carries a lock, so it never differs by color alone.
	call_button.icon = IconTex.make(&"lock", 56) if locked else null
	call_button.add_theme_color_override(&"icon_normal_color", Palette.TEXT_SOFT)
	call_button.add_theme_color_override(&"icon_hover_color", Palette.TEXT_SOFT)
	call_button.add_theme_color_override(&"icon_pressed_color", Palette.TEXT_SOFT)
	_fit_call_text()


func _on_speed(value: int) -> void:
	set_speed(value)
	speed_selected.emit(value)


## A round button: a ring-edged disc, so the shape tells it from the square speed buttons.
func _round(b: TapButton) -> void:
	var disc: StyleBoxFlat = UiKit.box(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 4, 100, 8)
	var lit: StyleBoxFlat = UiKit.box(Palette.PANEL_HOVER, Palette.HONEY, 4, 100, 8)
	b.add_theme_stylebox_override(&"normal", disc)
	b.add_theme_stylebox_override(&"hover", disc)
	b.add_theme_stylebox_override(&"pressed", lit)
	b.add_theme_stylebox_override(&"hover_pressed", lit)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_hover_pressed_color"]:
		b.add_theme_color_override(state, Palette.TEXT_LIGHT)


func _on_sound() -> void:
	var now: bool = not sound_on
	set_sound(now)
	sound_selected.emit(now)


func _on_pause() -> void:
	if paused:
		resume_requested.emit()
	else:
		pause_requested.emit()


func _on_call() -> void:
	if battle == null:
		return
	var early: bool = battle.phase == Battle.Phase.WAVE
	var result: StringName = battle.start_next_wave() if run == null else run.start_next_wave()
	if result == &"draft_waiting":
		# A card is owed. The sentence says when to pick it (RULES 14.4).
		var wait_text: String = BattleText.draft_wait_text(early)
		show_feedback(wait_text)
		refused.emit(result, wait_text)
		return
	if finish(result):
		if early:
			_called_early = true
		refresh()
		wave_started.emit()
