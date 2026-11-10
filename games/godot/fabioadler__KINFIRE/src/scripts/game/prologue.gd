class_name Prologue
extends World
## Prólogo: a Reminiscência de Vale Cinzento (REGRAS #13, MECANICAS #11, LORE #9).
## Vila de tutorial handcrafted: casa do jogador, clareira com fogueira,
## campo de treino com espantalho e floresta densa ao norte (além do portão de névoa).
## O Cinzento (Silhueta) guia os passos do tutorial; ao nível 1, o espelho chama.

signal tutorial_step_done(step: int)

enum TutStep { MOVE, ATTACK, COLLECT, EQUIP, POTION, CAMPFIRE, DONE }

const MAP_W := 56
const MAP_H := 44

# Layout (células) - tudo determinístico, nada de RNG
const FOREST := Rect2i(10, 3, 36, 15)       ## floresta rala ao norte
const GATE := Rect2i(25, 17, 6, 8)         ## corredor da névoa (floresta ↔ clareira)
const CLEARING := Rect2i(16, 24, 25, 17)   ## clareira central da vila
const HOUSE_RING := Rect2i(21, 33, 8, 7)   ## paredes da casa
const HOUSE := Rect2i(22, 34, 6, 5)        ## interior da casa
const DOOR := Vector2i(24, 39)             ## porta da casa (sul)
const TRAINING := Rect2i(42, 26, 12, 11)   ## campo de treino (leste)
const TRAINING_PATH := Rect2i(40, 30, 3, 2) ## passagem clareira ↔ campo

const START_CELL := Vector2i(24, 36)       ## onde o aldeão acorda (dentro da casa)
const MIRROR_CELL := Vector2i(26, 34)      ## espelho antigo (parede norte da casa)
const CAMPFIRE_CELL := Vector2i(28, 32)    ## fogueira central da vila
const SCARECROW_CELL := Vector2i(47, 31)   ## espantalho de treino
const CHEST_CELLS := [Vector2i(44, 28), Vector2i(50, 34), Vector2i(52, 27)]

# Tutorial
const MOVE_DIST := 90.0                    ## distância andada para concluir o passo 1
const GATE_ROW := 20                       ## linha do portão de névoa
const WOLF_CELLS := [Vector2i(22, 8), Vector2i(27, 15), Vector2i(31, 7)]
## Para onde o Cinzento se move em cada passo
const CINZENTO_ANCHORS := [
	Vector2i(26, 36),  ## MOVE - dentro da casa
	Vector2i(45, 30),  ## ATTACK - junto ao espantalho
	Vector2i(46, 32),  ## COLLECT - onde cai a espada
	Vector2i(44, 33),  ## EQUIP
	Vector2i(25, 34),  ## POTION - caminho até a fogueira
	Vector2i(27, 33),  ## CAMPFIRE
]
const CINZENTO_LINES := [
	"As pernas primeiro. Tudo o mais vem andando atrás.",
	"Madeira não revida. A madeira é mais honesta que a maioria do que você vai enfrentar.",
	"Ferro de verdade para mãos de verdade. Apanhe.",
	"Uma arma na mão vale mais que dez promessas no bolso. Vista-a.",
	"Você vai se machucar. Todos se machucam. Aprenda a carregar a cura.",
	"Fogo é memória que aquece as mãos. Acenda - e o sonho vai guardar você.",
]

# Fase 6.4: onboarding visual (MECANICAS #9) - seta-guia, dicas contextuais
const GUIDE_MIN_DIST := 70.0   ## seta some quando o objetivo está perto
const HINT_DELAY := 14.0       ## segundos no passo até a dica contextual
## 9.3: flags que espelham cada passo concluído - o diário de missões
## (painel J + tracker da HUD) mostra o que fazer, em vez de depender
## só dos sussurros (que somem)
const TUT_FLAGS := [
	&"tut_move", &"tut_attack", &"tut_collect", &"tut_equip",
	&"tut_potion", &"tut_campfire", &"tut_espelho",
]
const STEP_HINTS := {
	TutStep.MOVE: "Use WASD ou clique no chão para andar.",
	TutStep.ATTACK: "Clique esquerdo no espantalho para atacar.",
	TutStep.COLLECT: "Aproxime-se do brilho da espada (ou clique no nome) para apanhá-la.",
	TutStep.EQUIP: "Abra o inventário (I) e arraste a espada até o slot de arma (ou Shift + clique nela).",
	TutStep.POTION: "Aperte Q para usar a Cura Simples.",
	TutStep.CAMPFIRE: "Aperte E na fogueira para acendê-la.",
}

