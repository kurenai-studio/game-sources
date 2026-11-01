# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name DamagedScreen
extends ScreenFrame
## Shown instead of the game when a bundled data file fails its check
## (docs/ARCHITECTURE.md 2.12). Nothing else starts. The player can only close the app.

const MESSAGE: String = "This copy of Forkline is damaged. Installing it again should fix it."

## The player chose to close the app.
signal close_requested()

var message_label: Label
var close_button: TapButton


func _init() -> void:
	super()
	var center: CenterContainer = CenterContainer.new()
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 40)
	box.custom_minimum_size.x = 900.0
	center.add_child(box)
	message_label = UiKit.label(MESSAGE, &"TitleLabel")
	message_label.add_theme_font_size_override(&"font_size", UiTheme.FONT_BUTTON)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(message_label)
	close_button = UiKit.button("Close", &"PrimaryButton")
	close_button.tapped.connect(func() -> void: close_requested.emit())
	box.add_child(close_button)
