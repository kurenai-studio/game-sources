class_name DialogueChoice
extends Resource
## Escolha de um nó de diálogo (MECANICAS #7): texto, condição, efeito e destino.

@export var text: String = ""
## Próximo nó - StringName vazio encerra o diálogo
@export var next_id: StringName = &""
## Condição para a escolha aparecer (sintaxe em `ConditionResolver`); vazio = sempre
@export var condition: String = ""
## Efeitos aplicados ao escolher - um por linha (sintaxe em `DialogueEngine.apply_effects`)
@export_multiline var effects: String = ""
