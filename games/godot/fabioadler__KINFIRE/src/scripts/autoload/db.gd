extends Node
## Banco de dados global: raças, classes, monstros, sprites animados, ícones e geração de itens.

var TILESHEET: Texture2D
var DT2_SHEET: Texture2D
const DT2_LIST := "res://assets/sprites/dt2/tile_list.txt"
const INDEX := "res://data/index.json"
const TILE := 16
const SHEET_COLS := 12

const ABILITIES := ["str", "dex", "con", "int", "wis", "cha"]
const ABILITY_NAMES := {
	"str": "Força", "dex": "Destreza", "con": "Constituição",
	"int": "Inteligência", "wis": "Sabedoria", "cha": "Carisma",
}
const ABILITY_SHORT := {"str": "FOR", "dex": "DES", "con": "CON", "int": "INT", "wis": "SAB", "cha": "CAR"}
const ABILITY_DESC := {
	"str": "Força física. Dano de classes de Força.",
	"dex": "Agilidade. Chance de crítico, armadura e dano de classes ágeis.",
	"con": "Vitalidade. Vida máxima e vida ganha por nível.",
	"int": "Intelecto. Dano de magos e recurso máximo.",
	"wis": "Sabedoria. Dano de clérigos/druidas e regeneração de recurso.",
	"cha": "Carisma. Dano de bardos/bruxos/feiticeiros e ouro encontrado.",
}
const ELEMENT_NAMES := {
	"physical": "Físico", "fire": "Fogo", "ice": "Gelo", "lightning": "Raio", "poison": "Veneno",
	"holy": "Sagrado", "shadow": "Sombra", "arcane": "Arcano",
}
const ELEMENT_COLORS := {
	"physical": Color(1, 1, 1), "fire": Color(1, 0.55, 0.2), "ice": Color(0.6, 0.9, 1), "lightning": Color(0.8, 0.85, 1),
	"poison": Color(0.5, 1, 0.3), "holy": Color(1, 0.95, 0.6), "shadow": Color(0.75, 0.5, 1), "arcane": Color(0.85, 0.6, 1),
}

## Antecedentes (D&D): pequeno bônus escolhido na criação
const BACKGROUNDS := {
	"soldado": {"name": "Soldado", "desc": "+10 de armadura.", "stats": {"armor": 10.0}},
	"acolito": {"name": "Acólito", "desc": "+2 de regeneração de recurso.", "stats": {"resource_regen": 2.0}},
	"criminoso": {"name": "Criminoso", "desc": "+3% de chance de crítico.", "stats": {"crit_chance": 0.03}},
	"sabio": {"name": "Sábio", "desc": "+10% de experiência.", "stats": {"xp_bonus": 0.10}},
	"nobre": {"name": "Nobre", "desc": "+20% de ouro encontrado e 100 de ouro inicial.", "stats": {"gold_find": 0.20}},
	"forasteiro": {"name": "Forasteiro", "desc": "+6% de velocidade de movimento.", "stats": {"move_speed": 0.06}},
	"artesao": {"name": "Artesão de Guilda", "desc": "+15% de valor de venda dos itens.", "stats": {"sell_bonus": 0.15}},
	"heroi_do_povo": {"name": "Herói do Povo", "desc": "+20 de vida.", "stats": {"life": 20.0}},
}

## Dificuldades estilo Diablo 3
const DIFFICULTIES := [
	{"name": "Normal", "hp": 1.0, "dmg": 1.0, "loot": 0.0, "xp": 1.0, "death_gold_loss": 0.10, "color": Color(0.85, 0.85, 0.85)},
	{"name": "Difícil", "hp": 1.6, "dmg": 1.35, "loot": 0.08, "xp": 1.25, "death_gold_loss": 0.20, "color": Color(0.5, 0.75, 1)},
	{"name": "Pesadelo", "hp": 2.5, "dmg": 1.8, "loot": 0.16, "xp": 1.6, "death_gold_loss": 0.30, "color": Color(1, 0.85, 0.3)},
	{"name": "Inferno", "hp": 4.0, "dmg": 2.5, "loot": 0.28, "xp": 2.0, "death_gold_loss": 0.30, "color": Color(1, 0.35, 0.15)},
]

