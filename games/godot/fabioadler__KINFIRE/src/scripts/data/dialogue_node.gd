class_name DialogueNode
extends Resource
## Nó de um diálogo (MECANICAS #7): páginas de texto + escolhas ramificadas.

@export var id: StringName = &""
## Texto em página única (ignorado quando `pages` está preenchido)
@export_multiline var text: String = ""
## Páginas alternativas - cada elemento é uma página; a UI avança uma a uma
@export var pages: PackedStringArray = PackedStringArray()
## Retrato próprio do nó (expressão/emção); vazio usa o retrato do diálogo
@export var portrait: String = ""
## Escolhas visíveis no fim das páginas (filtradas por `condition`)
@export var choices: Array[DialogueChoice] = []


func page_count() -> int:
	if not pages.is_empty():
		return pages.size()
	return 1 if text != "" else 0


func page(i: int) -> String:
	if not pages.is_empty():
		return pages[i] if i >= 0 and i < pages.size() else ""
	return text
