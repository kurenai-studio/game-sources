class_name World
extends Node2D
## Base dos mundos jogáveis. Esta classe implementa a MASMORRA (salas + corredores);
## o mundo aberto (Overworld) herda dela e sobrescreve os métodos de mapa/spawn.

## Preloads para type hints funcionarem em parse time (evita dependências circulares)
const Player := preload("res://scripts/game/player.gd")
const Interactable := preload("res://scripts/game/interactable.gd")
const Enemy := preload("res://scripts/game/enemy.gd")
# HUD não é preloadado aqui para evitar dependência circular com hud.gd

const TILE := 16
const PLAYER_SCENE := preload("res://scenes/game/player.tscn")
const ENEMY_SCENE := preload("res://scenes/game/enemy.tscn")

## Tiles usados do 0x72 (montados num atlas próprio em tempo de execução)
const TILE_NAMES := [
	"__solid", "floor_1", "floor_2", "floor_3", "floor_4", "floor_5", "floor_6", "floor_7", "floor_8",
	"wall_mid", "wall_left", "wall_right", "wall_top_mid", "wall_top_left", "wall_top_right",
	"wall_edge_mid_left", "wall_edge_mid_right", "wall_banner_red", "wall_banner_blue", "wall_banner_green",
	"wall_banner_yellow", "wall_hole_1", "wall_hole_2", "wall_goo", "wall_fountain_mid_red_anim_f0",
	"wall_fountain_mid_blue_anim_f0", "wall_edge_bottom_left", "wall_edge_bottom_right", "floor_stairs",
]
const FLOOR_WEIGHTS := {"floor_1": 30, "floor_2": 2, "floor_3": 2, "floor_4": 1, "floor_5": 2, "floor_6": 1, "floor_7": 1, "floor_8": 1}
const FACE_VARIANTS := ["wall_banner_red", "wall_banner_blue", "wall_banner_green", "wall_banner_yellow", "wall_hole_1", "wall_hole_2", "wall_goo", "wall_fountain_mid_red_anim_f0", "wall_fountain_mid_blue_anim_f0"]

@onready var floor_layer: TileMapLayer = $Floor
@onready var wall_layer: TileMapLayer = $Walls
@onready var decals: Node2D = $Decals
@onready var entities: Node2D = $Entities
@onready var fx_layer: Node2D = $Fx
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

var gen := DungeonGenerator.new()
var astar := AStarGrid2D.new()
var player: Player
var hud: HUD  # HUD original (HUDResponsive Fase 12+ é future enhancement)
var stairs: Interactable
var boss: Enemy
var explored := PackedByteArray()
var slow_zones: Array[Dictionary] = []
var fire_zones: Array[Dictionary] = []
var _tile_index: Dictionary = {}
## Hash espacial de inimigos (reconstruído uma vez por frame de física)
const BUCKET := 32.0
var _buckets: Dictionary = {}
var _bucket_frame := -1
var _minion_frame := -1
var _minion_list: Array[Minion] = []
var _shake := 0.0
var _explore_timer := 0.0
## Fase 7.5 (#15): áudio adaptativo - tick de atualização
var _audio_timer := 0.0
## Fase 7.3 (#14.3): bloom (HDR 2D) + camada de vinheta/temperatura
var _world_env: WorldEnvironment
var _atmos_layer: CanvasLayer
var _atmos: ColorRect
## Ultimo preset aplicado (inspeção/smoke - headless não lê uniforms de shader)
var _atmos_preset: Dictionary = {}


func _ready() -> void:
	add_to_group("world")
	if Game.hero == null:
		# Execução direta da cena (debug): cria um herói padrão
		Game.hero = Hero.create("Aventureiro", DB.races[0], DB.classes[0], "m", Color.WHITE, {"str": 15, "dex": 13, "con": 14, "int": 8, "wis": 10, "cha": 12})
	_setup_map()
	_apply_brightness()
	_setup_post()

	hud = HUD.new()  # Usa HUD estável (v10); HUDResponsive é Fase 12 future
	add_child(hud)

	player = PLAYER_SCENE.instantiate()
	player.setup(Game.hero, self)
	player.position = _start_position()
	entities.add_child(player)
	player.died.connect(_on_player_died)
	hud.setup(self, player)

	_spawn_content()
	_intro()


