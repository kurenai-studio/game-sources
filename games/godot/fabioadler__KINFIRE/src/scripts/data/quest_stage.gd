class_name QuestStage
extends Resource
## Um estágio de uma quest (Fase 4): descrição narrativa + objetivos.
## A quest avança de estágio quando todos os objetivos são cumpridos.

@export_multiline var description: String = ""
@export var objectives: Array[QuestObjective] = []


## Linha de progresso de um objetivo ("2/3 Mate goblins")
func objective_text(i: int, progress: int) -> String:
	if i < 0 or i >= objectives.size():
		return ""
	var o: QuestObjective = objectives[i]
	var txt := o.done_text()
	if o.type == QuestObjective.Type.KILL or o.type == QuestObjective.Type.COLLECT:
		return "%d/%d %s" % [mini(progress, o.count), o.count, txt]
	return txt
