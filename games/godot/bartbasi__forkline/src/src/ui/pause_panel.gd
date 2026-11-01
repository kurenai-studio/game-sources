# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name PausePanel
extends Modal
## The Pause menu (playbook 6.4): Resume, Info, Settings, back to the menu (the
## game stays saved), Restart and Abandon side by side (each after a confirm), and a
## quiet Buy me a coffee row at the bottom. The back button resumes, or cancels an open
## confirm.

signal resume_requested()
signal info_requested()
signal settings_requested()
## The player goes to the menu. The game stays saved.
signal leave_requested()
## The player confirmed that this game ends now.
signal abandon_confirmed()
## The player confirmed that this game starts over.
signal restart_confirmed()

## What Restart does, in plain words, for the question it asks. The battle screen sets the
## one that fits the game (set_restart_text); this one fits a campaign level.
const RESTART_LEVEL: String = "This level starts over from the beginning, on the same difficulty. Nothing from this game is recorded."

## The three star lines, when this game has stars (RULES 10.6). Empty otherwise.
var star_lines: Array[StarLine] = []

## The Twist's name and text label, when this game is a Twist (RULES 13). Null otherwise.
var twist_name_label: Label = null
var twist_text_label: Label = null

var restart_button: TapButton
var abandon_button: TapButton

var _restart_text: String = RESTART_LEVEL
var _confirm: ConfirmDialog = null
var _stars_box: VBoxContainer = null
var _twist_box: VBoxContainer = null
var _window_size: Vector2 = Vector2.ZERO
var _safe: Rect2 = Rect2()


func _init() -> void:
	super("Paused")
	var resume: TapButton = UiKit.button("Resume", &"PrimaryButton")
	resume.tapped.connect(_resume)
	body.add_child(resume)
	var info: TapButton = UiKit.button("Info")
	info.tapped.connect(func() -> void: info_requested.emit())
	body.add_child(info)
	var settings: TapButton = UiKit.button("Settings")
	settings.tapped.connect(func() -> void: settings_requested.emit())
	body.add_child(settings)
	var leave: TapButton = UiKit.button("Back to menu")
	leave.tapped.connect(func() -> void: leave_requested.emit())
	body.add_child(leave)
	var ends: HBoxContainer = HBoxContainer.new()
	ends.add_theme_constant_override(&"separation", 20)
	restart_button = UiKit.button("Restart")
	restart_button.tapped.connect(_ask_restart)
	ends.add_child(restart_button)
	abandon_button = UiKit.button("Abandon")
	abandon_button.tapped.connect(_ask_abandon)
	ends.add_child(abandon_button)
	body.add_child(ends)
	body.add_child(CoffeeButton.new())


## Shows the level's star lines (StarText.play_lines) under the title. Call it again to
## replace them; an empty list takes them away. Only a campaign level that is not a Twist
## has them (RULES 10.6).
func set_stars(entries: Array[Dictionary]) -> void:
	if _stars_box != null:
		body.remove_child(_stars_box)
		_stars_box.free()
		_stars_box = null
	star_lines.clear()
	if entries.is_empty():
		return
	_stars_box = VBoxContainer.new()
	_stars_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stars_box.add_theme_constant_override(&"separation", 14)
	_stars_box.add_child(UiKit.heading("Stars"))
	for entry: Dictionary in entries:
		var line: StarLine = StarLine.new(entry)
		star_lines.append(line)
		_stars_box.add_child(line)
	body.add_child(_stars_box)
	body.move_child(_stars_box, 1)


## Shows the Twist's rule under the title, in place of the star lines: a Twist has no stars.
## An empty name takes it away.
func set_twist(twist_name: String, twist_text: String) -> void:
	if _twist_box != null:
		body.remove_child(_twist_box)
		_twist_box.free()
		_twist_box = null
		twist_name_label = null
		twist_text_label = null
	if twist_name.is_empty():
		return
	_twist_box = VBoxContainer.new()
	_twist_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_twist_box.add_theme_constant_override(&"separation", 8)
	twist_name_label = UiKit.heading("Twist: %s" % twist_name)
	_twist_box.add_child(twist_name_label)
	twist_text_label = UiKit.label(twist_text)
	_twist_box.add_child(twist_text_label)
	body.add_child(_twist_box)
	body.move_child(_twist_box, 1)


## Sets the sentence of the Restart question. It says plainly what happens to this game.
func set_restart_text(text: String) -> void:
	_restart_text = text


func apply_layout(window_size: Vector2, safe: Rect2) -> void:
	super(window_size, safe)
	_window_size = window_size
	_safe = safe
	if _confirm != null:
		_confirm.apply_layout(window_size, safe)


func request_close() -> void:
	if _confirm != null:
		_confirm.request_close()
	else:
		_resume()


## True while the abandon question is open.
func confirm_open() -> bool:
	return _confirm != null


func _resume() -> void:
	resume_requested.emit()
	closed.emit()


func _ask_abandon() -> void:
	_ask("Abandon?", "This game ends now and cannot be resumed.", "Abandon", abandon_confirmed)


func _ask_restart() -> void:
	_ask("Restart?", _restart_text, "Restart", restart_confirmed)


func _ask(title: String, message: String, confirm_text: String, answer: Signal) -> void:
	if _confirm != null:
		return
	_confirm = ConfirmDialog.new(title, message, confirm_text, "Keep playing")
	_confirm.confirmed.connect(func() -> void: answer.emit())
	_confirm.closed.connect(_confirm_closed)
	add_child(_confirm)
	if _window_size.x > 0.0:
		_confirm.apply_layout(_window_size, _safe)


func _confirm_closed() -> void:
	if _confirm != null:
		_confirm.queue_free()
		_confirm = null
