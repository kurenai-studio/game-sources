class_name RunGates
extends RefCounted
## Switches and gates during a run. Mirrors the switchAt, gateAt and flipped parts of simulate.ts.
## A pair is its index in the level's `switches`. `flipped` holds the switches entered an odd number
## of times; a gate is open when it started open xor its switch is flipped.


## The run state for a level's switches: cell to pair index for switches and for gates, and the
## pairs whose gate starts open.
static func tables(level: Dictionary) -> Dictionary:
	var switches := {}
	var gates := {}
	var starts_open := {}
	var pairs: Array = level.get("switches", [])
	for i in pairs.size():
		var at: Array = pairs[i]["switch"]
		var gate: Array = pairs[i]["gate"]
		switches[Vector2i(int(at[0]), int(at[1]))] = i
		gates[Vector2i(int(gate[0]), int(gate[1]))] = i
		if pairs[i].get("open", false):
			starts_open[i] = true
	return {"switches": switches, "gates": gates, "starts_open": starts_open}


## True when a gate stands on the cell and it is shut.
static func shut_gate(run: Dictionary, cell: Vector2i) -> bool:
	var gates: Dictionary = run["gates"]
	if not gates.has(cell):
		return false
	var pair: int = gates[cell]
	return (run["starts_open"] as Dictionary).has(pair) == (run["flipped"] as Dictionary).has(pair)


## Flips the switch on the cell, if there is one. Returns true when one was entered.
static func toggle(run: Dictionary, cell: Vector2i) -> bool:
	var switches: Dictionary = run["switches"]
	if not switches.has(cell):
		return false
	var flipped: Dictionary = run["flipped"]
	if not flipped.erase(switches[cell]):
		flipped[switches[cell]] = true
	return true
