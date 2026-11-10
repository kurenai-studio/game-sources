extends Control

var title: String
var content: Control
var can_close: bool = true
var can_resize: bool = true
var can_move: bool = true

# Dragging is determined by moving a ui to the mouse with the offset where the mouse first clicked
var dragging = false
var offset_drag: Vector2 = Vector2.ZERO


func close():
	visible = false

# set variables and anything that may be changed at runtime as _ready() may start early
func initialize(cn: Control):
	content = cn
	$Top/Title.text = title
	$Body.add_child(cn)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				dragging = false
			elif not get_global_rect().has_point(get_global_mouse_position()):
				z_index = 0
				

func _process(delta: float) -> void:
	if dragging and get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position()):
		position = get_viewport().get_mouse_position() - offset_drag

func _ready() -> void:
	$Top.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				dragging = true
				z_index = 1
				offset_drag = get_viewport().get_mouse_position() - position
	)
	
	$Top/MarginContainer/AspectRatioContainer/Exit.pressed.connect(close)
