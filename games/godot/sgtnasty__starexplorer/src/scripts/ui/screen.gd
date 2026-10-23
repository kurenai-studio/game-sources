# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name Screen
extends Control
## Base class for every full-screen view (title, map, system, ...).
##
## Main creates a screen, calls enter(params), and listens to `navigate` to
## swap to the next one. Pressing ui_cancel (Esc / B button) calls back().

signal navigate(screen_name: String, params: Dictionary)

const PAD := 6


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Called once after the screen is added to the tree.
func enter(_params: Dictionary) -> void:
	pass


## Called on ui_cancel. Override to go somewhere.
func back() -> void:
	pass


func go(screen_name: String, params: Dictionary = {}) -> void:
	navigate.emit(screen_name, params)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back()


## A full-screen margin box to lay a screen out in.
func make_root() -> MarginContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, PAD)
	add_child(m)
	return m


## Gives focus to the first enabled button under `root`.
func focus_first(root: Node) -> void:
	var b := _first_button(root)
	if b:
		b.grab_focus()


func _first_button(node: Node) -> Button:
	for c in node.get_children():
		if c is Button and not c.disabled and c.is_visible_in_tree():
			return c
		var found := _first_button(c)
		if found:
			return found
	return null


## Name of the focused control, so focus can be restored after a rebuild.
func focused_key() -> String:
	var f := get_viewport().gui_get_focus_owner()
	return String(f.name) if f and is_ancestor_of(f) else ""


## Re-focuses the control named `key`, falling back to the first button
## under `fallback`.
func refocus(key: String, fallback: Node) -> void:
	if key != "":
		var n := find_child(key, true, false)
		if n is Button and n.is_visible_in_tree():
			n.grab_focus()
			return
	focus_first(fallback)
