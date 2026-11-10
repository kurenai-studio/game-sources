class_name PlantSystem
extends RefCounted
## Grows planted seeds and flowers them on schedule.


func step(sim: Simulation) -> void:
	var world: WorldState = sim.world
	for plant: PlantState in world.plants:
		if plant.flowered:
			continue
		var def: PlantDef = sim.content.get_plant(plant.def_id)
		if def == null:
			push_error("Unknown plant '%s'" % plant.def_id)
			continue
		if world.tick - plant.planted_tick < def.ticks_to_flower:
			continue
		plant.flowered = true
		if def.flower_flag != &"":
			world.flags[def.flower_flag] = true
		if not def.flower_text.is_empty():
			sim.add_journal(def.flower_text, &"nature", &"", &"")
		if def.flower_achievement != &"":
			sim.grant_achievement(def.flower_achievement, def.flower_achievement_title)
