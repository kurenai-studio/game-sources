extends Button
## One round face with two matching pointer and lighting regions.
const DOWN_START := 0.68
var hover_region := -1
var down_control: Button
var down_pressed := false

func _ready() -> void:
	# Native text remains the accessible label; a child draws it above the lit face.
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_hover_pressed_color"]:
		add_theme_color_override(state,Color.TRANSPARENT)
	var caption := Label.new()
	caption.text = "BET"
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",12)
	caption.add_theme_color_override("font_color",Color("27221c"))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	mouse_entered.connect(refresh_hover)
	mouse_exited.connect(refresh_hover)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	refresh_hover()

func connect_down(control: Button) -> void:
	down_control = control
	control.mouse_entered.connect(refresh_hover)
	control.mouse_exited.connect(refresh_hover)
	control.gui_input.connect(func(event):
		if event is InputEventMouseMotion: set_hover_region(control.position+event.position))
	control.button_down.connect(func(): down_pressed = true; queue_redraw())
	control.button_up.connect(func(): down_pressed = false; queue_redraw())

func region_at(point: Vector2) -> int:
	if not Rect2(Vector2.ZERO,size).has_point(point): return -1
	return 1 if point.y >= size.y*DOWN_START else 0

func refresh_hover() -> void:
	set_hover_region(get_local_mouse_position() if is_inside_tree() else Vector2(-1,-1))

func set_hover_region(point: Vector2) -> void:
	var next := region_at(point)
	if hover_region != next:
		hover_region = next
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: set_hover_region(event.position)

func _draw() -> void:
	if disabled: return
	var region := 1 if down_pressed else (0 if is_pressed() else hover_region)
	if region < 0: return
	var polygon := PackedVector2Array()
	var center := size*0.5
	var radius := minf(size.x,size.y)*0.5-5.0
	var cutoff := size.y*DOWN_START
	# Clip the circular face at the same height as the subtract hit region.
	var previous := center+Vector2(radius,0)
	for i in range(1,65):
		var point := center+Vector2.from_angle(TAU*float(i)/64.0)*radius
		var inside: bool = point.y >= cutoff if region == 1 else point.y <= cutoff
		var previous_inside: bool = previous.y >= cutoff if region == 1 else previous.y <= cutoff
		if inside != previous_inside:
			polygon.append(previous.lerp(point,(cutoff-previous.y)/(point.y-previous.y)))
		if inside: polygon.append(point)
		previous = point
	if polygon.size() >= 3:
		draw_colored_polygon(polygon,Color("d5a01b") if down_pressed or is_pressed() else Color("ffdf76"))
