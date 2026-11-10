class_name OverworldGen
extends RefCounted
## Gerador procedural infinito do mundo aberto (determinístico pela semente).
## Usa ruído para lagos, rios, temperatura, umidade e corrupção -> biomas.

const CHUNK := 32
## Raio (em células) da área segura do acampamento inicial
const SAFE_RADIUS := 12

## Biomas: nome, cor do minimapa, chão (coord. na folha Kenney Roguelike RPG) e tonalidade
const BIOMES := {
	"planicie": {"name": "Planícies de Kinfire", "map": Color(0.45, 0.65, 0.3), "ground": Vector2i(5, 0), "mod": Color(0.82, 0.9, 0.78)},
	"floresta": {"name": "Floresta Sussurrante", "map": Color(0.25, 0.5, 0.25), "ground": Vector2i(5, 0), "mod": Color(0.72, 0.88, 0.7)},
	"deserto": {"name": "Areias Escaldantes", "map": Color(0.85, 0.75, 0.45), "ground": Vector2i(8, 0), "mod": Color(0.92, 0.85, 0.72)},
	"tundra": {"name": "Tundra Congelada", "map": Color(0.85, 0.9, 0.95), "ground": Vector2i(45, 26), "mod": Color(0.82, 0.86, 0.94)},
	"pantano": {"name": "Pântano Pútrido", "map": Color(0.3, 0.4, 0.25), "ground": Vector2i(5, 0), "mod": Color(0.55, 0.68, 0.48)},
	"vulcanico": {"name": "Ermos Vulcânicos", "map": Color(0.55, 0.25, 0.15), "ground": Vector2i(0, 18), "mod": Color(0.55, 0.38, 0.34)},
	"corrompido": {"name": "Terras Corrompidas", "map": Color(0.45, 0.25, 0.5), "ground": Vector2i(0, 21), "mod": Color(0.55, 0.45, 0.6)},
}
const BIOME_IDS := ["planicie", "floresta", "deserto", "tundra", "pantano", "vulcanico", "corrompido"]

## Objetos de cenário: top = tile de cima (árvores altas), base = tile no chão
const PROPS := {
	"tree_round": {"top": Vector2i(13, 10), "base": Vector2i(13, 11), "solid": true},
	"tree_autumn": {"top": Vector2i(14, 10), "base": Vector2i(14, 11), "solid": true},
	"tree_teal": {"top": Vector2i(15, 10), "base": Vector2i(15, 11), "solid": true},
	"pine": {"top": Vector2i(16, 10), "base": Vector2i(16, 11), "solid": true},
	"pine_autumn": {"top": Vector2i(17, 10), "base": Vector2i(17, 11), "solid": true},
	"pine_snow": {"top": Vector2i(18, 10), "base": Vector2i(18, 11), "solid": true},
	"tree_fruit": {"top": Vector2i(23, 10), "base": Vector2i(23, 11), "solid": true},
	"dead_tall": {"top": Vector2i(27, 10), "base": Vector2i(27, 11), "solid": true},
	"small_tree": {"base": Vector2i(13, 9), "solid": true},
	"small_pine": {"base": Vector2i(16, 9), "solid": true},
	"bush": {"base": Vector2i(19, 9), "solid": false},
	"bush_orange": {"base": Vector2i(20, 9), "solid": false},
	"bush_small": {"base": Vector2i(25, 9), "solid": false},
	"cactus": {"base": Vector2i(26, 9), "solid": true},
	"cactus_small": {"base": Vector2i(22, 9), "solid": true},
	"dead_tree": {"base": Vector2i(27, 9), "solid": true},
	"flowers": {"base": Vector2i(24, 10), "solid": false},
	"flowers2": {"base": Vector2i(24, 9), "solid": false},
	"mushroom": {"base": Vector2i(48, 4), "solid": false},
	"rock": {"base": Vector2i(54, 19), "solid": true},
	"rock_grey": {"base": Vector2i(54, 21), "solid": true},
	"rock_moss": {"base": Vector2i(55, 20), "solid": true},
	"grave": {"base": Vector2i(51, 10), "solid": true},
	"grave2": {"base": Vector2i(52, 10), "solid": true},
	"cross": {"base": Vector2i(53, 10), "solid": true},
}
const BIOME_PROPS := {
	"planicie": [["tree_round", 0.018], ["small_tree", 0.01], ["bush", 0.02], ["flowers", 0.03], ["flowers2", 0.02], ["rock", 0.004], ["tree_fruit", 0.005]],
	"floresta": [["tree_round", 0.07], ["pine", 0.07], ["tree_teal", 0.025], ["tree_autumn", 0.015], ["bush", 0.03], ["mushroom", 0.012], ["small_pine", 0.02]],
	"deserto": [["cactus", 0.012], ["cactus_small", 0.014], ["rock", 0.01], ["dead_tree", 0.005], ["bush_orange", 0.008]],
	"tundra": [["pine_snow", 0.045], ["small_pine", 0.01], ["rock_grey", 0.012]],
	"pantano": [["dead_tall", 0.025], ["tree_teal", 0.02], ["mushroom", 0.03], ["bush_small", 0.025]],
	"vulcanico": [["dead_tree", 0.018], ["rock", 0.03], ["rock_grey", 0.01]],
	"corrompido": [["dead_tall", 0.03], ["grave", 0.012], ["grave2", 0.008], ["cross", 0.006], ["mushroom", 0.01]],
}

