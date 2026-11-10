class_name Overworld
extends World
## Mundo aberto procedural e infinito, gerado em chunks (estilo Minecraft).
## Os chunks são criados ao redor do jogador e descartados quando ficam longe.
## Quanto mais longe do acampamento inicial, mais perigosa a região.

const CHUNK := OverworldGen.CHUNK
const LOAD_RADIUS := 1        ## chunks carregados ao redor do jogador (3x3)
const UNLOAD_RADIUS := 2
const DAY_LENGTH := 360.0     ## segundos por dia completo
const SHEET := preload("res://assets/sprites/overworld/roguelike_sheet.png")
const DUNGEON_NAMES := ["Cripta Esquecida", "Catacumbas de Varn", "Mina Abandonada", "Covil das Sombras", "Santuário Profanado",
	"Ruínas de Ashkar", "Caverna dos Ecos", "Masmorra de Kinfire", "Tumba do Rei Cinzento", "Fosso das Almas", "Gruta Rubra", "Cofre dos Anões"]

@onready var props: TileMapLayer = $Entities/Props

var og: OverworldGen
var territories: Territories
var chunks: Dictionary = {}              ## Vector2i -> {"solid": PackedByteArray, "biome": PackedByteArray, "nodes": Array}
var explored_cells: Dictionary = {}      ## Vector2i (chunk) -> PackedByteArray
var _queue: Array[Vector2i] = []
var _astar_dirty := true
var _astar_timer := 0.0
var _player_chunk: Vector2i = Vector2i(999999, 999999)
## Ultimo território racial em que o jogador esteve (objetivos REACH, Fase 4)
var _last_region := &""
var _tiles: Dictionary = {}              ## "x,y,mod" -> [coords, alt]
var _src: TileSetAtlasSource
var _ground_src: TileSetAtlasSource
var _time := 0.3
var _last_day := -1
var _last_hour := -1
## Fase 7.2: lanterna do herói - acende no crepúsculo, sempre com sombra (#14.2)
var _lantern: PointLight2D
## 7.3: timer da atualização de atmosfera por bioma
var _atmos_timer := 0.0
## 7.6: camada de clima (partículas, névoa, chuva/relâmpago)
var weather: WeatherLayer
## O Cinzento persistente do acampamento (fix da missão inicial): criado em
## _spawn_content, usado pelo diálogo de despertar e reencontrável depois.
var _cinzento: Cinzento

# 7.1: color grading por keyframes (MECANICAS #14.1) - [fração do dia, tom]
# 0.0 = meia-noite, 0.5 = meio-dia; interpolado suavemente (sem saltos)
const DAY_KEYFRAMES := [
	[0.0, Color(0.22, 0.26, 0.45)],    # 00:00 azul-profundo
	[0.23, Color(0.35, 0.38, 0.50)],  # 05:30 madrugada cinza-azul
	[0.27, Color(0.80, 0.60, 0.40)],  # 06:30 amanhecer âmbar
	[0.5, Color(0.80, 0.78, 0.74)],   # 12:00 neutro (referência)
	[0.73, Color(0.90, 0.68, 0.40)],  # 17:30 dourado de fim de tarde
	[0.79, Color(0.58, 0.47, 0.58)],  # 19:00 crepúsculo lilás
	[0.875, Color(0.26, 0.29, 0.48)], # 21:00 noite
	[1.0, Color(0.22, 0.26, 0.45)],  # 24:00 = 00:00 (fecha o ciclo)
]

## Fase 7.3 (MECANICAS #14.3): vinheta + temperatura por bioma -
## Tundra fria-azul, Areias quente, Pântano esverdeado, Terras Corrompidas
## dessaturadas com vinheta roxa (LORE #16: "luz sem laço" desbota o mundo)
const BIOME_ATMOS := {
	&"planicie": {"tint": Color(1.0, 0.98, 0.94), "amount": 0.06, "desat": 0.0, "vig": 0.22},
	&"floresta": {"tint": Color(0.94, 1.0, 0.92), "amount": 0.10, "desat": 0.0, "vig": 0.26},
	&"deserto": {"tint": Color(1.0, 0.92, 0.78), "amount": 0.14, "desat": 0.0, "vig": 0.24},
	&"tundra": {"tint": Color(0.82, 0.90, 1.0), "amount": 0.16, "desat": 0.0, "vig": 0.28},
	&"pantano": {"tint": Color(0.88, 1.0, 0.85), "amount": 0.14, "desat": 0.05, "vig": 0.3},
	&"vulcanico": {"tint": Color(1.0, 0.85, 0.75), "amount": 0.16, "desat": 0.05, "vig": 0.3},
	&"corrompido": {"tint": Color(0.9, 0.85, 1.0), "amount": 0.14, "desat": 0.28, "vig": 0.34,
		"vig_color": Color(0.06, 0.0, 0.1)},
}


