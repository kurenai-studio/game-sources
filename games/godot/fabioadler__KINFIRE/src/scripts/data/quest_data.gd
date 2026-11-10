class_name QuestData
extends Resource
## Uma quest (Fase 4): cadeia de estágios com objetivos, pré-requisitos e
## recompensas. Fica em res://data/narrative/quests/<id>.tres (data-driven, boa prática #2).
## O estado (estágio/progresso/concluída) vive em Game.quests (formato do save).

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var summary: String = ""
## Ato da história principal (1-3); define a raridade mínima do item de recompensa
@export var act := 1
## Nível nominal da quest (XP = 40 x nível x ato)
@export var quest_level := 1
## Cadeia: "main" (história principal) ou id da cadeia de mistério
@export var chain: StringName = &"main"
## Quests que precisam estar concluídas antes desta abrir
@export var prerequisites: Array[StringName] = []
## Flags narrativas exigidas para abrir (condições de diálogo, etc.)
@export var required_flags: Array[StringName] = []
## Flag que inicia a quest automaticamente quando setada por efeito de diálogo
@export var start_flag: StringName = &""
## Estágios em sequência; concluir o último conclui a quest
@export var stages: Array[QuestStage] = []
@export var rewards: QuestRewards
## Próxima quest da cadeia - auto-iniciada ao concluir esta (fluxo contínuo)
@export var next: StringName = &""


func is_main() -> bool:
	return chain == &"main"


## A quest é a final? (O Fogo dos Laços - REGRAS #12: regra do final)
func is_final() -> bool:
	return id == &"ato3_8"
