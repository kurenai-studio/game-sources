class_name NpcData
extends Resource
## NPC conversável (MECANICAS #7, Fase 2): dados + diálogo ramificado.
## Fica em res://data/narrative/npcs/*.tres (data-driven); o Npc instancia, o motor
## de diálogo resolve condições/efeitos (flags, ignorância, reputação).

@export var id: StringName = &""
@export var display_name: String = ""
## Papel social ("Vigia do Acampamento") - rótulo de hover
@export var role: String = ""
## Raça (id em data/races): define sprite, tint e reputação de referência
@export var race_id: StringName = &"humano"
@export var sex := "m"
## Id do DialogueData (data/dialogues/<id>.tres)
@export var dialogue_id: StringName = &""
## Sombra como o Cinzento (silhueta, sem raça) - aparições especiais
@export var shadow := false
