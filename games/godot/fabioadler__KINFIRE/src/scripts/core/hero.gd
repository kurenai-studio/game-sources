class_name Hero
extends RefCounted
## Ficha do personagem (dados puros, sem física). O nó Player apenas lê daqui.

## Preloads para type hints funcionarem em parse time
# const SkillTreeData := preload("res://scripts/data/skill_tree_data.gd")
# const SkillNodeData := preload("res://scripts/data/skill_node_data.gd")

signal stats_changed
signal leveled_up(new_level: int)
signal gold_changed(amount: int)
signal essence_changed(amount: int)
signal xp_changed

const MAX_LEVEL := 9999
const SKILL_SLOTS := 6
const BASE_MOVE_SPEED := 72.0

var hero_name: String = "Herói"
var race: RaceData
var cls: ClassData
var sex: String = "m"
var tint: Color = Color.WHITE
var background: String = "soldado"
var difficulty: int = 0
var hardcore := false
var base_abilities: Dictionary = {"str": 10, "dex": 10, "con": 10, "int": 10, "wis": 10, "cha": 10}
## +1 escolhidos na criação (Meio-Elfo)
var free_bonus: Dictionary = {}
var level: int = 1
var xp: int = 0
var gold: int = 0
## Moeda "dura" da economia (REGRAS #9): só dropa de Campeão/Lendário/Chefe
var essence: int = 0
var unspent_points: int = 0
## Status ARPG (pontos livres distribuíveis + base da classe)
## Total = base_status[classe] + pontos_gastos
var status: Dictionary = {"forca": 10, "agilidade": 10, "mente": 10, "vitalidade": 10}
## Pontos de status não gastos (ganhos ao subir de nível: +2/nível)
var status_points: int = 0
## Arvore de habilidades: pontos não gastos (+1/nível) e nós desbloqueados
var tree_points: int = 0
var tree_unlocked: Array[StringName] = []
var inventory: InventoryGrid
var equipment: Dictionary = {}
## Ids das habilidades em cada slot: [LMB, RMB, 1, 2, 3, 4]
var skill_bar: Array = [&"", &"", &"", &"", &"", &""]
## Slots de consumíveis (1-9): Array[Item] ou null
var consumable_slots: Array = []
## Cooldowns de consumíveis por base_id: {base_id: tempo_restante}
var consumable_cooldowns: Dictionary = {}
var kills: int = 0
var deepest: int = 1
var play_time: float = 0.0
## Modificadores temporários (buffs): {"damage": 0.3, ...}
var temp: Dictionary = {}
## Guildas (Fase 11): filiações e ranks
var guild_members: Array[StringName] = []
var guild_ranks: Dictionary[StringName, int] = {}
var active_contracts: Array[StringName] = []
var completed_contracts: Array[StringName] = []
## Nova estrutura Fase 11 (Task 2):
var guild_joined: StringName = &""  # ID da guilda NPC que o herói é membro
var guild_rank: String = "F"  # Rank dentro da guilda (ainda não usado, delegado a RankSystem)
var guild_xp: int = 0  # XP dentro da guilda
var contracts_active: Array[StringName] = []  # Contratos em andamento
var contracts_completed: int = 0  # Total de contratos concluídos
var rank_f_s: String = "F"  # Rank global F-S (REGRAS #18)
var player_guild_id: StringName = &""  # ID da guilda criada pelo jogador (se houver)
var membro_guilda_jogador: StringName = &""  # ID da guilda do jogador que o herói é membro (não fundador)


func _init() -> void:
	for s in DB.EQUIP_SLOTS:
		equipment[s] = null


