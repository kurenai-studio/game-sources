extends Control
const EffortEngine = preload("res://core/effort_race_engine.gd")
const TrackView = preload("res://ui/track_view.gd")
const GameSettings = preload("res://core/game_settings.gd")
const Sigma = preload("res://ui/sigma_style.gd")
const RaceDisplay = preload("res://ui/race_display.gd")
var instance_guard = preload("res://ui/instance_guard.gd").new()
var frame_budget = preload("res://ui/frame_budget.gd").new()
var track: Control
var model: RefCounted
var outcome: Dictionary = {}
var elapsed := 0.0
var playing := false
var duration := 30.0
var seed_input: SpinBox
var spread_input: SpinBox
var duration_input: SpinBox
var phase_input: SpinBox
var ticks: OptionButton
var strengths: OptionButton
var pause_button: Button
var seek_bar: HSlider
var status: Label
var detail: Label
var before_fullscreen := DisplayServer.WINDOW_MODE_WINDOWED

func _ready() -> void:
	if not instance_guard.allow_launch(get_tree()):
		set_process(false)
		return
	add_child(frame_budget)
	get_window().title = "Horse racing | SD race preview 0.8"
	var theme_value := Sigma.theme(18)
	theme_value.set_color("font_color","Label",Color("f4d185"))
	theme = theme_value
	var background := ColorRect.new()
	background.color = Sigma.BURGUNDY
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,8)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",4)
	margin.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var title := Label.new()
	title.text = "SD MODE  /  RACE PREVIEW 0.8"
	title.add_theme_font_size_override("font_size",20)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(title)
	var note := Label.new()
	note.text = "Experimental movement. Win probabilities are not calibrated. Settings apply on Start."
	note.add_theme_color_override("font_color",Color("d9c08b"))
	note.add_theme_font_size_override("font_size",17)
	box.add_child(note)
	note.hide()
	var fields := HBoxContainer.new()
	fields.add_theme_constant_override("separation",12)
	box.add_child(fields)
	fields.hide()
	seed_input = number_field(fields,"Seed",1,2147483645,1,123)
	spread_input = number_field(fields,"Speed spread (%)",0,30,1,12)
	spread_input.tooltip_text = "How far above or below normal speed a horse can aim during a surge or recovery. 12 means up to about 12%."
	phase_input = number_field(fields,"Pace phase limit (s)",1,6,0.5,3)
	phase_input.tooltip_text = "A horse keeps a surge, recovery, or steady pace for a randomly chosen 1 second to this limit, then chooses another phase."
	duration_input = number_field(fields,"Playback seconds",5,90,5,30)
	ticks = OptionButton.new()
	ticks.add_item("Fine: 10x")
	ticks.add_item("Coarse: 1x")
	add_field(fields,"Movement ticks",ticks)
	strengths = OptionButton.new()
	strengths.add_item("Varied trial tendencies")
	strengths.add_item("Equal tendencies")
	strengths.tooltip_text = "Varied gives horses 1 to 5 different chances of starting a surge. Equal removes this built-in difference. Winning odds are not calibrated."
	add_field(fields,"Surge tendencies",strengths)
	var help := Label.new()
	help.text = "Speed spread: size of pace changes.  Pace phase limit: longest time before a horse chooses a new pace.\nSurge tendencies: trial differences in how often each horse accelerates, or no built-in advantage."
	help.add_theme_font_size_override("font_size",15)
	help.add_theme_color_override("font_color",Color("b8c9d8"))
	box.add_child(help)
	help.hide()
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation",10)
	top.add_child(buttons)
	add_button(buttons,"New race",func():
		var random_seed := int(Crypto.new().generate_random_bytes(4).decode_u32(0) % 2147483645)+1
		seed_input.value = random_seed
		start_seed(random_seed))
	pause_button = add_button(buttons,"Pause / Resume",toggle_pause)
	add_button(buttons,"Replay",func():
		if not outcome.is_empty():
			elapsed = 0.0
			playing = true
			_update_view())
	add_button(buttons,"Fullscreen  F11",toggle_fullscreen)
	var race_display := RaceDisplay.new()
	box.add_child(race_display)
	var sound_preferences := GameSettings.new().values.duplicate(true)
	if FileAccess.file_exists("user://session.json"):
		var saved: Dictionary = load("res://core/session_store.gd").new().load_session("user://session.json")
		if saved.ok:
			for key in ["master_volume","mechanical_enabled","mechanical_volume","hoof_enabled","hoof_volume","frame_limit","background_fps","vsync"]:
				sound_preferences[key] = saved.settings.values[key]
	frame_budget.configure(sound_preferences)
	race_display.configure(null,sound_preferences)
	track = race_display.track
	track.moving = false
	track.directional = true
	track.size_flags_vertical = Control.SIZE_EXPAND_FILL
	seek_bar = HSlider.new()
	seek_bar.min_value = 0
	seek_bar.max_value = 100
	seek_bar.step = 0.01
	seek_bar.custom_minimum_size.y = 30
	seek_bar.tooltip_text = "Scrub the actual recorded race. Scrubbing pauses playback."
	seek_bar.value_changed.connect(func(value): seek_to(value/100.0))
	box.add_child(seek_bar)
	seek_bar.hide()
	status = Label.new()
	status.text = "Press New race. Sample payouts only; this preview does not use player balances or wagers."
	status.add_theme_font_size_override("font_size",14)
	box.add_child(status)
	detail = Label.new()
	detail.add_theme_font_size_override("font_size",16)
	detail.add_theme_color_override("font_color",Color("9fb5c7"))
	detail.text = "Each movement round shuffles all five horses. Boundary repeats and long intervals are retained."
	box.add_child(detail)
	detail.hide()

