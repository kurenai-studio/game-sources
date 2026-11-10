class_name ConsumableSlot
extends Control
## Slot da barra de consumíveis (1-9) com ícone, tecla, contagem e recarga.

signal used(slot: int)

var slot := 0
var key_text := ""
var player: Player
var _flash := 0.0


func _init(p_slot: int, p_key: String) -> void:
	slot = p_slot
	key_text = p_key
	custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = " "


func flash() -> void:
	_flash = 1.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		used.emit(slot)
		accept_event()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 4.0, 0.0)
	queue_redraw()


func get_item() -> Item:
	if player == null:
		return null
	return player.hero.consumable_slots[slot] if slot < player.hero.consumable_slots.size() else null


func _make_custom_tooltip(_for_text: String) -> Object:
	var item: Item = get_item()
	var r := UIKit.rich()
	r.custom_minimum_size = Vector2(300, 0)
	if item == null:
		r.text = "[color=#999999]Slot vazio.\nArraste um consumível do inventário.\n[color=#666666]Tecla: %s[/color]" % key_text
		return r
	var count: int = player.hero.count_item(item.base_id)
	var t := "[font_size=19][color=#e8c060]%s[/color][/font_size]\n" % item.name
	t += "%s\n\n" % item.description
	t += "[color=#cccccc]Quantidade: %d[/color]\n" % count
	if item.cooldown > 0:
		t += "[color=#cccccc]Recarga: %.1fs[/color]\n" % item.cooldown
	t += "[color=#999999]Tecla: %s[/color]" % key_text
	r.text = t
	return r


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.03, 0.02, 0.02))
	var item: Item = get_item()
	var icon_name := ""
	var color := Color.WHITE
	var count: int = 0
	if item:
		icon_name = item.icon
		color = item.color if item.color != Color.WHITE else Color(0.8, 0.7, 0.5)
		count = player.hero.count_item(item.base_id)
	if icon_name != "":
		draw_rect(rect.grow(-3), Color(color.r * 0.25, color.g * 0.25, color.b * 0.25))
		draw_texture_rect(DB.icon(icon_name), rect.grow(-4), false)
	# Recarga do item
	var frac := 0.0
	var remaining := 0.0
	if player and item:
		remaining = player.hero.consumable_cooldowns.get(item.base_id, 0.0)
		if item.cooldown > 0:
			frac = remaining / item.cooldown
	if frac > 0.0:
		draw_colored_polygon(SkillSlot._radial_points(size * 0.5, size.length() * 0.75, frac), Color(0, 0, 0, 0.66))
		var f := UIKit.FONT_TITLE
		var txt := str(ceili(remaining))
		draw_string_outline(f, Vector2(0, size.y * 0.5 + 8), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, 4, Color.BLACK)
		draw_string(f, Vector2(0, size.y * 0.5 + 8), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color.WHITE)
	# Contagem
	if count > 1:
		var f := UIKit.FONT_TITLE
		draw_string_outline(f, Vector2(size.x - 18, size.y - 18), "x%d" % count, HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, 3, Color.BLACK)
		draw_string(f, Vector2(size.x - 18, size.y - 18), "x%d" % count, HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, Color.WHITE)
	if _flash > 0.0:
		draw_rect(rect, Color(1, 0.1, 0.1, _flash * 0.5))
	var border := UIKit.GOLD if get_global_rect().has_point(get_global_mouse_position()) else UIKit.GOLD_DIM
	draw_rect(rect, border, false, 2.0)
	# Tecla
	draw_string_outline(UIKit.FONT_TITLE, Vector2(4, 14), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
	draw_string(UIKit.FONT_TITLE, Vector2(4, 14), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIKit.TEXT)