class_name SimCondition
extends Resource
## One yes/no test about the world, used to gate events and choices. Authored as data so
## designers can compose requirements in the inspector.

enum Kind {
	## Append new kinds at the end: saved .tres content stores the integer value.
	HAS_BUILDING, ## `key` is a completed building id.
	FLAG_SET, ## `key` is a world flag.
	RESOURCE_AT_LEAST, ## `key` resource holds at least `amount`.
	ITEM_AT_LEAST, ## `key` item holds at least `amount`.
	CONSTRUCTION_IDLE, ## Nothing is currently being built.
	DAYS_AT_LEAST, ## The settlement is at least `amount` days old.
	SUBJECT_HAS_TRAIT, ## The event's subject villager has trait `key`.
	SUBJECT_AT_HOME, ## The event's subject villager is not away.
	ERA_AT_LEAST, ## The settlement's era `order` is at least `amount`.
	ACHIEVEMENT_EARNED, ## Achievement `key` has been earned.
	SUBJECT_AWAKE, ## The event's subject villager is not asleep (it is not sleeping hours).
	ERA_DAYS_AT_LEAST, ## The settlement has been in its current era for at least `amount` days.
	HAS_ROOM, ## The camp has room for at least `amount` more villagers (negate: it is crowded).
	SEASON_IS, ## The season is `amount` (a Season constant).
	WEATHER_IS, ## The weather is `key`; an empty key means clear sky.
	HAS_BUILDING_TAG, ## A completed building that weather can reach (see BuildingDef.tags): has
	## tag `key`, or is any building if `key` is empty, and is not already damaged.
	HAS_DAMAGED_BUILDING, ## Some completed building is damaged (negate: none is).
	TIDE_LOW, ## The sea is at low tide (negate: it is not).
}

@export var kind: Kind = Kind.FLAG_SET
@export var key: StringName = &""
@export var amount: int = 0
## Invert the result.
@export var negate: bool = false


func is_met(world: WorldState, config: SimConfig, subject: VillagerState = null) -> bool:
	var subject_kind: bool = kind == Kind.SUBJECT_HAS_TRAIT or kind == Kind.SUBJECT_AT_HOME \
			or kind == Kind.SUBJECT_AWAKE
	if subject_kind and subject == null:
		return false
	var result: bool = false
	match kind:
		Kind.HAS_BUILDING:
			result = world.has_building(key)
		Kind.FLAG_SET:
			result = world.has_flag(key)
		Kind.RESOURCE_AT_LEAST:
			result = world.resource_amount(key) >= amount
		Kind.ITEM_AT_LEAST:
			result = world.item_count(key) >= amount
		Kind.CONSTRUCTION_IDLE:
			result = world.constructing() == null
		Kind.DAYS_AT_LEAST:
			result = config.day_of(world.tick) >= amount
		Kind.SUBJECT_HAS_TRAIT:
			result = subject.has_trait(key)
		Kind.SUBJECT_AT_HOME:
			result = not subject.is_away()
		Kind.ERA_AT_LEAST:
			result = world.era_order >= amount
		Kind.ACHIEVEMENT_EARNED:
			result = world.has_achievement(key)
		Kind.SUBJECT_AWAKE:
			result = not config.is_sleeping_hour(config.hour_of(world.tick))
		Kind.ERA_DAYS_AT_LEAST:
			result = config.day_of(world.tick - world.era_started_tick) >= amount
		Kind.HAS_ROOM:
			result = world.room() >= amount
		Kind.SEASON_IS:
			result = config.season_at(world.tick) == amount
		Kind.WEATHER_IS:
			result = world.weather == key
		Kind.HAS_BUILDING_TAG:
			result = not world.damageable_buildings(key).is_empty()
		Kind.HAS_DAMAGED_BUILDING:
			result = world.has_damaged_building()
		Kind.TIDE_LOW:
			result = config.is_low_tide(world.tick)
	return result != negate


static func all_met(
	conditions: Array[SimCondition],
	world: WorldState,
	config: SimConfig,
	subject: VillagerState = null,
) -> bool:
	for condition: SimCondition in conditions:
		if not condition.is_met(world, config, subject):
			return false
	return true