const EQUIP_SLOTS := ["helm", "amulet", "weapon", "chest", "offhand", "gloves", "ring", "accessory_1", "accessory_2", "accessory_3", "boots"]
const SLOT_NAMES := {
	"weapon": "Arma", "offhand": "Mão Secundária", "helm": "Elmo", "chest": "Armadura",
	"boots": "Botas", "amulet": "Amuleto", "ring": "Anel", "gloves": "Luvas",
	"accessory_1": "Acessório 1", "accessory_2": "Acessório 2", "accessory_3": "Acessório 3",
}
const CATEGORY_NAMES := {
	"sword": "Espada", "axe": "Machado", "mace": "Maça", "dagger": "Adaga", "spear": "Lança",
	"staff": "Cajado", "bow": "Arco", "fist": "Arma de Punho", "shield": "Escudo", "book": "Tomo",
	"orb": "Orbe", "quiver": "Aljava",
}

static func _icons(prefix: String, from: int, to: int, digits: int) -> Array:
	var out: Array = []
	for i in range(from, to + 1):
		out.append(prefix + str(i).pad_zeros(digits))
	return out

## Tipos-base de itens
var BASES: Dictionary = {
	&"wood_sword": {"name": "Espada de Treino", "slot": "weapon", "cat": "sword", "size": Vector2i(1, 3), "dmg": Vector2(2, 4), "speed": 1.1, "icons": ["W_Sword001"], "sprites": ["weapon_rusty_sword"]},
	&"sword": {"name": "Espada Longa", "slot": "weapon", "cat": "sword", "size": Vector2i(1, 3), "dmg": Vector2(5, 9), "speed": 1.1, "icons": _icons("W_Sword", 2, 22, 3), "sprites": ["weapon_regular_sword", "weapon_knight_sword", "weapon_golden_sword", "weapon_lavish_sword", "weapon_red_gem_sword", "weapon_duel_sword", "weapon_saw_sword", "weapon_katana"]},
	&"axe": {"name": "Machado", "slot": "weapon", "cat": "axe", "size": Vector2i(2, 3), "dmg": Vector2(7, 12), "speed": 0.95, "icons": _icons("W_Axe", 1, 7, 3), "sprites": ["weapon_axe", "weapon_waraxe", "weapon_throwing_axe"]},
	&"great_axe": {"name": "Machado Grande", "slot": "weapon", "cat": "axe", "two_handed": true, "size": Vector2i(2, 3), "dmg": Vector2(12, 18), "speed": 0.8, "icons": _icons("W_Axe", 8, 14, 3), "sprites": ["weapon_double_axe"]},
	&"mace": {"name": "Maça", "slot": "weapon", "cat": "mace", "size": Vector2i(1, 3), "dmg": Vector2(6, 10), "speed": 1.05, "icons": _icons("W_Mace", 1, 10, 3), "sprites": ["weapon_mace", "weapon_hammer", "weapon_baton_with_spikes"]},
	&"great_hammer": {"name": "Martelo de Guerra", "slot": "weapon", "cat": "mace", "two_handed": true, "size": Vector2i(2, 3), "dmg": Vector2(11, 17), "speed": 0.8, "icons": ["W_Mace011", "W_Mace012", "W_Mace013", "W_Mace014", "W_Mace15", "W_Mace16"], "sprites": ["weapon_big_hammer"]},
	&"dagger": {"name": "Adaga", "slot": "weapon", "cat": "dagger", "size": Vector2i(1, 2), "dmg": Vector2(3, 6), "speed": 1.5, "crit": 0.03, "icons": _icons("W_Dagger", 1, 21, 3), "sprites": ["weapon_knife", "weapon_cleaver"]},
	&"spear": {"name": "Lança", "slot": "weapon", "cat": "spear", "two_handed": true, "size": Vector2i(1, 4), "dmg": Vector2(8, 13), "speed": 1.0, "icons": _icons("W_Spear", 1, 14, 3), "sprites": ["weapon_spear"]},
	&"staff": {"name": "Cajado", "slot": "weapon", "cat": "staff", "size": Vector2i(1, 4), "dmg": Vector2(6, 10), "speed": 1.0, "icons": _icons("W_Staff", 1, 8, 2), "sprites": ["weapon_red_magic_staff", "weapon_green_magic_staff"]},
	&"bow": {"name": "Arco", "slot": "weapon", "cat": "bow", "two_handed": true, "size": Vector2i(2, 3), "dmg": Vector2(6, 10), "speed": 1.15, "icons": _icons("W_Bow", 1, 17, 2), "sprites": ["weapon_bow", "weapon_bow_2"]},
	&"fist": {"name": "Manoplas", "slot": "weapon", "cat": "fist", "size": Vector2i(2, 2), "dmg": Vector2(4, 7), "speed": 1.4, "crit": 0.02, "icons": _icons("W_Fist", 1, 5, 3), "sprites": []},
	&"shield_round": {"name": "Broquel", "slot": "offhand", "cat": "shield", "size": Vector2i(2, 2), "armor": 8, "block": 0.10, "icons": ["k:101"], "sprites": []},
	&"shield_kite": {"name": "Escudo de Torre", "slot": "offhand", "cat": "shield", "size": Vector2i(2, 3), "armor": 14, "block": 0.15, "icons": ["k:102"], "sprites": []},
	&"book": {"name": "Tomo", "slot": "offhand", "cat": "book", "size": Vector2i(2, 2), "armor": 2, "implicit": {"resource_regen": 1.5}, "icons": _icons("W_Book", 1, 7, 2), "sprites": []},
	&"orb": {"name": "Orbe de Foco", "slot": "offhand", "cat": "orb", "size": Vector2i(1, 1), "armor": 2, "implicit": {"damage_pct": 0.06}, "icons": ["I_Crystal01", "I_Crystal02", "I_Crystal03", "I_Opal", "I_Sapphire", "I_Amethist"], "sprites": []},
	&"quiver": {"name": "Aljava", "slot": "offhand", "cat": "quiver", "size": Vector2i(1, 2), "armor": 2, "implicit": {"attack_speed": 0.06}, "icons": ["I_Feather01", "I_Feather02"], "sprites": []},
	&"helm": {"name": "Elmo", "slot": "helm", "size": Vector2i(2, 2), "armor": 6, "icons": ["C_Elm01", "C_Elm03", "C_Elm04"], "sprites": []},
	&"hat": {"name": "Chapéu Arcano", "slot": "helm", "size": Vector2i(2, 2), "armor": 2, "implicit": {"resource_regen": 1.0}, "icons": ["C_Hat01", "C_Hat02"], "sprites": []},
	&"plate": {"name": "Armadura de Placas", "slot": "chest", "size": Vector2i(2, 3), "armor": 18, "icons": ["A_Armor04", "A_Armor05", "A_Armour01", "A_Armour02", "A_Armour03"], "sprites": []},
	&"leather": {"name": "Gibão de Couro", "slot": "chest", "size": Vector2i(2, 3), "armor": 9, "implicit": {"dex": 1.0}, "icons": ["A_Clothing01", "A_Clothing02"], "sprites": []},
	&"boots": {"name": "Botas", "slot": "boots", "size": Vector2i(2, 2), "armor": 4, "implicit": {"move_speed": 0.03}, "icons": _icons("A_Shoes", 1, 7, 2), "sprites": []},
	&"amulet": {"name": "Amuleto", "slot": "amulet", "size": Vector2i(1, 1), "armor": 0, "icons": _icons("Ac_Necklace", 1, 8, 2) + _icons("Ac_Medal", 1, 4, 2), "sprites": []},
	&"ring": {"name": "Anel", "slot": "ring", "size": Vector2i(1, 1), "armor": 0, "icons": ["Ac_Ring01", "Ac_Ring02", "I_Ruby", "I_Jade", "I_Diamond"], "sprites": []},
}

