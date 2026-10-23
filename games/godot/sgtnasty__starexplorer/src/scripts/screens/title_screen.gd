# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Screen
## Title: continue a saved game, start a new one, or quit.


func enter(_params: Dictionary) -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := UIKit.vbox(6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	var title := UIKit.label("STAR EXPLORER", UIKit.ACCENT, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UIKit.label("Mine. Trade. Upgrade. Survive.", UIKit.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(UIKit.sprite(load("res://assets/sprites/ship_player.png"), 4))

	var buttons := UIKit.vbox(3)
	buttons.custom_minimum_size.x = 140
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)
	if Game.has_save():
		buttons.add_child(UIKit.button("Continue", _on_continue))
	buttons.add_child(UIKit.button("New Game", _on_new_game))
	if not OS.has_feature("web"):
		buttons.add_child(UIKit.button("Quit", func() -> void: get_tree().quit()))

	var help := UIKit.label("D-pad / arrows: move   A / Enter: select   B / Esc: back", UIKit.DIM)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(help)
	var lic := UIKit.label("Free software under the GNU GPL v3", UIKit.DIM.darkened(0.3))
	lic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lic)
	focus_first(buttons)


func _on_continue() -> void:
	if Game.load_game():
		go("system")
	else:
		Game.new_game()
		go("system")


func _on_new_game() -> void:
	Game.new_game()
	Game.save_game()
	go("system")