var tut_step: TutStep = TutStep.MOVE
var _moved := 0.0
var _last_player_pos := Vector2.ZERO
var _cinzento: Cinzento
var _espantalho: Enemy
var _mirror_used := false
var _gate_wall: StaticBody2D
var _gate_fog: Array[Polygon2D] = []
var _gate_t := 0.0
var _level1_seen := false
var _guide: Polygon2D
var _step_time := 0.0
var _hint_shown := false


func _ready() -> void:
	super()
	_setup_tutorial()


func _setup_map() -> void:
	gen.width = MAP_W
	gen.height = MAP_H
	gen.grid = PackedByteArray()
	gen.grid.resize(MAP_W * MAP_H)
	gen.grid.fill(DungeonGenerator.SOLID)
	gen.rooms.clear()
	_carve_rect(CLEARING)
	_carve_rect(FOREST)
	_carve_rect(TRAINING)
	_carve_rect(TRAINING_PATH)
	_carve_rect(GATE)
	# Floresta densa com uma clareira circular (centro 27,10, raio 7) ligada ao
	# portão por um corredor de 3 células no eixo do portão: os lobos ficam
	# dentro da clareira e todos são alcançáveis a pé com o portão aberto
	var clearing := Vector2i(27, 10)
	for x in range(FOREST.position.x, FOREST.position.x + FOREST.size.x):
		for y in range(FOREST.position.y, FOREST.position.y + FOREST.size.y):
			var c := Vector2i(x, y)
			gen.set_cell(c, DungeonGenerator.FLOOR if c.distance_to(clearing) <= 7 else DungeonGenerator.SOLID)
	for x in range(26, 29):
		for y in range(clearing.y, GATE.position.y + 1):
			gen.set_cell(Vector2i(x, y), DungeonGenerator.FLOOR)
	# Casa: paredes, interior e porta
	for x in range(HOUSE_RING.position.x, HOUSE_RING.position.x + HOUSE_RING.size.x):
		for y in range(HOUSE_RING.position.y, HOUSE_RING.position.y + HOUSE_RING.size.y):
			gen.set_cell(Vector2i(x, y), DungeonGenerator.SOLID)
	_carve_rect(HOUSE)
	gen.set_cell(DOOR, DungeonGenerator.FLOOR)
	# Registros de sala (uso geral do World)
	gen.rooms = [HOUSE, CLEARING, TRAINING, FOREST]
	gen.start_room = HOUSE
	explored.resize(gen.width * gen.height)
	explored.fill(0)
	_build_tiles()
	_build_astar()


func _carve_rect(r: Rect2i) -> void:
	for x in range(r.position.x, r.position.x + r.size.x):
		for y in range(r.position.y, r.position.y + r.size.y):
			gen.set_cell(Vector2i(x, y), DungeonGenerator.FLOOR)


func _spawn_content() -> void:
	# Espelho antigo da casa - vazio, sem reflexo (o Véu roubou; LORE #9)
	Interactable.create(self, Interactable.Kind.MIRROR, cell_to_world(MIRROR_CELL))
	# Fogueira central da vila
	Interactable.create(self, Interactable.Kind.CAMPFIRE, cell_to_world(CAMPFIRE_CELL))
	# Espantalho de treino (passivo - nunca agride)
	_espantalho = spawn_enemy(DB.get_enemy(&"espantalho"), cell_to_world(SCARECROW_CELL), Enemy.Rarity.COMUM)
	# Baús didáticos
	for c in CHEST_CELLS:
		Interactable.create(self, Interactable.Kind.CHEST, cell_to_world(c))
	# Decoração: caixotes e detalhes da vila
	for d in [Vector2i(43, 27), Vector2i(51, 33), Vector2i(23, 32), Vector2i(30, 34)]:
		var s := Sprite2D.new()
		s.texture = DB.dt2_texture("crate")
		s.position = cell_to_world(d)
		decals.add_child(s)


