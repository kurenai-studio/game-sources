extends Control


signal close_pressed()


class ControlItem:
	var name: String
	var tooltip: String
	var action: StringName

	func _init(new_name: String, new_tooltip: String, new_action: StringName) -> void:
		name = new_name
		tooltip = new_tooltip
		action = new_action


class ControlGroup:
	var name: String
	var tooltip: String
	var items: Array[ControlItem]

	func _init(new_name: String, new_tooltip: String, new_items: Array) -> void:
		name = new_name
		tooltip = new_tooltip
		items.assign(new_items)


var CONTROL_ITEMS = [
	ControlGroup.new(atr("General", &"HelpMenu"), atr("General actions", &"HelpMenu"), [
			ControlItem.new(atr("Open Menu", &"HelpMenu"), atr("Open the main menu", &"HelpMenu"), &"open_menu"),
			ControlItem.new(atr("Open Help", &"HelpMenu"), atr("Open the help menu", &"HelpMenu"), &"open_help"),
		]),
	ControlGroup.new(atr("Movement", &"HelpMenu"), atr("Movement actions", &"HelpMenu"), [
			ControlItem.new(atr("Turn Left/Counter Clockwise", &"HelpMenu"), atr("Rotate the ship Left/Counter clockwise", &"HelpMenu"), &"turn_left"),
			ControlItem.new(atr("Turn Right/Clockwise", &"HelpMenu"), atr("Rotate the ship Right/Clockwise", &"HelpMenu"), &"turn_right"),
			ControlItem.new(atr("Move Forward/Accelerate", &"HelpMenu"), atr("Increase the ship speed", &"HelpMenu"), &"move_forward"),
			ControlItem.new(atr("Move Back/Decelerate", &"HelpMenu"), atr("Decrease the ship speed, or reverse", &"HelpMenu"), &"move_back"),
		]),
	ControlGroup.new(atr("Actions", &"HelpMenu"), atr("Ship actions", &"HelpMenu"), [
			ControlItem.new(atr("Shoot", &"HelpMenu"), atr("Fire weapons", &"HelpMenu"), &"shoot"),
			ControlItem.new(atr("Shield", &"HelpMenu"), atr("Enable the shields (not implemented)", &"HelpMenu"), &"shield"),
		]),
]


# Help Menu.

@onready var controls_tree : Tree = %ControlsTree

@onready var close_button : Button = %CloseButton


func _ready() -> void:
	_fill_controls()


func _controls_add_group_item(group: ControlGroup, parent: TreeItem) -> TreeItem:
	var new_item := parent.create_child()
	new_item.set_text(0, group.name)
	new_item.set_tooltip_text(0, group.tooltip)
	new_item.set_selectable(0, false)
	new_item.set_text(1, atr("Primary", &"HelpMenu"))
	new_item.set_selectable(1, false)
	new_item.set_text(2, atr("Secondary", &"HelpMenu"))
	new_item.set_selectable(2, false)

	return new_item


func _controls_add_control_item(item: ControlItem, parent: TreeItem) -> TreeItem:
	var new_item := parent.create_child()
	new_item.set_text(0, item.name)
	new_item.set_tooltip_text(0, item.tooltip)
	new_item.set_selectable(0, false)
	new_item.set_selectable(1, false)
	new_item.set_selectable(2, false)
	var action_events := InputMap.action_get_events(item.action)

	# TODO: Translate keys.
	if action_events.size() >= 1:
		var key_event := action_events[0] as InputEventKey
		if key_event:
			new_item.set_text(1, atr(key_event.as_text_physical_keycode()))
			new_item.set_tooltip_text(1, atr(key_event.as_text()))

	if action_events.size() >= 2:
		var key_event := action_events[1] as InputEventKey
		if key_event:
			new_item.set_text(2, atr(key_event.as_text_physical_keycode()))
			new_item.set_tooltip_text(2, atr(key_event.as_text()))

	return new_item


func _fill_controls() -> void:
	var root_node := controls_tree.create_item()

	for group : ControlGroup in CONTROL_ITEMS:
		var group_item := _controls_add_group_item(group, root_node)

		for item : ControlItem in group.items:
			_controls_add_control_item(item, group_item)


func _on_close_button_pressed() -> void:
	close_pressed.emit()


func _on_visibility_changed() -> void:
	if visible:
		close_button.grab_focus()
