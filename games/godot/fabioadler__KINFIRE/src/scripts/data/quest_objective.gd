class_name QuestObjective
extends Resource
## Um objetivo dentro de um estágio de quest (Fase 4).
## Progresso por evento: KILL/TALK/REACH acumulam notificações;
## FLAG/COLLECT são idempotentes (flag setada / item no inventário).

enum Type { TALK, KILL, FLAG, REACH, COLLECT }

@export var type: Type = Type.FLAG
## Alvo: id do diálogo/NPC (TALK), id do inimigo (KILL), nome da flag (FLAG),
## id do território/raça (REACH) ou base_id do item (COLLECT).
@export var target: StringName = &""
## Quantidade exigida (KILL/COLLECT; os demais usam 1)
@export var count := 1
## Descrição curta exibida no tracker ("Fale com Marn", "Mate 3 goblins")
@export var text: String = ""


func done_text() -> String:
	if text != "":
		return text
	match type:
		Type.TALK:
			return "Fale com %s" % target
		Type.KILL:
			return "Derrote %d %s" % [count, target]
		Type.FLAG:
			return "Descubra: %s" % target
		Type.REACH:
			return "Viaje até %s" % String(target)
		Type.COLLECT:
			return "Recolha %d %s" % [count, target]
	return ""