func _setup_tutorial() -> void:
	_last_player_pos = player.global_position
	_cinzento = Cinzento.new()
	entities.add_child(_cinzento)
	_cinzento.appear_at(cell_to_world(CINZENTO_ANCHORS[0]))
	_whisper("Levante-se, cinza. Este lugar já foi casa - e vai querer ser de novo.")
	_whisper(CINZENTO_LINES[0])
	# 9.3: o tutorial entra no diário de missões - "Primeiros Passos na
	# Névoa" (data/quests/prologo_tutorial.tres), visível no painel (J) e
	# no tracker da HUD desde o primeiro segundo de jogo
	Game.quest_log.notify_flag(&"tut_inicio")
	Game.quest_log.tracked = &"prologo_tutorial"
	_build_gate()
	_setup_guide()
	Game.hero.leveled_up.connect(_on_hero_leveled_up)


# ------------------------------------------------------------------ PASSOS

func _process(delta: float) -> void:
	super(delta)
	_gate_t += delta
	# Névoa do portão tremula
	for i in _gate_fog.size():
		_gate_fog[i].modulate.a = 0.45 + sin(_gate_t * 2.2 + i * 1.7) * 0.12
	if player == null or player.is_dead():
		return
	# 6.4: onboarding visual - seta-guia e dica contextual
	_update_guide()
	_step_time += delta
	if not _hint_shown and _step_time > HINT_DELAY and tut_step in STEP_HINTS:
		_hint_shown = true
		# 9.3: 8s de leitura - dicas contextuais também somiam rápido demais
		hud.show_message("Dica: %s" % STEP_HINTS[tut_step], UIKit.TEXT_DIM, 8.0)
	if tut_step == TutStep.MOVE:
		_moved += player.global_position.distance_to(_last_player_pos)
		if _moved >= MOVE_DIST:
			_advance()
	elif tut_step == TutStep.COLLECT:
		if _has_wood_sword():
			_advance()
	elif tut_step == TutStep.EQUIP:
		if Game.hero.equipment.weapon != null:
			_advance()
	elif tut_step == TutStep.POTION:
		if player.simple_heal_cd > 0.0:
			_advance()
	_last_player_pos = player.global_position


func _has_wood_sword() -> bool:
	for it in Game.hero.inventory.items:
		if it is Item and it.base_id == &"wood_sword":
			return true
	return false


func _step_condition_met() -> bool:
	match tut_step:
		TutStep.MOVE: return _moved >= MOVE_DIST
		TutStep.COLLECT: return _has_wood_sword()
		TutStep.EQUIP: return Game.hero.equipment.weapon != null
		TutStep.POTION: return player.simple_heal_cd > 0.0
	return false


func _advance() -> void:
	var finished := tut_step
	tut_step += 1
	tutorial_step_done.emit(tut_step)
	Sfx.play(&"levelup", -8.0)
	# 9.3: passo concluído vira flag - o diário de missões registra o
	# progresso (a quest do tutorial avança de estágio junto com o jogo)
	if finished < TUT_FLAGS.size():
		Game.flags[TUT_FLAGS[finished]] = true
		Game.quest_log.notify_flag(TUT_FLAGS[finished])
	# 6.4: reinicia o relógio da dica contextual do passo novo
	_step_time = 0.0
	_hint_shown = false
	# 6.4: destaque na HUD do controle que o passo pede (MECANICAS #9)
	match tut_step:
		TutStep.EQUIP:
			hud.pulse_hint("I")
		TutStep.POTION:
			hud.pulse_hint("Q")
	if tut_step == TutStep.DONE:
		_open_gate()
		return
	_cinzento.appear_at(cell_to_world(CINZENTO_ANCHORS[tut_step]))
	_whisper(CINZENTO_LINES[tut_step])
	# Passos concluídos fora de ordem avançam em cascata
	if _step_condition_met():
		_advance()


