class_name Territories
extends RefCounted
## Territórios raciais (MECANICAS #3, tarefa 2.4): Voronoi procedural sobre o
## mundo infinito, determinístico por (semente + raça do jogador) - não precisa
## ser salvo. 14 capitais: a raça do jogador fica na origem (o acampamento
## inicial promovido a capital), as demais num anel com espaçamento mínimo
## garantido, preferindo o bioma da raça e nunca sobre água/terraços líquidos.
## O Vale do Centro (zona neutra da Kinfire apagada) não pertence a ninguém.

## Raio do Vale do Centro (células) - coincide com a planície forçada do gerador
const NEUTRAL_RADIUS := 42.0
## Perímetro da capital: sem spawn de inimigos, repel radius (MECANICAS #3)
const CAPITAL_SAFE_RADIUS := 14.0
## Anel de placement das 13 capitais não-jogadoras (células da origem)
const RING_MIN := 180.0
const RING_MAX := 430.0
## Espaçamento mínimo garantido entre capitais (células)
const CAPITAL_MIN_GAP := 150.0

var seed_value := 0
var player_race: StringName = &""
## race_id -> Vector2 (posição da capital, em CELULAS)
var capitals: Dictionary = {}

var _gen: OverworldGen


func _init(p_seed: int, p_player_race: StringName) -> void:
	seed_value = p_seed
	player_race = p_player_race
	_gen = OverworldGen.new(p_seed)
	_build()


# ------------------------------------------------------------------ CONSULTAS

## Território dono da célula - Voronoi da capital mais próxima.
## Retorna &"" dentro do Vale do Centro (neutro: de todos = de ninguém).
func territory_at(c: Vector2i) -> StringName:
	if Vector2(c).length() <= NEUTRAL_RADIUS:
		return &""
	var best: StringName = &""
	var best_d := INF
	for race in capitals:
		var d: float = Vector2(c).distance_to(capitals[race])
		if d < best_d:
			best_d = d
			best = race
	return best


func capital_of(race: StringName) -> Vector2:
	return capitals.get(race, Vector2.INF)


## Célula dentro do perímetro seguro de alguma capital? (sem spawn de inimigos)
func near_any_capital(c: Vector2i, radius := CAPITAL_SAFE_RADIUS) -> bool:
	for race in capitals:
		if Vector2(c).distance_to(capitals[race]) <= radius:
			return true
	return false


## Nível da região: distância do Vale do Centro + modificador do território (REGRAS #11)
func region_level(c: Vector2i) -> int:
	var base := clampi(1 + int(OverworldGen.danger(c) * 0.9), 1, 60)
	var race := territory_at(c)
	if race == &"":
		return base
	var t: TerritoryData = DB.territory(race)
	return base + (t.level_modifier if t != null else 0)


## Nome da região para a HUD: capital > Vale do Centro > território racial
func region_name_at(c: Vector2i) -> String:
	for race in capitals:
		if Vector2(c).distance_to(capitals[race]) <= CAPITAL_SAFE_RADIUS:
			var t: TerritoryData = DB.territory(race)
			if t != null:
				return "%s (área segura)" % t.capital_name
	if Vector2(c).length() <= NEUTRAL_RADIUS:
		return "Vale do Centro — a Kinfire apagada"
	var race := territory_at(c)
	if race != &"":
		var r: RaceData = DB.get_race(race)
		if r != null:
			return "Território %s - Nível %d" % [r.display_name, region_level(c)]
	return "Terra de Ninguém"


# ------------------------------------------------------------------ GERACAO

func _build() -> void:
	# A capital do jogador é o acampamento promovido (origem)
	capitals[player_race] = Vector2.ZERO
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|territorios|%s" % [seed_value, player_race])
	var order: Array[StringName] = []
	for r in DB.races:
		if r.id != player_race:
			order.append(r.id)
	# Embaralha com o rng local (determinístico - Array.shuffle usaria o global)
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	for race in order:
		var t: TerritoryData = DB.territory(race)
		var pos := _place_capital(rng, t)
		capitals[race] = pos
		if pos == Vector2.INF:
			push_warning("[territorios] capital de %s sem lugar - anel cheio?" % race)


## Amostragem por rejeição no anel: primeiro exige o bioma preferido,
## depois relaxa para qualquer terreno seco com o espaçamento mínimo.
func _place_capital(rng: RandomNumberGenerator, t: TerritoryData) -> Vector2:
	for relax in 2:
		for _i in 240:
			var ang := rng.randf() * TAU
			var dist := sqrt(rng.randf()) * (RING_MAX - RING_MIN) + RING_MIN
			var pos := Vector2.from_angle(ang) * dist
			if _fits(pos, t.preferred_biome if relax == 0 else ""):
				return pos
	return Vector2.INF


func _fits(pos: Vector2, want_biome: String) -> bool:
	for race in capitals:
		if pos.distance_to(capitals[race]) < CAPITAL_MIN_GAP:
			return false
	var c: Vector2i = Vector2i(roundi(pos.x), roundi(pos.y))
	var biome: String = _gen.biome_at(c)
	if want_biome != "" and biome != want_biome:
		return false
	# Capital não pode cair na água - checa o centro e os 4 vizinhos imediatos
	for off in [Vector2i.ZERO, Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
		if _gen.liquid_at(c + off, biome):
			return false
	return true
