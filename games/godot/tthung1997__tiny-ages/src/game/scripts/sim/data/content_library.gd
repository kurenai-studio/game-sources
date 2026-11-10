class_name ContentLibrary
extends Resource
## All authored simulation content: events, buildings, plants and the starting setup.

@export var events: Array[EventDef] = []
@export var buildings: Array[BuildingDef] = []
@export var plants: Array[PlantDef] = []
## The ages of the arc. The lowest `order` is where a new world starts.
@export var eras: Array[EraDef] = []
## The kinds of weather events can start (see WeatherDef).
@export var weathers: Array[WeatherDef] = []
@export_group("Starting world")
## Each new world draws its starting group from these pools, using the world's seed, so every
## run begins with different people.
@export var villager_names: Array[String] = []
@export var villager_traits: Array[StringName] = []
## Art sheets under assets/world/<age>/villagers/ (no extension); one per starting villager.
@export var villager_looks: Array[StringName] = []
@export var starting_villager_count: int = 3
@export var traits_per_villager: int = 2
## At least one starting villager has each of these, so the first story chain can always begin.
@export var guaranteed_traits: Array[StringName] = []
@export var starting_resources: Dictionary[StringName, int] = {}
@export_group("Room")
## World flags that add room for villagers once set, for example a lean-to the group built.
@export var flag_housing: Dictionary[StringName, int] = {}

var _event_index: Dictionary = {}
var _building_index: Dictionary = {}
var _plant_index: Dictionary = {}
var _era_index: Dictionary = {}
var _weather_index: Dictionary = {}


func get_weather(weather_id: StringName) -> WeatherDef:
	if _weather_index.size() != weathers.size():
		_weather_index = _index_by_id(weathers)
	return _weather_index.get(weather_id)


func get_era(era_id: StringName) -> EraDef:
	if _era_index.size() != eras.size():
		_era_index = _index_by_id(eras)
	return _era_index.get(era_id)


## The era a new world starts in: the one with the lowest `order`, or null if there are none.
func first_era() -> EraDef:
	var first: EraDef = null
	for era: EraDef in eras:
		if first == null or era.order < first.order:
			first = era
	return first


## The age right after `order`: the lowest `order` above it, or null at the end of the arc.
func next_era(order: int) -> EraDef:
	var next: EraDef = null
	for era: EraDef in eras:
		if era.order > order and (next == null or era.order < next.order):
			next = era
	return next


func get_event(event_id: StringName) -> EventDef:
	if _event_index.size() != events.size():
		_event_index = _index_by_id(events)
	return _event_index.get(event_id)


func get_building(building_id: StringName) -> BuildingDef:
	if _building_index.size() != buildings.size():
		_building_index = _index_by_id(buildings)
	return _building_index.get(building_id)


func get_plant(plant_id: StringName) -> PlantDef:
	if _plant_index.size() != plants.size():
		_plant_index = _index_by_id(plants)
	return _plant_index.get(plant_id)


func plant_for_seed(seed_item: StringName) -> PlantDef:
	for plant: PlantDef in plants:
		if plant.seed_item == seed_item:
			return plant
	return null


## Returns a list of authoring problems; empty means the content is consistent.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	_check_unique_ids(events, "event", problems)
	_check_unique_ids(buildings, "building", problems)
	_check_unique_ids(plants, "plant", problems)
	_check_unique_ids(eras, "era", problems)
	_check_unique_ids(weathers, "weather", problems)
	for weather: WeatherDef in weathers:
		if weather.max_days < weather.min_days:
			problems.append("weather '%s' lasts at most less than its least" % weather.id)
		if weather.then != &"" and get_weather(weather.then) == null:
			problems.append("weather '%s' is followed by unknown '%s'" % [weather.id, weather.then])
	var orders: Dictionary = {}
	for era: EraDef in eras:
		if orders.has(era.order):
			problems.append("era '%s' reuses order %d" % [era.id, era.order])
		orders[era.order] = true
		if era.max_villagers < starting_villager_count:
			problems.append("era '%s' holds fewer villagers than a new group starts with" % era.id)
		var next: EraDef = next_era(era.order)
		if next != null and next.max_villagers < era.max_villagers:
			problems.append("era '%s' holds fewer villagers than the age before it" % next.id)
	for event: EventDef in events:
		var where: String = "event '%s'" % event.id
		if event.chance_per_tick <= 0.0 and not _is_scheduled_target(event.id):
			problems.append("%s never fires: zero chance and nothing schedules it" % where)
		if not event.is_decision() and event.effects.is_empty():
			problems.append("%s has no choices and no effects" % where)
		_check_conditions(event.requires, where, problems)
		_check_conditions(event.subject_requires, where, problems)
		_check_effects(event.effects, where, problems)
		var choice_ids: Dictionary = {}
		for choice: ChoiceDef in event.choices:
			if choice.id == &"" or choice_ids.has(choice.id):
				problems.append("%s has a missing or duplicate choice id '%s'" % [where, choice.id])
			choice_ids[choice.id] = true
			_check_conditions(choice.requires, "%s choice '%s'" % [where, choice.id], problems)
			_check_effects(choice.effects, "%s choice '%s'" % [where, choice.id], problems)
	for building: BuildingDef in buildings:
		if building.work_required <= 0:
			problems.append("building '%s' needs work_required > 0" % building.id)
	for plant: PlantDef in plants:
		if plant.seed_item == &"":
			problems.append("plant '%s' has no seed_item" % plant.id)
	_check_starting_group(problems)
	_check_era_gates(problems)
	return problems