const PREFIXES := ["Feroz", "Brutal", "Sombrio", "Ardente", "Glacial", "Sagrado", "Ancestral", "Rúnico", "Maldito", "Vil", "Glorioso", "Sangrento"]
const SUFFIXES := ["da Ruína", "do Abismo", "dos Reis", "da Aurora", "do Dragão", "da Brasa", "do Eclipse", "dos Mártires", "do Lobo", "da Tempestade"]
const LEGENDARY_NAMES := {
	"weapon": ["Kinfire, a Chama Ancestral", "Ceifadora de Almas", "Fúria do Rei Caído", "Juramento Quebrado", "Lâmina do Crepúsculo", "Presa de Grolmak"],
	"offhand": ["Egide do Ultimo Bastião", "Coração de Brasa", "Olho do Vazio", "Grimório de Azkhar"],
	"helm": ["Coroa do Rei Cinzento", "Elmo de Mil Batalhas", "Visão do Profeta"],
	"chest": ["Couraça do Dragão Rubro", "Manto das Estrelas Mortas", "Pele de Putrefato"],
	"boots": ["Passos do Vento Norte", "Botas do Andarilho Eterno"],
	"amulet": ["Lágrima da Fênix", "Selo do Primeiro Fogo", "Ambar dos Antigos"],
	"ring": ["Anel do Juramento", "Círculo da Brasa Eterna", "Aliança dos Mortos"],
}
const LEGENDARY_FLAVOR := [
	"Forjado nas chamas que deram nome a este reino.",
	"Dizem que sussurra o nome de quem irá morrer.",
	"Pertenceu a um rei cujo nome foi apagado da história.",
	"Ainda quente ao toque, mesmo séculos depois.",
	"Nenhum portador sobreviveu para contar a história. Até agora.",
]

