class_name SkillTreeData
extends Resource
## Arvore de habilidades de uma classe (data-driven).
## Fonte de verdade: scripts/data/skill_trees.gd (DB.get_skill_tree)

## Preload para type hint funcionar em parse time
const SkillNodeData := preload("res://scripts/data/skill_node_data.gd")

@export var class_id: StringName
@export var nodes: Array[SkillNodeData] = []


func get_node(node_id: StringName) -> SkillNodeData:
	for n in nodes:
		if n.id == node_id:
			return n
	return null


func get_available_nodes(unlocked: Array[StringName]) -> Array[SkillNodeData]:
	var available: Array = []
	for n in nodes:
		if n.id in unlocked:
			continue
		if n.is_available(unlocked):
			available.append(n)
	return available


func get_node_dependencies(node_id: StringName) -> Array[StringName]:
	var node := get_node(node_id)
	if node:
		return node.requires.duplicate()
	return []


func get_dependent_nodes(node_id: StringName) -> Array[SkillNodeData]:
	var deps: Array = []
	for n in nodes:
		if node_id in n.requires:
			deps.append(n)
	return deps