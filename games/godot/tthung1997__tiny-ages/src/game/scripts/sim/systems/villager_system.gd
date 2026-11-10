class_name VillagerSystem
extends RefCounted
## Gives villagers their autonomous day: sleep at night, otherwise drift between work and
## leisure, gathering as they go. Traits only bias what they choose.

const WEIGHT_GATHER: float = 3.0
const WEIGHT_FORAGE: float = 3.0
const WEIGHT_SOCIALIZE: float = 1.0
const WEIGHT_WANDER: float = 1.0
const WEIGHT_BUILD: float = 6.0
## A group that chose to hunt sometimes goes out hunting; a hunt brings back more than foraging.
const WEIGHT_HUNT: float = 2.0
const HUNT_YIELD: float = 2.0
const TRAIT_BIAS: float = 2.0
## Multiplies the wish to gather a resource the group already has plenty of.
const PLENTY_WEIGHT: float = 0.02
## While food is short the group shifts its effort: it forages and hunts more, and cuts wood and
## builds less. Nobody is hurt; the cost is only what does not get done meanwhile.
const HUNGRY_FOOD_WEIGHT: float = 3.0
const HUNGRY_OTHER_WEIGHT: float = 0.5
## Chance per tick that an idle villager joins a building site that appears.
const BUILD_DRIFT_CHANCE: float = 0.5
## A profession tilts what its villager chooses, the way a trait does, and never assigns work
## (docs/ages.md B4): a Forager forages more, a Smith cuts the wood the hearth burns, and a Trader
## walks the road and talks to whoever is on it.
const PROFESSION_BIAS: Dictionary = {
	&"forager": {VillagerState.ACTIVITY_FORAGE: 2.0},
	&"smith": {VillagerState.ACTIVITY_GATHER_WOOD: 2.0},
	&"trader": {VillagerState.ACTIVITY_WANDER: 2.0, VillagerState.ACTIVITY_SOCIALIZE: 2.0},
}


func step(sim: Simulation) -> void:
	var world: WorldState = sim.world
	var config: SimConfig = sim.config
	var sleeping: bool = config.is_sleeping_hour(config.hour_of(world.tick))
	var building_underway: bool = world.constructing() != null
	var working: Array[VillagerState] = []
	for villager: VillagerState in world.villagers:
		if villager.is_away():
			if world.tick < villager.away_until_tick:
				continue
			_return_home(villager)
		if sleeping:
			villager.activity = VillagerState.ACTIVITY_REST
			villager.activity_ticks_left = 0
			continue
		villager.activity_ticks_left -= 1
		var building_unwanted: bool = villager.activity == VillagerState.ACTIVITY_BUILD \
				and not building_underway
		var drifts_to_build: bool = building_underway \
				and villager.activity != VillagerState.ACTIVITY_BUILD \
				and sim.rng.randf() < BUILD_DRIFT_CHANCE
		if villager.activity_ticks_left <= 0 or villager.activity == VillagerState.ACTIVITY_REST \
				or building_unwanted or drifts_to_build:
			_choose_activity(sim, villager, building_underway)
		working.append(villager)
	var foragers: int = _count(working, VillagerState.ACTIVITY_FORAGE)
	var hunters: int = _count(working, VillagerState.ACTIVITY_HUNT)
	var food_rate: float = sim.food_multiplier() * sim.food_yield_scale()
	var wood_rate: float = sim.wood_multiplier() * sim.wood_yield_scale()
	for villager: VillagerState in working:
		_work(sim, villager, foragers, hunters, food_rate, wood_rate)


func _count(villagers: Array[VillagerState], activity: StringName) -> int:
	var count: int = 0
	for villager: VillagerState in villagers:
		if villager.activity == activity:
			count += 1
	return count


## What each of `crowd` villagers working the same ground brings back, as a share of a lone
## worker's: the ground is shared, so more at once means less each.
static func shared_ground(crowd: int, config: SimConfig) -> float:
	return 1.0 / (1.0 + config.forage_crowding * float(maxi(crowd - 1, 0)))


func _return_home(villager: VillagerState) -> void:
	villager.activity = VillagerState.ACTIVITY_REST
	villager.activity_ticks_left = 0
	villager.location = VillagerState.LOCATION_CAMP
	villager.away_until_tick = 0


