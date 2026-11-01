# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name PauseStrip
extends BattlePanel
## Shown while the clock is frozen by the HUD's pause button (RULES 4.7). The game
## stays open, so the player can build, upgrade, sell and look at things. The word
## "Paused" and the pause mark say so, and a Menu button opens the Pause menu.

signal menu_requested()

var menu_button: TapButton


func _init() -> void:
	super()
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	var mark: TextureRect = TextureRect.new()
	mark.texture = IconTex.make(&"pause", 72)
	mark.custom_minimum_size = Vector2(64.0, 64.0)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.modulate = Palette.HONEY
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mark)
	var text: Label = UiKit.heading("Paused")
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text)
	menu_button = UiKit.button("Menu")
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	menu_button.tapped.connect(func() -> void: menu_requested.emit())
	row.add_child(menu_button)
	column.add_child(row)
	visible = false
