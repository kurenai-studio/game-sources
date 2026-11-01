extends Control
## Looping motion demo for one direction's interface layer. Every
## direction's ui_demo.tscn uses this script with its direction_id. Run it
## in a window:
##     godot --path . res://tools/directions/<id>/ui/ui_demo.tscn
##
## The loop: a booster press (Shuffle), targeting on with its pulse (Hammer)
## and the cancel tap, a tap on the disabled booster that is ignored, the
## sound toggle switching off and on, a card coming in with dialog_in, and
## the score counting up from 20,450 to SCORE. Taps are real pointer events
## pushed through the viewport, so the controls' own input code runs. Each
## step prints a line, so a run's output shows what happened.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

## Score the count up starts from.
const COUNT_FROM: int = 20450
## How long a simulated finger stays down, seconds.
const TAP_HOLD: float = 0.14
## Beats of the loop, seconds from the loop start.
const BEATS: Dictionary[String, float] = {
	"press": 0.8,
	"target": 2.0,
	"cancel": 4.4,
	"disabled": 5.4,
	"toggle_off": 6.4,
	"toggle_on": 7.2,
	"card_in": 8.2,
	"card_out": 10.2,
	"count": 11.2,
	"end": 13.0,
}

@export var direction_id: String = "gumdrop"

var _tokens: DirectionTokens = null
var _hud: Control = null
var _bar: Control = null
var _toggle: Control = null
var _card: PanelContainer = null
var _card_home: Vector2 = Vector2.ZERO
var _score_label: Label = null
var _active: String = ""
var _pressed_ids: PackedStringArray = PackedStringArray()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tokens = Directions.load_tokens(direction_id)
	if _tokens == null:
		return
	theme = _ui("theme_factory").call("build", _tokens) as Theme
	var canvas: Vector2 = Vector2(MockState.CANVAS_SIZE)
	var margin: float = _tokens.num("board_margin")

	var backdrop: Control = _make("backdrop")
	backdrop.size = canvas

	_hud = _make("hud")
	_hud.position = Vector2(0.0, float(MockState.SAFE_TOP))
	_hud.size = Vector2(canvas.x, float(_hud.call("preferred_height")))
	_hud.call("set_scores", MockState.SCORE, MockState.BEST_SCORE)
	_score_label = _hud.call("score_label") as Label

	_bar = _make("booster_bar")
	_bar.connect("booster_pressed", _on_booster_pressed)
	var bar_height: float = float(_bar.call("preferred_height"))
	_bar.position = Vector2(0.0, canvas.y - float(MockState.SAFE_BOTTOM) - bar_height)
	_bar.size = Vector2(canvas.x, bar_height)
	_show_bar("")

	# Sound row in the middle of the screen.
	var row: HBoxContainer = HBoxContainer.new()
	add_child(row)
	var label: Label = Label.new()
	label.theme_type_variation = "BodyLabel"
	label.text = _tokens.cased("body", MockState.SOUND_LABEL)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	_toggle = _ui("toggle_switch").new() as Control
	row.add_child(_toggle)
	_toggle.call("setup", _tokens)
	_toggle.call("set_on", MockState.SOUND_ON, false)
	_toggle.connect("toggled", func(on: bool) -> void: print("demo %s: sound toggled %s" % [direction_id, "on" if on else "off"]))
	row.position = Vector2(margin, _bar.position.y - _tokens.num("space_xl") - _tokens.num("touch_min"))
	row.size = Vector2(canvas.x - margin * 2.0, _tokens.num("touch_min"))

	_card = _build_card(canvas.x - margin * 2.0)
	_card_home = Vector2(margin, _hud.position.y + _hud.size.y + _tokens.num("space_l"))
	_card.position = _card_home
	# The card stays in the tree but clear, so its wrapped text is laid out
	# before it first comes in.
	_card.modulate.a = 0.0
	_fit_card()

	var timeline: Tween = create_tween()
	timeline.set_loops()
	var previous: float = 0.0
	for beat: String in BEATS:
		var at: float = BEATS[beat]
		timeline.tween_interval(at - previous)
		timeline.tween_callback(_on_beat.bind(beat))
		previous = at


## The direction's ui script with this file name.
func _ui(file_name: String) -> GDScript:
	return load("%s/%s/ui/%s.gd" % [Directions.ROOT, direction_id, file_name]) as GDScript


func _make(file_name: String) -> Control:
	var control: Control = _ui(file_name).new() as Control
	add_child(control)
	control.call("setup", _tokens)
	return control


