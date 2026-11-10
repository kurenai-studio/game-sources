class_name ConstructionSystem
extends RefCounted
## Advances the building under construction and collects output from finished buildings.


func step(sim: Simulation) -> void:
	var world: WorldState = sim.world
	var config: SimConfig = sim.config
	var site: BuildingState = world.constructing()
	if site != null:
		var builders: int = _count_builders(world)
		site.progress += float(builders) * config.build_rate_per_builder
		var def: BuildingDef = sim.content.get_building(site.def_id)
		if def == null:
			push_error("Unknown building '%s' under construction" % site.def_id)
		elif site.progress >= float(def.work_required):
			sim.complete_building(site)
	for building: BuildingState in world.buildings:
		if not building.complete:
			continue
		var built: BuildingDef = sim.content.get_building(building.def_id)
		if built == null:
			continue
		_mend_if_due(sim, building, built)
		var share: float = config.damaged_output if building.damaged else 1.0
		for key: StringName in built.daily_output:
			# Full stores: nobody bothers to dry or cut more until they have been used.
			if world.resource_amount(key) >= config.comfortable_stock:
				continue
			var weather: float = _weather_share(sim, key)
			world.add_resource_fraction(
				key, built.daily_output[key] / float(config.ticks_per_day) * share * weather
			)


## Damage never waits for ever: the villagers mend it with their own hands after a few days.
func _mend_if_due(sim: Simulation, building: BuildingState, built: BuildingDef) -> void:
	if not building.damaged:
		return
	var waited: int = sim.world.tick - building.damaged_tick
	if waited < sim.config.self_repair_days * sim.config.ticks_per_day:
		return
	sim.repair_building(building)
	sim.add_journal(
		"The %s was mended by the villagers' own hands." % built.display_name,
		&"settlement", &"", &""
	)


func _weather_share(sim: Simulation, resource: StringName) -> float:
	match resource:
		&"food":
			return sim.food_multiplier()
		&"wood":
			return sim.wood_multiplier()
	return 1.0


func _count_builders(world: WorldState) -> int:
	var count: int = 0
	for villager: VillagerState in world.villagers:
		if villager.activity == VillagerState.ACTIVITY_BUILD:
			count += 1
	return count