func _setup_map() -> void:
	og = OverworldGen.new(Game.world_seed)
	# 2.4: Voronoi determinístico por (semente + raça do jogador) - não é salvo.
	# A capital da raça do jogador é o acampamento promovido (LORE #X).
	territories = Territories.new(Game.world_seed, Game.hero.race.id if Game.hero else &"humano")
	_time = Game.world_time
	# 7.4: o vento é coerente com a semente do mundo e sabe o bioma (#14.5)
	WindField.world_seed = Game.world_seed
	# Provider como método vinculado (NÃO lambda): uma closure GDScript guardada
	# numa static var de classe global é liberada em dupla no teardown do engine
	# (heap corruption). Callable(object, método) não tem esse problema.
	WindField.set_provider(Callable(self, "_biome_at"))
	# 7.6: clima - partículas por bioma, névoa, chuva determinística (#14.4)
	Weather.world_seed = Game.world_seed
	weather = WeatherLayer.new()
	add_child(weather)
	_build_tileset()
	var start := world_to_cell(_start_position())
	var sc := _chunk_of(start)
	for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			_generate_chunk(sc + Vector2i(dx, dy))
	_player_chunk = sc
	_rebuild_astar()


## Bioma sob a posição do mundo - consultado pelo WindField (#14.5)
func _biome_at(p: Vector2) -> StringName:
	return og.biome_at(world_to_cell(p))


func _start_position() -> Vector2:
	if Game.overworld_pos != Vector2.INF:
		return Game.overworld_pos
	return Vector2(TILE * 0.5, TILE * 2.5)


func respawn_position() -> Vector2:
	return Game.respawn_pos if Game.respawn_pos != Vector2.INF else Vector2(TILE * 0.5, TILE * 2.5)


func _intro() -> void:
	# 7.5: música base do mundo aberto vem do Audio adaptativo (mus_overworld)
	var diff: Dictionary = Game.hero.difficulty_data()
	hud.show_message("Mundo de Kinfire", UIKit.GOLD, 3.0)
	hud.show_message("Dificuldade: %s%s" % [diff.name, "  -  HARDCORE" if Game.hero.hardcore else ""], diff.color, 3.0)
	if Game.awakened_from_prologue:
		Game.awakened_from_prologue = false
		_awakening()
	elif Game.overworld_pos == Vector2.INF:
		hud.show_message("Explore o mundo. Quanto mais longe do acampamento, mais perigoso.", Color(0.8, 0.8, 0.8), 5.0)


## Despertar no acampamento após o prólogo: o Cinzento entrega as primeiras
## palavras do mundo real (REGRAS #13, LORE #8-9). Ele é o node persistente
## criado em _spawn_content - não se despede: quem fechar o diálogo antes
## da escolha "(Partir)" pode reencontrá-lo perto da fogueira (fix da
## missão inicial - a flag cinzento_primeiro_dialogo volta a ser alcançável).
func _awakening() -> void:
	if _cinzento == null:
		return
	hud.show_message("Você acorda com cheiro de brasa e chuva antiga. Não é sonho desta vez.", UIKit.TEXT_DIM, 4.0)
	# A sombra termina de chegar antes de o diálogo pausar o mundo (2.2)
	var t := get_tree().create_timer(0.9, true, false, true)
	t.timeout.connect(func():
		hud.open_dialogue(DB.dialogue(&"cinzento_acampamento"), "Cinzento")
	)