# ------------------------------------------------------------------ GANCHOS (sobrescritos no Overworld)

func _setup_map() -> void:
	gen.generate(Game.depth)
	explored.resize(gen.width * gen.height)
	explored.fill(0)
	_build_tiles()
	_build_astar()
	# 7.4: masmorras não consultam bioma - vento de base planície
	WindField.set_provider(Callable())


func _start_position() -> Vector2:
	return cell_to_world(gen.start_room.get_center())


func _intro() -> void:
	Game.play_music("res://assets/audio/music_dungeon.ogg")
	var diff: Dictionary = Game.hero.difficulty_data()
	hud.show_message(region_name(), UIKit.GOLD, 3.0)
	hud.show_message("Dificuldade: %s%s" % [diff.name, "  -  HARDCORE" if Game.hero.hardcore else ""], diff.color, 3.0)
	if boss:
		hud.show_message("%s aguarda nas profundezas..." % boss.display_name, Color(1, 0.4, 0.2), 3.0)


## Nível dos monstros/itens desta área
func level() -> int:
	return Game.dungeon_level + Game.depth - 1


func region_name() -> String:
	return "%s - Andar %d" % [Game.dungeon_name, Game.depth]


func is_floor(c: Vector2i) -> bool:
	return gen.is_floor(c)