func _on_enemy_killed(e: Enemy) -> void:
	super(e)
	if e == _espantalho:
		# O Cinzento deixa ferro de verdade onde o espantalho caiu
		LootDrop.drop_item(self, e.global_position, DB.create_item(&"wood_sword", 1, Item.Rarity.COMMON))
		if tut_step == TutStep.ATTACK:
			_advance()


func _on_campfire_lit(fire: Interactable) -> void:
	player.heal(player.max_hp)
	Game.respawn_pos = fire.global_position + Vector2(0, 20)
	Game.save_game()
	hud.show_message("A brasa te reconhece. Você renascerá aqui.", Color(1, 0.7, 0.3))
	if tut_step == TutStep.CAMPFIRE:
		_advance()


# ------------------------------------------------------- GUIA (Fase 6.4)

## Seta que orbita o herói apontando o objetivo do passo do tutorial
func _setup_guide() -> void:
	_guide = Polygon2D.new()
	_guide.polygon = PackedVector2Array([
		Vector2(12, 0), Vector2(-6, 7), Vector2(-2, 0), Vector2(-6, -7)])
	_guide.color = Color(1, 0.78, 0.35, 0.9)
	_guide.z_index = 60
	add_child(_guide)
	_guide.visible = false


## Objetivo do passo atual; Vector2.ZERO = sem seta (ação livre ou de UI)
func _guide_target() -> Vector2:
	match tut_step:
		TutStep.ATTACK:
			if _espantalho != null and is_instance_valid(_espantalho) and not _espantalho.is_dead():
				return _espantalho.global_position
			return cell_to_world(CINZENTO_ANCHORS[TutStep.ATTACK])
		TutStep.COLLECT:
			var drop := _nearest_sword_drop()
			if drop != null:
				return drop.global_position
			return cell_to_world(CINZENTO_ANCHORS[TutStep.COLLECT])
		TutStep.EQUIP:
			return Vector2.ZERO  # ação de inventário - o botão I pulsa na HUD
		TutStep.POTION:
			return cell_to_world(CINZENTO_ANCHORS[TutStep.POTION])
		TutStep.CAMPFIRE:
			return cell_to_world(CAMPFIRE_CELL)
	return Vector2.ZERO


func _update_guide() -> void:
	if _guide == null or player == null:
		return
	var target := _guide_target()
	if target == Vector2.ZERO or tut_step == TutStep.DONE or _mirror_used:
		_guide.visible = false
		return
	var d := player.global_position.distance_to(target)
	_guide.visible = d > GUIDE_MIN_DIST
	if not _guide.visible:
		return
	var dir := (target - player.global_position) / maxf(d, 1.0)
	var bob := sin(_gate_t * 5.0) * 3.0
	_guide.position = player.global_position + dir * (30.0 + bob)
	_guide.rotation = dir.angle()


func _nearest_sword_drop() -> LootDrop:
	var best: LootDrop = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactables"):
		if n is LootDrop and n.item != null and n.item.base_id == &"wood_sword":
			var d := player.global_position.distance_to(n.global_position)
			if d < best_d:
				best_d = d
				best = n
	return best


# ------------------------------------------------------------------ PORTAO

func _build_gate() -> void:
	_gate_wall = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(GATE.size.x * TILE, 14.0)
	shape.shape = rect
	_gate_wall.position = cell_to_world(Vector2i(GATE.position.x + GATE.size.x / 2, GATE_ROW + 1))
	_gate_wall.add_child(shape)
	add_child(_gate_wall)
	# Véu visual: faixas de névoa translúcidas
	for i in 3:
		var fog := Polygon2D.new()
		var w := GATE.size.x * float(TILE)
		var mid := cell_to_world(Vector2i(GATE.position.x + GATE.size.x / 2, GATE_ROW + 1))
		fog.polygon = PackedVector2Array([
			Vector2(mid.x - w / 2, mid.y - 14), Vector2(mid.x + w / 2, mid.y - 14),
			Vector2(mid.x + w / 2, mid.y + 14), Vector2(mid.x - w / 2, mid.y + 14),
		])
		fog.color = Color(0.72, 0.7, 0.82, 0.4)
		fog.z_index = 4
		add_child(fog)
		_gate_fog.append(fog)


