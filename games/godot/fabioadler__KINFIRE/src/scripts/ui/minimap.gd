class_name Minimap
extends Control
## Minimapa centrado no jogador (funciona no mundo aberto e na masmorra).
## Pergunta ao World a cor de cada célula explorada ao redor.

const SCALE := 3.0
const RADIUS := 32      ## células desenhadas em cada direção
const CIRCLE_MASK := preload("res://shaders/circle_mask.gdshader")
var world: World
var _img: Image
var _tex: ImageTexture
var _t := 0.0
var _center := Vector2i.ZERO


func _init(p_world: World) -> void:
	world = p_world
	custom_minimum_size = Vector2(190, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	# Fase 6.1: máscara circular + borda dourada (#9.2)
	var mat := ShaderMaterial.new()
	mat.shader = CIRCLE_MASK
	material = mat


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = 0.3
		_rebuild()
	queue_redraw()


func _rebuild() -> void:
	if world.player == null:
		return
	var size_px := RADIUS * 2
	if _img == null:
		_img = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	_center = world.world_to_cell(world.player.global_position)
	for y in size_px:
		for x in size_px:
			_img.set_pixel(x, y, world.minimap_color(_center + Vector2i(x - RADIUS, y - RADIUS)))
	if _tex == null:
		_tex = ImageTexture.create_from_image(_img)
	else:
		_tex.update(_img)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	if _tex == null or world.player == null:
		return
	# Posição exata do jogador dentro da célula central (rolagem suave)
	var pc := world.player.global_position / World.TILE
	var origin := size * 0.5 - (pc - Vector2(_center - Vector2i(RADIUS, RADIUS))) * SCALE
	draw_set_transform(origin, 0, Vector2(SCALE, SCALE))
	draw_texture(_tex, Vector2.ZERO)
	draw_set_transform(Vector2.ZERO)
	var to_map := func(p: Vector2) -> Vector2: return size * 0.5 + (p / World.TILE - pc) * SCALE
	for poi in world.points_of_interest():
		var mp: Vector2 = to_map.call(poi.pos)
		mp = mp.clamp(Vector2(4, 4), size - Vector2(4, 4))
		draw_circle(mp, 3.5, Color.BLACK)
		draw_circle(mp, 2.6, poi.color)
	for e in world.enemies_near(world.player.global_position, 160.0):
		# 3.1: cor/contorno do minimapa por raridade (chefe maior e laranja)
		var col: Color = Color(1, 0.2, 0.2) if e.rarity == Enemy.Rarity.COMUM else Enemy.RARITY_COLORS[e.rarity]
		if e.is_boss():
			col = Color(1, 0.55, 0.1)
		var r_map := 2.4 if (e.rarity >= Enemy.Rarity.ELITE or e.is_boss()) else 1.6
		if e.rarity >= Enemy.Rarity.LENDARIO:
			r_map = 3.0
			# 3.4: anel pulsante - Lendário identificável no minimapa à primeira vista
			var pulse_r := r_map + 1.4 + sin(Time.get_ticks_msec() * 0.005) * 0.8
			draw_circle(to_map.call(e.global_position), pulse_r, Color(col.r, col.g, col.b, 0.3))
		draw_circle(to_map.call(e.global_position), r_map, col)
	for m in world.minions_near(world.player.global_position, 160.0):
		draw_circle(to_map.call(m.global_position), 1.6, Color(0.4, 1, 0.6))
	draw_circle(size * 0.5, 3.0, Color(0.3, 1.0, 0.3))
	# 7.4: "Ler o Vento" (Caçador, #14.5.5) - vetor do vento no minimapa
	var reading74 := false
	for b in world.player.buffs.values():
		if b.stat == "wind_reader":
			reading74 = true
			break
	if reading74:
		var w74 := WindField.at(world.player.global_position)
		if w74.length() > 0.02:
			var tip74 := size * 0.5 + w74.normalized() * (24.0 + 40.0 * w74.length())
			draw_line(size * 0.5, tip74, Color(0.6, 0.9, 1.0, 0.9), 2.0, true)
			draw_circle(tip74, 2.6, Color(0.7, 0.95, 1.0))
	# Fase 6.1: borda dourada circular (a máscara do shader corta os cantos)
	draw_arc(size * 0.5, size.x * 0.5 - 2.0, 0, TAU, 64, UIKit.GOLD, 2.0, true)
