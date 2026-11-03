class_name PlayerStats
extends RefCounted
## Stat block: final = (base + flat adds) * (1 + sum of multipliers), then clamped.

signal changed(stat: StringName)

const LIMITS := {
	&"fire_rate": Vector2(0.25, 30.0),
	&"crit_chance": Vector2(0.0, 1.0),
	&"dash_cooldown": Vector2(0.25, 10.0),
	&"ability_cooldown": Vector2(0.75, 60.0),
	&"projectile_count": Vector2(1.0, 12.0),
	&"move_speed": Vector2(60.0, 900.0),
	&"armor": Vector2(0.0, 50.0),
}

var base: Dictionary = {}
var adds: Dictionary = {}
var mults: Dictionary = {}


static func defaults() -> Dictionary:
	return {
		&"max_hp": 100.0, &"move_speed": 250.0, &"damage": 12.0, &"fire_rate": 3.0,
		&"projectile_speed": 720.0, &"projectile_count": 1.0, &"pierce": 0.0,
		&"crit_chance": 0.05, &"crit_mult": 1.6, &"pickup_radius": 110.0,
		&"dash_cooldown": 1.0, &"regen": 0.0, &"ability_cooldown": 6.0,
		&"armor": 0.0, &"coin_gain": 1.0, &"ability_power": 40.0,
	}


static func from_character(c: CharacterData) -> PlayerStats:
	var s := PlayerStats.new()
	s.base = defaults()
	s.base[&"max_hp"] = c.max_hp
	s.base[&"move_speed"] = c.move_speed
	s.base[&"damage"] = c.damage
	s.base[&"fire_rate"] = c.fire_rate
	s.base[&"projectile_speed"] = c.projectile_speed
	s.base[&"pierce"] = float(c.pierce)
	s.base[&"ability_cooldown"] = c.ability_cooldown
	s.base[&"ability_power"] = c.ability_power
	return s


func _init() -> void:
	base = defaults()


func get_stat(stat: StringName) -> float:
	var value: float = (float(base.get(stat, 0.0)) + float(adds.get(stat, 0.0))) * (1.0 + float(mults.get(stat, 0.0)))
	if LIMITS.has(stat):
		var lim: Vector2 = LIMITS[stat]
		value = clampf(value, lim.x, lim.y)
	return value


func get_int(stat: StringName) -> int:
	return int(floor(get_stat(stat) + 0.0001))


func add_flat(stat: StringName, amount: float) -> void:
	adds[stat] = float(adds.get(stat, 0.0)) + amount
	changed.emit(stat)


func add_mult(stat: StringName, amount: float) -> void:
	mults[stat] = float(mults.get(stat, 0.0)) + amount
	changed.emit(stat)


func apply_upgrade(u: UpgradeData) -> void:
	if u.mode == UpgradeData.Mode.ADD:
		add_flat(u.stat, u.amount)
	else:
		add_mult(u.stat, u.amount)
