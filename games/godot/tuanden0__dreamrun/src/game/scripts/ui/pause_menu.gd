## Pause menu, icons only (no text anywhere): resume, back to the last checkpoint, quit. Esc or Start opens and
## closes it; left/right (arrows, D-pad) choose, accept (Enter, Space, A) confirms. It keeps running while the
## rest of the tree is paused.
class_name PauseMenu
extends CanvasLayer

signal resumed
signal checkpoint_requested
signal quit_requested

enum Choice { RESUME, CHECKPOINT, QUIT }

## Tests turn this off so choosing quit does not end the test run.
@export var quits_the_game := true

var selected := Choice.RESUME

var _icons: Array[PauseIcon] = []


## One round icon button: a ring with a glyph, bright when chosen and dim otherwise.
class PauseIcon extends Control:
	var kind := Choice.RESUME
	var chosen := false:
		set(value):
			chosen = value
			queue_redraw()

	func _draw() -> void:
		var centre := size * 0.5
		var tone := Color(0.86, 0.88, 0.95, 1.0 if chosen else 0.35)
		draw_circle(centre, 40.0, Color(0.02, 0.02, 0.03, 0.85))
		draw_arc(centre, 40.0, 0.0, TAU, 48, tone, 3.0 if chosen else 2.0, true)
		match kind:
			Choice.RESUME:  # play triangle
				draw_colored_polygon(PackedVector2Array([centre + Vector2(-9.0, -16.0), centre + Vector2(-9.0, 16.0), centre + Vector2(17.0, 0.0)]), tone)
			Choice.CHECKPOINT:  # a circular arrow: back to the last candle
				draw_arc(centre, 17.0, deg_to_rad(-60.0), deg_to_rad(240.0), 24, tone, 3.5, true)
				var tip := centre + Vector2.from_angle(deg_to_rad(-60.0)) * 17.0
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-9.0, -3.0), tip + Vector2(6.0, -9.0), tip + Vector2(8.0, 8.0)]), tone)
			Choice.QUIT:  # a cross
				draw_line(centre + Vector2(-15.0, -15.0), centre + Vector2(15.0, 15.0), tone, 4.0, true)
				draw_line(centre + Vector2(15.0, -15.0), centre + Vector2(-15.0, 15.0), tone, 4.0, true)


func _ready() -> void:
	layer = 15  # above the film grain, below the respawn fade
	process_mode = Node.PROCESS_MODE_ALWAYS
	var veil := ColorRect.new()
	veil.color = Color(0.0, 0.0, 0.0, 0.62)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.add_child(centre)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 56)
	centre.add_child(row)
	for choice in Choice.values():
		var icon := PauseIcon.new()
		icon.kind = choice
		icon.custom_minimum_size = Vector2(96.0, 96.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		_icons.append(icon)
	visible = false


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()
	elif visible:
		if event.is_action_pressed(&"ui_left"):
			_select(-1)
		elif event.is_action_pressed(&"ui_right"):
			_select(1)
		elif event.is_action_pressed(&"ui_accept"):
			_confirm()
		else:
			return
		get_viewport().set_input_as_handled()


func _open() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as PlayerController
	if player != null and player.is_dead:
		return  # the respawn fade is running; pausing it would leave the screen black
	selected = Choice.RESUME
	_refresh()
	visible = true
	get_tree().paused = true


func _close() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()


func _select(step: int) -> void:
	selected = clampi(selected + step, 0, Choice.size() - 1) as Choice
	_refresh()


func _confirm() -> void:
	match selected:
		Choice.RESUME:
			_close()
		Choice.CHECKPOINT:
			_close()
			checkpoint_requested.emit()
			var player := get_tree().get_first_node_in_group(&"player") as PlayerController
			if player != null:
				player.die()  # the checkpoint manager plays the usual fade and puts everything back
		Choice.QUIT:
			quit_requested.emit()
			if quits_the_game:
				get_tree().quit()


func _refresh() -> void:
	for i in _icons.size():
		_icons[i].chosen = i == selected
