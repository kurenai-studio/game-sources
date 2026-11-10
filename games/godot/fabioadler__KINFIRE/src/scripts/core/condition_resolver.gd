class_name ConditionResolver
extends RefCounted
## Avalia condições de diálogo (MECANICAS #7). Puro e sem estado - lê Game/Hero.
## Sintaxe - um segmento por vírgula (AND lógico); prefixo `!` nega o segmento:
##   flag nome            - flag narrativa verdadeira
##   flag nome=valor      - flag igual ao valor (string)
##   raca = id            - raça do herói (ex.: `raca = elfo_floresta`)
##   classe = id          - classe do herói
##   nivel >= n           - nível do herói (aceita = == != > >= < <=)
##   ignorancia > n       - ignorância do Laço-Vivo (Game.ignorance)
##   rep raca >= n        - reputação com a raça (0-4)
##   quest id >= k        - estágio da quest (Fase 4)
##   item id_base [n]     - possui n (padrão 1) do item-base (inventário+equipado)
## Condição vazia é sempre verdadeira; comando desconhecido é permissivo.

const OPS := ["=", "==", "!=", ">", ">=", "<", "<="]


static func eval(condition: String) -> bool:
	if condition.strip_edges() == "":
		return true
	for seg in condition.split(","):
		if not _eval_one(seg.strip_edges()):
			return false
	return true


static func _eval_one(seg: String) -> bool:
	var negated := false
	if seg.begins_with("!"):
		negated = true
		seg = seg.substr(1).strip_edges()
	var parts: PackedStringArray = seg.split(" ", false)
	if parts.is_empty():
		return true
	var ok := true
	match parts[0].to_lower():
		"flag":
			if parts.size() >= 2 and parts[1].contains("="):
				var kv := parts[1].split("=", false)
				ok = str(Game.flags.get(kv[0], "")) == (kv[1] if kv.size() > 1 else "")
			elif parts.size() >= 2:
				ok = bool(Game.flags.get(parts[1], false))
			else:
				ok = false
		"raca":
			ok = Game.hero != null and parts.size() >= 3 and Game.hero.race.id == _value_id(parts)
		"classe":
			ok = Game.hero != null and parts.size() >= 3 and Game.hero.cls.id == _value_id(parts)
		"nivel":
			ok = _compare(Game.hero.level if Game.hero else 0, parts)
		"ignorancia":
			ok = _compare(Game.ignorance, parts)
		"rep":
			# rep raca >= n
			if parts.size() >= 2:
				var v: int = int(Game.reputation.get(StringName(parts[1]), 0))
				ok = _compare(v, parts.slice(2))
			else:
				ok = false
		"quest":
			# quest id >= k
			if parts.size() >= 2:
				var q: Dictionary = Game.quests.get(StringName(parts[1]), {})
				ok = _compare(int(q.get("stage", -1)), parts.slice(2))
			else:
				ok = false
		"item":
			if parts.size() >= 2:
				var count := int(parts[2]) if parts.size() >= 3 and parts[2].is_valid_int() else 1
				ok = Game.hero != null and Game.hero.count_item(StringName(parts[1])) >= count
			else:
				ok = false
		_:
			# Identificador simples sem comando (ex: "misterio_7_complete"): trata como flag booleana
			if parts.size() == 1 and Game != null and Game.flags != null:
				ok = bool(Game.flags.get(parts[0], false))
			else:
				ok = true
	return ok != negated


## Id da direita de comparações `cmd = id` (posição após o operador)
static func _value_id(parts: PackedStringArray) -> StringName:
	for i in parts.size():
		if parts[i] in OPS:
			return StringName(parts[i + 1]) if i + 1 < parts.size() else &""
	return &""


## Compara um inteiro contra `<...> op n` (varre partes procurando o operador)
static func _compare(value: int, parts: PackedStringArray) -> bool:
	var op := "="
	var rhs := 0
	for i in parts.size():
		if parts[i] in OPS:
			op = parts[i]
			rhs = int(parts[i + 1]) if i + 1 < parts.size() and parts[i + 1].is_valid_int() else 0
			break
		elif parts[i].is_valid_int():
			rhs = int(parts[i])
			break
	match op:
		"=", "==": return value == rhs
		"!=": return value != rhs
		">": return value > rhs
		">=": return value >= rhs
		"<": return value < rhs
		"<=": return value <= rhs
	return false