## Afixos possíveis: [chave, min, max, escala por nível]
const AFFIXES := [
	["str", 1.0, 3.0, 0.15], ["dex", 1.0, 3.0, 0.15], ["con", 1.0, 3.0, 0.15],
	["int", 1.0, 3.0, 0.15], ["wis", 1.0, 3.0, 0.15], ["cha", 1.0, 3.0, 0.15],
	["life", 5.0, 15.0, 2.0], ["armor", 3.0, 8.0, 1.0],
	["crit_chance", 0.01, 0.03, 0.0], ["crit_damage", 0.1, 0.25, 0.0],
	["attack_speed", 0.04, 0.1, 0.0], ["damage_pct", 0.05, 0.12, 0.004],
	["move_speed", 0.03, 0.08, 0.0], ["life_on_hit", 1.0, 3.0, 0.3],
	["resource_regen", 1.0, 3.0, 0.1], ["gold_find", 0.05, 0.2, 0.0], ["cdr", 0.03, 0.08, 0.0],
	["fire_resist", 0.05, 0.15, 0.0], ["ice_resist", 0.05, 0.15, 0.0], ["poison_resist", 0.05, 0.15, 0.0],
	["magic_resist", 0.04, 0.12, 0.0], ["lifesteal", 0.01, 0.03, 0.0],
]

var races: Array[RaceData] = []
var classes: Array[ClassData] = []
var enemies: Array[EnemyData] = []
var racial_breath: SkillData
## Classe oculta do aldeão do prólogo (fora do index.json -> não aparece na criação)
var villager_class: ClassData
## LootTableData por raridade de monstro (REGRAS #6); índice = Enemy.Rarity
var loot_tables: Array[LootTableData] = []
## Diálogos carregados sob demanda: id -> DialogueData (data/dialogues/*.tres)
var dialogues: Dictionary = {}
## NPCs carregados sob demanda: id -> NpcData (data/npcs/*.tres)
var npcs: Dictionary = {}
## Quests (Fase 4): id -> QuestData (data/quests/*.tres, lista no index.json)
var quests: Dictionary = {}
## Vendors (Fase 5): id -> VendorData (data/vendors/*.tres, lista no index.json)
var vendors: Dictionary = {}
var _tile_cache: Dictionary = {}
var _sheet_image: Image
var _dt2_image: Image
var _dt2_rects: Dictionary = {}
var _frames_cache: Dictionary = {}
var _icon_cache: Dictionary = {}


func _ready() -> void:
	# Carregar texturas dinamicamente
	TILESHEET = load("res://assets/sprites/dungeon_tiles.png")
	DT2_SHEET = load("res://assets/sprites/dt2/dungeon_sheet.png")
	
	var idx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	races.assign(_load_dir("res://data/races/", idx.races))
	classes.assign(_load_dir("res://data/classes/", idx.classes))
	enemies.assign(_load_dir("res://data/enemies/", idx.enemies))
	racial_breath = load("res://data/skills/racial/sopro_draconico.tres")
	villager_class = load("res://data/classes/aldeao.tres")
	loot_tables.assign(_build_loot_tables())
	for line in FileAccess.get_file_as_string(DT2_LIST).split("\n"):
		var p := line.strip_edges().split(" ", false)
		if p.size() >= 5:
			_dt2_rects[p[0]] = Rect2i(int(p[1]), int(p[2]), int(p[3]), int(p[4]))
	# Fase 4: quests (data/quests/*.tres)
	for qid in idx.get("quests", []):
		var qres: QuestData = load("res://data/narrative/quests/%s.tres" % qid)
		if qres:
			quests[StringName(qid)] = qres
		else:
			push_error("Quest não encontrada: data/quests/%s.tres" % qid)
	# Fase 5: vendors (data/vendors/*.tres)
	for vid in idx.get("vendors", []):
		var vres: VendorData = load("res://data/vendors/%s.tres" % vid)
		if vres:
			vendors[StringName(vid)] = vres
		else:
			push_error("Vendor não encontrado: data/vendors/%s.tres" % vid)