func _spawn_content() -> void:
	# Acampamento inicial = capital da raça do jogador, promovida (2.4, MECANICAS #3).
	# O rótulo usa o nome da capital do território (LORE #X): "Porto Franco"...
	var terr: TerritoryData = DB.territory(Game.hero.race.id) if Game.hero else null
	var capital := terr.capital_name if terr != null else "Acampamento"
	var fire := Interactable.create(self, Interactable.Kind.CAMPFIRE, Vector2(TILE * 0.5, TILE * 0.5))
	fire.label = capital
	_register_waypoint(capital, fire.global_position)
	if Game.respawn_pos == Vector2.INF:
		Game.respawn_pos = fire.global_position + Vector2(0, 24)
	Interactable.create(self, Interactable.Kind.MERCHANT, Vector2(TILE * 4.5, TILE * -1.5))
	for t in [Vector2i(-5, -4), Vector2i(3, -5), Vector2i(-2, 4)]:
		_place_tent(t)
	# NPCs conversáveis (tarefa 2.3): Marn vigia o círculo da fogueira,
	# Bree cozinha perto da tenda oeste
	Npc.create(self, DB.npc(&"marn_vigia"), fire.global_position + Vector2(34, 8))
	Npc.create(self, DB.npc(&"bree_cozinheira"), fire.global_position + Vector2(-38, 16))
	# O Cinzento permanece no acampamento, à esquerda da fogueira: quem
	# fechar o diálogo de despertar antes da despedida (ou chegar ao estágio
	# "volte ao Cinzento" de ato1_1) o reencontra aqui - a sombra que guia
	# não se vai enquanto o Laço-Vivo precisar de rumo (LORE #8).
	_cinzento = Cinzento.new()
	_cinzento.world = self
	_cinzento.interactive = true
	entities.add_child(_cinzento)
	_cinzento.appear_at(fire.global_position + Vector2(0, -34))
	# 2.5: líder racial + gente comum da capital do jogador (persistentes,
	# como Marn/Bree - o acampamento não descarrega)
	TerritoryNpcs.populate(self, Game.hero.race.id, fire.global_position)


func _place_tent(c: Vector2i) -> void:
	var tent: Array = [[Vector2i(46, 10), Vector2i(47, 10)], [Vector2i(46, 11), Vector2i(47, 11)]]
	for y in 2:
		for x in 2:
			var cc := c + Vector2i(x, y)
			props.set_cell(cc, 0, tent[y][x], _alt(tent[y][x], Color.WHITE, y == 1, y == 0))
			if y == 1:
				_set_solid(cc, true)


# ------------------------------------------------------------------ CONSULTAS DO MUNDO

func level() -> int:
	return level_at(player.global_position) if player else 1


## Nível da região: distância do Vale do Centro + modificador do território (REGRAS #11)
func level_at(p: Vector2) -> int:
	if territories != null:
		return territories.region_level(world_to_cell(p))
	var d := OverworldGen.danger(world_to_cell(p))
	return clampi(1 + int(d * 0.9), 1, 60)


func biome_at_pos(p: Vector2) -> String:
	return og.biome_at(world_to_cell(p))


## Nome da região para a HUD: capital > Vale do Centro > território racial (2.4)
func region_name() -> String:
	if player and territories != null:
		return territories.region_name_at(world_to_cell(player.global_position))
	var b: String = biome_at_pos(player.global_position) if player else "planicie"
	if Vector2(world_to_cell(player.global_position)).length() < OverworldGen.SAFE_RADIUS:
		return "Acampamento (área segura)"
	return "%s - Nível %d" % [OverworldGen.BIOMES[b].name, level()]


func time_label() -> String:
	var hours := fmod(_time, 1.0) * 24.0
	return "Dia %d - %02d:%02d" % [int(_time) + 1, int(hours), int(fmod(hours, 1.0) * 60)]


func is_floor(c: Vector2i) -> bool:
	var ch: Variant = chunks.get(_chunk_of(c))
	if ch == null:
		return false
	return ch.solid[_local_index(c)] == 0


func is_explored(c: Vector2i) -> bool:
	var e: Variant = explored_cells.get(_chunk_of(c))
	return e != null and e[_local_index(c)] == 1


func _set_explored(c: Vector2i) -> void:
	var k := _chunk_of(c)
	if not explored_cells.has(k):
		var arr := PackedByteArray()
		arr.resize(CHUNK * CHUNK)
		explored_cells[k] = arr
	explored_cells[k][_local_index(c)] = 1


func minimap_color(c: Vector2i) -> Color:
	if not is_explored(c):
		return Color(0, 0, 0, 0)
	var ch: Variant = chunks.get(_chunk_of(c))
	var b: String
	var wet := false
	if ch != null:
		b = OverworldGen.BIOME_IDS[ch.biome[_local_index(c)]]
		wet = ch.liquid[_local_index(c)] == 1
	else:
		b = og.biome_at(c)
		wet = og.liquid_at(c, b)
	if wet:
		return Color(0.95, 0.4, 0.1) if b == "vulcanico" else Color(0.25, 0.5, 0.85)
	var col: Color = OverworldGen.BIOMES[b].map
	if ch != null and ch.solid[_local_index(c)] == 1:
		col = col.darkened(0.35)
	return col


func points_of_interest() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("interactables"):
		if n is Interactable and is_explored(world_to_cell(n.global_position)):
			match n.kind:
				Interactable.Kind.DUNGEON_ENTRANCE: out.append({"pos": n.global_position, "color": Color(0.75, 0.4, 1.0)})
				Interactable.Kind.CAMPFIRE: out.append({"pos": n.global_position, "color": Color(1, 0.6, 0.2)})
				Interactable.Kind.MERCHANT: out.append({"pos": n.global_position, "color": Color(1, 0.9, 0.4)})
	return out


