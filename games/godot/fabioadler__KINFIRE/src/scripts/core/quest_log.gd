class_name QuestLog
extends RefCounted
## Log de quests (Fase 4): estado e progresso sobre `Game.quests`
## (formato do save: id -> {"stage": int, "prog": Array, "done": bool}).
## Retrocompatível com o efeito de diálogo `quest id=k` (escreve {"stage": k})
## e com a condição `quest id >= k` (estágio além do último = concluída).

signal quest_started(id: StringName)
signal quest_advanced(id: StringName, stage: int)
signal quest_completed(id: StringName)
signal objective_updated(id: StringName)

## Quest em destaque no tracker do HUD (vazia = a primeira ativa, main primeiro)
var tracked: StringName = &""

const FINAL_QUEST := &"ato3_8"
const FRAGMENTS_FOR_GOLDEN := 8


# ------------------------------------------------------------------ ESTADO

func state(id: StringName) -> Dictionary:
	return Game.quests.get(id, {})


func is_active(id: StringName) -> bool:
	var s := state(id)
	return not s.is_empty() and not bool(s.get("done", false))


func is_completed(id: StringName) -> bool:
	var q: QuestData = DB.quest(id)
	if q == null:
		return bool(state(id).get("done", false))
	var s := state(id)
	return bool(s.get("done", false)) or int(s.get("stage", -1)) >= q.stages.size()


## Pré-requisitos e flags atendidos (e ainda não iniciada)?
func available(q: QuestData) -> bool:
	if not state(q.id).is_empty():
		return false
	for p in q.prerequisites:
		if not is_completed(p):
			return false
	for f in q.required_flags:
		if not Game.flags.has(f):
			return false
	return true


func start(q: QuestData) -> void:
	if q == null or not available(q):
		return
	Game.quests[q.id] = {"stage": 0, "prog": [], "done": false}
	if tracked == &"":
		tracked = q.id
	quest_started.emit(q.id)


## Estágio atual (limitado ao último; concluída fica em stages.size())
func stage_of(q: QuestData) -> int:
	if q.stages.is_empty():
		return 0
	return clampi(int(state(q.id).get("stage", 0)), 0, q.stages.size() - 1)


## Progresso dos objetivos do estágio atual (completa com zeros)
func progress_of(q: QuestData) -> Array:
	if q.stages.is_empty():
		return []
	var stage: QuestStage = q.stages[stage_of(q)]
	var s := state(q.id)
	var p: Array = s.get("prog", [])
	while p.size() < stage.objectives.size():
		p.append(0)
	return p


func objective_text(q: QuestData, obj: int) -> String:
	var stage: QuestStage = q.stages[stage_of(q)]
	var p := progress_of(q)
	return stage.objective_text(obj, int(p[obj]) if obj < p.size() else 0)


## Conclui um objetivo à força (diálogo roteirizado, cutscene)
func complete_objective(q: QuestData, obj: int) -> void:
	if not is_active(q.id):
		return
	var stage: QuestStage = q.stages[stage_of(q)]
	if obj < 0 or obj >= stage.objectives.size():
		return
	var p := progress_of(q)
	p[obj] = stage.objectives[obj].count
	_store(q, p)
	_check_stage(q)
	objective_updated.emit(q.id)


# ------------------------------------------------------------------ EVENTOS

## Inimigo morto (id do EnemyData) - alimenta objetivos KILL
func notify_kill(enemy_id: StringName) -> void:
	_event(QuestObjective.Type.KILL, enemy_id)


## Conversa iniciada (id do diálogo/NPC) - alimenta objetivos TALK
func notify_talk(npc_id: StringName) -> void:
	_event(QuestObjective.Type.TALK, npc_id)


## Território alcançado (id da raça) - alimenta objetivos REACH
func notify_reach(region: StringName) -> void:
	_event(QuestObjective.Type.REACH, region)


## Flag narrativa setada - alimenta objetivos FLAG e dispara auto-início
func notify_flag(flag_name: StringName) -> void:
	_event(QuestObjective.Type.FLAG, flag_name)
	for qid in DB.quest_ids():
		var q: QuestData = DB.quest(qid)
		if q != null and q.start_flag == flag_name:
			start(q)
			_recalc(q)


## Inventário mudou - reconfere objetivos COLLECT
func notify_collect() -> void:
	for qid in Game.quests.keys():
		var q: QuestData = DB.quest(qid)
		if q == null or not is_active(qid):
			continue
		_recalc(q)
	_check_autoflow()


func _event(type: int, target: StringName) -> void:
	for qid in Game.quests.keys():
		var q: QuestData = DB.quest(qid)
		if q == null or not is_active(qid):
			continue
		var st := stage_of(q)
		var stage: QuestStage = q.stages[st]
		var p := progress_of(q)
		var touched := false
		for i in stage.objectives.size():
			var o: QuestObjective = stage.objectives[i]
			if p[i] >= o.count:
				continue
			match o.type:
				QuestObjective.Type.KILL, QuestObjective.Type.TALK, QuestObjective.Type.REACH:
					if o.type == type and _matches(o.target, target):
						p[i] += 1
						touched = true
				QuestObjective.Type.FLAG:
					if o.target == target and Game.flags.has(o.target):
						p[i] = o.count
						touched = true
				QuestObjective.Type.COLLECT:
					var have := Game.hero.count_item(o.target) if Game.hero else 0
					if have >= o.count:
						p[i] = o.count
						touched = true
		if touched:
			_store(q, p)
			_check_stage(q)
			objective_updated.emit(q.id)
	_check_autoflow()