func _load_dir(dir: String, order: Array) -> Array:
	var out: Array = []
	for id in order:
		var res := load(dir + str(id) + ".tres")
		if res:
			out.append(res)
		else:
			push_error("Recurso não encontrado: %s%s.tres" % [dir, id])
	return out


## LootTableData por raridade de monstro - REGRAS #6 ("drops garantidos").
## Chefe é roteirizado: HP/XP tuned no EnemyData; o ouro x25 é o da tabela,
## pois não há dado por inimigo para ouro.
func _build_loot_tables() -> Array[LootTableData]:
	var out: Array[LootTableData] = []
	# COMUM: ouro pequeno; 10% item
	var t := LootTableData.new()
	t.gold_chance = 0.4
	t.gold_mult = 1
	t.globe_chance = 0.12
	t.item_chance = 0.10
	out.append(t)
	# ELITE: >=1 item Mágico + ouro
	t = LootTableData.new()
	t.gold_chance = 1.0
	t.gold_mult = 3
	t.globe_chance = 1.0
	t.item_chance = 0.35
	t.item_magic = 0.15
	t.guaranteed.assign([Item.Rarity.MAGIC])
	out.append(t)
	# CAMPEAO: >=1 Raro + 20% Lendário + 50% Essência
	t = LootTableData.new()
	t.gold_chance = 1.0
	t.gold_mult = 6
	t.globe_chance = 1.0
	t.item_chance = 0.35
	t.item_magic = 0.25
	t.guaranteed.assign([Item.Rarity.RARE])
	t.legend_chance = 0.2
	t.essence_chance = 0.5
	out.append(t)
	# LENDARIO: >=1 Lendário/Unico + >=1 Essência
	t = LootTableData.new()
	t.gold_chance = 1.0
	t.gold_mult = 15
	t.globe_chance = 1.0
	t.item_chance = 0.35
	t.item_magic = 0.4
	t.guaranteed.assign([Item.Rarity.LEGENDARY])
	t.essence_chance = 1.0
	out.append(t)
	# CHEFE: >=2 itens (>=1 Raro+) + Essência x2 + item único garantido
	t = LootTableData.new()
	t.gold_chance = 1.0
	t.gold_mult = 25
	t.globe_chance = 1.0
	t.item_chance = 0.6
	t.item_magic = 0.6
	t.guaranteed.assign([Item.Rarity.RARE, Item.Rarity.RARE])
	t.essence_chance = 1.0
	t.essence_amount = 2
	t.unique_chance = 1.0
	out.append(t)
	return out


# ------------------------------------------------------------------ SPRITES

## Tile da folha Kenney (16x16)
func tile(index: int) -> AtlasTexture:
	if _tile_cache.has(index):
		return _tile_cache[index]
	var at := AtlasTexture.new()
	at.atlas = TILESHEET
	at.region = Rect2((index % SHEET_COLS) * TILE, (index / SHEET_COLS) * TILE, TILE, TILE)
	_tile_cache[index] = at
	return at


## Sprite Kenney isolado com 1px de margem (permite contorno via shader)
func sprite(index: int) -> ImageTexture:
	var key := -1 - index
	if _tile_cache.has(key):
		return _tile_cache[key]
	if _sheet_image == null:
		_sheet_image = _decompressed(TILESHEET)
	var img := Image.create(TILE + 2, TILE + 2, false, Image.FORMAT_RGBA8)
	img.blit_rect(_sheet_image, Rect2i((index % SHEET_COLS) * TILE, (index / SHEET_COLS) * TILE, TILE, TILE), Vector2i.ONE)
	var tex := ImageTexture.create_from_image(img)
	_tile_cache[key] = tex
	return tex


func _decompressed(t: Texture2D) -> Image:
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


func dt2_rect(frame_name: String) -> Rect2i:
	return _dt2_rects.get(frame_name, Rect2i())


func has_dt2(frame_name: String) -> bool:
	return _dt2_rects.has(frame_name)