func _apply_brightness() -> void:
	_update_daylight()


func _update_daylight() -> void:
	var b: float = Game.settings.brightness
	var h := fmod(_time, 1.0)
	var day := clampf(0.5 - 0.5 * cos(h * TAU), 0.0, 1.0)
	var c := _day_color(h)
	canvas_modulate.color = Color(c.r * b, c.g * b, c.b * b, 1.0)
	if player:
		player.light.energy = lerpf(1.6, 0.12, day)
		# 7.2: lanterna do herói - acende sozinha no crepúsculo (#14.2),
		# quente e curta (~90px), única luz que sempre projeta sombra;
		# sem tremulação: a energia segue o ciclo do dia (_update_daylight)
		if _lantern == null:
			_lantern = Fx.make_light(Color(1.0, 0.78, 0.45), 0.7, 0.0,
				LightFx.Flicker.NONE, true)
			player.add_child(_lantern)
			_lantern.position = Vector2(0, -4)
		# crepúsculo: 0.3 (dia pleno) -> 0.0 (noite): suaviza o acender
		_lantern.energy = lerpf(1.1, 0.0, clampf(day / 0.3, 0.0, 1.0))


## 7.3: aplica o preset de vinheta/temperatura do bioma sob os pés do
## herói (MECANICAS #14.3) - chamado pelo _process a cada 0.5s
func _update_atmos() -> void:
	if player == null:
		return
	var biome: StringName = og.biome_at(world_to_cell(player.global_position))
	_apply_atmos(BIOME_ATMOS.get(biome, {}))
	# 7.6: clima por bioma (#14.4) - chuva determinística semente+dia
	if weather != null:
		weather.configure(biome, _is_night(), Weather.rain_on(int(_time)), self)


## 7.1: tom do mundo interpolado entre keyframes do dia (#14.1)
func _day_color(h: float) -> Color:
	for i in DAY_KEYFRAMES.size() - 1:
		var a: float = DAY_KEYFRAMES[i][0]
		var b: float = DAY_KEYFRAMES[i + 1][0]
		if h >= a and h <= b:
			var t := (h - a) / maxf(b - a, 0.0001)
			return (DAY_KEYFRAMES[i][1] as Color).lerp(DAY_KEYFRAMES[i + 1][1], t)
	return DAY_KEYFRAMES[0][1]


# ------------------------------------------------------------------ LOOP / STREAMING

func _process(delta: float) -> void:
	super._process(delta)
	_time += delta / DAY_LENGTH
	Game.world_time = _time
	# 7.1: eventos por hora (MECANICAS #14.1) - signal na virada da hora
	var hour := int(fmod(_time, 1.0) * 24.0)
	if hour != _last_hour:
		if _last_hour >= 0:
			Game.hour_changed.emit(hour)
			if hour == 0:
				# "A Vela Virou": autosave na meia-noite
				Game.save_game()
				hud.show_message("A vela virou - o dia %d começa." % (int(_time) + 1),
					Color(0.55, 0.68, 1.0), 3.0)
		_last_hour = hour
	_update_daylight()
	# 7.3: vinheta/temperatura do bioma sob os pés do herói (#14.3)
	_atmos_timer -= delta
	if _atmos_timer <= 0.0:
		_atmos_timer = 0.5
		_update_atmos()
	# Fase 5.2: virada do dia às 06:00 - vendors re-estocam e a demanda
	# recupera 5% rumo ao nível natural (REGRAS #10/#14)
	var mday := Market.market_day()
	if mday != _last_day:
		if _last_day >= 0:
			Market.new_day()
		_last_day = mday
	if player == null:
		return
	# Fase 4: mudança de território alimenta objetivos REACH das quests
	if territories != null:
		var reg: StringName = territories.territory_at(world_to_cell(player.global_position))
		if reg != _last_region:
			_last_region = reg
			if reg != &"":
				Game.quest_log.notify_reach(reg)
	var pc := _chunk_of(world_to_cell(player.global_position))
	if pc != _player_chunk:
		_player_chunk = pc
		for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
				var k := pc + Vector2i(dx, dy)
				if not chunks.has(k) and not _queue.has(k):
					_queue.append(k)
		for k in chunks.keys():
			if maxi(absi(k.x - pc.x), absi(k.y - pc.y)) > UNLOAD_RADIUS:
				_unload_chunk(k)
	# Gera no máximo um chunk por frame (evita travadas)
	if not _queue.is_empty():
		_generate_chunk(_queue.pop_front())
	_astar_timer -= delta
	if _astar_dirty and _astar_timer <= 0.0 and _queue.is_empty():
		_rebuild_astar()