static func create(p_name: String, p_race: RaceData, p_cls: ClassData, p_sex: String, p_tint: Color, abilities: Dictionary,
		p_free_bonus: Dictionary = {}, p_background: String = "soldado", p_difficulty: int = 0, p_hardcore := false) -> Hero:
	var h := Hero.new()
	h.hero_name = p_name
	h.race = p_race
	h.cls = p_cls
	h.sex = p_sex
	h.tint = p_tint
	h.base_abilities = abilities.duplicate()
	h.free_bonus = p_free_bonus.duplicate()
	h.background = p_background
	h.difficulty = p_difficulty
	h.hardcore = p_hardcore
	h._make_inventory()
	h.equipment.weapon = DB.create_item(p_cls.starting_weapon, 1, Item.Rarity.COMMON)
	if p_cls.starting_offhand != &"":
		h.equipment.offhand = DB.create_item(p_cls.starting_offhand, 1, Item.Rarity.COMMON)
	h.equipment.chest = DB.create_item(&"leather" if p_cls.base_armor < 12 else &"plate", 1, Item.Rarity.COMMON)
	h.inventory.add(DB.create_item(&"wood_sword", 1, Item.Rarity.COMMON))
	# Inicializa slots de consumíveis (9 slots vazios)
	h.consumable_slots.resize(9)
	for i in 9:
		h.consumable_slots[i] = null
	# Inicializa status ARPG a partir da classe
	h._init_status()
	if p_background == "nobre":
		h.gold = 100
	h.refresh_skill_bar()
	return h


## Herói provisório do prólogo: aldeão nível 0, raça/classe ocultas (REGRAS #13,
## MECANICAS #11). Ao criar o personagem de verdade, o objeto é reconstruído.
static func create_villager() -> Hero:
	var h := Hero.new()
	h.hero_name = "Aldeão"
	h.race = DB.get_race(&"humano")
	h.cls = DB.villager_class
	h.sex = "m"
	h.base_abilities = {"str": 10, "dex": 10, "con": 10, "int": 10, "wis": 10, "cha": 10}
	h.level = 0
	h._make_inventory()
	h.consumable_slots.resize(9)
	for i in 9:
		h.consumable_slots[i] = null
	h._init_status()
	h.refresh_skill_bar()
	return h


func _make_inventory() -> void:
	inventory = InventoryGrid.new(10 + race.extra_inventory_cols, 6)


## Quantos itens-base o herói possui (inventário + equipados) - condições de diálogo (MECANICAS #7)
func count_item(base: StringName) -> int:
	var n := 0
	for it in inventory.items:
		if it is Item and it.base_id == base:
			n += 1
	for it in equipment.values():
		if it is Item and it.base_id == base:
			n += 1
	return n


## Nome-base do sprite animado
func sprite_base() -> String:
	return race.sprite_f if sex == "f" else race.sprite_m


func background_data() -> Dictionary:
	return DB.BACKGROUNDS.get(background, DB.BACKGROUNDS.soldado)


func bg_stat(key: String) -> float:
	return float(background_data().stats.get(key, 0.0))


func difficulty_data() -> Dictionary:
	return DB.DIFFICULTIES[clampi(difficulty, 0, DB.DIFFICULTIES.size() - 1)]


# ------------------------------------------------------------ ATRIBUTOS

func item_stat(key: String) -> float:
	var total := 0.0
	for s in DB.EQUIP_SLOTS:
		var it: Item = equipment[s]
		if it:
			total += it.stat(key)
	return total


func ability(a: String) -> int:
	return int(base_abilities.get(a, 10)) + int(race.ability_bonus.get(a, 0)) + int(free_bonus.get(a, 0)) + int(item_stat(a))


func mod(a: String) -> int:
	return DB.ability_mod(ability(a))


func max_hp() -> float:
	var con := ability("con")
	var per_level := cls.hit_die + maxi(mod("con"), 0) * 2
	return cls.base_hp + race.bonus_hp + con * 3 + (level - 1) * per_level + item_stat("life") + bg_stat("life")


func max_resource() -> float:
	var bonus := 0.0
	if cls.primary_ability in ["int", "wis", "cha"]:
		bonus = maxf(mod(cls.primary_ability), 0) * 5.0
	return (cls.resource_max + bonus) * race.resource_max_mult


func resource_regen() -> float:
	var r := cls.resource_regen
	if r > 0:
		r = (r + maxf(mod("wis"), 0) * 0.5 + item_stat("resource_regen") + bg_stat("resource_regen")) * race.resource_regen_mult
	return r


func armor() -> float:
	var a: float = float(cls.base_armor) + maxf(mod("dex"), 0) * 2.0 + item_stat("armor") + bg_stat("armor") + float(temp.get("armor", 0.0))
	for s in DB.EQUIP_SLOTS:
		var it: Item = equipment[s]
		if it:
			a += it.armor
	return a * race.armor_mult