## Um quadro da folha 0x72, isolado com 1px de margem
func dt2_texture(frame_name: String) -> Texture2D:
	var key := "dt2:" + frame_name
	if _icon_cache.has(key):
		return _icon_cache[key]
	if not _dt2_rects.has(frame_name):
		return null
	if _dt2_image == null:
		_dt2_image = _decompressed(DT2_SHEET)
	var r: Rect2i = _dt2_rects[frame_name]
	var img := Image.create(r.size.x + 2, r.size.y + 2, false, Image.FORMAT_RGBA8)
	img.blit_rect(_dt2_image, r, Vector2i.ONE)
	var tex := ImageTexture.create_from_image(img)
	_icon_cache[key] = tex
	return tex


## SpriteFrames animado ("idle", "run", "hit") de um personagem 0x72
func frames(base: String) -> SpriteFrames:
	if _frames_cache.has(base):
		return _frames_cache[base]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	# "k:NN" = sprite de um quadro da folha Kenney
	if base.begins_with("k:"):
		var tex := sprite(int(base.substr(2)))
		for anim in ["idle", "run", "hit"]:
			sf.add_animation(anim)
			sf.add_frame(anim, tex)
		_frames_cache[base] = sf
		return sf
	var anims: Dictionary = {"idle": base + "_idle_anim_f", "run": base + "_run_anim_f", "hit": base + "_hit_anim_f", "any": base + "_anim_f", "open": base + "_open_anim_f"}
	var found: Dictionary = {}
	for anim in anims:
		var list: Array = []
		for i in 12:
			var n: String = anims[anim] + str(i)
			if _dt2_rects.has(n):
				list.append(n)
		if base == "zombie" and anim == "any" and _dt2_rects.has("zombie_anim_f10"):
			list.push_front("zombie_anim_f10")
		if not list.is_empty():
			found[anim] = list
	if found.has("any") and not found.has("idle"):
		found["idle"] = found["any"]
		found["run"] = found["any"]
	if found.has("open") and not found.has("idle"):
		found["idle"] = [found["open"][0]]
		found["run"] = found["open"]
	if not found.has("idle"):
		push_warning("Sprite não encontrado: " + base)
		found["idle"] = []
	if not found.has("run"):
		found["run"] = found["idle"]
	if not found.has("hit"):
		found["hit"] = [found["idle"][0]] if not found["idle"].is_empty() else []
	for anim in ["idle", "run", "hit"]:
		sf.add_animation(anim)
		sf.set_animation_speed(anim, 8.0 if anim != "run" else 11.0)
		sf.set_animation_loop(anim, anim != "hit")
		for n in found[anim]:
			sf.add_frame(anim, dt2_texture(n))
	_frames_cache[base] = sf
	return sf


## Altura do quadro de um personagem 0x72 (para posicionar barras de vida etc.)
func frame_size(base: String) -> Vector2i:
	if base.begins_with("k:"):
		return Vector2i(16, 16)
	for suffix in ["_idle_anim_f0", "_anim_f0", "_open_anim_f0"]:
		if _dt2_rects.has(base + suffix):
			return _dt2_rects[base + suffix].size
	return Vector2i(16, 16)


## Icone: "k:101" = tile Kenney; senão nome do arquivo em assets/icons
func icon(icon_name: String) -> Texture2D:
	if icon_name.is_empty():
		icon_name = "S_Sword01"
	if icon_name.begins_with("k:"):
		return tile(int(icon_name.substr(2)))
	if _icon_cache.has(icon_name):
		return _icon_cache[icon_name]
	var path := "res://assets/icons/%s.png" % icon_name
	var tex: Texture2D
	if ResourceLoader.exists(path):
		tex = load(path)
	elif ResourceLoader.exists("res://assets/icons/S_Sword01.png"):
		# shortcut: fallback para S_Sword01; quando família nova chegar, adicionar PNG
		tex = load("res://assets/icons/S_Sword01.png")
	else:
		tex = tile(104)
	_icon_cache[icon_name] = tex
	return tex


# ------------------------------------------------------------------ CONSULTAS

func get_race(id: StringName) -> RaceData:
	for r in races:
		if r.id == id:
			return r
	return races[0]


func get_class_data(id: StringName) -> ClassData:
	if id == villager_class.id:
		return villager_class
	for c in classes:
		if c.id == id:
			return c
	return classes[0]


func get_enemy(id: StringName) -> EnemyData:
	for e in enemies:
		if e.id == id:
			return e
	return null


