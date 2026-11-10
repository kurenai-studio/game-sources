class_name Market
extends RefCounted
## Economia dinâmica (Fase 5.2): preços por oferta/demanda - REGRAS #10,
## MECANICAS #10. Estado no Game.market: {território: {"demand": {cat: float},
## "sold": [índices do estoque do dia]}}.
##
## - Demanda por categoria ∈ [0.6, 1.5], inicia 1.0.
## - Vender N itens da categoria reduz 3% por item; comprar eleva 3% por item.
## - A cada virada de dia (06:00, REGRAS #14) a demanda recupera 5% rumo ao
##   nível natural: 0.7 para o que o território PRODUZ (inundado), 1.3 para
##   o que não produz (escasso) - "cada território paga mais pelo que não
##   produz e menos pelo que produz".
## - Preço de compra = valor base x demanda x fator da especialidade
##   (produto local x0.7) x (1 - desconto de reputação, 5.3).
## - Preço de venda = valor base x 40% (REGRAS #8) x demanda x fator de
##   escassez (categoria que o território NAO produz x1.25; produz x0.8).
##   Rotas comerciais emergem: comprar barato no produtor, vender caro
##   em quem não produz.

const DEMAND_MIN := 0.6
const DEMAND_MAX := 1.5
const SELL_STEP := 0.03        ## por item vendido
const BUY_STEP := 0.03         ## por item comprado
const DAY_RECOVERY := 0.05     ## por dia rumo ao nível natural
const NATURAL_PRODUCED := 0.7  ## nível natural da especialidade local
const NATURAL_SCARCE := 1.3    ## nível natural do que não produz
const PRODUCER_BUY := 0.45    ## produto local sai barato na compra (dump do produtor)
const SCARCE_SELL := 1.25      ## o que falta paga premium na venda
const FLOODED_SELL := 0.8      ## o que sobra paga pouco na venda
const VENDOR_BUYS_AT := 0.40   ## REGRAS #8: vendor compra a 40% do valor


## Dia de mercado: vira às 06:00 (REGRAS #14) - dia do estoque dos vendors
static func market_day() -> int:
	return floori(Game.world_time - 0.25)


## Demanda atual da categoria no território (default 1.0)
static func demand(race: StringName, cat: StringName) -> float:
	var r: Dictionary = Game.market.get(race, {})
	var d: Dictionary = r.get("demand", {})
	return clampf(float(d.get(cat, 1.0)), DEMAND_MIN, DEMAND_MAX)


## Nível natural: especialidade local é barata, o resto é caro
static func natural(race: StringName, cat: StringName) -> float:
	var v: VendorData = DB.vendor(race)
	if v != null and cat in v.specialties:
		return NATURAL_PRODUCED
	return NATURAL_SCARCE


## Jogador compra do vendor: eleva a demanda e consome o slot do estoque
static func on_buy(race: StringName, cat: StringName, stock_index := -1, amount := 1) -> void:
	_shift(race, cat, BUY_STEP * amount)
	if stock_index >= 0:
		var sold: Array = Game.market.get(race, {}).get("sold", [])
		if not sold.has(stock_index):
			sold.append(stock_index)
		_state(race)["sold"] = sold


## Jogador vende ao vendor: derruba a demanda 3% por item
static func on_sell(race: StringName, cat: StringName, amount := 1) -> void:
	_shift(race, cat, -SELL_STEP * amount)


## Virada do dia (06:00): demanda recupera 5% rumo ao natural; estoque vendido
## sai com o dia (o re-estoque é determinístico por dia, VendorData.stock_for)
static func new_day() -> void:
	for race in Game.market.keys():
		var state: Dictionary = Game.market[race]
		state["sold"] = []
		var dem: Dictionary = state.get("demand", {})
		for cat in dem.keys():
			var nat := natural(race, cat)
			var cur := float(dem[cat])
			dem[cat] = cur + signf(nat - cur) * minf(DAY_RECOVERY, absf(nat - cur))


## Preço de compra (player -> vendor) de uma entrada do estoque
static func buy_price(race: StringName, entry: Dictionary, reputation := -1) -> int:
	var cat := category_of(entry["base"])
	var v: VendorData = DB.vendor(race)
	var factor := PRODUCER_BUY if (v != null and cat in v.specialties) else 1.0
	return int(round(float(entry["price"]) * demand(race, cat) * factor * (1.0 - rep_discount(reputation, race))))


## Preço de venda (vendor -> player) de um item do inventário
static func sell_price(race: StringName, item: Item) -> int:
	var cat := StringName(item.category) if item.category != "" else category_of(item.base_id)
	var v: VendorData = DB.vendor(race)
	var factor := FLOODED_SELL if (v != null and cat in v.specialties) else SCARCE_SELL
	var base_price = int(round(VendorData._base_value(item.item_level, item.rarity) * VENDOR_BUYS_AT \
		* demand(race, cat) * factor))
	
	# Aplicar bonus de MerchantGuild se herói é membro
	if Game.hero and Game.hero.guild_joined == &"mercadores":
		var merchant_bonus = MerchantGuild.get_sell_price_bonus(Game.hero)
		base_price = int(float(base_price) * (merchant_bonus / 0.40))  # Normalizar vs base 40%
	
	return base_price


## Desconto por reputação (REGRAS #10, MECANICAS #10): 0/5/10/15/20% por tier
## 0-4. Sem `reputation` explícito, usa a reputação do herói COM O
## TERRITÓRIO do vendor (não a raça do herói - cada território lembra).
static func rep_discount(reputation := -1, race := &"") -> float:
	var rep := 0
	if reputation >= 0:
		rep = clampi(reputation, 0, 4)
	elif race != &"":
		rep = clampi(int(Game.reputation.get(race, 0)), 0, 4)
	elif Game.hero != null:
		rep = clampi(int(Game.reputation.get(Game.hero.race.id, 0)), 0, 4)
	return 0.05 * rep


## Nome do tier de reputação (MECANICAS #10) - exibido na UI de comércio
static func tier_name(rep: int) -> String:
	return ["Estranho", "Conhecido", "Respeitado", "Honrado", "Laço"][clampi(rep, 0, 4)]


## Slot do estoque já vendido no dia?
static func is_sold(race: StringName, stock_index: int) -> bool:
	return Game.market.get(race, {}).get("sold", []).has(stock_index)


## Categoria de uma base (armaduras/joias sem "cat" contam como "equipamento")
static func category_of(base: StringName) -> StringName:
	var b: Dictionary = DB.BASES.get(base, {})
	var cat := StringName(b.get("cat", "equipamento"))
	return cat


static func _shift(race: StringName, cat: StringName, delta: float) -> void:
	var state := _state(race)
	var dem: Dictionary = state.get("demand", {})
	dem[cat] = clampf(float(dem.get(cat, 1.0)) + delta, DEMAND_MIN, DEMAND_MAX)
	state["demand"] = dem


static func _state(race: StringName) -> Dictionary:
	if not Game.market.has(race):
		Game.market[race] = {"demand": {}, "sold": []}
	return Game.market[race]
