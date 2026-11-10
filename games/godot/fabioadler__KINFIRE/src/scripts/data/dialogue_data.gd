class_name DialogueData
extends Resource
## Diálogo completo: grafo de `DialogueNode` com ponto de entrada.
## Fica em res://data/narrative/dialogues/*.tres (data-driven, boa prática #2).

@export var id: StringName = &""
@export var display_name: String = ""
## Nome do sprite de retrato do falante; vazio = silhueta (Cinzento)
@export var portrait: String = ""
@export var start_id: StringName = &""
@export var nodes: Array[DialogueNode] = []


func node(nid: StringName) -> DialogueNode:
	for n in nodes:
		if n.id == nid:
			return n
	return null