func _chunk_of(c: Vector2i) -> Vector2i:
	return Vector2i(floori(c.x / float(CHUNK)), floori(c.y / float(CHUNK)))


func _local_index(c: Vector2i) -> int:
	var lx := posmod(c.x, CHUNK)
	var ly := posmod(c.y, CHUNK)
	return ly * CHUNK + lx


func _set_solid(c: Vector2i, v: bool) -> void:
	var ch: Variant = chunks.get(_chunk_of(c))
	if ch != null:
		ch.solid[_local_index(c)] = 1 if v else 0
		_astar_dirty = true


# ------------------------------------------------------------------ TILESET

func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	# 7.2: camada de oclusão - árvores, rochas e muros de capital projetam
	# sombras reais nas luzes com shadow_enabled (MECANICAS #14.2)
	ts.add_occlusion_layer()
	_src = TileSetAtlasSource.new()
	_src.texture = SHEET
	_src.texture_region_size = Vector2i(TILE, TILE)
	_src.separation = Vector2i(1, 1)
	ts.add_source(_src, 0)
	floor_layer.tile_set = ts
	wall_layer.tile_set = ts
	props.tile_set = ts


## Retorna o id da tile alternativa para (coords, tonalidade, sólida, topo de árvore)
func _alt(coords: Vector2i, mod: Color, solid: bool, is_top := false) -> int:
	var key := "%d,%d,%s,%s,%s" % [coords.x, coords.y, mod.to_html(), solid, is_top]
	if _tiles.has(key):
		return _tiles[key]
	if not _src.has_tile(coords):
		_src.create_tile(coords)
	var alt := _src.create_alternative_tile(coords)
	var td := _src.get_tile_data(coords, alt)
	if td == null:
		# tile fora do atlas: usa a tile padrao (-1) em vez de quebrar
		_tiles[key] = -1
		return -1
	td.modulate = mod
	if solid:
		td.add_collision_polygon(0)
		var r := 6.0 if not is_top else 8.0
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]))
		# 7.2: oclusor de sombra do sólido (copas de árvore não bloqueiam
		# a luz - só troncos/rochas/muros, daí o recorte menor sem is_top)
		var occ := OccluderPolygon2D.new()
		occ.polygon = PackedVector2Array([Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)])
		td.set_occluder(0, occ)
	if is_top:
		# A copa da árvore ordena junto com o tronco (célula de baixo)
		td.y_sort_origin = TILE
	_tiles[key] = alt
	return alt


# ------------------------------------------------------------------ GERACAO DE CHUNK

func _generate_chunk(k: Vector2i) -> void:
	if chunks.has(k):
		return
	var solid := PackedByteArray()
	solid.resize(CHUNK * CHUNK)
	var biomes := PackedByteArray()
	biomes.resize(CHUNK * CHUNK)
	var liquid := PackedByteArray()
	liquid.resize(CHUNK * CHUNK)
	var data: Dictionary = {"solid": solid, "biome": biomes, "liquid": liquid, "nodes": []}
	chunks[k] = data
	var origin := k * CHUNK
	for ly in CHUNK:
		for lx in CHUNK:
			var c := origin + Vector2i(lx, ly)
			var i := ly * CHUNK + lx
			var b := og.biome_at(c)
			biomes[i] = OverworldGen.BIOME_IDS.find(b)
			var info: Dictionary = OverworldGen.BIOMES[b]
			if og.liquid_at(c, b):
				solid[i] = 1
				liquid[i] = 1
				_paint_liquid(c, b)
				continue
			# Clareira de terra batida no acampamento
			if Vector2(c).length() < 6.0:
				floor_layer.set_cell(c, 0, Vector2i(6, 0), _alt(Vector2i(6, 0), Color(0.78, 0.68, 0.6), false))
				continue
			var g := og.ground_variant(c, b)
			floor_layer.set_cell(c, 0, g, _alt(g, info.mod, false))
			var p := og.prop_at(c, b)
			if p != "":
				var pd: Dictionary = OverworldGen.PROPS[p]
				props.set_cell(c, 0, pd.base, _alt(pd.base, Color.WHITE, pd.solid))
				if pd.has("top"):
					props.set_cell(c + Vector2i.UP, 0, pd.top, _alt(pd.top, Color.WHITE, false, true))
				if pd.solid:
					solid[i] = 1
	_spawn_chunk_content(k, data)
	_astar_dirty = true
	_astar_timer = 0.3


