class_name MageDisplay
extends Node2D

const WIDTH := 80.0
const PAD := 9.0
const BAR_HEIGHT := 9.0

var _mage: MageData = null
var _height: float = 70.0
var _highlighted := false
var _hovered := false
var _mana_committed: int = 0
var _mana_max: int = 0
var _incoming_attack: int = 0
var _statuses: Array = []
var _shield: int = 0


func setup(mage: MageData, height: float) -> void:
	_mage = mage
	_height = height
	queue_redraw()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_hovered(on: bool) -> void:
	_hovered = on
	queue_redraw()


func set_mana(committed: int, max_mana: int) -> void:
	_mana_committed = committed
	_mana_max = max_mana
	queue_redraw()


func set_status(incoming_attack: int = 0, statuses: Array = [], shield: int = 0) -> void:
	_incoming_attack = incoming_attack
	_statuses = statuses
	_shield = shield
	queue_redraw()


func get_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(WIDTH, _height))


func _draw() -> void:
	if _mage == null:
		return
	var is_dead := _mage.current_hp <= 0
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, _height)), Palette.COLOR_WIDGET_DEAD if is_dead else Palette.COLOR_WIDGET_BG, true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, _height)), Palette.COLOR_WIDGET_BORDER, false, 1.0)

	# vertically centre the content block
	var has_status := not _statuses.is_empty()
	var status_count := _statuses.size()
	var content_h := 16.0 + 6.0 + BAR_HEIGHT + 5.0 + 13.0 + 6.0 + 12.0
	if has_status:
		content_h += status_count * (5.0 + 12.0)
	var y := (_height - content_h) * 0.5

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(PAD, y + 16.0), _mage.name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	var bar_y := y + 24.0
	var bar_w := WIDTH - PAD * 2.0
	draw_rect(Rect2(Vector2(PAD, bar_y), Vector2(bar_w, BAR_HEIGHT)), Palette.COLOR_HP_BG, true)

	var hp_frac := float(_mage.current_hp) / float(_mage.max_hp)
	var status_dmg := 0
	for status: StatusData in _statuses:
		status_dmg += status.get_turn_damage()
	var total_dmg := _incoming_attack + status_dmg
	var hp_after := maxi(0, _mage.current_hp - total_dmg)
	var hp_after_frac := float(hp_after) / float(_mage.max_hp)
	var hp_color := Palette.COLOR_HP_FULL.lerp(Palette.COLOR_HP_LOW, 1.0 - hp_frac)
	draw_rect(Rect2(Vector2(PAD, bar_y), Vector2(bar_w * hp_after_frac, BAR_HEIGHT)), hp_color, true)

	var dx := PAD + bar_w * hp_after_frac
	var max_x := PAD + bar_w * hp_frac
	var atk_w := minf(bar_w * float(_incoming_attack) / float(_mage.max_hp), max_x - dx)
	if atk_w > 0.5:
		draw_rect(Rect2(Vector2(dx, bar_y), Vector2(atk_w, BAR_HEIGHT)), Palette.COLOR_HP_LOSS, true)
		dx += atk_w
	for status: StatusData in _statuses:
		var dmg := status.get_turn_damage()
		if dmg <= 0:
			continue
		var seg_w := minf(bar_w * float(dmg) / float(_mage.max_hp), max_x - dx)
		if seg_w > 0.5:
			var c := status.display_color
			draw_rect(Rect2(Vector2(dx, bar_y), Vector2(seg_w, BAR_HEIGHT)), Color(c.r, c.g, c.b, 0.88), true)
			dx += seg_w

	if _shield > 0:
		var shield_w := minf(bar_w * float(_shield) / float(_mage.max_hp), bar_w)
		var shield_x := PAD + bar_w - shield_w
		draw_rect(Rect2(Vector2(shield_x, bar_y), Vector2(shield_w, BAR_HEIGHT)),
				Palette.COLOR_SHIELD_FILL, true)
		draw_rect(Rect2(Vector2(shield_x, bar_y), Vector2(shield_w, BAR_HEIGHT)),
				Palette.COLOR_SHIELD_EDGE, false, 1.0)

	var hp_text_y := bar_y + BAR_HEIGHT + 13.0
	var hp_label := "%d/%d" % [_mage.current_hp, _mage.max_hp]
	if _shield > 0:
		hp_label += " +%d" % _shield
	draw_string(font, Vector2(PAD, hp_text_y),
			hp_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.COLOR_HP_LABEL)

	if _mana_max > 0:
		draw_string(font, Vector2(PAD, hp_text_y + 18.0),
				"%d/%d" % [_mana_committed, _mana_max],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.COLOR_MANA_LABEL)
		draw_string(font, Vector2(WIDTH - PAD, hp_text_y + 18.0),
				"uses", HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Palette.COLOR_MANA_LABEL)
	if has_status:
		var pill_y := hp_text_y + 18.0 + 5.0
		var pill_h := 12.0
		var pill_w := WIDTH - PAD * 2.0
		for status: StatusData in _statuses:
			draw_rect(Rect2(Vector2(PAD, pill_y), Vector2(pill_w, pill_h)), status.display_color, true)
			draw_string(font, Vector2(PAD + pill_w * 0.5, pill_y + 10.0),
					status.get_label(), HORIZONTAL_ALIGNMENT_CENTER, pill_w, 9, Color.WHITE)
			pill_y += pill_h + 5.0

	var r := get_rect()
	if _hovered:
		draw_rect(r, Palette.COLOR_TARGET_HOVER, false, 3.0)
	elif _highlighted:
		draw_rect(r, Palette.COLOR_TARGET_AVAILABLE, false, 2.5)