func is_explored(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= gen.width or c.y >= gen.height:
		return false
	return explored[c.y * gen.width + c.x] == 1


## Cor de uma célula no minimapa (transparente = não desenhar)
func minimap_color(c: Vector2i) -> Color:
	if not is_explored(c):
		return Color(0, 0, 0, 0)
	if is_floor(c):
		return Color(0.45, 0.35, 0.25, 0.85)
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if is_floor(c + d):
			return Color(0.75, 0.65, 0.5, 0.9)
	return Color(0, 0, 0, 0)


## Pontos de interesse do minimapa: [{pos, color}]
func points_of_interest() -> Array:
	var out: Array = []
	if stairs and is_instance_valid(stairs) and is_explored(world_to_cell(stairs.global_position)):
		var color = Color(0.7, 0.4, 1.0) if not stairs.locked else Color(1, 0.3, 0.1)
		out.append({"pos": stairs.global_position, "color": color})
	return out


func respawn_position() -> Vector2:
	return cell_to_world(gen.start_room.get_center())


## Acender uma fogueira (hook - sobrescrito por Overworld/Prologue)
func _on_campfire_lit(_fire: Interactable) -> void:
	hud.show_message("Fogueira acesa: você renascerá aqui.", Color(1, 0.7, 0.3))
	hud.open_waypoints()


## Olhar-se no espelho (hook - sobrescrito pelo Prologue)
func _on_mirror(_mirror: Interactable) -> void:
	hud.show_message("Só o escuro olha de volta.", Color(0.68, 0.64, 0.82))


## Fase 7.3 (MECANICAS #14.3): pós-processo do mundo - bloom/glow via
## WorldEnvironment sobre HDR 2D (fogueiras, lava, orbes, feixes de loot Raro+
## e auras de Campeão/Lendário têm energia >1 e florescem) e camada de
## vinheta/temperatura entre o mundo (base) e a HUD (layer 10).
func _setup_post() -> void:
	var env := Environment.new()
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.0
	env.glow_bloom = 0.1
	env.glow_hdr_threshold = 1.05      # só o que passa de 1.0 (luzes) brilha
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set("glow_levels/3", 1.0)
	env.set("glow_levels/4", 0.8)
	env.set("glow_levels/5", 0.4)
	_world_env = WorldEnvironment.new()
	_world_env.environment = env
	add_child(_world_env)
	_atmos_layer = CanvasLayer.new()
	_atmos_layer.layer = 2
	add_child(_atmos_layer)
	_atmos = ColorRect.new()
	_atmos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atmos.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/atmosphere.gdshader")
	_atmos.material = m
	_atmos_layer.add_child(_atmos)
	# masmorra: vinheta mais fechada e fria (o Overworld sobrepõe pelo bioma)
	_apply_atmos({"tint": Color(0.9, 0.88, 1.0), "amount": 0.1, "desat": 0.05, "vig": 0.32})
	# 7.7: presets de qualidade (#14.6) - glow liga/desliga em runtime
	_apply_glow()
	Game.quality_changed.connect(_apply_glow)


## 7.7: glow do preset - Baixo desliga o bloom (#14.6), Médio/Alto mantêm
func _apply_glow() -> void:
	if _world_env != null and _world_env.environment != null:
		_world_env.environment.glow_enabled = bool(Game.settings.get("glow", true))


## Preset de vinheta/temperatura: {tint, amount, desat, vig, vig_color}.
## O Overworld chama por bioma (BIOME_ATMOS); a masmorra usa o próprio.
func _apply_atmos(a: Dictionary) -> void:
	_atmos_preset = a.duplicate()
	if _atmos == null:
		return
	var m := _atmos.material as ShaderMaterial
	m.set_shader_parameter("tint", a.get("tint", Color.WHITE))
	m.set_shader_parameter("tint_amount", a.get("amount", 0.0))
	m.set_shader_parameter("desat", a.get("desat", 0.0))
	m.set_shader_parameter("vignette", a.get("vig", 0.22))
	m.set_shader_parameter("vignette_color", a.get("vig_color", Color(0.01, 0.0, 0.03)))


func _apply_brightness() -> void:
	var b: float = Game.settings.brightness
	var c: Color = Color(0.34, 0.3, 0.34).darkened(clampf((Game.depth - 1) * 0.04, 0.0, 0.3))
	canvas_modulate.color = Color(c.r * b, c.g * b, c.b * b, 1.0)


func _process(delta: float) -> void:
	if _shake > 0.0 and player:
		_shake = maxf(_shake - delta * 18.0, 0.0)
		player.camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * float(Game.settings.shake_intensity)
	# 7.2: tremulação das luzes + orçamento de sombra em torno do herói
	if player:
		LightFx.update(player.global_position, Time.get_ticks_msec() * 0.001)
	# 7.5: áudio adaptativo (MECANICAS #15) - ambiência por bioma, camadas de
	# combate/noite/chefe/descanso, vento controla o bus Ambience, reverb de
	# masmorra (Overworld sobrescreve super._process, então isto cobre ambos)
	_audio_timer -= delta
	if _audio_timer <= 0.0:
		_audio_timer = 0.5
		Audio.update_world(self)
	_explore_timer -= delta
	if _explore_timer <= 0.0 and player:
		_explore_timer = 0.15
		_reveal_around(world_to_cell(player.global_position), 8)
	for z in slow_zones:
		z.time -= delta
	slow_zones = slow_zones.filter(func(z): return z.time > 0.0)
	# 3.2: piso em chamas (afixo ARDENTE) - queimadura enquanto o jogador fica dentro
	for z in fire_zones:
		z.time -= delta
		if z.time > 0.0 and player and not player.is_dead() and player.global_position.distance_to(z.pos) <= z.radius:
			player.apply_poison(z.dps * 0.5, 0.6)
	fire_zones = fire_zones.filter(func(z): return z.time > 0.0)


# ------------------------------------------------------------------ MAPA

func _build_tiles() -> void:
	# Monta um atlas 16x16 com os tiles nomeados
	var cols := 8
	var rows := ceili(TILE_NAMES.size() / float(cols))
	var img := Image.create(cols * TILE, rows * TILE, false, Image.FORMAT_RGBA8)
	var sheet := DB.DT2_SHEET.get_image()
	if sheet.is_compressed():
		sheet.decompress()
	sheet.convert(Image.FORMAT_RGBA8)
	for i in TILE_NAMES.size():
		var n: String = TILE_NAMES[i]
		_tile_index[n] = Vector2i(i % cols, i / cols)
		if n == "__solid":
			continue
		var r := DB.dt2_rect(n)
		r.size = Vector2i(mini(r.size.x, TILE), mini(r.size.y, TILE))
		img.blit_rect(sheet, r, Vector2i(i % cols, i / cols) * TILE)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	# 7.2: camada de oclusão - cada tile sólido projeta sombra nas luzes
	# com shadow_enabled (paredes de masmorra, árvores, lápides, muros - #14.2)
	ts.add_occlusion_layer()
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var square := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	for n in TILE_NAMES:
		var coords: Vector2i = _tile_index[n]
		src.create_tile(coords)
		if not n.begins_with("floor"):
			var td := src.get_tile_data(coords, 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, square)
			# 7.2: oclusor de sombra cobrindo o tile inteiro
			var occ := OccluderPolygon2D.new()
			occ.polygon = square
			td.set_occluder(0, occ)
	# Alternativa espelhada do topo da parede (borda inferior das salas)
	var top: Vector2i = _tile_index["wall_top_mid"]
	var flipped := src.create_alternative_tile(top)
	var ftd := src.get_tile_data(top, flipped)
	ftd.flip_v = true
	ftd.add_collision_polygon(0)
	ftd.set_collision_polygon_points(0, 0, square)
	var focc := OccluderPolygon2D.new()
	focc.polygon = square
	ftd.set_occluder(0, focc)
	floor_layer.tile_set = ts
	wall_layer.tile_set = ts

	var floor_pool: Array = []
	for k in FLOOR_WEIGHTS:
		for i in FLOOR_WEIGHTS[k]:
			floor_pool.append(k)
	for y in gen.height:
		for x in gen.width:
			var c: Vector2i = Vector2i(x, y)
			if gen.is_floor(c):
				_set_tile(floor_layer, c, floor_pool.pick_random())
	for y in gen.height:
		for x in gen.width:
			var c: Vector2i = Vector2i(x, y)
			if not gen.is_floor(c) and (_near_floor(c, 1) or _is_face(c + Vector2i.DOWN)):
				_paint_solid(c, flipped)


func _set_tile(layer: TileMapLayer, c: Vector2i, tile_name: String, alt := 0) -> void:
	layer.set_cell(c, 0, _tile_index[tile_name], alt)


func _near_floor(c: Vector2i, r: int) -> bool:
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if gen.is_floor(c + Vector2i(dx, dy)):
				return true
	return false


func _is_face(c: Vector2i) -> bool:
	return not gen.is_floor(c) and gen.is_floor(c + Vector2i.DOWN)


func _paint_solid(c: Vector2i, flipped_alt: int) -> void:
	var fl := gen.is_floor(c + Vector2i.LEFT)
	var fr := gen.is_floor(c + Vector2i.RIGHT)
	if _is_face(c):
		var t := "wall_mid"
		if randf() < 0.07 and not fl and not fr:
			t = FACE_VARIANTS.pick_random()
		_set_tile(wall_layer, c, t)
		return
	if _is_face(c + Vector2i.DOWN):
		_set_tile(wall_layer, c, "wall_top_mid")
	elif gen.is_floor(c + Vector2i.UP):
		_set_tile(wall_layer, c, "wall_top_mid", flipped_alt)
	elif fl:
		_set_tile(wall_layer, c, "wall_edge_mid_left")
	elif fr:
		_set_tile(wall_layer, c, "wall_edge_mid_right")
	else:
		_set_tile(wall_layer, c, "__solid")


func _build_astar() -> void:
	astar.region = Rect2i(0, 0, gen.width, gen.height)
	astar.cell_size = Vector2(TILE, TILE)
	astar.offset = Vector2(TILE * 0.5, TILE * 0.5)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for y in gen.height:
		for x in gen.width:
			if not gen.is_floor(Vector2i(x, y)):
				astar.set_point_solid(Vector2i(x, y), true)


func cell_to_world(c: Vector2i) -> Vector2:
	return Vector2(c) * TILE + Vector2(TILE * 0.5, TILE * 0.5)


func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


func is_solid(p: Vector2) -> bool:
	return not is_floor(world_to_cell(p))


func has_line_of_sight(a: Vector2, b: Vector2) -> bool:
	var d := a.distance_to(b)
	var steps := int(d / 6.0)
	for i in range(1, steps):
		if is_solid(a.lerp(b, float(i) / steps)):
			return false
	return true


func last_free_point(from: Vector2, to: Vector2) -> Vector2:
	var d := from.distance_to(to)
	var steps := maxi(int(d / 3.0), 1)
	var last := from
	for i in range(1, steps + 1):
		var p := from.lerp(to, float(i) / steps)
		if is_solid(p) or is_solid(p + Vector2(5, 0)) or is_solid(p - Vector2(5, 0)) or is_solid(p + Vector2(0, 2)) or is_solid(p - Vector2(0, 5)):
			break
		last = p
	return last


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := world_to_cell(from)
	var b := world_to_cell(to)
	if not is_floor(a):
		a = _nearest_floor(a)
	if not is_floor(b):
		b = _nearest_floor(b)
	if not astar.is_in_boundsv(a) or not astar.is_in_boundsv(b) or astar.is_point_solid(a) or astar.is_point_solid(b):
		return PackedVector2Array()
	var path := astar.get_point_path(a, b)
	if path.size() > 0:
		path.remove_at(0)
	if path.size() > 0 and is_floor(world_to_cell(to)):
		path[path.size() - 1] = to
	return path


func _nearest_floor(c: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if is_floor(c + Vector2i(dx, dy)):
					return c + Vector2i(dx, dy)
	return c


func _reveal_around(c: Vector2i, r: int) -> void:
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue
			_set_explored(c + Vector2i(dx, dy))


func _set_explored(n: Vector2i) -> void:
	if n.x >= 0 and n.y >= 0 and n.x < gen.width and n.y < gen.height:
		explored[n.y * gen.width + n.x] = 1


# ------------------------------------------------------------------ CONSULTAS

func _rebuild_buckets() -> void:
	var f := Engine.get_physics_frames()
	if f == _bucket_frame:
		return
	_bucket_frame = f
	_buckets.clear()
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		var k: Vector2i = Vector2i(floori(e.global_position.x / BUCKET), floori(e.global_position.y / BUCKET))
		if _buckets.has(k):
			_buckets[k].append(e)
		else:
			_buckets[k] = [e]


func enemies_near(p: Vector2, r: float) -> Array[Enemy]:
	_rebuild_buckets()
	var out: Array[Enemy] = []
	var r2 := r * r
	var a: Vector2i = Vector2i(floori((p.x - r) / BUCKET), floori((p.y - r) / BUCKET))
	var b: Vector2i = Vector2i(floori((p.x + r) / BUCKET), floori((p.y + r) / BUCKET))
	for x in range(a.x, b.x + 1):
		for y in range(a.y, b.y + 1):
			var list: Variant = _buckets.get(Vector2i(x, y))
			if list == null:
				continue
			for e in list:
				if is_instance_valid(e) and not e.is_dead() and e.global_position.distance_squared_to(p) <= r2:
					out.append(e)
	return out


func minions_near(p: Vector2, r: float) -> Array[Minion]:
	var f := Engine.get_physics_frames()
	if f != _minion_frame:
		_minion_frame = f
		_minion_list.assign(get_tree().get_nodes_in_group("minions"))
	var out: Array[Minion] = []
	var r2 := r * r
	for m in _minion_list:
		if is_instance_valid(m) and not m.is_dead() and m.global_position.distance_squared_to(p) <= r2:
			out.append(m)
	return out


func get_enemy_at(mouse: Vector2) -> Enemy:
	var best: Enemy
	var best_d := INF
	for e in enemies_near(mouse, 48.0):
		var d := e.hit_center().distance_to(mouse)
		if d < e.body_radius() + 5.0 and d < best_d:
			best = e
			best_d = d
	return best


func get_interactable_at(mouse: Vector2) -> Node2D:
	for n in get_tree().get_nodes_in_group("interactables"):
		if n.hover_check(mouse):
			return n
	return null


func add_slow_zone(pos: Vector2, radius: float, amount: float, time: float) -> void:
	slow_zones.append({"pos": pos, "radius": radius, "amount": amount, "time": time})


## Piso em chamas (afixo ARDENTE, 3.2): dps de queimadura dentro do raio
func add_fire_zone(pos: Vector2, radius: float, dps: float, time: float) -> void:
	fire_zones.append({"pos": pos, "radius": radius, "dps": dps, "time": time})
	Fx.explosion(fx_layer, pos, Color(1.0, 0.45, 0.15), radius * 0.8)


## Multiplicador de tempo local (Dobra Temporal do Mago)
func time_scale_at(p: Vector2) -> float:
	var s := 1.0
	for z in slow_zones:
		if p.distance_to(z.pos) <= z.radius:
			s = minf(s, 1.0 - z.amount)
	return s


func shake(amount: float) -> void:
	if float(Game.settings.shake_intensity) > 0.0:
		_shake = maxf(_shake, amount)


func item_level() -> int:
	return maxi(1, level() * 2 - 1 + randi_range(0, 1))


func gold_amount() -> int:
	return int(randi_range(3, 9) * (1.0 + level() * 0.6) * (1.0 + Game.hero.gold_find()))


func loot_bonus() -> float:
	return Game.hero.difficulty_data().loot


func roll_loot_item(magic: float) -> Item:
	return DB.roll_item(item_level(), magic + loot_bonus(), Game.hero.cls)


# ------------------------------------------------------------------ SPAWN

func _spawn_content() -> void:
	var pool: Array[EnemyData] = []
	for e in DB.enemies:
		if e.min_depth <= level() and e.spawn_weight > 0 and "dungeon" in e.habitats:
			pool.append(e)
	# Portal de saída para o mundo aberto
	Interactable.create(self, Interactable.Kind.DUNGEON_EXIT, cell_to_world(gen.start_room.get_center()) + Vector2(0, -20))
	var is_boss_level := Game.depth % 3 == 0
	var density: float = Game.settings.monster_density

	for room in gen.rooms:
		if room == gen.start_room:
			continue
		var packs := int(round((1 + int(randf() < 0.5) + level() / 3) * density))
		if room == gen.end_room and is_boss_level:
			packs = 0
		for p in packs:
			var data := _weighted_pick(pool)
			var count := randi_range(3, 5) if data.behavior != EnemyData.Behavior.SWARM else randi_range(5, 8)
			var center := gen.random_floor_in(room, 2)
			var pack_rarity := Enemy.roll_rarity(level(), Game.hero.difficulty_data().loot if Game.hero else 0.0)
			for i in count:
				var c := center + Vector2i(randi_range(-2, 2), randi_range(-2, 2))
				if not gen.is_floor(c):
					c = center
				spawn_enemy(data, cell_to_world(c) + Vector2(randf_range(-4, 4), randf_range(-4, 4)), pack_rarity if i == 0 else Enemy.Rarity.COMUM)

	var end_pos := cell_to_world(gen.end_room.get_center())
	stairs = Interactable.create(self, Interactable.Kind.STAIRS, end_pos)
	if is_boss_level:
		var bosses := DB.bosses()
		var b: EnemyData = bosses[(Game.depth / 3 - 1) % bosses.size()]
		boss = spawn_enemy(b, end_pos + Vector2(0, -24), Enemy.Rarity.CHEFE)
		stairs.locked = true

	var rooms_copy := gen.rooms.duplicate()
	rooms_copy.erase(gen.start_room)
	rooms_copy.shuffle()
	var chests := randi_range(2, 4)
	for i in mini(chests, rooms_copy.size()):
		Interactable.create(self, Interactable.Kind.CHEST, cell_to_world(gen.random_floor_in(rooms_copy[i], 1)))
	if randf() < 0.75 and rooms_copy.size() > chests:
		Interactable.create(self, Interactable.Kind.SHRINE, cell_to_world(gen.random_floor_in(rooms_copy[chests], 2)))
	# Armadilhas de espinhos e decoração
	for i in randi_range(2, 4) + level() / 2:
		var room: Rect2i = rooms_copy.pick_random()
		Interactable.create(self, Interactable.Kind.SPIKES, cell_to_world(gen.random_floor_in(room, 1)))
	for i in randi_range(6, 12):
		var room: Rect2i = gen.rooms.pick_random()
		var s := Sprite2D.new()
		s.texture = DB.dt2_texture(["skull", "skull", "floor_ladder", "hole"].pick_random())
		s.position = cell_to_world(gen.random_floor_in(room, 1))
		decals.add_child(s)


func _weighted_pick(pool: Array[EnemyData]) -> EnemyData:
	var total := 0.0
	for e in pool:
		total += e.spawn_weight
	var r := randf() * total
	for e in pool:
		r -= e.spawn_weight
		if r <= 0.0:
			return e
	return pool[0]


func spawn_enemy(data: EnemyData, pos: Vector2, rarity: int, lvl := -1, p_affixes: Array = []) -> Enemy:
	var e: Enemy = ENEMY_SCENE.instantiate()
	# 3.2: afixos explícitos (determinismo do chunk) ou rolagem pela raridade;
	# Inferno dá +1 afixo a Elite+ (REGRAS #7)
	var aff: Array[int] = []
	aff.assign(p_affixes)
	if aff.is_empty():
		var hell: bool = Game.hero != null and Game.hero.difficulty_data().loot >= 0.28
		aff = Enemy.affixes_for(rarity, null, hell)
	e.setup(data, self, lvl if lvl > 0 else level(), rarity, aff)
	e.position = pos
	entities.add_child(e)
	e.killed.connect(_on_enemy_killed)
	# 3.4: Lendário anuncia o spawn - sting + aviso na HUD (REGRAS #6)
	if rarity == Enemy.Rarity.LENDARIO:
		Sfx.play(&"levelup", -8.0)
		if hud:
			hud.show_message("✦ %s surge nas redondezas..." % e.display_name,
				Enemy.RARITY_COLORS[Enemy.Rarity.LENDARIO], 4.0)
	# 7.5: sting adaptativo (MECANICAS #15.2) - Campeão avisa, Lendário assombra
	Audio.sting(rarity)
	return e


func _on_enemy_killed(e: Enemy) -> void:
	var hero := Game.hero
	hero.kills += 1
	hero.add_xp(e.xp)
	Game.quest_log.notify_kill(e.data.id)  # Fase 4: objetivos KILL
	var pos := e.global_position
	if hero.cls.gain_on_kill > 0 and player and pos.distance_to(player.global_position) < 220.0:
		player.gain_resource(hero.cls.gain_on_kill)
	# 3.3: LootTableData por raridade (REGRAS #6); HP/XP do chefe já vêm tuned
	# no EnemyData - a tabela carrega só os drops/ouro
	var t: LootTableData = DB.loot_tables[e.rarity]
	if randf() < t.gold_chance:
		LootDrop.drop_gold(self, pos, gold_amount() * t.gold_mult)
	if randf() < t.globe_chance:
		LootDrop.drop_globe(self, pos)
	# Itens garantidos (>= raridade de cada entrada)
	for r in t.guaranteed:
		LootDrop.drop_item(self, pos, DB.roll_item_of(item_level(), r, hero.cls))
	# Lendário extra (Campeão: 20%)
	if randf() < t.legend_chance:
		LootDrop.drop_item(self, pos, DB.roll_item_of(item_level(), Item.Rarity.LEGENDARY, hero.cls))
	# Item de roll aleatório
	if randf() < t.item_chance:
		LootDrop.drop_item(self, pos, roll_loot_item(t.item_magic))
	# Item único: por inimigo (EnemyData.unique_drop) ou chance da tabela (chefe)
	if e.data.unique_drop != &"":
		LootDrop.drop_item(self, pos, DB.create_item(e.data.unique_drop, item_level() + 2, Item.Rarity.LEGENDARY))
	elif randf() < t.unique_chance:
		LootDrop.drop_item(self, pos, DB.roll_item_of(item_level() + 2, Item.Rarity.LEGENDARY, hero.cls))
	# Essência: moeda rara, só Campeão/Lendário/Chefe (REGRAS #9)
	if t.essence_chance > 0.0 and randf() < t.essence_chance:
		LootDrop.drop_essence(self, pos, t.essence_amount)
	# 3.4: kill de Lendário anunciado na HUD (chefe já tem mensagem própria)
	if e.rarity == Enemy.Rarity.LENDARIO:
		hud.show_message("%s foi derrotado! Espólios lendários aguardam." % e.display_name,
			Enemy.RARITY_COLORS[Enemy.Rarity.LENDARIO], 3.5)
	if e.is_boss():
		hud.show_message("%s foi derrotado!" % e.display_name, Color(1, 0.6, 0.2), 3.0)
		if stairs and stairs.locked:
			stairs.locked = false
			hud.show_message("A passagem para as profundezas está aberta.", UIKit.GOLD, 3.0)
		shake(8.0)


func time_label() -> String:
	return ""


func _on_player_died() -> void:
	if Game.hero.hardcore:
		Game.delete_save()
	hud.show_death_screen()


func respawn_player() -> void:
	var lost := int(Game.hero.gold * Game.hero.difficulty_data().death_gold_loss)
	Game.hero.gold -= lost
	Game.hero.gold_changed.emit(Game.hero.gold)
	player.global_position = respawn_position()
	player.revive()
	if lost > 0:
		hud.show_message("Você perdeu %d de ouro." % lost, Color(1, 0.5, 0.4))


func _exit_tree() -> void:
	"""Desconectar signals para evitar memory leak"""
	if player and player.died.is_connected(_on_player_died):
		player.died.disconnect(_on_player_died)
	if Game.quality_changed.is_connected(_apply_glow):
		Game.quality_changed.disconnect(_apply_glow)
