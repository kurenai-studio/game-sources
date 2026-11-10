# The sound menu, opened by the speaker button in the top bar (see
# main.gd's `_on_sound_pressed`): "Tout couper", then for each audio bus
# (everything, the music, the sound effects) a mute button, "-", a level
# bar and "+". Only presentation: the settings themselves live in
# AudioSettings (audio_settings.gd), which this panel changes, applies to
# Godot's mixer and saves on every press.
class_name SoundPanel
extends PanelContainer

# Emitted after any change, so main.gd can update the speaker button's
# icon. A signal is Godot's observer pattern: other nodes `connect` a
# function to it and `emit()` calls them all (no direct Python
# equivalent; think of a list of callbacks).
signal changed

const SPEAKER := preload("res://assets/textures/speaker_icon.svg")
const SPEAKER_MUTED := preload("res://assets/textures/speaker_muted_icon.svg")
# Bus name -> the row's label.
const LABELS := {"Master": "Général", "Music": "Musique", "Effects": "Effets"}

var settings := AudioSettings.read()

var _all_button: Button
# Bus name -> that row's mute button / level bar, to refresh them.
var _mute_buttons := {}
var _bars := {}


func _ready() -> void:
	# Applied as soon as the game starts, not only once the menu is opened.
	settings.apply()
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	add_child(rows)
	_all_button = Button.new()
	_all_button.pressed.connect(_change.bind(settings.toggle_all))
	rows.add_child(_all_button)
	# A GridContainer lays its children out in rows of `columns` cells:
	# label, mute, -, bar, + for each bus.
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	rows.add_child(grid)
	for bus: String in AudioSettings.BUSES:
		var label := Label.new()
		label.text = LABELS[bus]
		grid.add_child(label)
		var mute := Button.new()
		mute.custom_minimum_size = Vector2(44, 44)
		mute.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# `bind` fixes a function's arguments ahead of time, like Python's
		# functools.partial: pressing calls settings.toggle_mute(bus).
		mute.pressed.connect(_change.bind(settings.toggle_mute.bind(bus)))
		grid.add_child(mute)
		_mute_buttons[bus] = mute
		grid.add_child(_step_button("-", bus, -1))
		# A ProgressBar is a filled bar showing `value` between its
		# `min_value` and `max_value`.
		var bar := ProgressBar.new()
		bar.max_value = AudioSettings.STEPS
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(110, 0)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(bar)
		_bars[bus] = bar
		grid.add_child(_step_button("+", bus, 1))
	_refresh()


func _step_button(text: String, bus: String, delta: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(44, 44)
	button.pressed.connect(_change.bind(settings.change_level.bind(bus, delta)))
	return button


# Runs one change to the settings (`action`, a Callable: a function value),
# then makes it heard, keeps it, and shows it.
func _change(action: Callable) -> void:
	action.call()
	settings.apply()
	settings.save()
	_refresh()
	changed.emit()


func _refresh() -> void:
	_all_button.text = "Remettre le son" if settings.all_muted() else "Tout couper"
	for bus: String in AudioSettings.BUSES:
		_mute_buttons[bus].icon = SPEAKER_MUTED if settings.muted[bus] else SPEAKER
		_bars[bus].value = settings.levels[bus]
		# Greyed out while muted, so the level reads as "kept, not playing".
		_bars[bus].modulate.a = 0.4 if settings.muted[bus] else 1.0
