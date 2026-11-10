extends Node
## QA-only browser entry point. Requires a real click to unlock browser audio.
## Its dedicated export is never included in the public release ZIP.

const Scene = preload("res://main.tscn")
const FONT = preload("res://assets/fonts/Silkscreen-Regular.ttf")
var game: Node
var index: int = -1
var next_note: int = 0
var next_jump: int = 0
var jumps: Array[float] = []
var shift_release: float = INF
var space_release: float = INF
var transition: float = 0.0
var started: bool = false
var stage: String = "tour"
var errors: int = 0
var calibration_beat: int = 4
var label: Label
var start_button: Button

func _ready() -> void:
	game = Scene.instantiate()
	add_child(game)
	game.persist_progress = false
	game.classic_lane = false
	game.reduced_fx = false
	game.muted = false
	game.music_volume = 0.6
	game.hit_sounds = true
	game.input_offset = 0.0
	game._apply_audio()
	var overlay := CanvasLayer.new()
	add_child(overlay)
	label = Label.new()
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",8)
	label.add_theme_color_override("font_color",Color("2bcbd4"))
	label.position = Vector2(18,54)
	label.text = "WEB INTEGRATION QA / SAVED PROGRESS IS UNTOUCHED"
	overlay.add_child(label)
	start_button = Button.new()
	start_button.text = "START AUTOMATED WEB TEST"
	start_button.add_theme_font_override("font",FONT)
	start_button.add_theme_font_size_override("font_size",11)
	start_button.position = Vector2(181,178)
	start_button.size = Vector2(278,39)
	start_button.pressed.connect(_start)
	overlay.add_child(start_button)

func _start() -> void:
	start_button.hide()
	started = true
	_start_track()

func _start_track() -> void:
	game.track_id = index
	game._start_run()
	next_note = 0
	next_jump = 0
	shift_release = INF
	space_release = INF
	jumps.clear()
	for obstacle in game.obstacles:
		jumps.append(float(obstacle["time"])-game._beat()*0.5)
	for rail in game.rails:
		jumps.append(float(rail["time"])-game._beat()*0.5)
	jumps.sort()
	label.text = "WEB QA / "+str(game.track["title"])
	print("WEBQA_START "+str(game.track["title"]))

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.location = KEY_LOCATION_LEFT if code == KEY_SHIFT else KEY_LOCATION_UNSPECIFIED
	event.pressed = pressed
	Input.parse_input_event(event)

func _process(delta: float) -> void:
	if not started:
		return
	if stage == "calibration":
		_calibration_step()
		return
	if game.mode == "pause":
		game._resume()
		if game.active_hold >= 0:
			_key(KEY_SHIFT,true)
	if game.mode == "results":
		if transition == 0.0:
			var success: bool = game.misses == 0 and game.bumps == 0 and game.grinds == game.rails.size()
			print("WEBQA_RESULT "+JSON.stringify({"track": game.track["title"],"pass": success,"accuracy": game.accuracy(),"misses": game.misses,"bumps": game.bumps,"grinds": game.grinds}))
			if not success:
				errors += 1
		transition += delta
		if transition > 0.8:
			transition = 0.0
			index += 1
			if index > 2:
				stage = "calibration"
				game._begin_calibration()
				label.text = "WEB QA / AUDIO CALIBRATION"
			else:
				_start_track()
		return
	var now: float = game.clock.seconds()
	if now >= shift_release:
		_key(KEY_SHIFT,false)
		shift_release = INF
	if now >= space_release:
		_key(KEY_SPACE,false)
		space_release = INF
	if next_jump < jumps.size() and now >= jumps[next_jump]:
		_key(KEY_SPACE,true)
		space_release = now+0.22
		next_jump += 1
	if next_note < game.chart.size() and now >= float(game.chart[next_note]["time"])-0.004:
		_key(KEY_SHIFT,true)
		shift_release = now+0.055 if float(game.chart[next_note]["hold"]) == 0 else float(game.chart[next_note]["end"])-0.025
		next_note += 1

func _calibration_step() -> void:
	if game.calibration_paused:
		game.calibration_paused = false
		game.clock.set_paused(false)
	var now: float = game.clock.seconds()
	if calibration_beat < 20 and now >= calibration_beat*0.6+0.085:
		_key(KEY_SHIFT,true)
		_key(KEY_SHIFT,false)
		calibration_beat += 1
	if game.calibration.done:
		var success: bool = game.calibration.valid() and absf(game.calibration.offset()+0.085) < 0.035
		if not success:
			errors += 1
		print("WEBQA_CALIBRATION "+JSON.stringify({"pass": success,"offset": game.calibration.offset(),"taps": game.calibration.errors.size()}))
		label.text = "WEB QA COMPLETE / %d FAILURES" % errors
		print("WEBQA_COMPLETE "+JSON.stringify({"pass": errors == 0,"failures": errors}))
		started = false
