class_name UiKit
extends RefCounted
## Factory helpers that give every widget the same motion and sound design.


static func button(text: String, min_size: Vector2 = Vector2(320, 58)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	wire_feedback(b)
	return b


## Hover = focus, so mouse, keyboard and gamepad users see the same state.
static func wire_feedback(b: Control, hover_scale: float = 1.04) -> void:
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.mouse_entered.connect(func() -> void:
		if b.focus_mode != Control.FOCUS_NONE and b.is_visible_in_tree():
			b.grab_focus())
	b.focus_entered.connect(func() -> void:
		pop(b, hover_scale)
		AudioManager.play_ui(&"ui_hover"))
	b.focus_exited.connect(func() -> void: pop(b, 1.0))
	if b is BaseButton:
		(b as BaseButton).button_down.connect(func() -> void: pop(b, 0.96, 0.06))
		(b as BaseButton).button_up.connect(func() -> void: pop(b, hover_scale))
		(b as BaseButton).pressed.connect(func() -> void: AudioManager.play_ui(&"ui_click"))


static func pop(c: Control, s: float, dur: float = 0.14) -> void:
	if not c.is_inside_tree():
		return
	var tw := c.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2(s, s), dur)


static func label(text: String, variation: String = "", font_size: int = 0,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if font_size > 0:
		l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = align
	return l


## Fade + scale entrance; safe inside containers (doesn't fight layout position).
static func animate_in(c: Control, delay: float = 0.0, from_scale: float = 0.9) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(from_scale, from_scale)
	_center_pivot.call_deferred(c)
	var tw := c.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, 0.35).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.45).set_delay(delay).set_trans(Tween.TRANS_BACK)


static func _center_pivot(c: Variant) -> void:
	if is_instance_valid(c):
		(c as Control).pivot_offset = (c as Control).size / 2.0


static func shake(c: Control) -> void:
	var x := c.position.x
	var tw := c.create_tween()
	for i in 4:
		tw.tween_property(c, "position:x", x + (8.0 if i % 2 == 0 else -8.0), 0.04)
	tw.tween_property(c, "position:x", x, 0.04)


static func focus_chain(controls: Array, horizontal: bool = false) -> void:
	var n := controls.size()
	for i in n:
		var c: Control = controls[i]
		var prev: Control = controls[(i - 1 + n) % n]
		var next: Control = controls[(i + 1) % n]
		if horizontal:
			c.focus_neighbor_left = c.get_path_to(prev)
			c.focus_neighbor_right = c.get_path_to(next)
		else:
			c.focus_neighbor_top = c.get_path_to(prev)
			c.focus_neighbor_bottom = c.get_path_to(next)


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c