func _paint_liquid(c: Vector2i, b: String) -> void:
	if b == "vulcanico":
		floor_layer.set_cell(c, 0, Vector2i(11, 14), _alt(Vector2i(11, 14), Color(1.0, 0.7, 0.5), true))
		return
	var mod := Color.WHITE
	match b:
		"pantano": mod = Color(0.55, 0.75, 0.5)
		"tundra": mod = Color(0.8, 0.95, 1.0)
		"corrompido": mod = Color(0.6, 0.45, 0.75)
	# Bordas de grama na margem (3x3 do lago da folha)
	var up := og.liquid_at(c + Vector2i.UP, og.biome_at(c + Vector2i.UP))
	var down := og.liquid_at(c + Vector2i.DOWN, og.biome_at(c + Vector2i.DOWN))
	var left := og.liquid_at(c + Vector2i.LEFT, og.biome_at(c + Vector2i.LEFT))
	var right := og.liquid_at(c + Vector2i.RIGHT, og.biome_at(c + Vector2i.RIGHT))
	var tx := 3
	var ty := 1
	if b in ["planicie", "floresta", "pantano"]:
		tx = 2 if not left else (4 if not right else 3)
		ty = 0 if not up else (2 if not down else 1)
	var coords: Vector2i = Vector2i(tx, ty) if (b in ["planicie", "floresta", "pantano"]) else Vector2i(0, 0)
	floor_layer.set_cell(c, 0, coords, _alt(coords, mod, true))
	# Vitórias-régias no pântano
	if b == "pantano" and og.rand01(c, 11) < 0.05 and up and down and left and right:
		props.set_cell(c, 0, Vector2i(28, 10), _alt(Vector2i(28, 10), Color.WHITE, false))


func _unload_chunk(k: Vector2i) -> void:
	var data: Dictionary = chunks[k]
	var origin := k * CHUNK
	for ly in CHUNK:
		for lx in CHUNK:
			var c := origin + Vector2i(lx, ly)
			floor_layer.erase_cell(c)
			props.erase_cell(c)
	# Copas de árvores da primeira linha ficam na linha do chunk de cima
	for lx in CHUNK:
		var c := origin + Vector2i(lx, 0)
		var p := og.prop_at(c, og.biome_at(c))
		if p != "" and OverworldGen.PROPS[p].has("top"):
			props.erase_cell(c + Vector2i.UP)
	for n in data.nodes:
		if is_instance_valid(n):
			# Não remove inimigos que estão perseguindo o jogador
			if n is Enemy and (n.state != Enemy.State.IDLE and not n.is_dead()):
				continue
			n.queue_free()
	chunks.erase(k)
	_astar_dirty = true


func _rebuild_astar() -> void:
	_astar_dirty = false
	_astar_timer = 0.5
	if chunks.is_empty():
		return
	var mn: Vector2i = Vector2i(999999, 999999)
	var mx: Vector2i = Vector2i(-999999, -999999)
	for k in chunks:
		mn = Vector2i(mini(mn.x, k.x), mini(mn.y, k.y))
		mx = Vector2i(maxi(mx.x, k.x), maxi(mx.y, k.y))
	astar.region = Rect2i(mn * CHUNK, (mx - mn + Vector2i.ONE) * CHUNK)
	astar.cell_size = Vector2(TILE, TILE)
	astar.offset = Vector2(TILE * 0.5, TILE * 0.5)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	astar.fill_solid_region(astar.region, true)
	for k in chunks:
		var solid: PackedByteArray = chunks[k].solid
		var origin: Vector2i = k * CHUNK
		for i in CHUNK * CHUNK:
			if solid[i] == 0:
				astar.set_point_solid(origin + Vector2i(i % CHUNK, i / CHUNK), false)


# ------------------------------------------------------------------ CONTEUDO DO CHUNK