func physical_reduction() -> float:
	var a := armor()
	var dr := a / (a + 60.0 + level * 8.0)
	return clampf(1.0 - (1.0 - dr) * (1.0 - race.physical_resist), 0.0, 0.85)


## Resistência total contra um elemento (0..1)
func resist(element: String) -> float:
	match element:
		"physical":
			return physical_reduction()
		"fire":
			if race.fire_resist >= 1.0:
				return 1.0
			return clampf(race.fire_resist + item_stat("fire_resist") + race.magic_resist + item_stat("magic_resist"), 0.0, 0.75)
		"ice":
			return clampf(race.ice_resist + item_stat("ice_resist") + race.magic_resist + item_stat("magic_resist"), 0.0, 0.75)
		"poison":
			return clampf(race.poison_resist + item_stat("poison_resist") + race.magic_resist * 0.5, 0.0, 0.75)
	return clampf(race.magic_resist + item_stat("magic_resist"), 0.0, 0.75)


func weapon_damage() -> Vector2:
	var w: Item = equipment.weapon
	if w == null:
		return Vector2(1, 3)
	return Vector2(w.min_damage, w.max_damage)


func damage_multiplier() -> float:
	var primary := ability(cls.primary_ability)
	return (1.0 + (primary - 10) * 0.05) * (1.0 + item_stat("damage_pct") + float(temp.get("damage", 0.0)))


func attack_speed() -> float:
	var w: Item = equipment.weapon
	var base := w.attack_speed if w else 1.0
	var bonus := item_stat("attack_speed") + float(temp.get("attack_speed", 0.0))
	if w and w.two_handed:
		bonus += race.two_hand_speed
	return base * (1.0 + bonus)


func crit_chance() -> float:
	return clampf(0.05 + maxf(mod("dex"), 0) * 0.01 + race.crit_chance_bonus + item_stat("crit_chance") + bg_stat("crit_chance") + float(temp.get("crit", 0.0)), 0.0, 0.75)


func crit_damage() -> float:
	return 0.5 + item_stat("crit_damage")


func move_speed() -> float:
	return BASE_MOVE_SPEED * race.move_speed_mult * (1.0 + item_stat("move_speed") + bg_stat("move_speed") + float(temp.get("speed", 0.0)))


func gold_find() -> float:
	return race.gold_find + item_stat("gold_find") + maxf(mod("cha"), 0) * 0.03 + bg_stat("gold_find")


func xp_multiplier() -> float:
	return (1.0 + race.xp_bonus + bg_stat("xp_bonus")) * difficulty_data().xp


func cooldown_mult() -> float:
	return 1.0 - clampf(item_stat("cdr") + race.cooldown_reduction, 0.0, 0.5)


func life_on_hit() -> float:
	return item_stat("life_on_hit")


func lifesteal() -> float:
	return cls.lifesteal + item_stat("lifesteal") + float(temp.get("lifesteal", 0.0))


func block_chance() -> float:
	var off: Item = equipment.offhand
	if off == null or off.category != "shield":
		return 0.0
	return clampf(cls.block_chance + off.block, 0.0, 0.5)


func sell_multiplier() -> float:
	return 1.0 + bg_stat("sell_bonus")


func dps_estimate() -> float:
	var w := weapon_damage()
	var avg := (w.x + w.y) * 0.5 * damage_multiplier()
	return avg * attack_speed() * (1.0 + crit_chance() * crit_damage())


## Retorna [dano, foi_critico]
func roll_damage(mult: float) -> Array:
	var w := weapon_damage()
	var dmg := randf_range(w.x, w.y) * mult * damage_multiplier()
	var crit := randf() < crit_chance()
	if crit:
		dmg *= 1.0 + crit_damage()
		if randf() < race.double_crit_chance:
			dmg *= 2.0
	return [maxf(dmg, 1.0), crit]


# ------------------------------------------------------------ PROGRESSAO

func xp_to_next() -> int:
	## Nível 0 (prólogo do aldeão) usa o mesmo requisito do nível 1 - REGRAS #13
	if level <= 0:
		return 20
	return int(20 * pow(level, 1.5))


