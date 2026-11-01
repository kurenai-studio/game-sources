# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name BattlePanel
extends PanelContainer
## Base of the battle panels (HUD, build, tower, creature, wave preview).
##
## A panel talks to a real Battle through its commands and queries only, and
## never touches the clock, so everything works while paused. A refused command
## shows a short sentence in the panel (BattleText.refusal) and is announced with
## `refused`, so the screen can add a sound or a mark on the map.

## A command was refused. `text` is the sentence the panel shows.
signal refused(reason: StringName, text: String)
## A command was carried out: the Battle changed.
signal changed()
## The player closed the panel.
signal closed()

## How long a message stays, in seconds.
const FEEDBACK_SECONDS: float = 3.0

var battle: Battle = null
var wide: bool = true
## False when the game has no third star to protect (a Twist, a run, or a star already
## earned): the panel then shows no star warnings (RULES 10.6). The battle screen sets it.
var star_warnings: bool = true
var column: VBoxContainer
var feedback_box: PanelContainer
var feedback_label: Label

var _feedback_left: float = 0.0
## Old parts of a panel that is not in a scene tree; freed with the panel.
var _trash: Array[Node] = []


func _init() -> void:
	# Pass: the panel still takes the touch (nothing under it gets it), and a drag that starts
	# on its background reaches the scroll container above it.
	mouse_filter = Control.MOUSE_FILTER_PASS
	column = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	feedback_box = PanelContainer.new()
	feedback_box.add_theme_stylebox_override(&"panel", UiKit.box(Palette.PANEL_RAISED, Palette.HONEY, 4, 24, 14))
	feedback_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label = UiKit.label("", &"Label")
	feedback_box.add_child(feedback_label)
	feedback_box.visible = false
	set_process(false)


func setup(new_battle: Battle) -> void:
	battle = new_battle
	refresh()


## True when this action would lose a third star that is still possible and not earned yet.
## The sim answers (Battle.loses_star3); this only adds the screen's "not earned yet" part.
func warns(action: StringName, tower: StringName = &"", tier: int = 0) -> bool:
	return star_warnings and battle != null and battle.loses_star3(action, tower, tier)


## Reads the Battle again. Cheap; the screen may call it every frame.
func refresh() -> void:
	pass


## The message showing now, "" for none.
func feedback_text() -> String:
	return feedback_label.text if feedback_box.visible else ""


func show_feedback(text: String) -> void:
	feedback_label.text = text
	feedback_box.visible = not text.is_empty()
	_feedback_left = FEEDBACK_SECONDS
	set_process(feedback_box.visible)


func clear_feedback() -> void:
	feedback_label.text = ""
	feedback_box.visible = false
	_feedback_left = 0.0
	set_process(false)


## Shows the sentence for a refusal and announces it. `need` is the gold missing.
func refuse(reason: StringName, need: int = 0) -> void:
	var text: String = BattleText.refusal(reason, need)
	show_feedback(text)
	refused.emit(reason, text)


## Runs the result of a command: a carried out command clears the message and
## announces `changed`; anything else is shown as a refusal. Returns true when done.
func finish(result: StringName, need: int = 0) -> bool:
	if result == Battle.DONE:
		clear_feedback()
		changed.emit()
		return true
	refuse(result, need)
	return false


## True in the portrait layout; false in the narrow side panel of the landscape layout.
## The screen calls it on every layout change.
func set_wide(value: bool) -> void:
	wide = value
	set_tight(not value)


## A narrower inner margin for the side panel of the landscape layout, and for the dock
## that floats over the map in portrait, where every pixel of height counts.
func set_tight(tight: bool, margin: int = 18) -> void:
	if tight:
		add_theme_stylebox_override(&"panel", UiKit.box(Palette.PANEL, Palette.PANEL_EDGE, 3, 34, margin))
	else:
		remove_theme_stylebox_override(&"panel")


## Takes every part out of the column, except the feedback box, and frees it.
func clear_column() -> void:
	for child: Node in column.get_children():
		column.remove_child(child)
		if child != feedback_box:
			discard(child)


## In a tree the free waits for the frame's end, so a button may rebuild its own
## panel from its tap. Outside a tree (tests) the part is freed with the panel.
func discard(node: Node) -> void:
	if is_inside_tree():
		node.queue_free()
	else:
		_trash.append(node)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for node: Node in _trash:
			if is_instance_valid(node):
				node.free()
		_trash.clear()
		# A panel that never shows messages has not put the box in its column.
		if is_instance_valid(feedback_box) and feedback_box.get_parent() == null:
			feedback_box.free()


func _process(delta: float) -> void:
	_feedback_left -= delta
	if _feedback_left <= 0.0:
		clear_feedback()


## A square close button, top right of a panel.
func close_button() -> TapButton:
	var b: TapButton = UiKit.icon_button(&"close")
	b.tapped.connect(func() -> void: closed.emit())
	return b


## Selected buttons get the honey look and a check mark, so a choice is never
## shown by color alone.
static func mark_chosen(button: TapButton, chosen: bool) -> void:
	button.theme_type_variation = &"PrimaryButton" if chosen else &"Button"
	button.icon = IconTex.make(&"check", 56) if chosen else null
	button.add_theme_color_override(&"icon_normal_color", Palette.TEXT_DARK)
	button.add_theme_color_override(&"icon_hover_color", Palette.TEXT_DARK)
	button.add_theme_color_override(&"icon_pressed_color", Palette.TEXT_DARK)
	button.add_theme_color_override(&"icon_hover_pressed_color", Palette.TEXT_DARK)