func _spawn_chunk_content(k: Vector2i, data: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(k.x, k.y, Game.world_seed))
	var center_cell := k * CHUNK + Vector2i(CHUNK / 2, CHUNK / 2)
	var lvl := territories.region_level(center_cell) if territories != null else clampi(1 + int(OverworldGen.danger(center_cell) * 0.9), 1, 60)
	# 2.5: alguma capital racial fica neste chunk?
	var capital_race: StringName = &""
	if territories != null:
		for race in territories.capitals:
			var cap_cell: Vector2i = Vector2i(roundi(territories.capitals[race].x), roundi(territories.capitals[race].y))
			if _chunk_of(cap_cell) == k:
				capital_race = race
				break
	# Seguro: acampamento/capital do jogador OU chunk de capital OU perímetro de qualquer capital (2.4)
	var safe: bool = Vector2(center_cell).length() < OverworldGen.SAFE_RADIUS + 20 \
		or capital_race != &"" \
		or (territories != null and territories.near_any_capital(center_cell))
	var nodes: Array = data.nodes

	# Entrada de masmorra (garantida no chunk (1,0) para o jogador achar logo)
	if k == Vector2i(1, 0) or (not safe and rng.randf() < 0.14):
		var p := _random_floor(k, rng, 3)
		if p != Vector2.INF:
			var e := Interactable.create(self, Interactable.Kind.DUNGEON_ENTRANCE, p)
			e.dungeon_level = lvl
			e.label = DUNGEON_NAMES[rng.randi() % DUNGEON_NAMES.size()]
			nodes.append(e)
	# Fogueira (ponto de viagem rápida)
	if not safe and rng.randf() < 0.1:
		var p := _random_floor(k, rng, 2)
		if p != Vector2.INF:
			var f := Interactable.create(self, Interactable.Kind.CAMPFIRE, p)
			f.label = "Fogueira - %s" % OverworldGen.BIOMES[og.biome_at(world_to_cell(p))].name
			nodes.append(f)
	# 2.5: capital racial neste chunk - Fogueira Principal (waypoint) + líder
	# + gente comum. A capital do jogador já é o acampamento (em _spawn_content).
	if capital_race != &"" and Game.hero != null and capital_race != Game.hero.race.id:
		var ct: TerritoryData = DB.territory(capital_race)
		var cap_cell: Vector2i = Vector2i(roundi(territories.capitals[capital_race].x), roundi(territories.capitals[capital_race].y))
		var center := cell_to_world(cap_cell)
		var f := Interactable.create(self, Interactable.Kind.CAMPFIRE, center)
		f.label = ct.capital_name
		nodes.append(f)
		TerritoryNpcs.populate(self, capital_race, center, nodes)
	if safe:
		return
	# Baús e santuários (lembrados no save para não reaparecer)
	if rng.randf() < 0.3:
		var p := _random_floor(k, rng, 1)
		var pid := "chest:%d,%d" % [k.x, k.y]
		if p != Vector2.INF and not Game.world_opened.has(pid):
			var ch := Interactable.create(self, Interactable.Kind.CHEST, p)
			ch.persist_id = pid
			nodes.append(ch)
	if rng.randf() < 0.1:
		var p := _random_floor(k, rng, 2)
		var pid := "shrine:%d,%d" % [k.x, k.y]
		if p != Vector2.INF and not Game.world_opened.has(pid):
			var sh := Interactable.create(self, Interactable.Kind.SHRINE, p)
			sh.persist_id = pid
			nodes.append(sh)

	# Monstros por bioma
	var density: float = Game.settings.monster_density
	var packs := int(round(rng.randi_range(1, 3) * density))
	# REGRAS #6: noite (21:00-05:00) - mortos-vivos +50% peso em biomas sombrios,
	# todos os monstros +10% agressividade (raio de aggro)
	var night: bool = _is_night()
	var shadowy_biomes: Array[String] = ["corrompido", "pantano"]  # biomas sombrios
	for i in packs:
		var p := _random_floor(k, rng, 3)
		if p == Vector2.INF:
			continue
		var biome := og.biome_at(world_to_cell(p))
		var pool := _pool_for(biome, lvl)
		if pool.is_empty():
			continue
		# bônus noturno: aplica +50% no peso de spawn de mortos-vivos em biomas sombrios
		if night and shadowy_biomes.has(biome):
			for e in pool:
				if e.elemental_type == EnemyData.ElementalType.UNDEAD:
					e.spawn_weight *= 1.5
		var data_e := _weighted_pick(pool)
		# restaura o peso original (evita acumular entre chunks)
		if night and shadowy_biomes.has(biome):
			for e in pool:
				if e.elemental_type == EnemyData.ElementalType.UNDEAD:
					e.spawn_weight /= 1.5
		var count := rng.randi_range(2, 4) if data_e.behavior != EnemyData.Behavior.SWARM else rng.randi_range(4, 7)
		# 3.1: raridade do pack pelo rng do chunk (determinístico) + bônus de dificuldade
		var pack_rarity := Enemy.roll_rarity(lvl, Game.hero.difficulty_data().loot if Game.hero else 0.0, rng)
		# 3.2: afixos de Campeão pelo rng do chunk; Inferno dá +1 a Elite+ (REGRAS #7)
		var hell: bool = Game.hero != null and Game.hero.difficulty_data().loot >= 0.28
		var pack_affixes: Array[int] = Enemy.affixes_for(pack_rarity, rng, hell)
		for j in count:
			var off: Vector2 = Vector2(rng.randf_range(-24, 24), rng.randf_range(-24, 24))
			var pos := last_free_point(p, p + off)
			var en := spawn_enemy(data_e, pos, pack_rarity if j == 0 else Enemy.Rarity.COMUM, lvl, pack_affixes if j == 0 else [])
			# noite: +10% aggro (REGRAS #6)
			if night:
				en.aggro_mult *= 1.1
			nodes.append(en)
	# Chefe de mundo (raro, regiões distantes)
	if lvl >= 4 and rng.randf() < 0.025:
		var p := _random_floor(k, rng, 6)
		var biome := og.biome_at(world_to_cell(p)) if p != Vector2.INF else ""
		for e in DB.enemies:
			if e.world_boss and biome in e.habitats and p != Vector2.INF:
				var bb := spawn_enemy(e, p, Enemy.Rarity.CHEFE, lvl + 2)
				nodes.append(bb)
				# 3.4: chefe de mundo é anunciado quando surge numa região distante
				if hud:
					hud.show_message("Um terror ancestral ronda estas terras: %s" % bb.display_name,
						Color(1, 0.55, 0.1), 4.0)
				break


