class_name WorldState
extends Resource
## Everything that must survive a save and load. Pure data plus small accessors; the rules
## live in Simulation and its systems. Saved as a single resource (see SaveStore).

const SAVE_VERSION: int = 1
## Resource fractions are kept to 1/FRACTION_SCALE.
const FRACTION_SCALE: float = 1000000.0

@export var save_version: int = SAVE_VERSION

@export_group("Time")
@export var tick: int = 0
## Fraction of a tick carried over between real-time updates.
@export var tick_fraction: float = 0.0
## Unix time of the last real-time update; drives offline catch-up.
@export var last_seen_unix: float = 0.0

@export_group("Randomness")
@export var rng_seed: int = 0
@export var rng_state: int = 0

@export_group("Era")
## Id of the current era and its `order`, kept together so conditions need no content lookup.
@export var era: StringName = &""
@export var era_order: int = 0
## Tick the current era began; the entry gate of the next era measures from here.
@export var era_started_tick: int = 0
## The newest age the player has not been told about yet. The bulb carries it like a waiting
## decision until `Simulation.acknowledge_era` clears it.
@export var unseen_era: StringName = &""

@export_group("Weather")
## The weather now (a WeatherDef id), or &"" for clear sky, and the tick its spell ends. The tick
## it began is kept for the view (a tornado shows only on its first day).
@export var weather: StringName = &""
@export var weather_started_tick: int = 0
@export var weather_until_tick: int = 0

@export_group("Stocks")
@export var resources: Dictionary[StringName, int] = {}
## Sub-unit production not yet converted into whole resources.
@export var resource_fraction: Dictionary[StringName, float] = {}
@export var inventory: Dictionary[StringName, int] = {}
@export var flags: Dictionary[StringName, bool] = {}

@export_group("Entities")
@export var villagers: Array[VillagerState] = []
@export var buildings: Array[BuildingState] = []
@export var plants: Array[PlantState] = []

@export_group("Story")
@export var scheduled: Array[ScheduledEvent] = []
@export var pending: Array[PendingDecision] = []
@export var journal: Array[JournalEntry] = []
@export var achievements: Array[StringName] = []
## The title each achievement was earned under, as the journal told it. The same achievement can
## have a different title by route ("The First Harvest" or "The First Calves"). Saves from before
## this existed have none; `AchievementPresenter` falls back to the content.
@export var achievement_titles: Dictionary[StringName, String] = {}
@export var event_counts: Dictionary[StringName, int] = {}
@export var event_last_tick: Dictionary[StringName, int] = {}
@export var last_decision_tick: int = -1000

@export var next_id: int = 1

@export_group("View")
## Where the view put each piece (`LanePlacer`): a piece's key to the first space it stands in, and
## the order the keys were first shown, which says which of two pieces of a rank is newer. The sim
## never reads either; they are saved so a piece keeps its space from one launch to the next. A
## save without them is placed again by the same rules.
@export var lane_spaces: Dictionary[StringName, int] = {}
@export var lane_order: Array[StringName] = []

## How many villagers the camp holds. Derived from the age, the buildings and the answers the
## group gave, and kept up to date by Simulation.refresh_housing; it is never saved.
var housing: int = 0
## The age's ceiling on the group's size (EraDef.max_villagers), kept up to date alongside
## `housing` and never saved.
var villager_limit: int = 1000
## What weather can reach, by building definition: def id to its tags (BuildingDef.tags). Derived
## from the content like `housing`, kept up to date by Simulation.refresh_housing, never saved.
var building_tags: Dictionary = {}


func find_villager(villager_id: StringName) -> VillagerState:
	for villager: VillagerState in villagers:
		if villager.id == villager_id:
			return villager
	return null


func find_pending(decision_id: StringName) -> PendingDecision:
	for decision: PendingDecision in pending:
		if decision.id == decision_id:
			return decision
	return null


func resource_amount(key: StringName) -> int:
	return resources.get(key, 0)


## Adds to a resource, never dropping below zero.
func add_resource(key: StringName, amount: int) -> void:
	resources[key] = maxi(resource_amount(key) + amount, 0)


## Adds a fractional amount, banking the remainder until it makes a whole unit. The remainder is
## kept to a millionth, so it is a number that survives being saved to text exactly.
func add_resource_fraction(key: StringName, amount: float) -> void:
	var total: float = resource_fraction.get(key, 0.0) + amount
	var whole: int = floori(total)
	resource_fraction[key] = roundf((total - float(whole)) * FRACTION_SCALE) / FRACTION_SCALE
	if whole != 0:
		add_resource(key, whole)


func item_count(key: StringName) -> int:
	return inventory.get(key, 0)


func add_item(key: StringName, amount: int) -> void:
	inventory[key] = maxi(item_count(key) + amount, 0)


func has_flag(key: StringName) -> bool:
	return flags.get(key, false)


## Whether the settlement has fire. Fire is found, not given (docs/gameplay.md P6).
func has_fire() -> bool:
	return has_flag(&"fire_found")


func has_building(def_id: StringName) -> bool:
	for building: BuildingState in buildings:
		if building.complete and building.def_id == def_id:
			return true
	return false


## The building currently under construction, or null.
func constructing() -> BuildingState:
	for building: BuildingState in buildings:
		if not building.complete:
			return building
	return null


## Completed buildings weather could damage now: not already damaged, and carrying `tag`
## (any building if `tag` is empty).
func damageable_buildings(tag: StringName) -> Array[BuildingState]:
	var found: Array[BuildingState] = []
	for building: BuildingState in buildings:
		if not building.complete or building.damaged:
			continue
		var tags: Array = building_tags.get(building.def_id, [])
		if tag == &"" or tags.has(tag):
			found.append(building)
	return found


func has_damaged_building() -> bool:
	for building: BuildingState in buildings:
		if building.complete and building.damaged:
			return true
	return false


func has_achievement(key: StringName) -> bool:
	return achievements.has(key)


## How many more villagers the camp has room for: its housing, held to the age's ceiling. Never
## negative, so a group that is over its ceiling (an older save) keeps everyone and simply has no
## room for more.
func room() -> int:
	return maxi(mini(housing, villager_limit) - villagers.size(), 0)


func new_id(prefix: String) -> StringName:
	var made: StringName = StringName("%s%d" % [prefix, next_id])
	next_id += 1
	return made