func _choose_activity(sim: Simulation, villager: VillagerState, building_underway: bool) -> void:
	var activities: Array[StringName] = []
	var weights: Array[float] = []
	var hungry: bool = is_hungry(sim)
	var food_push: float = HUNGRY_FOOD_WEIGHT if hungry else 1.0
	var other_push: float = HUNGRY_OTHER_WEIGHT if hungry else 1.0
	activities.append(VillagerState.ACTIVITY_GATHER_WOOD)
	weights.append(
		WEIGHT_GATHER * other_push
		* _bias(villager, VillagerState.TRAIT_INDUSTRIOUS) * _plenty(sim, &"wood")
		* profession_bias(villager, VillagerState.ACTIVITY_GATHER_WOOD)
	)
	activities.append(VillagerState.ACTIVITY_FORAGE)
	weights.append(
		WEIGHT_FORAGE * food_push
		* _bias(villager, VillagerState.TRAIT_NATURE_LOVING) * _plenty(sim, &"food")
		* profession_bias(villager, VillagerState.ACTIVITY_FORAGE)
	)
	activities.append(VillagerState.ACTIVITY_SOCIALIZE)
	weights.append(
		WEIGHT_SOCIALIZE * _bias(villager, VillagerState.TRAIT_SOCIAL)
		* profession_bias(villager, VillagerState.ACTIVITY_SOCIALIZE)
	)
	activities.append(VillagerState.ACTIVITY_WANDER)
	weights.append(
		WEIGHT_WANDER * _bias(villager, VillagerState.TRAIT_CURIOUS)
		* profession_bias(villager, VillagerState.ACTIVITY_WANDER)
	)
	if sim.world.has_flag(&"path_hunting"):
		activities.append(VillagerState.ACTIVITY_HUNT)
		weights.append(
			WEIGHT_HUNT * food_push
			* _bias(villager, VillagerState.TRAIT_CURIOUS) * _plenty(sim, &"food")
		)
	if building_underway:
		activities.append(VillagerState.ACTIVITY_BUILD)
		weights.append(
			WEIGHT_BUILD * other_push * _bias(villager, VillagerState.TRAIT_INDUSTRIOUS)
		)
	var picked: int = SimRandom.pick_weighted(sim.rng, weights)
	villager.activity = activities[maxi(picked, 0)]
	villager.activity_ticks_left = sim.rng.randi_range(
		sim.config.min_activity_ticks, sim.config.max_activity_ticks
	)


func _bias(villager: VillagerState, trait_name: StringName) -> float:
	return TRAIT_BIAS if villager.has_trait(trait_name) else 1.0


## How much a villager's profession (if any) tilts a choice of `activity`.
static func profession_bias(villager: VillagerState, activity: StringName) -> float:
	var tilts: Dictionary = PROFESSION_BIAS.get(villager.profession, {})
	return float(tilts.get(activity, 1.0))


## Whether food is low: below the same line the strip gauge reads as low.
static func is_hungry(sim: Simulation) -> bool:
	var line: float = float(sim.config.comfortable_stock) * sim.config.low_stock_fraction
	return float(sim.world.resource_amount(&"food")) < line


## How keen the group is to gather a resource: full while it is short, much less once the stores
## are comfortable, so stock hovers instead of piling up for ever.
func _plenty(sim: Simulation, resource: StringName) -> float:
	if sim.world.resource_amount(resource) >= sim.config.comfortable_stock:
		return PLENTY_WEIGHT
	return 1.0


func _work(
	sim: Simulation, villager: VillagerState, foragers: int, hunters: int,
	food_rate: float = 1.0, wood_rate: float = 1.0
) -> void:
	var config: SimConfig = sim.config
	var rate: float = config.gather_rate
	if villager.has_trait(VillagerState.TRAIT_INDUSTRIOUS):
		rate *= config.industrious_multiplier
	match villager.activity:
		VillagerState.ACTIVITY_GATHER_WOOD:
			sim.world.add_resource_fraction(&"wood", rate * wood_rate)
		VillagerState.ACTIVITY_FORAGE:
			sim.world.add_resource_fraction(
				&"food", rate * food_rate * shared_ground(foragers, config)
			)
		VillagerState.ACTIVITY_HUNT:
			sim.world.add_resource_fraction(
				&"food", rate * food_rate * HUNT_YIELD * shared_ground(hunters, config)
			)