func _build_card(width: float) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	add_child(card)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", roundi(_tokens.num("space_s")))
	card.add_child(stack)
	var title: Label = Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = _tokens.cased("title", MockState.GAMEOVER_TITLE)
	stack.add_child(title)
	var body: Label = Label.new()
	body.theme_type_variation = "BodyLabel"
	body.text = _tokens.cased("body", MockState.GAMEOVER_BODY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)
	var rescue: Button = Button.new()
	rescue.theme_type_variation = "PrimaryButton"
	var rescue_cost: int = MockState.GAMEOVER_COSTS[MockState.BOOSTER_IDS.find(MockState.RESCUE_BOOSTER)]
	rescue.text = _tokens.cased("body", MockState.buy_text(MockState.RESCUE_BOOSTER, rescue_cost))
	stack.add_child(rescue)
	var end: Button = Button.new()
	end.theme_type_variation = "SecondaryButton"
	end.text = _tokens.cased("body", MockState.GAMEOVER_END)
	stack.add_child(end)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel: StyleBox = card.get_theme_stylebox("panel")
	body.custom_minimum_size.x = width - panel.get_margin(SIDE_LEFT) - panel.get_margin(SIDE_RIGHT)
	card.size = Vector2(width, 0.0)
	return card


## Shrinks the card to its content once containers have laid it out.
func _fit_card() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_card.size = Vector2(_card.size.x, _card.get_combined_minimum_size().y)


func _on_beat(beat: String) -> void:
	match beat:
		"press":
			_say("tap Shuffle")
			_tap(_booster("shuffle"))
		"target":
			_say("tap Hammer, targeting on")
			_tap(_booster("hammer"))
		"cancel":
			_say("tap Hammer again, targeting off")
			_tap(_booster("hammer"))
		"disabled":
			_pressed_ids.clear()
			_say("tap %s, which is not usable now" % MockState.booster_name(_disabled_id()))
			_tap(_booster(_disabled_id()))
		"toggle_off", "toggle_on":
			if beat == "toggle_off" and _pressed_ids.has(_disabled_id()):
				push_error("demo %s: the disabled %s reacted to a tap" % [direction_id, _disabled_id()])
			elif beat == "toggle_off":
				_say("%s ignored the tap" % MockState.booster_name(_disabled_id()))
			_say("tap the sound toggle")
			_tap(_toggle)
		"card_in":
			_say("card in")
			_card.position = _card_home
			_card.scale = Vector2.ONE
			_card.modulate.a = 1.0
			Motion.dialog_in(_card, _tokens)
		"card_out":
			_say("card out")
			Motion.fade(_card, _tokens, 0.0)
		"count":
			_say("score counts up")
			if _score_label != null:
				Motion.count_up(_score_label, _tokens, COUNT_FROM, MockState.SCORE)
		"end":
			_say("loop")


func _on_booster_pressed(booster_id: String) -> void:
	_pressed_ids.append(booster_id)
	_say("booster_pressed(%s)" % booster_id)
	if booster_id == MockState.TARGETING_BOOSTER:
		# Tapping the targeting booster again cancels it.
		_active = "" if _active == booster_id else booster_id
		_show_bar(_active)


func _show_bar(active_id: String) -> void:
	_bar.call("show_boosters", MockState.BOOSTER_IDS, MockState.BOOSTER_COSTS, MockState.board_usable(), active_id)
	var targeting: bool = not active_id.is_empty()
	_bar.call("set_hint", MockState.TARGET_HINT if targeting else "")
	var context: String = "%s: %s" % [MockState.booster_name(active_id), MockState.TARGET_HINT] if targeting else ""
	_hud.call("set_context", context, targeting)


## The first booster that is not usable on the board screen (Undo, with no
## snapshot to go back to).
func _disabled_id() -> String:
	var usable: Array[bool] = MockState.board_usable()
	for i: int in usable.size():
		if not usable[i]:
			return MockState.BOOSTER_IDS[i]
	push_error("demo %s: every booster is usable, so there is no disabled tap to show" % direction_id)
	return MockState.BOOSTER_IDS[0]


## The booster button for an id: the bar's buttons are its children in bar order.
func _booster(booster_id: String) -> Control:
	var buttons: Array[Control] = []
	for child: Node in _bar.get_children():
		if child.has_method("set_look") and child.has_signal("pressed"):
			buttons.append(child as Control)
	return buttons[MockState.BOOSTER_IDS.find(booster_id)]


## A finger down on the middle of control, then up after TAP_HOLD.
func _tap(control: Control) -> void:
	var at: Vector2 = control.get_global_rect().get_center()
	_push_button(at, true)
	await get_tree().create_timer(TAP_HOLD).timeout
	_push_button(at, false)


func _push_button(at: Vector2, down: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at
	event.global_position = at
	get_viewport().push_input(event, true)


func _say(text: String) -> void:
	print("demo %s: %s" % [direction_id, text])