func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	xp += int(amount * xp_multiplier())
	while xp >= xp_to_next() and level < MAX_LEVEL:
		xp -= xp_to_next()
		level += 1
		## +1 ponto de atributo D&D a cada 4 níveis (1, 5, 9, 13...) - REGRAS #2
		unspent_points += 1 if level % 4 == 1 else 0
		## +2 pontos de status ARPG por nível (livres para distribuir) - REGRAS #2/Fase 10
		status_points += 2
		## +1 ponto de árvore de habilidades por nível - Fase 10.4
		tree_points += 1
		## Base da classe escala com o nível (status_growth)
		_recalc_status()
		refresh_skill_bar()
		leveled_up.emit(level)
	xp_changed.emit()
	stats_changed.emit()


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func add_essence(amount: int) -> void:
	essence += amount
	essence_changed.emit(essence)


func spend_point(a: String) -> void:
	if unspent_points <= 0:
		return
	unspent_points -= 1
	base_abilities[a] = int(base_abilities[a]) + 1
	stats_changed.emit()


## Inicializa status ARPG a partir da classe (base_status)
func _init_status() -> void:
	for s in ["forca", "agilidade", "mente", "vitalidade"]:
		var base: int = cls.base_status.get(s, 10)
		status[s] = base
	status_points = 0
	_recalc_status()


## Recalcula status: base da classe (com growth por nível) + pontos gastos
func _recalc_status() -> void:
	for s in ["forca", "agilidade", "mente", "vitalidade"]:
		var base: int = cls.base_status.get(s, 10)
		var growth: int = cls.status_growth.get(s, 0)
		# base sobe com o nível
		if level > 1:
			base += growth * (level - 1)
		# status final = base + pontos gastos (já está em status[s])
		# mantemos apenas a parte "base" separada para respec
		# status[s] já contém base + gasto
		# nada a fazer aqui, só emitir sinal
	stats_changed.emit()


## Gasta 1 ponto de status no atributo indicado
## Retorna true se gastou
func spend_status_point(stat: String) -> bool:
	if status_points <= 0:
		return false
	if not status.has(stat):
		return false
	status_points -= 1
	status[stat] = int(status[stat]) + 1
	stats_changed.emit()
	return true


## Respec gratuito: devolve todos os pontos gastos (exceto base da classe)
func respec_status() -> void:
	var total_gasto: int = 0
	for s in ["forca", "agilidade", "mente", "vitalidade"]:
		var base: int = cls.base_status.get(s, 10)
		var growth: int = cls.status_growth.get(s, 0)
		if level > 1:
			base += growth * (level - 1)
		var gasto: int = int(status[s]) - base
		if gasto > 0:
			total_gasto += gasto
			status[s] = base
	status_points += total_gasto
	stats_changed.emit()


## Retorna bônus de combate dos status (para SkillExecutor/Player)
## Força: +1% dano melee/ponto | Agilidade: +0.5% vel mov/ataque | Mente: +1% dano mágico + 2 MP | Vitalidade: +5 HP
func status_bonus() -> Dictionary:
	return {
		"melee_damage_pct": status["forca"] * 0.01,
		"move_speed_pct": status["agilidade"] * 0.005,
		"attack_speed_pct": status["agilidade"] * 0.005,
		"spell_damage_pct": status["mente"] * 0.01,
		"max_mp_bonus": status["mente"] * 2,
		"max_hp_bonus": status["vitalidade"] * 5,
	}


## Retorna o rank atual de um nó da árvore de habilidades
## Conta quantas vezes o nó foi comprado (cada compra = +1 rank)
func get_tree_node_rank(node_id: StringName) -> int:
	return tree_unlocked.count(node_id)


## Gasta 1 ponto de árvore no nó indicado
## Retorna true se comprou
func spend_tree_point(node_id: StringName) -> bool:
	if tree_points <= 0:
		return false
	# Verifica pré-requisitos
	var tree := DB.get_skill_tree(cls.id)
	if not tree:
		return false
	var node := tree.get_node(node_id)
	if not node:
		return false
	if not node.is_available(tree_unlocked):
		return false
	# Verifica se já está no rank máximo
	var current_rank := get_tree_node_rank(node_id)
	if current_rank >= node.max_rank:
		return false
	# Compra
	tree_points -= 1
	tree_unlocked.append(node_id)
	# Se for nova skill, atualiza a skill bar
	if node.is_new_skill:
		refresh_skill_bar()
	stats_changed.emit()
	return true


