class_name FloatingDamage extends CanvasLayer

const FLOAT_DIST := 55.0
const HOLD_SECS := 0.5
const FADE_SECS := 0.8


func _init() -> void:
	layer = 20


func spawn_events(events: Array, origin: Vector2) -> void:
	for i: int in events.size():
		var ev := events[i] as CastEvent
		var text := _text_for(ev)
		if text.is_empty():
			continue
		var color := _color_for(ev)
		_spawn(text, color, origin + Vector2(0.0, i * -26.0))


func _spawn(text: String, color: Color, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Palette.COLOR_TEXT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - FLOAT_DIST, HOLD_SECS + FADE_SECS)
	tween.tween_property(label, "modulate:a", 0.0, FADE_SECS).set_delay(HOLD_SECS)
	tween.chain().tween_callback(label.queue_free)


static func _text_for(ev: CastEvent) -> String:
	match ev.type:
		CastEvent.Type.PROJECTILE:
			var name := ev.spell.display_name if ev.spell != null else "???"
			if ev.total_damage > 0:
				return "%s  %d" % [name, ev.total_damage]
			return name
		CastEvent.Type.FIZZLE:
			return "Fizzle"
		CastEvent.Type.BACKFIRE:
			return "Backfire!  %d" % ev.backfire_damage
	return ""


static func _color_for(ev: CastEvent) -> Color:
	match ev.type:
		CastEvent.Type.PROJECTILE:
			return Palette.COLOR_DAMAGE_HIT
		CastEvent.Type.FIZZLE:
			return Palette.COLOR_DAMAGE_FIZZLE
		CastEvent.Type.BACKFIRE:
			return Palette.COLOR_DAMAGE_BACKFIRE
	return Color.WHITE
