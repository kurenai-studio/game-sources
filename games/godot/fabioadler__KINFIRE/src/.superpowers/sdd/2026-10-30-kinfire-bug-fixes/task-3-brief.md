# Task 3 Brief: Fix Skill Tree Layout Algorithm (Depth Calculation)

## Task Description
Fix the `_calculate_depths()` function in `skill_tree_panel.gd` which incorrectly calculates node depths, causing prerequisites to appear to the RIGHT of dependents instead of to the LEFT. The tree should flow left-to-right (prerequisites on left, dependents on right).

## Files to Modify
- `/media/f/HD/KINFIRE/scripts/ui/skill_tree_panel.gd` (lines 141-175)

## Current Bug
In `_calculate_depths()`:
- Prerequisites are pushed with `depth - 1` (wrong - puts them left of current, but current starts at 0)
- Dependents are pushed with `depth + 1` (correct direction)
- Root nodes start at depth 0

This causes the tree to be laid out with root nodes in the middle and everything flowing outward, or inverted.

## Required Fix
Replace the entire `_calculate_depths()` function (lines 141-175) with corrected algorithm:

```gdscript
func _calculate_depths() -> Dictionary:
	var depths: Dictionary[StringName, int] = {}
	var visited: Dictionary[StringName, bool] = {}
	var stack: Array[Dictionary] = []
	
	# Começa dos nós raiz (sem pré-requisitos) - profundidade 0 (esquerda)
	for n in _tree.nodes:
		if n.requires.is_empty():
			stack.append({"node_id": n.id, "depth": 0})
	
	while stack.size() > 0:
		var item: Dictionary = stack.pop_back()
		var node_id: StringName = item.node_id
		var depth: int = item.depth
		
		if visited.has(node_id):
			depths[node_id] = max(depths[node_id], depth)
			continue
		visited[node_id] = true
		depths[node_id] = depth
		
		var node := _tree.get_node(node_id)
		if not node:
			continue
		
		# PRÉ-REQUISITOS: vão para a ESQUERDA (depth - 1)
		for req_id in node.requires:
			stack.append({"node_id": req_id, "depth": depth - 1})
		
		# DEPENDENTES: vão para a DIREITA (depth + 1)
		for dep in _tree.get_dependent_nodes(node_id):
			stack.append({"node_id": dep.id, "depth": depth + 1})
	
	# Normaliza para começar em 0 (shift all to positive)
	var min_depth := INF
	for d in depths.values():
		if d < min_depth:
			min_depth = d
	if min_depth < 0:
		for k in depths.keys():
			depths[k] -= min_depth
	
	return depths
```

## Test to Verify
Run: `flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn`
Expected: Skill tree lays out left-to-right correctly, test passes

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns
- Follow existing code style (UTF-8, 4-space indent, Portuguese comments)

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-3-report.md`