class_name DialogueEngine
extends RefCounted
## Motor de diálogo (MECANICAS #7): percorre o grafo de `DialogueData`,
## pagina o texto, filtra escolhas por condição e aplica efeitos.
## Não desenha UI - emite sinais; a UI (tarefa 2.2) consome.
## Efeitos (um por linha em `DialogueChoice.effects`):
##   flag nome | flag nome=valor   - flag narrativa (Game.flags)
##   gold n | gold -n              - ouro do herói
##   xp n                          - experiência
##   item id_base [qtd]            - adiciona itens comuns
##   rep raca +n | -n              - reputação (0-4)
##   ignorancia -n                 - ignorância do Laço-Vivo (0-10)
##   quest id=estagio              - define estágio da quest (Fase 4)
##   comercio raca                 - abre a UI de comércio no território (Fase 5.5)

signal page_shown(text: String, portrait: String)
signal choices_shown(choices: Array[DialogueChoice])
signal dialogue_ended

var data: DialogueData
var current: DialogueNode
var _page := 0
var _awaiting_choice := false


func start(p_data: DialogueData) -> void:
	data = p_data
	# Fase 4: conversa alimenta objetivos TALK das quests ativas
	Game.quest_log.notify_talk(p_data.id)
	current = data.node(data.start_id)
	_page = 0
	_awaiting_choice = false
	if current == null:
		dialogue_ended.emit()
		return
	page_shown.emit(current.page(0), _portrait(current))


## Avança uma página; na última, mostra as escolhas visíveis ou encerra.
func advance() -> void:
	if current == null or _awaiting_choice:
		return
	if _page + 1 < current.page_count():
		_page += 1
		page_shown.emit(current.page(_page), _portrait(current))
		return
	var visible := visible_choices()
	if visible.is_empty():
		_end()
		return
	_awaiting_choice = true
	choices_shown.emit(visible)


## Escolhe a opção `i` (índice na lista de escolhas VISIVES).
func choose(i: int) -> void:
	if not _awaiting_choice:
		return
	var visible := visible_choices()
	if i < 0 or i >= visible.size():
		return
	_awaiting_choice = false
	var c: DialogueChoice = visible[i]
	apply_effects(c.effects)
	if c.next_id == &"":
		_end()
		return
	current = data.node(c.next_id)
	_page = 0
	if current == null:
		_end()
		return
	page_shown.emit(current.page(0), _portrait(current))


## Encerra imediatamente (usado pelo botão de fechar da UI).
func stop() -> void:
	_awaiting_choice = false
	_end()


func visible_choices() -> Array[DialogueChoice]:
	var out: Array[DialogueChoice] = []
	if current == null:
		return out
	for c in current.choices:
		if ConditionResolver.eval(c.condition):
			out.append(c)
	return out


func _end() -> void:
	current = null
	dialogue_ended.emit()


func _portrait(n: DialogueNode) -> String:
	return n.portrait if n.portrait != "" else data.portrait


# ------------------------------------------------------------------ EFEITOS

## Aplica efeitos textuais (um por linha). Estático: reutilizado pelas quests (Fase 4).
static func apply_effects(effects: String) -> void:
	for line in effects.split("\n", false):
		var seg: String = line.strip_edges()
		if seg == "":
			continue
		var parts: PackedStringArray = seg.split(" ", false)
		if parts.is_empty():
			continue
		match parts[0].to_lower():
			"flag":
				if parts.size() >= 2 and parts[1].contains("="):
					var kv := parts[1].split("=", false)
					Game.flags[kv[0]] = kv[1] if kv.size() > 1 else ""
					Game.quest_log.notify_flag(StringName(kv[0]))  # Fase 4
				elif parts.size() >= 2:
					Game.flags[parts[1]] = true
					Game.quest_log.notify_flag(StringName(parts[1]))  # Fase 4
			"gold":
				if Game.hero and parts.size() >= 2:
					Game.hero.gold = maxi(0, Game.hero.gold + _int(parts[1]))
					Game.hero.gold_changed.emit(Game.hero.gold)
			"xp":
				if Game.hero and parts.size() >= 2:
					Game.hero.add_xp(_int(parts[1]))
			"item":
				if Game.hero and parts.size() >= 2:
					var qty := _int(parts[2]) if parts.size() >= 3 else 1
					for i in maxi(1, qty):
						Game.hero.inventory.add(DB.create_item(StringName(parts[1]), maxi(1, Game.hero.level), 0))
			"rep":
				if parts.size() >= 3:
					var rid := StringName(parts[1])
					var v: int = int(Game.reputation.get(rid, 0)) + _int(parts[2])
					Game.reputation[rid] = clampi(v, 0, 4)
			"ignorancia":
				Game.ignorance = clampi(Game.ignorance + _int(parts[1]), 0, 10)
			"quest":
				if parts.size() >= 2 and parts[1].contains("="):
					var kv := parts[1].split("=", false)
					Game.quests[kv[0]] = {"stage": _int(kv[1]) if kv.size() > 1 else 0}
			"comercio":
				# Fase 5.5: o líder libera a negociação - o HUD abre o TradePanel
				if parts.size() >= 2:
					Game.trade_requested.emit(StringName(parts[1]))
			_:
				push_warning("[dialogo] efeito desconhecido: %s" % seg)


static func _int(s: String) -> int:
	var t := s.strip_edges()
	if t.is_valid_int():
		return int(t)
	# aceita +n / -n
	if t.begins_with("+") and t.substr(1).is_valid_int():
		return int(t.substr(1))
	return 0
