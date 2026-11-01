class_name ProgramSlots
extends RefCounted
## The command budget a program uses. Mirrors packages/level-contract/src/slots.ts: an action
## and a CALL are 1 slot, a loop and a PROC are 1 plus the slots of their body items, and an IF
## is 1 plus its then actions plus the slots of its else (actions, or a nested IF).
## Compare it with constraints.maxCommands and par.


## Slots of a list of instruction nodes.
static func count(program: Array) -> int:
	var total := 0
	for node: Dictionary in program:
		total += of_node(node)
	return total


## Slots of one node.
static func of_node(node: Dictionary) -> int:
	if ContractLimits.is_if(node["op"]):
		var other: Array = node["else"]
		var else_slots := other.size()
		if other.size() == 1 and ContractLimits.is_if(other[0]["op"]):
			else_slots = of_node(other[0])
		return 1 + (node["then"] as Array).size() + else_slots
	if ContractLimits.is_loop(node["op"]) or ContractLimits.is_proc(node["op"]):
		return 1 + count(node["body"])
	return 1