var seed_value := 0
var _height := FastNoiseLite.new()
var _river := FastNoiseLite.new()
var _temp := FastNoiseLite.new()
var _moist := FastNoiseLite.new()
var _corrupt := FastNoiseLite.new()


func _init(p_seed: int) -> void:
	seed_value = p_seed
	var noises: Array = [_height, _river, _temp, _moist, _corrupt]
	var freqs: Array = [0.03, 0.006, 0.0045, 0.006, 0.004]
	for i in noises.size():
		var n: FastNoiseLite = noises[i]
		n.seed = p_seed + i * 1013
		n.frequency = freqs[i]
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.fractal_octaves = 3


## Distância da origem em "chunks" (define a dificuldade da região)
static func danger(c: Vector2i) -> float:
	return Vector2(c).length() / CHUNK


func biome_at(c: Vector2i) -> String:
	var dist: float = Vector2(c).length()
	if dist < SAFE_RADIUS + 30:
		return "planicie"
	var d := dist / CHUNK
	var t := _temp.get_noise_2d(c.x, c.y)
	var m := _moist.get_noise_2d(c.x, c.y)
	var k := _corrupt.get_noise_2d(c.x, c.y)
	if d > 4.0 and k > 0.32 - minf(d * 0.01, 0.15):
		return "corrompido"
	if t > 0.22:
		return "vulcanico" if (m < -0.05 and d > 3.0) else "deserto"
	if t < -0.25:
		return "tundra"
	if m > 0.28:
		return "pantano"
	if m > -0.02:
		return "floresta"
	return "planicie"


## 0 = chão, 1 = água/lava
func liquid_at(c: Vector2i, biome: String) -> bool:
	if Vector2(c).length() < SAFE_RADIUS + 4:
		return false
	var h := _height.get_noise_2d(c.x, c.y)
	var r := absf(_river.get_noise_2d(c.x, c.y))
	var lake := -0.38
	match biome:
		"pantano": lake = -0.12
		"deserto": lake = -0.55
		"vulcanico": lake = -0.3
	return h < lake or (r < 0.018 and biome != "deserto")


## Número pseudoaleatório estável por célula
func rand01(c: Vector2i, salt: int) -> float:
	var h := hash(Vector3i(c.x * 73856093, c.y * 19349663, seed_value + salt * 83492791))
	return float(h & 0xFFFFFF) / float(0xFFFFFF)


## Objeto de cenário numa célula (ou "")
func prop_at(c: Vector2i, biome: String) -> String:
	if Vector2(c).length() < SAFE_RADIUS:
		return ""
	var r := rand01(c, 7)
	var acc := 0.0
	for p in BIOME_PROPS[biome]:
		acc += p[1]
		if r < acc:
			return p[0]
	return ""


## Variação de chão com flores na planície
func ground_variant(c: Vector2i, biome: String) -> Vector2i:
	return BIOMES[biome].ground
