class_name SimFixture
extends RefCounted
## Shared helpers for simulation tests: build a seeded sim from the real content and step it.

const CONTENT_PATH: String = "res://resources/sim/content.tres"
const CONFIG_PATH: String = "res://resources/sim/sim_config.tres"
const START_UNIX: float = 1_700_000_000.0
const TICKS_PER_DAY: int = 24


static func load_content() -> ContentLibrary:
	return load(CONTENT_PATH) as ContentLibrary


static func load_config() -> SimConfig:
	return load(CONFIG_PATH) as SimConfig


static func new_sim(rng_seed: int = 1, lit: bool = true) -> Simulation:
	var config: SimConfig = load_config()
	var content: ContentLibrary = load_content()
	var world: WorldState = WorldFactory.create_new(content, config, rng_seed, START_UNIX)
	if lit:
		light_fire(world)
	return Simulation.new(world, config, content)


## Worlds start without fire. Most tests are about something later, so they start lit; pass
## `lit = false` to new_sim for the fire story itself.
static func light_fire(world: WorldState) -> void:
	world.flags[&"fire_found"] = true
	world.achievements.append(&"fire")


## Steps one tick at a time until `predicate` is true. Returns ticks used, or -1 on timeout.
static func advance_until(sim: Simulation, predicate: Callable, max_ticks: int) -> int:
	for used: int in max_ticks:
		sim.advance_ticks(1)
		if predicate.call():
			return used + 1
	return -1


## Gives the first three villagers fixed traits, so a test about one trait does not depend on
## which group the seed happened to draw. Each entry is the trait list for one villager.
static func set_traits(sim: Simulation, traits_by_villager: Array) -> void:
	for index: int in traits_by_villager.size():
		var villager: VillagerState = sim.world.villagers[index]
		villager.traits.assign(traits_by_villager[index])


## Moves the clock forward to a game day (keeping the hour). Cave Age milestones are staged over
## the first days (see build_sim_content.gd), so tests about a later one start from there.
static func jump_to_day(sim: Simulation, day: int) -> void:
	var hour_ticks: int = posmod(sim.world.tick, TICKS_PER_DAY)
	sim.world.tick = maxi(sim.world.tick, day * TICKS_PER_DAY + hour_ticks)


static func pending_for(sim: Simulation, event_id: StringName) -> PendingDecision:
	for decision: PendingDecision in sim.world.pending:
		if decision.event_id == event_id:
			return decision
	return null


static func advance_until_pending(sim: Simulation, event_id: StringName, max_ticks: int) -> int:
	return advance_until(
		sim, func() -> bool: return pending_for(sim, event_id) != null, max_ticks
	)


## Like advance_until_pending, but discards every other decision as it goes so the pending cap
## never hides the one being waited for. For tests about one event among many.
static func advance_until_asked(sim: Simulation, event_id: StringName, max_ticks: int) -> int:
	for used: int in max_ticks:
		sim.advance_ticks(1)
		if pending_for(sim, event_id) != null:
			return used + 1
		sim.world.pending.clear()
	return -1


static func advance_until_flag(sim: Simulation, flag: StringName, max_ticks: int) -> int:
	return advance_until(sim, func() -> bool: return sim.world.has_flag(flag), max_ticks)


## Like advance_until_flag, but a DecisionBot answers every decision after each tick.
static func advance_until_flag_with(
	sim: Simulation, bot: DecisionBot, flag: StringName, max_ticks: int
) -> int:
	for used: int in max_ticks:
		sim.advance_ticks(1)
		bot.answer_all(sim)
		if sim.world.has_flag(flag):
			return used + 1
	return -1


static func advance_until_built(sim: Simulation, building_id: StringName, max_ticks: int) -> int:
	return advance_until(
		sim, func() -> bool: return sim.world.has_building(building_id), max_ticks
	)


static func journal_index(world: WorldState, fragment: String) -> int:
	for index: int in world.journal.size():
		if world.journal[index].text.contains(fragment):
			return index
	return -1


## A comparable summary of a world, for asserting two worlds are in the same state.
static func snapshot(world: WorldState) -> Dictionary:
	var villagers: Array = []
	for villager: VillagerState in world.villagers:
		villagers.append([
			villager.id, villager.activity, villager.location, villager.profession,
			villager.activity_ticks_left, villager.away_until_tick,
		])
	var journal: Array = []
	for entry: JournalEntry in world.journal:
		journal.append("%d %s" % [entry.tick, entry.text])
	var pending: Array = []
	for decision: PendingDecision in world.pending:
		pending.append([decision.id, decision.event_id, decision.subject_id])
	return {
		"tick": world.tick,
		"fraction": world.tick_fraction,
		"resources": world.resources.duplicate(),
		"resource_fraction": world.resource_fraction.duplicate(),
		"inventory": world.inventory.duplicate(),
		"flags": world.flags.duplicate(),
		"villagers": villagers,
		"journal": journal,
		"pending": pending,
		"achievements": world.achievements.duplicate(),
		"buildings": world.buildings.size(),
		"plants": world.plants.size(),
		"rng_state": world.rng_state,
		"weather": [world.weather, world.weather_until_tick],
		"damaged": world.buildings.filter(func(b: BuildingState) -> bool: return b.damaged).size(),
	}