## Alvo exato OU wildcard "any:<fragmento>": casa por substring -
## `any:_comum` conta conversa com qualquer plebeu (`capital_<raca>_comum0-2`).
## O fragmento pode conter `*` (qualquer sequência): `any:capital_*_lider`
## casa o líder de qualquer capital (`capital_<raca>_lider`).
static func _matches(spec: StringName, id: StringName) -> bool:
	if spec == id:
		return true
	var s := String(spec)
	if not s.begins_with("any:"):
		return false
	var frag := s.substr(4)
	var sid := String(id)
	if not frag.contains("*"):
		return sid.contains(frag)
	# glob: partes literais em ordem, * casa qualquer sequência (inclusive vazio)
	var from := 0
	for p in frag.split("*", false):
		var idx := sid.find(p, from)
		if idx < 0:
			return false
		from = idx + p.length()
	return true


## Recalcula objetivos idempotentes (FLAG/COLLECT) da quest ativa
func _recalc(q: QuestData) -> void:
	var st := stage_of(q)
	var stage: QuestStage = q.stages[st]
	var p := progress_of(q)
	var touched := false
	for i in stage.objectives.size():
		var o: QuestObjective = stage.objectives[i]
		if p[i] >= o.count:
			continue
		if o.type == QuestObjective.Type.FLAG and Game.flags.has(o.target):
			p[i] = o.count
			touched = true
		elif o.type == QuestObjective.Type.COLLECT:
			var have := Game.hero.count_item(o.target) if Game.hero else 0
			if have >= o.count:
				p[i] = o.count
				touched = true
	if touched:
		_store(q, p)
		_check_stage(q)
		objective_updated.emit(q.id)


func _store(q: QuestData, p: Array) -> void:
	Game.quests[q.id]["prog"] = p


## Todos os objetivos do estágio prontos -> avança; último estágio -> conclui
func _check_stage(q: QuestData) -> void:
	var st := stage_of(q)
	var stage: QuestStage = q.stages[st]
	var p := progress_of(q)
	for i in stage.objectives.size():
		if int(p[i]) < stage.objectives[i].count:
			return
	if st + 1 < q.stages.size():
		Game.quests[q.id]["stage"] = st + 1
		Game.quests[q.id]["prog"] = []
		_recalc(q)
		quest_advanced.emit(q.id, st + 1)
	else:
		_complete(q)


func _complete(q: QuestData) -> void:
	Game.quests[q.id]["stage"] = q.stages.size()
	Game.quests[q.id]["done"] = true
	if tracked == q.id:
		tracked = &""
	grant_rewards(q)
	quest_completed.emit(q.id)
	# REGRAS #13: autosave ao concluir quest
	if Game.hero != null and Game.is_inside_tree():
		Game.save_game()
	# Fluxo contínuo da cadeia: a próxima abre sozinha
	if q.next != &"":
		var nq: QuestData = DB.quest(q.next)
		if nq != null and available(nq):
			start(nq)


## Próxima da cadeia cujos pré-requisitos ficaram prontos após um evento
func _check_autoflow() -> void:
	for qid in DB.quest_ids():
		var q: QuestData = DB.quest(qid)
		if q != null and q.start_flag == &"" and available(q):
			# só auto-inicia se todas as prereqs são quests já concluídas
			var chained := not q.prerequisites.is_empty()
			if chained:
				start(q)


# ------------------------------------------------------------------ RECOMPENSAS

func grant_rewards(q: QuestData) -> void:
	var r := q.rewards
	if r == null:
		return
	var hero := Game.hero
	if hero != null:
		hero.add_xp(r.xp if r.xp > 0 else 40 * q.quest_level * q.act)  # REGRAS #12
		if r.gold > 0:
			hero.add_gold(r.gold)
		if r.essence > 0:
			hero.add_essence(r.essence)
		if r.item_base != &"":
			# raridade mínima por ato: Mágico/Raro/Lendário (REGRAS #12)
			hero.inventory.add(DB.create_item(r.item_base, maxi(1, q.quest_level),
				maxi(r.item_rarity, mini(q.act, Item.Rarity.LEGENDARY))))
	for rid in r.reputation:
		var v: int = int(Game.reputation.get(rid, 0)) + int(r.reputation[rid])
		Game.reputation[rid] = clampi(v, 0, 4)
	if r.fragment and not Game.fragmentos.has(q.id):
		Game.fragmentos.append(q.id)


# ------------------------------------------------------------------ FINAL (REGRAS #12)

## Fragmentos da Verdade coletados (mistérios concluídos)
func fragments() -> int:
	return Game.fragmentos.size()


## Final Dourado exige os 8 Fragmentos; sem eles, apenas o Final Cinzento
func golden_ending_unlocked() -> bool:
	return fragments() >= FRAGMENTS_FOR_GOLDEN


# ------------------------------------------------------------------ TRACKER (4.2)

## Quest rastreada (destaque no HUD); vazia = sem quests ativas
func tracked_quest() -> QuestData:
	var t: QuestData = DB.quest(tracked) if tracked != &"" else null
	if t != null and is_active(t.id):
		return t
	# rastreia a primeira ativa, história principal primeiro
	var best: QuestData = null
	for qid in Game.quests.keys():
		var q: QuestData = DB.quest(qid)
		if q == null or not is_active(qid):
			continue
		if best == null or (q.is_main() and not best.is_main()):
			best = q
	tracked = best.id if best != null else &""
	return best


## Linha resumida do objetivo atual ("Derrote 3 goblin  -  1/3")
func tracker_line() -> String:
	var q := tracked_quest()
	if q == null:
		return ""
	var stage: QuestStage = q.stages[stage_of(q)]
	var p := progress_of(q)
	if stage.objectives.is_empty():
		return q.title
	for i in stage.objectives.size():
		if int(p[i]) < stage.objectives[i].count:
			return stage.objective_text(i, int(p[i]))
	return q.title
