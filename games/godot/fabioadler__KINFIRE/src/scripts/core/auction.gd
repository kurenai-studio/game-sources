class_name Auction
extends RefCounted
## Casa de leilões da Guilda dos Aventureiros (Fase 5.4, REGRAS #9,
## MECANICAS #10) - só na capital humana (Porto Franco). 6 slots diários
## de itens Raro+ rotativos e determinísticos por dia; lance mínimo sobe
## 10% por contra-lance de NPC rival (REGRAS #9); um slot especial aceita
## ESSENCIA (moeda dura, REGRAS #9); relíquias de chefe aparecem raramente.
##
## Estado em Game.auction: {"day": int, "slots": [...]} - cada slot:
##   base, level, rarity, value, currency ("gold"/"essence"),
##   min_bid, rivals_left, sold, unique.
## O refresh é lazy: _ensure() re-sorteia quando o dia de mercado vira
## (Market.market_day(), às 06:00 - REGRAS #14).

const SLOT_COUNT := 6
const UNIQUE_CHANCE := 0.08        ## chance de slot ser relíquia de chefe
const UNIQUE_BONUS_LEVEL := 3      ## relíquia vem com nível extra
const BID_PREMIUM := 1.2           ## lance inicial = valor x 1.2 (prêmio)
const ESSENCE_INDEX := 5           ## último slot leiloa em essência
const ESSENCE_DIVISOR := 20        ## valor / 20 = lance inicial em essência


## Slots do dia (re-sorteia na virada do dia de mercado)
static func slots() -> Array:
	_ensure()
	return Game.auction["slots"]


## Lance atual (mínimo) de um slot
static func min_bid(slot_index: int) -> int:
	var s: Dictionary = slots()[slot_index]
	return int(s["min_bid"])


## O jogador dá lance: rival pode contra-lançar (mínimo +10%). Retorna
## {"result": "won"|"outbid"|"broke"|"full"|"sold", "item": Item?}
static func place_bid(slot_index: int) -> Dictionary:
	var s: Dictionary = slots()[slot_index]
	var out: Dictionary = {"result": "", "item": null}
	if bool(s["sold"]):
		out["result"] = "sold"
		return out
	var cost := int(s["min_bid"])
	var currency: String = s["currency"]
	var hero := Game.hero
	if currency == "essence":
		if hero.essence < cost:
			out["result"] = "broke"
			return out
	elif hero.gold < cost:
		out["result"] = "broke"
		return out
	# NPC rival contra-lança: nada é cobrado, mas o mínimo sobe 10%
	# (REGRAS #9) e o jogador precisa insistir
	if int(s["rivals_left"]) > 0:
		s["min_bid"] = ceili(cost * 1.10)
		s["rivals_left"] = int(s["rivals_left"]) - 1
		out["result"] = "outbid"
		return out
	# Lance vencedor: item direto para o inventário
	var it := DB.create_item(s["base"], int(s["level"]), int(s["rarity"]))
	if not hero.inventory.add(it):
		out["result"] = "full"
		return out
	if currency == "essence":
		hero.add_essence(-cost)
	else:
		hero.add_gold(-cost)
	s["sold"] = true
	out["result"] = "won"
	out["item"] = it
	return out


# ------------------------------------------------------------------ INTERNAS

## Garante que o estado corresponde ao dia de mercado atual
static func _ensure() -> void:
	var day := Market.market_day()
	var st: Dictionary = Game.auction
	if st.is_empty() or int(st.get("day", -1)) != day:
		Game.auction = _roll(day)


## Sorteio determinístico dos 6 slots do dia
static func _roll(day: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("leilao|%d" % day)
	var level := maxi(3, Game.hero.level + 1) if Game.hero != null else 5
	var lvl_range := level + 2
	var out: Array = []
	for i in SLOT_COUNT:
		var rarity: int = Item.Rarity.LEGENDARY if rng.randf() < 0.25 else Item.Rarity.RARE
		var unique := false
		var lvl := maxi(1, clampi(level + rng.randi_range(-1, 2), 1, 9999))
		# relíquia de chefe: rara, Lendária e acima do nível da casa
		if rng.randf() < UNIQUE_CHANCE:
			unique = true
			rarity = Item.Rarity.LEGENDARY
			lvl = lvl + UNIQUE_BONUS_LEVEL
		# só bases de equipamento (armas/armaduras/joias com slot)
		var base: StringName = _roll_base(rng)
		var value := VendorData._base_value(lvl, rarity)
		var essence := i == ESSENCE_INDEX
		var minb := ceili(float(value) / float(ESSENCE_DIVISOR)) if essence \
			else ceili(float(value) * BID_PREMIUM)
		# 1 a 3 contra-lances de rivais - determinísticos por (dia, slot)
		var rr := RandomNumberGenerator.new()
		rr.seed = hash("leilao|%d|%d" % [day, i])
		var rivals := 1 + (rr.randi() % 3)
		out.append({
			"base": base, "level": lvl, "rarity": rarity, "value": value,
			"currency": "essence" if essence else "gold",
			"min_bid": minb, "rivals_left": rivals, "sold": false,
			"unique": unique,
		})
	return {"day": day, "slots": out}


## Base de equipamento (tem slot) - mercadoria digna de leilão
static func _roll_base(rng: RandomNumberGenerator) -> StringName:
	var pool: Array[StringName] = []
	for k in DB.BASES:
		var b: Dictionary = DB.BASES[k]
		if k == &"wood_sword" or b.get("slot", "") == "":
			continue
		pool.append(k)
	if pool.is_empty():
		return &""
	return pool[rng.randi_range(0, pool.size() - 1)]
