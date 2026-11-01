class_name WandDisplay
extends Node2D

const SLOT_SIZE := Vector2(50.0, 50.0)
const CELL_SPACING := Vector2(70.0, 60.0)
const PAD := Vector2(16.0, 16.0)
const PAD_BOTTOM := 14.0

signal tip_pressed(wand: WandDisplay)
signal body_slot_clicked(wand: WandDisplay, slot_id: String)
signal body_slot_right_clicked(wand: WandDisplay, slot_id: String)

var _data: WandData = null
var _highlighted := false
var _hovered := false
var _charges: Dictionary = {}  # slot_id -> int
var _webbed: Dictionary = {}   # slot_id -> true


func setup(wand_data: WandData) -> void:
	_data = wand_data
	queue_redraw()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_hovered(on: bool) -> void:
	_hovered = on
	queue_redraw()


func set_charges(charges: Dictionary) -> void:
	_charges = charges
	queue_redraw()


func set_webbed(webbed: Dictionary) -> void:
	_webbed = webbed
	queue_redraw()


func get_display_size() -> Vector2:
	return _compute_bounds().size


func get_wand_data() -> WandData:
	return _data


func get_slot_at(local_pos: Vector2) -> SpellSlotData:
	if _data == null:
		return null
	for slot: SpellSlotData in _data.slots:
		if Rect2(_slot_pixel_pos(slot), SLOT_SIZE).has_point(local_pos):
			return slot
	return null


func get_tip_spell() -> SpellData:
	if _data == null:
		return null
	var tip := _data.get_tip_slot()
	return tip.spell if tip else null


func _slot_pixel_pos(slot: SpellSlotData) -> Vector2:
	return Vector2(float(slot.grid_col), float(slot.grid_row)) * CELL_SPACING + PAD


func _slot_center(slot: SpellSlotData) -> Vector2:
	return _slot_pixel_pos(slot) + SLOT_SIZE * 0.5


func _compute_bounds() -> Rect2:
	if _data == null or _data.slots.is_empty():
		return Rect2(Vector2.ZERO, Vector2(120.0, 70.0))
	var max_col := 0
	var max_row := 0
	for slot: SpellSlotData in _data.slots:
		max_col = maxi(max_col, slot.grid_col)
		max_row = maxi(max_row, slot.grid_row)
	var w := float(max_col) * CELL_SPACING.x + SLOT_SIZE.x + PAD.x * 2.0
	var h := float(max_row) * CELL_SPACING.y + SLOT_SIZE.y + PAD.y + PAD_BOTTOM
	return Rect2(Vector2.ZERO, Vector2(w, h))


func _unhandled_input(event: InputEvent) -> void:
	if _data == null:
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	var button: MouseButton = event.button_index
	if button != MOUSE_BUTTON_LEFT and button != MOUSE_BUTTON_RIGHT:
		return
	var local := to_local(event.position)
	for slot: SpellSlotData in _data.slots:
		if not Rect2(_slot_pixel_pos(slot), SLOT_SIZE).has_point(local):
			continue
		if button == MOUSE_BUTTON_RIGHT:
			body_slot_right_clicked.emit(self, slot.id)
		elif slot.is_tip:
			tip_pressed.emit(self)
		else:
			body_slot_clicked.emit(self, slot.id)
		get_viewport().set_input_as_handled()
		return


func _draw() -> void:
	if _data == null:
		return
	var bounds := _compute_bounds()
	draw_rect(bounds, Palette.COLOR_WAND_BG, true)
	draw_rect(bounds, Palette.COLOR_WAND_BG_BORDER, false, 1.5)
	_draw_edges()
	for slot: SpellSlotData in _data.slots:
		_draw_slot(slot)
	if _hovered:
		draw_rect(bounds, Palette.COLOR_TARGET_HOVER, false, 3.0)
	elif _highlighted:
		draw_rect(bounds, Palette.COLOR_TARGET_AVAILABLE, false, 2.5)


func _draw_edges() -> void:
	for slot: SpellSlotData in _data.slots:
		if slot.next_id.is_empty():
			continue
		var next := _data.get_slot(slot.next_id)
		if next == null:
			continue
		var from := _slot_center(slot)
		var to := _slot_center(next)
		var dir := (to - from).normalized()
		var half := SLOT_SIZE.x * 0.5
		draw_line(from + dir * (half + 1.0), to - dir * (half + 1.0), Palette.COLOR_WAND_EDGE, 1.5)
		_draw_arrowhead(from, to)


