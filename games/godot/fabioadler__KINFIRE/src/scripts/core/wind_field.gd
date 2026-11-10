class_name WindField
extends RefCounted
## Fase 7.4 (MECANICAS #14.5): campo de vento global - o mundo respira.
## Vento é INFORMACAO (direção, mudança de tempo, calmaria que pressagia
## chefes) e MECANICA (desvia projéteis, inclina fogueiras, empurra
## partículas, muda o custo de rotas).
## Coerência espacial e temporal: value-noise sobre (semente do mundo,
## tick de 10s) interpolado com smoothstep - o vento nunca vira do nada.
## Determinístico por (semente, tempo): mesma consulta = mesmo vento.

const TICK := 10.0         ## segundos por amostra de noise (#14.5.1)
const MAX_DEVIATION_DEG := 15.0

## Base por bioma (#14.5.1): rumo predominante + força média.
## Pantano sobe bolhas de gás e Vulcânico tem ascensão térmica (tela: -y é
## "para cima"); Corrompidas são erráticas - o rumo muda sem aviso.
const BIOME_WIND := {
	&"planicie": {"dir": Vector2(1, 0), "strength": 0.4},
	&"floresta": {"dir": Vector2(0.87, 0.5), "strength": 0.3},
	&"deserto": {"dir": Vector2(0, 1), "strength": 0.6},
	&"tundra": {"dir": Vector2(-0.98, 0.2), "strength": 0.5},
	&"pantano": {"dir": Vector2(0, -1), "strength": 0.2},
	&"vulcanico": {"dir": Vector2(0, -1), "strength": 0.4},
	&"corrompido": {"dir": Vector2(1, 0), "strength": 0.3, "erratic": true},
}

## Semente do mundo (o Overworld sincroniza com Game.world_seed)
static var world_seed := 0
## Vento fixo para testes/efeitos scriptados (Vector2.ZERO = desligado)
static var override := Vector2.ZERO
## Callable(pos) -> bioma (o Overworld registra o seu)
static var _provider: Callable
## Zonas de calmaria sobrenatural: chefes/campeões PARAM o vento ao redor
## (#14.5.2 - cue visual/auditiva gratuita de perigo). id -> {pos, radius}
static var _calms: Dictionary = {}


## Vetor de vento (direção * força 0-1) na posição pedida.
static func at(pos: Vector2, t := -1.0) -> Vector2:
	if override != Vector2.ZERO:
		return _calm_damp(override, pos)
	if t < 0.0:
		t = Time.get_ticks_msec() * 0.001
	var base: Dictionary = BIOME_WIND.get(_biome_at(pos), BIOME_WIND[&"planicie"])
	# noise coerente: interpola amostras de 10s (não muda abrupto)
	var n1 := _val_noise(t / TICK + pos.x * 0.01)
	var n2 := _val_noise(t / TICK + 1007.0 + pos.y * 0.01)
	var strength: float = clampf(float(base.strength) + n1 * 0.25, 0.0, 1.0)
	var dir: Vector2 = base.dir
	if base.get("erratic", false):
		dir = dir.rotated(n2 * PI * 1.5)
	else:
		dir = dir.rotated(n2 * 0.8)
	return _calm_damp(dir.normalized() * strength, pos)


static func strength_at(pos: Vector2, t := -1.0) -> float:
	return at(pos, t).length()


static func direction_at(pos: Vector2, t := -1.0) -> Vector2:
	var w := at(pos, t)
	return w.normalized() if w.length() > 0.001 else Vector2.ZERO


## Bônus de deslocamento a favor do vento (ventania #14.5.1): até ±10%.
static func speed_factor(pos: Vector2, move_dir: Vector2) -> float:
	if move_dir == Vector2.ZERO or strength_at(pos) < 0.8:
		return 1.0
	return 1.0 + move_dir.normalized().dot(direction_at(pos)) * 0.1


## Custo de rota (#14.5.4): contra o vento +5%, a favor -5% (sutil).
static func path_factor(from: Vector2, to: Vector2) -> float:
	var d := to - from
	if d == Vector2.ZERO:
		return 1.0
	var w := at((from + to) * 0.5)
	return 1.0 - d.normalized().dot(w) * 0.05


## Evento do dia, determinístico por (semente, dia) - #14.5.1:
## calmaria (<0.1: presságio), ventania (>0.8), frente (rumo vira), normal.
static func forecast(day := -1) -> StringName:
	if day < 0:
		day = Market.market_day()
	var r := _rand(day * 917 + 13)
	if r < 0.15:
		return &"calmaria"
	if r < 0.30:
		return &"ventania"
	if r < 0.40:
		return &"frente"
	return &"normal"


## Calmaria pressagia: 30% de chance de chefe nas próximas 2h (#14.5.1)
static func presagio(day := -1) -> bool:
	return forecast(day) == &"calmaria" and _rand(day * 917 + 137) < 0.3


# ------------------------------------------------------------------ CALMARIA

## Chefes/campeões registram a calmaria ao redor de si (id = instance id)
static func add_calm(id: int, pos: Vector2, radius := 320.0) -> void:
	_calms[id] = {"pos": pos, "radius": radius}


static func move_calm(id: int, pos: Vector2) -> void:
	if _calms.has(id):
		_calms[id]["pos"] = pos


static func remove_calm(id: int) -> void:
	_calms.erase(id)


## A calmaria deste id está viva? (smoke - robusto ao streaming de chunks)
static func has_calm(id: int) -> bool:
	return _calms.has(id)


static func calm_count() -> int:
	return _calms.size()


static func set_provider(c: Callable) -> void:
	_provider = c


static func _calm_damp(w: Vector2, pos: Vector2) -> Vector2:
	for c in _calms.values():
		var d: float = pos.distance_to(c.pos)
		if d < c.radius:
			w *= d / float(c.radius)
	return w


static func _biome_at(pos: Vector2) -> StringName:
	if _provider.is_valid():
		var b: StringName = _provider.call(pos)
		return b
	return &""


# ------------------------------------------------------------------ NOISE

static func _rand(x: int) -> float:
	# hash determinístico 0..1 (sin-based, estável na mesma build)
	return fmod(absf(sin(float(x) * 127.1 + float(world_seed) * 311.7)) * 43758.5453, 1.0)


static func _val_noise(x: float) -> float:
	var i := floori(x)
	var f := x - float(i)
	var s := f * f * (3.0 - 2.0 * f)
	return lerpf(_rand(i), _rand(i + 1), s) * 2.0 - 1.0