## Diálogo por id, carregado sob demanda de data/dialogues/<id>.tres
func dialogue(id: StringName) -> DialogueData:
	if not dialogues.has(id):
		dialogues[id] = load("res://data/narrative/dialogues/%s.tres" % id)
	return dialogues[id]


## NPC por id, carregado sob demanda de data/npcs/<id>.tres
func npc(id: StringName) -> NpcData:
	if not npcs.has(id):
		npcs[id] = load("res://data/narrative/npcs/%s.tres" % id)
	return npcs[id]


## Territórios carregados sob demanda: race_id -> TerritoryData (data/territories/*.tres)
var territories: Dictionary = {}


## Território racial por id da raça, carregado sob demanda
func territory(id: StringName) -> TerritoryData:
	if not territories.has(id):
		territories[id] = load("res://data/territories/%s.tres" % id)
	return territories[id]


## Quest por id (Fase 4); null se não existe
func quest(id: StringName) -> QuestData:
	return quests.get(id) as QuestData


## Todas as quests registradas (ids)
func quest_ids() -> Array:
	return quests.keys()


## Vendor por id (Fase 5); null se não existe
func vendor(id: StringName) -> VendorData:
	return vendors.get(id) as VendorData


## Todos os fornecedores registrados (ids)
func vendor_ids() -> Array:
	return vendors.keys()


func get_skill(cls: ClassData, id: StringName) -> SkillData:
	for s in cls.skills:
		if s.id == id:
			return s
	if racial_breath and racial_breath.id == id:
		return racial_breath
	return null


## Arvore de habilidades por classe (via skill_trees.gd - GDScript data-driven)
var skill_trees: Dictionary = {}
## Preload da classe para type hint funcionar em parse time
const SkillTreeData := preload("res://scripts/data/skill_tree_data.gd")
## Preload do módulo de árvores GDScript
const SkillTrees := preload("res://scripts/data/skill_trees.gd")


func get_skill_tree(class_id: StringName) -> SkillTreeData:
	if not skill_trees.has(class_id):
		skill_trees[class_id] = SkillTrees.get_tree(class_id)
	return skill_trees.get(class_id)


## Retorna um contrato pela ID (Fase 11)
func get_contract(contract_id: StringName) -> ContractData:
	var path := "res://data/contracts/%s.tres" % contract_id
	if ResourceLoader.exists(path):
		return load(path)
	return null


## Retorna todos os contratos de uma guilda (Fase 11)
func contracts_for(guild_id: StringName) -> Array[ContractData]:
	return Guilds.contracts_for(guild_id)


## Retorna uma guilda pela ID (Fase 11)
func get_guild(guild_id: StringName) -> GuildData:
	return Guilds.get_guild(guild_id)


func bosses() -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	for e in enemies:
		if e.boss_order > 0:
			out.append(e)
	out.sort_custom(func(a, b): return a.boss_order < b.boss_order)
	return out


static func ability_mod(score: int) -> int:
	return floori((score - 10) / 2.0)


func format_stat(key: String, v: Variant) -> String:
	var f := float(v)
	match key:
		"str", "dex", "con", "int", "wis", "cha":
			return "+%d %s" % [f, ABILITY_NAMES[key]]
		"life": return "+%d Vida" % f
		"armor": return "+%d Armadura" % f
		"crit_chance": return "+%.1f%% Chance de Crítico" % (f * 100.0)
		"crit_damage": return "+%d%% Dano Crítico" % roundi(f * 100.0)
		"attack_speed": return "+%d%% Velocidade de Ataque" % roundi(f * 100.0)
		"damage_pct": return "+%d%% de Dano" % roundi(f * 100.0)
		"move_speed": return "+%d%% Velocidade de Movimento" % roundi(f * 100.0)
		"life_on_hit": return "+%d Vida por Acerto" % f
		"resource_regen": return "+%.1f Regeneração de Recurso" % f
		"gold_find": return "+%d%% Ouro Encontrado" % roundi(f * 100.0)
		"cdr": return "-%d%% Tempo de Recarga" % roundi(f * 100.0)
		"fire_resist": return "+%d%% Resistência a Fogo" % roundi(f * 100.0)
		"ice_resist": return "+%d%% Resistência a Gelo" % roundi(f * 100.0)
		"poison_resist": return "+%d%% Resistência a Veneno" % roundi(f * 100.0)
		"magic_resist": return "+%d%% Resistência Mágica" % roundi(f * 100.0)
		"lifesteal": return "+%.1f%% Roubo de Vida" % (f * 100.0)
	return "%s: %s" % [key, str(v)]