func _check_era_gates(problems: PackedStringArray) -> void:
	var grantable: Dictionary = _grantable_achievements()
	for era: EraDef in eras:
		var where: String = "era '%s'" % era.id
		for key: StringName in era.required_achievements:
			if not grantable.has(key):
				problems.append("%s requires achievement '%s', which nothing grants" % [where, key])
		if era.turn_event == &"":
			continue
		var turn: EventDef = get_event(era.turn_event)
		if turn == null:
			problems.append("%s has unknown turn event '%s'" % [where, era.turn_event])
			continue
		if not turn.is_decision():
			problems.append("%s turn event '%s' needs choices" % [where, turn.id])
		for choice: ChoiceDef in turn.choices:
			if not _advances_to(choice.effects, era.id):
				problems.append("%s turn choice '%s' does not advance the era" % [where, choice.id])


func _advances_to(effects: Array[SimEffect], era_id: StringName) -> bool:
	for effect: SimEffect in effects:
		if effect.kind == SimEffect.Kind.ADVANCE_ERA and effect.key == era_id:
			return true
	return false


## The title an achievement is earned under, for saves that did not keep it: the first one found
## (an achievement can carry a different title per route). Empty if nothing grants it.
func achievement_title(key: StringName) -> String:
	for event: EventDef in events:
		var title: String = _effect_title(event.effects, key)
		for choice: ChoiceDef in event.choices:
			if title.is_empty():
				title = _effect_title(choice.effects, key)
		if not title.is_empty():
			return title
	for plant: PlantDef in plants:
		if plant.flower_achievement == key:
			return plant.flower_achievement_title
	for building: BuildingDef in buildings:
		if building.completion_achievement == key:
			return building.completion_achievement_title
	return ""


func _effect_title(effects: Array[SimEffect], key: StringName) -> String:
	for effect: SimEffect in effects:
		if effect.kind == SimEffect.Kind.ACHIEVEMENT and effect.key == key:
			return effect.text
	return ""


## Every achievement some effect, plant or building can grant.
func _grantable_achievements() -> Dictionary:
	var grantable: Dictionary = {}
	for event: EventDef in events:
		_collect_achievements(event.effects, grantable)
		for choice: ChoiceDef in event.choices:
			_collect_achievements(choice.effects, grantable)
	for plant: PlantDef in plants:
		if plant.flower_achievement != &"":
			grantable[plant.flower_achievement] = true
	for building: BuildingDef in buildings:
		if building.completion_achievement != &"":
			grantable[building.completion_achievement] = true
	return grantable


func _collect_achievements(effects: Array[SimEffect], into: Dictionary) -> void:
	for effect: SimEffect in effects:
		if effect.kind == SimEffect.Kind.ACHIEVEMENT:
			into[effect.key] = true


func _check_starting_group(problems: PackedStringArray) -> void:
	var count: int = starting_villager_count
	if count < 1:
		problems.append("starting_villager_count must be at least 1")
	var unique_names: Dictionary = {}
	for villager_name: String in villager_names:
		var villager_id: String = villager_name.to_lower()
		if villager_name.is_empty() or unique_names.has(villager_id):
			problems.append("villager name '%s' is empty or repeated" % villager_name)
		unique_names[villager_id] = true
	if villager_names.size() < count:
		problems.append("need at least %d villager names" % count)
	if villager_looks.size() < count:
		problems.append("need at least %d villager looks" % count)
	if villager_traits.size() < traits_per_villager or traits_per_villager < 1:
		problems.append("need at least traits_per_villager distinct traits to draw from")
	if guaranteed_traits.size() > count:
		problems.append("more guaranteed traits than starting villagers")
	for guaranteed: StringName in guaranteed_traits:
		if not villager_traits.has(guaranteed):
			problems.append("guaranteed trait '%s' is not in the trait pool" % guaranteed)