## Respec da árvore de habilidades: devolve todos os pontos gastos e desbloqueia todos os nós
func respec_tree() -> void:
	var spent := tree_unlocked.size()
	# Coleta skill_ids de nós "nova skill" antes de limpar
	var tree := DB.get_skill_tree(cls.id)
	var tree_skill_ids: Array[StringName] = []
	if tree:
		for node_id in tree_unlocked:
			var node := tree.get_node(node_id)
			if node and node.is_new_skill:
				tree_skill_ids.append(node.skill_id)
	tree_points += spent
	tree_unlocked.clear()
	# Remove skills desbloqueadas pela árvore do skill bar
	for sid in tree_skill_ids:
		var idx := skill_bar.find(sid)
		while idx >= 0:
			skill_bar[idx] = &""
			idx = skill_bar.find(sid)
	refresh_skill_bar()
	stats_changed.emit()


## Retorna bônus acumulado da árvore para uma skill específica
func get_tree_bonus_for_skill(skill_id: StringName) -> Dictionary:
	var bonus: Dictionary = {}
	var tree := DB.get_skill_tree(cls.id)
	if not tree:
		return bonus
	for node_id in tree_unlocked:
		var node := tree.get_node(node_id)
		if node and node.skill_id == skill_id:
			var rank := get_tree_node_rank(node_id)
			for key in node.per_rank:
				bonus[key] = bonus.get(key, 0) + node.per_rank[key] * rank
	return bonus


func unlocked_skills() -> Array[SkillData]:
	var out: Array[SkillData] = []
	for s in cls.skills:
		if s.unlock_level <= level:
			out.append(s)
	return out


## Filiação em guilda
func join_guild(guild_id: StringName) -> bool:
	if guild_id in guild_members:
		return false
	guild_members.append(guild_id)
	if not guild_ranks.has(guild_id):
		guild_ranks[guild_id] = 0
	stats_changed.emit()
	return true


## Retorna rank na guilda (0 = membro, 1+ = ranks)
func get_guild_rank(guild_id: StringName) -> int:
	return guild_ranks.get(guild_id, -1)


## Promove na guilda
func promote_guild(guild_id: StringName) -> bool:
	if not (guild_id in guild_members):
		return false
	var current: int = guild_ranks.get(guild_id, 0)
	guild_ranks[guild_id] = current + 1
	stats_changed.emit()
	return true


## Aceita contrato
func accept_contract(contract_id: StringName) -> bool:
	if contract_id in active_contracts or contract_id in completed_contracts:
		return false
	active_contracts.append(contract_id)
	stats_changed.emit()
	return true


## Completa contrato
func complete_contract(contract_id: StringName) -> bool:
	if not (contract_id in active_contracts):
		return false
	active_contracts.erase(contract_id)
	completed_contracts.append(contract_id)
	stats_changed.emit()
	return true


## Coloca habilidades recém-desbloqueadas em slots vazios
func refresh_skill_bar() -> void:
	for s in unlocked_skills():
		if skill_bar.has(s.id):
			continue
		for i in SKILL_SLOTS:
			if skill_bar[i] == &"":
				skill_bar[i] = s.id
				break


func skill_in_slot(i: int) -> SkillData:
	if i < 0 or i >= skill_bar.size() or skill_bar[i] == &"":
		return null
	return DB.get_skill(cls, skill_bar[i])


func racial_skill() -> SkillData:
	return DB.racial_breath if race.breath_element != "" else null


func assign_skill(slot: int, id: StringName) -> void:
	var prev := skill_bar.find(id)
	if prev >= 0:
		skill_bar[prev] = skill_bar[slot]
	skill_bar[slot] = id
	stats_changed.emit()


# ------------------------------------------------------------ EQUIPAMENTO