func add_field(row: HBoxContainer, label_text: String, control: Control) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 160
	row.add_child(column)
	var caption := Label.new()
	caption.text = label_text
	caption.add_theme_font_size_override("font_size",16)
	column.add_child(caption)
	control.custom_minimum_size.y = 36
	column.add_child(control)

func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]:
		DisplayServer.window_set_mode(before_fullscreen)
	else:
		before_fullscreen = mode
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func number_field(row: HBoxContainer, label_text: String, minimum: float, maximum: float, step_value: float, initial: float) -> SpinBox:
	var field := SpinBox.new()
	field.min_value = minimum
	field.max_value = maximum
	field.step = step_value
	field.value = initial
	add_field(row,label_text,field)
	return field

func add_button(row: HBoxContainer, label_text: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = label_text
	control.custom_minimum_size = Vector2(100,36)
	control.add_theme_font_size_override("font_size",14)
	control.pressed.connect(action)
	row.add_child(control)
	return control

func start_seed(seed_value: int) -> void:
	var config := {"record_trace":true,"speed_spread":spread_input.value/100.0,
		"phase_max":phase_input.value,"round_seconds":0.005 if ticks.selected == 0 else 0.05}
	if strengths.selected == 1:
		config.strengths = [0.0,0.0,0.0,0.0,0.0]
	var error := EffortEngine.validate_config(config)
	if not error.is_empty():
		status.text = error
		return
	model = EffortEngine.new(seed_value,config)
	outcome = model.run()
	duration = duration_input.value
	elapsed = 0.0
	playing = true
	_update_view()

func seek_to(fraction: float) -> void:
	if outcome.is_empty():
		return
	elapsed = clampf(fraction,0.0,1.0)*duration
	playing = false
	_update_view()

func toggle_pause() -> void:
	if outcome.is_empty():
		return
	if elapsed >= duration:
		elapsed = 0.0
	playing = not playing
	_update_view()

func _process(delta: float) -> void:
	if not playing or outcome.is_empty():
		return
	elapsed = minf(duration,elapsed+delta)
	if elapsed >= duration:
		playing = false
	_update_view()

func _update_view() -> void:
	var fraction := clampf(elapsed/duration,0.0,1.0)
	track.positions = model.positions_at(fraction*outcome.second_time)
	track._animation_clock = elapsed
	track.moving = playing and fraction < 1.0
	track.highlights = [outcome.first,outcome.second] if fraction >= 1.0 else []
	track.get_parent().get_parent().set_winning_pair(outcome.pair if fraction >= 1.0 else "")
	track.queue_redraw()
	seek_bar.set_value_no_signal(fraction*100.0)
	pause_button.text = "Pause" if playing else "Resume"
	if fraction >= 1.0:
		status.text = "Finish: %d first, %d second.  Winning pair: %s" % [outcome.first+1,outcome.second+1,outcome.pair]
	else:
		status.text = "%s  |  Seed %d  |  %.1f%% of recorded race" % ["Running" if playing else "Paused",outcome.seed,fraction*100.0]
	status.text += "  |  Sample payouts; no wagers"
	detail.text = "%s  |  %s movement turns  |  %.3f model seconds  |  Uncalibrated" % [outcome.model_version,str(outcome.events),outcome.second_time]
