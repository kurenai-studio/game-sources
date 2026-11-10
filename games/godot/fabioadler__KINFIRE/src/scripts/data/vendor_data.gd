class_name VendorData
extends Resource
## Fornecedor de um território (Fase 5.1): estoque rotativo diário e
## especialidades regionais - o território paga menos pelo que produz e
## mais pelo que não produz; rotas comerciais emergem (REGRAS #10,
## MECANICAS #10).

@export var id: StringName
@export var display_name: String = ""
## Território do fornecedor (id de `data/races/*.tres`)
@export var race: StringName
@export var greeting: String = ""
## Categorias (`cat` em `DB.BASES`) que o território PRODUZ - aparecem
## com frequência triplicada no estoque local e valem menos aqui (5.2)
@export var specialties: Array[StringName] = []
## Slots de estoque re-sorteados às 06:00 (REGRAS #14)
@export var stock_size: int = 6
## Orçamento de raridades do dia: chance de um slot sair Raro
@export var rare_chance: float = 0.15


## Estoque do dia - determinístico por (id, dia): mesmo dia, mesmo estoque
## (verificável no smoke); comprar reduz (5.2 persiste), às 06:00 re-estoca.
## Cada entrada: {"base": StringName, "level": int, "rarity": int, "price": int}.
## Preço base = valor de venda (REGRAS #8): (5 + nívelx3) x (1 + raridadex2).
func stock_for(day: int, region_level: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d" % [String(id), day])
	var pool_specialty: Array[StringName] = []
	var pool_rest: Array[StringName] = []
	for k in DB.BASES:
		if k == &"wood_sword":
			continue  # espada de treino não é mercadoria
		var b: Dictionary = DB.BASES[k]
		if b.get("slot", "") == "":
			continue
		# armaduras/joias não têm "cat" (só armas/offhands) - nunca são
		# especialidade; entram no pool geral de mercadorias
		if b.get("cat", &"") in specialties:
			pool_specialty.append(k)
		else:
			pool_rest.append(k)
	var out: Array[Dictionary] = []
	for i in stock_size:
		# 45% dos slots vêm da especialidade local (vs ~1/12 por categoria
		# no resto do pool) - o território vende o que produz
		var base: StringName
		if not pool_specialty.is_empty() and rng.randf() < 0.45:
			base = pool_specialty[rng.randi_range(0, pool_specialty.size() - 1)]
		elif not pool_rest.is_empty():
			base = pool_rest[rng.randi_range(0, pool_rest.size() - 1)]
		else:
			continue
		var level := maxi(1, clampi(region_level + rng.randi_range(-2, 1), 1, 9999))
		var rarity := 2 if rng.randf() < rare_chance else (1 if rng.randf() < 0.35 else 0)
		out.append({
			"base": base,
			"level": level,
			"rarity": rarity,
			"price": _base_value(level, rarity),
		})
	return out


## Valor de um item (REGRAS #8): (5 + nívelx3) x (1 + raridadex2)
static func _base_value(level: int, rarity: int) -> int:
	return int(round((5.0 + level * 3.0) * (1.0 + rarity * 2.0)))
