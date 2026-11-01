# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name StarNote
extends HBoxContainer
## The warning before a tap that would lose the third star (RULES 10.6): an empty star and
## the words, so color is never the only signal.

const TEXT: String = "Loses the third star."
## The gate message: placing a gate loses nothing, only starting a wave with it does.
const GATE_TEXT: String = "Start a wave with this gate and the third star is lost."

var label: Label


func _init(text: String = TEXT) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 12)
	var star: StarIcon = StarIcon.new(48.0, false)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(star)
	label = UiKit.label(text, &"Label")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)