func can_use_category(it: Item) -> bool:
	if it.slot == "weapon":
		# Se allowed_weapons está vazio, classe não pode equipar nenhuma arma
		if cls.allowed_weapons.is_empty():
			return false
		return it.category in cls.allowed_weapons
	if it.slot == "offhand":
		# Se allowed_offhands está vazio, não pode equipar nada na mão secundária
		if cls.allowed_offhands.is_empty():
			return false
		return it.category in cls.allowed_offhands
	return true


## "" se pode equipar, senão o motivo
func equip_problem(it: Item) -> String:
	if level + race.item_level_leeway < it.required_level():
		return "Nível insuficiente (requer %d)" % it.required_level()
	if not can_use_category(it):
		return "%s não sabe usar %s" % [cls.display_name, DB.CATEGORY_NAMES.get(it.category, "isso")]
	if it.slot == "offhand":
		var w: Item = equipment.weapon
		if w and w.two_handed and not (w.category == "bow" and it.category == "quiver"):
			return "Sua arma é de duas mãos"
	return ""


## Equipa um item; retorna os itens que saíram (0, 1 ou 2)
func equip(it: Item) -> Array[Item]:
	var out: Array[Item] = []
	var old: Item = equipment[it.slot]
	if old:
		out.append(old)
	equipment[it.slot] = it
	# Arma de duas mãos libera a mão secundária (exceto arco + aljava)
	if it.slot == "weapon" and it.two_handed and equipment.offhand:
		var off: Item = equipment.offhand
		if not (it.category == "bow" and off.category == "quiver"):
			out.append(off)
			equipment.offhand = null
	stats_changed.emit()
	return out


func unequip(slot: String) -> Item:
	var old: Item = equipment[slot]
	equipment[slot] = null
	stats_changed.emit()
	return old


# ------------------------------------------------------------ SAVE

func to_dict() -> Dictionary:
	var eq: Dictionary = {}
	for s in DB.EQUIP_SLOTS:
		eq[s] = equipment[s].to_dict() if equipment[s] else null
	var bar: Array = []
	for id in skill_bar:
		bar.append(String(id))
	var cons: Array = []
	for item in consumable_slots:
		cons.append(item.to_dict() if item else null)
	var cons_cds: Dictionary = {}
	for key in consumable_cooldowns:
		cons_cds[String(key)] = consumable_cooldowns[key]
	var st: Dictionary = {}
	for s in ["forca", "agilidade", "mente", "vitalidade"]:
		st[s] = status[s]
	var tree_unlocked_str: Array = []
	for id in tree_unlocked:
		tree_unlocked_str.append(String(id))
	var guild_members_str: Array = []
	for gid in guild_members:
		guild_members_str.append(String(gid))
	var guild_ranks_dict: Dictionary = {}
	for gid in guild_ranks:
		guild_ranks_dict[String(gid)] = guild_ranks[gid]
	var active_contracts_str: Array = []
	for cid in active_contracts:
		active_contracts_str.append(String(cid))
	var completed_contracts_str: Array = []
	for cid in completed_contracts:
		completed_contracts_str.append(String(cid))
	return {
		"name": hero_name, "race": String(race.id), "class": String(cls.id), "sex": sex, "tint": tint.to_html(),
		"background": background, "difficulty": difficulty, "hardcore": hardcore, "free_bonus": free_bonus,
		"abilities": base_abilities, "level": level, "xp": xp, "gold": gold, "essence": essence, "points": unspent_points,
		"inventory": inventory.to_array(), "equipment": eq, "skill_bar": bar, "kills": kills,
		"deepest": deepest, "play_time": play_time,
		"consumable_slots": cons, "consumable_cooldowns": cons_cds,
		"status": st, "status_points": status_points,
		"tree_points": tree_points, "tree_unlocked": tree_unlocked_str,
		"guild_members": guild_members_str, "guild_ranks": guild_ranks_dict,
		"active_contracts": active_contracts_str, "completed_contracts": completed_contracts_str,
		## v6 novo (Fase 11):
		"guild_joined": String(guild_joined), "guild_rank": guild_rank, "guild_xp": guild_xp,
		"contracts_active": contracts_active.map(func(c): return String(c)),
		"contracts_completed": contracts_completed,
		"rank_f_s": rank_f_s,
		"player_guild_id": String(player_guild_id),
		"membro_guilda_jogador": String(membro_guilda_jogador),
	}