# ------------------------------------------------------------------ ITENS

func roll_rarity(magic_bonus: float = 0.0) -> int:
	var r := randf()
	if r < 0.015 + magic_bonus * 0.3:
		return Item.Rarity.LEGENDARY
	if r < 0.12 + magic_bonus:
		return Item.Rarity.RARE
	if r < 0.45 + magic_bonus:
		return Item.Rarity.MAGIC
	return Item.Rarity.COMMON


func create_item(base_id: StringName, ilvl: int, rarity: int) -> Item:
	var b: Dictionary = BASES[base_id]
	var it := Item.new()
	it.base_id = base_id
	it.icon = b.icons.pick_random()
	it.sprite = b.sprites.pick_random() if not b.sprites.is_empty() else ""
	it.slot = b.slot
	it.category = b.get("cat", "")
	it.two_handed = b.get("two_handed", false)
	it.size = b.size
	it.item_level = ilvl
	it.rarity = rarity
	var lvl_mult := 1.0 + (ilvl - 1) * 0.18
	var q := randf_range(0.9, 1.1) * (1.0 + rarity * 0.08)
	if b.has("dmg"):
		var d: Vector2 = b.dmg
		it.min_damage = roundf(d.x * lvl_mult * q)
		it.max_damage = roundf(d.y * lvl_mult * q)
		it.attack_speed = b.speed
		if b.has("crit"):
			it.stats["crit_chance"] = b.crit
	if b.has("armor") and b.armor > 0:
		it.armor = roundf(b.armor * lvl_mult * q)
	it.block = b.get("block", 0.0)
	for k in b.get("implicit", {}):
		var base_v: float = b.implicit[k]
		it.stats[k] = base_v if base_v >= 1.0 else snappedf(base_v * (1.0 + ilvl * 0.05), 0.005)

	var n_affixes: int = [0, randi_range(1, 2), randi_range(3, 4), 5][rarity]
	var pool := AFFIXES.duplicate()
	pool.shuffle()
	for i in mini(n_affixes, pool.size()):
		var a: Array = pool[i]
		var v: float = randf_range(a[1], a[2]) + a[3] * ilvl
		if rarity == Item.Rarity.LEGENDARY:
			v *= 1.35
		v = roundf(v) if a[1] >= 1.0 else snappedf(v, 0.005)
		it.stats[a[0]] = float(it.stats.get(a[0], 0.0)) + v

	var base_name: String = b.name
	match rarity:
		Item.Rarity.COMMON:
			it.name = base_name
		Item.Rarity.MAGIC:
			it.name = "%s %s" % [base_name, PREFIXES.pick_random()]
		Item.Rarity.RARE:
			it.name = "%s %s %s" % [base_name, PREFIXES.pick_random(), SUFFIXES.pick_random()]
		Item.Rarity.LEGENDARY:
			it.name = LEGENDARY_NAMES[it.slot].pick_random()
			it.flavor = LEGENDARY_FLAVOR.pick_random()
	return it


func random_base() -> StringName:
	var keys := BASES.keys()
	keys.erase(&"wood_sword")
	return keys.pick_random()


## Base de item aleatória; com "for_class", 60% das armas/mãos secundárias são usáveis por ela
func random_base_for(for_class: ClassData) -> StringName:
	if for_class == null or randf() >= 0.6:
		return random_base()
	var usable: Array = []
	for k in BASES:
		if k == &"wood_sword":
			continue
		var b: Dictionary = BASES[k]
		if (b.slot == "weapon" and b.cat in for_class.allowed_weapons) or (b.slot == "offhand" and b.cat in for_class.allowed_offhands) or (b.slot != "weapon" and b.slot != "offhand"):
			usable.append(k)
	return usable.pick_random() if not usable.is_empty() else random_base()


## Rola um item; com "for_class", 60% das armas/mãos secundárias serão usáveis por ela
func roll_item(ilvl: int, magic_bonus: float = 0.0, for_class: ClassData = null) -> Item:
	return create_item(random_base_for(for_class), ilvl, roll_rarity(magic_bonus))


## Item de raridade garantida - drops garantidos por raridade de monstro (REGRAS #6)
func roll_item_of(ilvl: int, rarity: int, for_class: ClassData = null) -> Item:
	return create_item(random_base_for(for_class), ilvl, rarity)
