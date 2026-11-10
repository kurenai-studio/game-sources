class_name Item
extends RefCounted
## Item gerado em tempo de execução (loot aleatório estilo Diablo).

enum Rarity { COMMON, MAGIC, RARE, LEGENDARY }

const RARITY_NAMES := ["Comum", "Mágico", "Raro", "Lendário"]
const RARITY_COLORS := [
	Color(0.92, 0.92, 0.92),
	Color(0.45, 0.6, 1.0),
	Color(1.0, 0.9, 0.3),
	Color(1.0, 0.55, 0.1),
]

var base_id: StringName
var name: String = ""
var rarity: int = Rarity.COMMON
## Nome do ícone (assets/icons) ou "k:NN" (tile Kenney)
var icon: String = "W_Sword001"
## Sprite 0x72 exibido na mão do herói (armas)
var sprite: String = ""
var size := Vector2i.ONE
var slot: String = "weapon"
## Categoria: sword, axe, mace, dagger, spear, staff, bow, fist, shield, book, orb, quiver
var category: String = ""
var two_handed := false
var item_level: int = 1
var min_damage: float = 0.0
var max_damage: float = 0.0
var attack_speed: float = 1.0
var armor: float = 0.0
var block: float = 0.0
## Afixos: {"str": 3, "crit_chance": 0.02, ...}
var stats: Dictionary = {}
var flavor: String = ""
## Posição no grid do inventário
var grid_pos: Vector2i = Vector2i(-1, -1)


func rarity_color() -> Color:
	return RARITY_COLORS[rarity]


func is_weapon() -> bool:
	return slot == "weapon"


func required_level() -> int:
	## ilvl 1 = equipamento de treino: usado já no prólogo pelo aldeão nível 0
	return maxi(0, item_level - 1)


func sell_value() -> int:
	return int((5 + item_level * 3) * (1 + rarity * 2))


func dps() -> float:
	return (min_damage + max_damage) * 0.5 * attack_speed


func stat(key: String) -> float:
	return float(stats.get(key, 0.0))


func to_dict() -> Dictionary:
	return {
		"base_id": String(base_id), "name": name, "rarity": rarity, "icon": icon, "sprite": sprite,
		"size": [size.x, size.y], "slot": slot, "category": category, "two_handed": two_handed,
		"item_level": item_level, "min_damage": min_damage, "max_damage": max_damage,
		"attack_speed": attack_speed, "armor": armor, "block": block, "stats": stats, "flavor": flavor,
		"grid_pos": [grid_pos.x, grid_pos.y],
	}


static func from_dict(d: Dictionary) -> Item:
	var it := Item.new()
	it.base_id = StringName(d.get("base_id", ""))
	it.name = d.get("name", "")
	it.rarity = int(d.get("rarity", 0))
	it.icon = str(d.get("icon", "W_Sword001"))
	it.sprite = d.get("sprite", "")
	var s: Array = d.get("size", [1, 1])
	it.size = Vector2i(int(s[0]), int(s[1]))
	it.slot = d.get("slot", "weapon")
	it.category = d.get("category", "")
	it.two_handed = d.get("two_handed", false)
	it.item_level = int(d.get("item_level", 1))
	it.min_damage = float(d.get("min_damage", 0))
	it.max_damage = float(d.get("max_damage", 0))
	it.attack_speed = float(d.get("attack_speed", 1))
	it.armor = float(d.get("armor", 0))
	it.block = float(d.get("block", 0))
	it.stats = d.get("stats", {})
	it.flavor = d.get("flavor", "")
	var g: Array = d.get("grid_pos", [-1, -1])
	it.grid_pos = Vector2i(int(g[0]), int(g[1]))
	return it


## Texto BBCode para o tooltip
func tooltip_bbcode(compare: Item = null, hero: Hero = null) -> String:
	var c := rarity_color().to_html(false)
	var t := "[font_size=18][color=#%s]%s[/color][/font_size]\n" % [c, name]
	var type_name: String = DB.CATEGORY_NAMES.get(category, DB.SLOT_NAMES.get(slot, ""))
	t += "[color=#%s]%s %s[/color]%s\n" % [c, RARITY_NAMES[rarity], type_name, "  [color=#aaaaaa](Duas Mãos)[/color]" if two_handed else ""]
	if is_weapon():
		t += "\n[font_size=22][color=#ffffff]%.1f[/color][/font_size] [color=#aaaaaa]Dano por Segundo[/color]" % dps()
		if compare and compare.is_weapon():
			t += _diff(dps() - compare.dps(), "%.1f")
		t += "\n[color=#cccccc]%d-%d de Dano\n%.2f Ataques por Segundo[/color]\n" % [min_damage, max_damage, attack_speed]
	if armor > 0:
		t += "\n[font_size=22][color=#ffffff]%d[/color][/font_size] [color=#aaaaaa]Armadura[/color]" % armor
		if compare:
			t += _diff(armor - compare.armor, "%d")
		t += "\n"
	if block > 0:
		t += "[color=#cccccc]+%d%% Chance de Bloqueio[/color]\n" % roundi(block * 100)
	if not stats.is_empty():
		t += "\n"
		for k in stats:
			t += "[color=#7aa0ff]%s: %s[/color]\n" % [k, stats[k]]
	if flavor != "":
		t += "\n[color=#c07020][i]\"%s\"[/i][/color]\n" % flavor
	t += "\n"
	if hero:
		var req := required_level()
		var ok_lvl := hero.level + hero.race.item_level_leeway >= req
		t += "[color=#%s]Nível necessário: %d[/color]\n" % ["aaaaaa" if ok_lvl else "ff4040", req]
		if not hero.can_use_category(self):
			t += "[color=#ff4040]%s não pode usar este item[/color]\n" % hero.cls.display_name
	t += "[color=#e8c060]Valor: %d ouro[/color]" % sell_value()
	return t


func _diff(v: float, fmt: String) -> String:
	if absf(v) < 0.05:
		return ""
	if v > 0:
		return "  [color=#40ff40]▲ +" + (fmt % v) + "[/color]"
	return "  [color=#ff4040]▼ " + (fmt % v) + "[/color]"


## Usa o consumível no alvo (jogador). Retorna true se o efeito foi aplicado.
## Subclasses podem sobrescrever para efeitos customizados (cura, buff, etc.).
func use(user: Player = null) -> bool:
	if user == null:
		return false
	# Consumível padrão: cura 25% da vida máxima
	user.heal(user.max_hp * 0.25, true)
	return true