func _draw_arrowhead(from: Vector2, to: Vector2) -> void:
	var dir := (to - from).normalized()
	var tip := to - dir * (SLOT_SIZE.x * 0.5 + 2.0)
	var perp := Vector2(-dir.y, dir.x) * 4.5
	var base := tip - dir * 7.0
	draw_colored_polygon(PackedVector2Array([tip, base + perp, base - perp]), Palette.COLOR_WAND_EDGE)


func _draw_icon(pos: Vector2, size: Vector2, icon_name: String) -> void:
	if icon_name == "bomb":
		_draw_bomb_icon(pos, size)


func _draw_bomb_icon(pos: Vector2, size: Vector2) -> void:
	var center := pos + Vector2(size.x * 0.44, size.y * 0.60)
	var radius := size.x * 0.27

	draw_circle(center, radius, Palette.COLOR_BOMB_BODY)
	draw_arc(center, radius, 0.0, TAU, 32, Palette.COLOR_BOMB_RIM, 1.5)
	# Shine
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.32), radius * 0.22,
			Palette.COLOR_BOMB_SHINE)

	# Fuse
	var fuse_base := center + Vector2(radius * 0.60, -radius * 0.78)
	var fuse_tip := pos + Vector2(size.x * 0.76, size.y * 0.13)
	draw_line(fuse_base, fuse_tip, Palette.COLOR_BOMB_FUSE, 1.5)

	# Spark
	draw_circle(fuse_tip, 3.2, Palette.COLOR_BOMB_SPARK)
	draw_circle(fuse_tip, 1.6, Palette.COLOR_BOMB_SPARK_HOT)


func _draw_slot(slot: SpellSlotData) -> void:
	var pos := _slot_pixel_pos(slot)
	var rect := Rect2(pos, SLOT_SIZE)
	if slot.is_tip:
		draw_rect(rect, Palette.COLOR_WAND_SLOT_TIP, true)
		draw_rect(rect, Palette.COLOR_WAND_BORDER_TIP, false, 1.5)
	else:
		draw_rect(rect, Palette.COLOR_WAND_SLOT_BODY, true)
		draw_rect(rect, Palette.COLOR_WAND_BORDER_BODY, false, 1.0)

	if slot.spell == null:
		return

	var charges: int = _charges.get(slot.id, 0)
	var cost := slot.spell.mana_cost
	var active: bool = charges >= cost

	if slot.spell.icon.is_empty():
		draw_rect(rect, Color(slot.spell.element_color, 0.28), true)
		draw_string(ThemeDB.fallback_font,
				Vector2(pos.x, pos.y + SLOT_SIZE.y * 0.5 + 5.0),
				slot.spell.abbreviation,
				HORIZONTAL_ALIGNMENT_CENTER, SLOT_SIZE.x, 11, Color.WHITE)
	else:
		_draw_icon(pos, SLOT_SIZE, slot.spell.icon)

	_draw_mana_pips(pos, charges, cost)
	if active:
		draw_rect(rect, Palette.COLOR_ACTIVE_BORDER, false, 2.0)
	if _webbed.has(slot.id):
		_draw_net_overlay(pos)


func _draw_net_overlay(pos: Vector2) -> void:
	draw_rect(Rect2(pos, SLOT_SIZE), Palette.COLOR_BOMB_SLOT_FILL, true)
	var c := Palette.COLOR_BOMB_SLOT_BORDER
	const STEP := 9.0
	var end_x := pos.x + SLOT_SIZE.x
	var end_y := pos.y + SLOT_SIZE.y
	var y := pos.y
	while y <= end_y:
		draw_line(Vector2(pos.x, y), Vector2(end_x, y), c, 1.2)
		y += STEP
	var x := pos.x
	while x <= end_x:
		draw_line(Vector2(x, pos.y), Vector2(x, end_y), c, 1.2)
		x += STEP


func _draw_mana_pips(pos: Vector2, charges: int, cost: int) -> void:
	if cost <= 0:
		return
	const PIP := 5.0
	const GAP := 2.0
	var total_w := cost * PIP + (cost - 1) * GAP
	var px := pos.x + (SLOT_SIZE.x - total_w) * 0.5
	var py := pos.y + SLOT_SIZE.y - PIP - 3.0
	for i in cost:
		var color := Palette.COLOR_PIP_FILLED if i < charges else Palette.COLOR_PIP_EMPTY
		draw_rect(Rect2(Vector2(px + i * (PIP + GAP), py), Vector2(PIP, PIP)), color, true)