func _is_scheduled_target(event_id: StringName) -> bool:
	for era: EraDef in eras:
		if era.turn_event == event_id:
			return true
	for event: EventDef in events:
		if _effects_schedule(event.effects, event_id):
			return true
		for choice: ChoiceDef in event.choices:
			if _effects_schedule(choice.effects, event_id):
				return true
	return false


func _effects_schedule(effects: Array[SimEffect], event_id: StringName) -> bool:
	for effect: SimEffect in effects:
		if effect.kind == SimEffect.Kind.SCHEDULE_EVENT and effect.key == event_id:
			return true
	return false


func _check_conditions(
	conditions: Array[SimCondition], where: String, problems: PackedStringArray
) -> void:
	for condition: SimCondition in conditions:
		if condition.kind == SimCondition.Kind.HAS_BUILDING and get_building(condition.key) == null:
			problems.append("%s requires unknown building '%s'" % [where, condition.key])
		var era_kind: bool = condition.kind == SimCondition.Kind.ERA_AT_LEAST
		if era_kind and not _has_era_order(condition.amount):
			problems.append("%s requires era order %d, which no era has" % [where, condition.amount])
		if condition.kind == SimCondition.Kind.SEASON_IS \
				and (condition.amount < 0 or condition.amount >= Season.COUNT):
			problems.append("%s requires season %d, which does not exist" % [where, condition.amount])
		if condition.kind == SimCondition.Kind.WEATHER_IS \
				and condition.key != &"" and get_weather(condition.key) == null:
			problems.append("%s requires unknown weather '%s'" % [where, condition.key])
		if condition.kind == SimCondition.Kind.HAS_BUILDING_TAG \
				and condition.key != &"" and not _has_tag(condition.key):
			problems.append("%s requires tag '%s', which no building has" % [where, condition.key])


func _has_tag(tag: StringName) -> bool:
	for building: BuildingDef in buildings:
		if building.tags.has(tag):
			return true
	return false


func _has_era_order(order: int) -> bool:
	for era: EraDef in eras:
		if era.order == order:
			return true
	return false


func _check_effects(
	effects: Array[SimEffect], where: String, problems: PackedStringArray
) -> void:
	for effect: SimEffect in effects:
		match effect.kind:
			SimEffect.Kind.START_BUILD:
				if get_building(effect.key) == null:
					problems.append("%s starts unknown building '%s'" % [where, effect.key])
			SimEffect.Kind.ADVANCE_ERA:
				if get_era(effect.key) == null:
					problems.append("%s advances to unknown era '%s'" % [where, effect.key])
			SimEffect.Kind.SCHEDULE_EVENT:
				if get_event(effect.key) == null:
					problems.append("%s schedules unknown event '%s'" % [where, effect.key])
				if effect.amount <= 0:
					problems.append("%s schedules '%s' with no delay" % [where, effect.key])
			SimEffect.Kind.PLANT:
				if plant_for_seed(effect.key) == null:
					problems.append("%s plants item '%s' that grows nothing" % [where, effect.key])
			SimEffect.Kind.JOURNAL, SimEffect.Kind.ACHIEVEMENT:
				if effect.text.is_empty():
					problems.append("%s has a %s effect without text" % [where, effect.kind])
			SimEffect.Kind.SEND_AWAY:
				if effect.amount <= 0 or effect.key == &"":
					problems.append("%s sends a villager away without a place or duration" % where)
			SimEffect.Kind.SET_WEATHER:
				if get_weather(effect.key) == null:
					problems.append("%s starts unknown weather '%s'" % [where, effect.key])
			SimEffect.Kind.DAMAGE_BUILDING:
				if effect.key != &"" and not _has_tag(effect.key):
					problems.append("%s damages tag '%s', which no building has" % [where, effect.key])


func _check_unique_ids(items: Array, label: String, problems: PackedStringArray) -> void:
	var seen: Dictionary = {}
	for item: Resource in items:
		var item_id: StringName = item.get("id")
		if item_id == &"" or seen.has(item_id):
			problems.append("%s has a missing or duplicate id '%s'" % [label, item_id])
		seen[item_id] = true


func _index_by_id(items: Array) -> Dictionary:
	var index: Dictionary = {}
	for item: Resource in items:
		index[item.get("id")] = item
	return index
