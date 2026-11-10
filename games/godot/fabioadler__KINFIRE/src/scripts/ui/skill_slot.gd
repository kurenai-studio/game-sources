class_name SkillSlot
extends Control
## Slot da barra de habilidades com ícone, tecla e sobreposição de recarga.

signal clicked(slot: int)

var slot := 0
var key_text := ""
var player: Player
var _flash := 0.0
var is_potion := false


func _init(p_slot: int, p_key: String) -> void:
	slot = p_slot
	key_text = p_key
	custom_minimum_size = Vector2(52, 52)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = " "


func flash() -> void:
	_flash = 1.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(slot)
		accept_event()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 4.0, 0.0)
	queue_redraw()


func get_skill() -> SkillData:
	if player == null or is_potion:
		return null
	return player.skill_for_slot(slot)


func _make_custom_tooltip(_for_text: String) -> Object:
	var s := get_skill()
	var r := UIKit.rich()
	r.custom_minimum_size = Vector2(300, 0)
	if is_potion:
		r.text = "[font_size=18][color=#60ff90]Cura Simples[/color][/font_size]\nRestaura 15% da vida.\n[color=#999999]Recarga: 8s  -  Tecla Q[/color]"
		return r
	if s == null:
		r.text = "[color=#999999]Slot vazio.\nAbra Habilidades (K) para atribuir.[/color]"
		return r
	var hero := player.hero
	var t := "[font_size=19][color=#e8c060]%s[/color][/font_size]\n" % s.display_name
	t += "%s\n\n" % s.description
	if s.damage_mult > 0:
		t += "[color=#ff9060]Dano: %d%% do dano da arma[/color]\n" % roundi(s.damage_mult * 100)
	if s.element != "physical":
		t += "[color=#%s]Elemento: %s[/color]\n" % [DB.ELEMENT_COLORS[s.element].to_html(false), DB.ELEMENT_NAMES[s.element]]
	if s.cost > 0 and s != hero.racial_skill():
		if hero.cls.costs_life:
			t += "[color=#ff6080]Custo: %d de Vida (Pacto)[/color]\n" % player.skill_cost(s)
		else:
			t += "[color=#80a0ff]Custo: %d %s[/color]\n" % [s.cost, hero.cls.resource_label]
	if s.generate > 0:
		t += "[color=#80ff80]Gera: %d %s[/color]\n" % [s.generate, hero.cls.resource_label]
	if s.cooldown > 0:
		t += "[color=#cccccc]Recarga: %.1fs[/color]\n" % (s.cooldown * hero.cooldown_mult())
	r.text = t
	return r


## Setor radial do cooldown (Fase 6.1, #9.2: "varredura em cone") - pontos
## do polígono que cobre a fração restante, a partir do topo, horário.
static func _radial_points(center: Vector2, radius: float, frac: float) -> PackedVector2Array:
	var pts := PackedVector2Array([center])
	var n := 32
	for i in n + 1:
		var ang := -PI * 0.5 + TAU * frac * float(i) / float(n)
		pts.append(center + Vector2(cos(ang), sin(ang)) * radius)
	return pts


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.03, 0.02, 0.02))
	var s := get_skill()
	var icon_name := ""
	var color := Color.WHITE
	if is_potion:
		icon_name = "P_Red01"
		color = Color(1, 0.3, 0.3)
	elif s:
		icon_name = s.icon
		color = s.color
	if icon_name != "":
		draw_rect(rect.grow(-3), Color(color.r * 0.25, color.g * 0.25, color.b * 0.25))
		draw_texture_rect(DB.icon(icon_name), rect.grow(-4), false)
	# Recarga
	var frac := 0.0
	var remaining := 0.0
	if player:
		if is_potion:
			remaining = player.simple_heal_cd
			frac = remaining / Player.SIMPLE_HEAL_CD
		elif s:
			remaining = player.cooldowns.get(s.id, 0.0)
			var total := s.cooldown * player.hero.cooldown_mult()
			frac = remaining / total if total > 0 else 0.0
			if not player.can_afford(s):
				draw_rect(rect, Color(0.1, 0.1, 0.5, 0.45))
	if frac > 0.0:
		# varredura radial (cone que seca no sentido horário)
		draw_colored_polygon(_radial_points(size * 0.5, size.length() * 0.75, frac), Color(0, 0, 0, 0.66))
		var f := UIKit.FONT_TITLE
		var txt := str(ceili(remaining))
		draw_string_outline(f, Vector2(0, size.y * 0.5 + 8), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, 4, Color.BLACK)
		draw_string(f, Vector2(0, size.y * 0.5 + 8), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color.WHITE)
	if _flash > 0.0:
		draw_rect(rect, Color(1, 0.1, 0.1, _flash * 0.5))
	var border := UIKit.GOLD if get_global_rect().has_point(get_global_mouse_position()) else UIKit.GOLD_DIM
	draw_rect(rect, border, false, 2.0)
	# Tecla
	draw_string_outline(UIKit.FONT_TITLE, Vector2(4, 14), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
	draw_string(UIKit.FONT_TITLE, Vector2(4, 14), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIKit.TEXT)