static func from_dict(d: Dictionary) -> Hero:
	var h := Hero.new()
	h.hero_name = d.get("name", "Herói")
	h.race = DB.get_race(StringName(d.get("race", "humano")))
	h.cls = DB.get_class_data(StringName(d.get("class", "guerreiro")))
	h.sex = d.get("sex", "m")
	h.tint = Color.html(d.get("tint", "ffffffff"))
	h.background = d.get("background", "soldado")
	h.difficulty = int(d.get("difficulty", 0))
	h.hardcore = d.get("hardcore", false)
	h.free_bonus = d.get("free_bonus", {})
	var ab: Dictionary = d.get("abilities", {})
	for a in DB.ABILITIES:
		h.base_abilities[a] = int(ab.get(a, 10))
	h.level = int(d.get("level", 1))
	h.xp = int(d.get("xp", 0))
	h.gold = int(d.get("gold", 0))
	h.essence = int(d.get("essence", 0))
	h.unspent_points = int(d.get("points", 0))
	h.kills = int(d.get("kills", 0))
	h.deepest = int(d.get("deepest", 1))
	h.play_time = float(d.get("play_time", 0.0))
	h._make_inventory()
	h.inventory.load_array(d.get("inventory", []))
	var eq: Dictionary = d.get("equipment", {})
	for s in DB.EQUIP_SLOTS:
		if eq.get(s) is Dictionary:
			h.equipment[s] = Item.from_dict(eq[s])
	var bar: Array = d.get("skill_bar", [])
	for i in mini(bar.size(), SKILL_SLOTS):
		h.skill_bar[i] = StringName(bar[i])
	# Consumíveis
	var cons: Array = d.get("consumable_slots", [])
	h.consumable_slots.resize(9)
	for i in 9:
		if i < cons.size() and cons[i] is Dictionary:
			h.consumable_slots[i] = Item.from_dict(cons[i])
		else:
			h.consumable_slots[i] = null
	var cons_cds: Dictionary = d.get("consumable_cooldowns", {})
	for key in cons_cds:
		h.consumable_cooldowns[StringName(key)] = float(cons_cds[key])
	# Status ARPG
	var st: Dictionary = d.get("status", {})
	for s in ["forca", "agilidade", "mente", "vitalidade"]:
		h.status[s] = int(st.get(s, h.cls.base_status.get(s, 10)))
	h.status_points = int(d.get("status_points", 0))
	# Arvore de habilidades
	h.tree_points = int(d.get("tree_points", 0))
	var tree_unlocked_str: Array = d.get("tree_unlocked", [])
	for sid in tree_unlocked_str:
		h.tree_unlocked.append(StringName(sid))
	# Guildas (Fase 11)
	var guild_members_str: Array = d.get("guild_members", [])
	for gid in guild_members_str:
		h.guild_members.append(StringName(gid))
	var guild_ranks_dict: Dictionary = d.get("guild_ranks", {})
	for gid in guild_ranks_dict:
		h.guild_ranks[StringName(gid)] = int(guild_ranks_dict[gid])
	var active_contracts_str: Array = d.get("active_contracts", [])
	for cid in active_contracts_str:
		h.active_contracts.append(StringName(cid))
	var completed_contracts_str: Array = d.get("completed_contracts", [])
	for cid in completed_contracts_str:
		h.completed_contracts.append(StringName(cid))
	## v6 novo (Fase 11):
	h.guild_joined = StringName(d.get("guild_joined", ""))
	h.guild_rank = d.get("guild_rank", "F")
	h.guild_xp = int(d.get("guild_xp", 0))
	var contracts_active_str: Array = d.get("contracts_active", [])
	for cid in contracts_active_str:
		h.contracts_active.append(StringName(cid))
	h.contracts_completed = int(d.get("contracts_completed", 0))
	h.rank_f_s = d.get("rank_f_s", "F")
	h.player_guild_id = StringName(d.get("player_guild_id", ""))
	h.membro_guilda_jogador = StringName(d.get("membro_guilda_jogador", ""))
	h._recalc_status()
	h.refresh_skill_bar()
	return h
