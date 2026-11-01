class_name PausePanel extends "res://src/ui/dialog_base.gd"
## Pause (DESIGN_SYSTEM.md 7.3): "Paused", then Resume (primary), New game,
## Info and Settings (secondary), and last, space_l below Settings, the quiet
## Buy me a coffee button (coffee_button.gd, GDD 15.5 BC12), centered and only
## as wide as its content. Opened by the HUD's pause button or Android back
## during play; back resumes. The App cancels the drag and targeting before
## it opens this panel (docs/ARCHITECTURE.md section 11, flow 9). Info opens
## over it, so the run stays paused (GDD 21.1).

signal resume_chosen()
signal new_game_chosen()
signal settings_chosen()
signal info_chosen()

const CoffeeButton: GDScript = preload("res://src/ui/coffee_button.gd")

var _coffee: Control = null


func setup(skin: SkinData) -> void:
	_frame(skin)
	var gap: float = skin.num(&"space_s")
	_content.add_theme_constant_override(&"separation", roundi(gap))
	_content.add_child(UiParts.label(skin, &"TitleLabel", Copy.PAUSED, UiParts.block_alignment(skin)))
	_content.add_child(_choice(skin, &"PrimaryButton", Copy.RESUME, resume_chosen))
	_content.add_child(_choice(skin, &"SecondaryButton", Copy.NEW_GAME, new_game_chosen))
	_content.add_child(_choice(skin, &"SecondaryButton", Copy.INFO, info_chosen))
	_content.add_child(_choice(skin, &"SecondaryButton", Copy.SETTINGS, settings_chosen))
	# space_l above the coffee button, not the space_s between the buttons:
	# the box adds what the content's separation leaves.
	var coffee_box: MarginContainer = MarginContainer.new()
	coffee_box.name = "CoffeeRow"
	coffee_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coffee_box.add_theme_constant_override(&"margin_top", roundi(skin.num(&"space_l") - gap))
	_content.add_child(coffee_box)
	_coffee = CoffeeButton.new()
	_coffee.call(&"setup", skin)
	_coffee.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coffee_box.add_child(_coffee)


## Rebuilds the panel in a new skin, still open.
func apply_skin(skin: SkinData) -> void:
	setup(skin)


## The Buy me a coffee button. For tests.
func coffee_button() -> Control:
	return _coffee


func _choice(skin: SkinData, variation: StringName, text: String, chosen: Signal) -> Button:
	var made: Button = UiParts.button(skin, variation, text)
	made.name = text.replace(" ", "")
	made.pressed.connect(_emit.bind(chosen))
	return made


func _emit(chosen: Signal) -> void:
	if not _closing:
		chosen.emit()