func _open_gate() -> void:
	var tw := create_tween()
	for f in _gate_fog:
		tw.parallel().tween_property(f, "modulate:a", 0.0, 1.2)
	_cinzento.appear_at(cell_to_world(Vector2i(27, 21)))
	_whisper("A névoa guardava o que você ainda não podia enfrentar. Agora pode.")
	_whisper("Lobos de sombra adiante - restos de uma noite que ninguém lembra. Lute.")
	var wall := _gate_wall
	tw.tween_callback(func():
		if is_instance_valid(wall):
			wall.queue_free()
	)
	_gate_wall = null
	# As duas lutas do prólogo (REGRAS #13)
	for c in WOLF_CELLS:
		spawn_enemy(DB.get_enemy(&"lobo_sombrio"), cell_to_world(c), Enemy.Rarity.COMUM)


func _on_hero_leveled_up(new_level: int) -> void:
	# Nível 1: o reflexo chama (cutscene/criação entram na tarefa 1.4)
	if new_level == 1 and not _level1_seen:
		_level1_seen = true
		_cinzento.appear_at(cell_to_world(Vector2i(25, 36)))
		_whisper("Você não é mais quem era quando acordou. Volte à casa - o espelho espera.")


## Olhar-se no espelho: antes do nível 1, só o vazio; depois, a Reminiscência
## se dobra para dentro de si mesma e devolve não o que você era -
## mas o que você escolhe ser (REGRAS #13, MECANICAS #11).
func _on_mirror(_mirror: Interactable) -> void:
	if _mirror_used:
		return
	if Game.hero.level < 1:
		_whisper("Vidro vazio, como você. A névoa ainda tem algo a ensinar antes disto.")
		return
	if tut_step != TutStep.DONE:
		_whisper("O espelho espera. Termine o que a névoa pediu.")
		return
	_mirror_used = true
	# 9.3: último objetivo do tutorial registrado no diário - a quest
	# "Primeiros Passos na Névoa" conclui ao encarar a própria escolha
	Game.flags[&"tut_espelho"] = true
	Game.quest_log.notify_flag(&"tut_espelho")
	_cinzento.appear_at(player.global_position + Vector2(-24, -10))
	_whisper("...")
	_whisper("Vidro vazio. O Véu levou o reflexo - e guardou, em troca, uma escolha.")
	_whisper("Quem?")
	Sfx.play(&"levelup", -6.0)
	# A memória se dobra para dentro de si mesma
	await get_tree().create_timer(2.4, true, false, true).timeout
	if not is_inside_tree() or player == null or player.is_dead():
		return
	var tw := create_tween()
	tw.tween_property(canvas_modulate, "color", Color(0, 0, 0, 1), 1.2)
	await tw.finished
	Game.change_scene(Game.CHARACTER_CREATION)


# ------------------------------------------------------------------ MUNDO

func _intro() -> void:
	Game.play_music("res://assets/audio/music_menu.ogg")
	hud.show_message("Reminiscência", UIKit.GOLD, 3.0)
	hud.show_message("Um sonho que já foi casa.", UIKit.TEXT_DIM, 4.0)


func _apply_brightness() -> void:
	## Tom quente e levemente irreal - é uma memória, não um lugar.
	var b: float = Game.settings.brightness
	var c: Color = Color(0.52, 0.48, 0.46)
	canvas_modulate.color = Color(c.r * b, c.g * b, c.b * b, 1.0)


func _whisper(text: String) -> void:
	# 9.3: 9s de leitura - antes 5s e o texto sumia antes de dar para ler
	hud.show_message(text, Cinzento.VOICE, 9.0)
	Sfx.play(&"magic", -12.0)


func _start_position() -> Vector2:
	return cell_to_world(START_CELL)


func respawn_position() -> Vector2:
	return cell_to_world(START_CELL)


func level() -> int:
	return 1


func region_name() -> String:
	return "Reminiscência de Vale Cinzento"


func _exit_tree() -> void:
	"""Desconectar signals para evitar memory leak"""
	if Game.hero and Game.hero.leveled_up.is_connected(_on_hero_leveled_up):
		Game.hero.leveled_up.disconnect(_on_hero_leveled_up)
