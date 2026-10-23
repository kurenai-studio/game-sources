extends Resource
class_name WaveDefinition

## Stable numeric wave order within a stage.
@export_range(1, 999, 1) var wave: int = 1
## Unique resource id used for references, filenames, and tooling.
@export var id: StringName = &"wave_01"
## Human-readable name shown in the editor and debug UI.
@export var display_name: String = "Wave 01"
## Base duration of the wave in seconds before advancing to the next one.
@export_range(1.0, 600.0, 0.5) var duration: float = 45.0
## Total enemy budget the wave can spend on spawns.
@export_range(0, 5000, 1) var spawn_budget: int = 20
## Maximum number of enemies allowed alive at the same time.
@export_range(1, 2000, 1) var max_alive: int = 80
## Base time between spawn ticks at the start of the wave.
@export_range(0.05, 30.0, 0.05) var spawn_interval: float = 1.25
## Seconds between each spawn interval increase.
@export_range(0.0, 600.0, 0.5) var spawn_interval_step_seconds: float = 10.0
## Amount added to the spawn interval every time the step duration elapses.
@export_range(-10.0, 10.0, 0.05) var spawn_interval_step_amount: float = 0.1
## Weighted enemy pools available for this wave.
@export var enemy_pools: Array[Resource] = []
## Optional scripted events that fire at specific times during the wave.
@export var events: Array[Resource] = []


func get_safe_duration() -> float:
	return maxf(duration, 1.0)


func get_safe_spawn_interval() -> float:
	return maxf(spawn_interval, 0.05)


func get_spawn_interval_at(elapsed_seconds: float) -> float:
	var interval := get_safe_spawn_interval()
	if spawn_interval_step_seconds <= 0.0 or is_zero_approx(spawn_interval_step_amount):
		return interval

	var step_count := floori(maxf(elapsed_seconds, 0.0) / spawn_interval_step_seconds)
	return maxf(interval + float(step_count) * spawn_interval_step_amount, 0.05)


func get_safe_max_alive() -> int:
	return maxi(max_alive, 1)


func get_safe_spawn_budget() -> int:
	return maxi(spawn_budget, 0)


func get_total_weight() -> int:
	var total_weight := 0
	for rule in enemy_pools:
		if rule == null or not (rule is WaveEnemyRule):
			continue
		total_weight += maxi(rule.weight, 0)

	return total_weight


func pick_enemy_rule(rng: RandomNumberGenerator) -> Resource:
	var total_weight := get_total_weight()
	if total_weight <= 0:
		return null

	var cursor := rng.randi_range(1, total_weight)
	for rule in enemy_pools:
		if rule == null or not (rule is WaveEnemyRule):
			continue

		cursor -= maxi(rule.weight, 0)
		if cursor <= 0:
			return rule

	return null