func _pool_for(biome: String, lvl: int) -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	for e in DB.enemies:
		if e.spawn_weight > 0 and biome in e.habitats and e.min_depth <= lvl + 1:
			out.append(e)
	return out


## Ponto de chão aleatório dentro do chunk (longe das bordas)
func _random_floor(k: Vector2i, rng: RandomNumberGenerator, margin: int) -> Vector2:
	for i in 24:
		var c := k * CHUNK + Vector2i(rng.randi_range(margin, CHUNK - 1 - margin), rng.randi_range(margin, CHUNK - 1 - margin))
		if is_floor(c) and is_floor(c + Vector2i.UP) and is_floor(c + Vector2i.LEFT) and is_floor(c + Vector2i.RIGHT):
			return cell_to_world(c)
	return Vector2.INF


func _register_waypoint(wp_name: String, pos: Vector2) -> void:
	for w in Game.waypoints:
		if Vector2(w.x, w.y).distance_to(pos) < 4.0:
			return
	Game.waypoints.append({"name": wp_name, "x": pos.x, "y": pos.y})


## Acende uma fogueira: vira ponto de renascimento e de viagem rápida
func light_campfire(f: Interactable) -> void:
	_register_waypoint(f.label, f.global_position)
	Game.respawn_pos = f.global_position + Vector2(0, 20)
	player.heal(player.max_hp)
	Game.save_game()


func _on_campfire_lit(fire: Interactable) -> void:
	light_campfire(fire)
	hud.show_message("Fogueira acesa: você renascerá aqui.", Color(1, 0.7, 0.3))
	if _is_night():
		_offer_sleep()
	else:
		hud.open_waypoints()


## 7.1: noite na fogueira = opção de dormir até o amanhecer (#14.1)
func _is_night() -> bool:
	var h := fmod(_time, 1.0) * 24.0
	return h >= 18.0 or h < 6.0


func _offer_sleep() -> void:
	var body := hud._open_popup("Fogueira acesa", 430)
	body.add_child(UIKit.rich(
		"[color=#9A917F]A noite cobre Eldara. As fogueiras afastam o frio - e o resto.[/color]"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	body.add_child(row)
	row.add_child(UIKit.button("Dormir até o amanhecer", _sleep_until_dawn, 240))
	row.add_child(UIKit.button("Viajar (fogueiras)", func(): hud.open_waypoints(), 170))


## Fast-forward com fade até as 06:00: cura, re-estoca o mercado e salva
func _sleep_until_dawn() -> void:
	hud.close_popup()
	var veil := hud._overlay(0.0)
	var bg: ColorRect = veil.get_child(0)
	Sfx.play(&"potion", -10.0)
	var tw := create_tween()
	tw.tween_property(bg, "color:a", 1.0, 0.8)
	tw.tween_callback(func():
		# 06:00 = 0.25 do dia (REGRAS #14) - o hook de virada re-estoca
		_time += fposmod(0.25 - fmod(_time, 1.0), 1.0)
		Game.world_time = _time
		player.heal(player.max_hp)
		player.resource = player.max_resource
		_update_daylight()
		Game.save_game()
		hud.show_message("Você acorda ao amanhecer - dia %d." % (int(_time) + 1),
			Color(1, 0.85, 0.5), 3.5)
	)
	tw.tween_property(bg, "color:a", 0.0, 0.9)
	tw.tween_callback(veil.queue_free)


func travel_to(pos: Vector2) -> void:
	Game.overworld_pos = pos + Vector2(0, 20)
	Game.save_game()
	Game.change_scene(Game.OVERWORLD)
