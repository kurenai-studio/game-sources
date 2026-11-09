@tool
class_name SpawnWave
extends Resource
## One timed spawn rule for [HordeSpawner].
## Spawns [member batch_size] copies of [member enemy_scene] every
## [member interval] seconds, from [member start_time] (inclusive)
## until [member end_time] (exclusive). Times are run time in seconds.

const FLOAT_EPSILON := 1e-6

@export var enemy_scene: PackedScene
@export_range(0.0, 3600.0, 0.1, "suffix:s") var start_time: float = 0.0
@export_range(0.0, 3600.0, 0.1, "suffix:s") var end_time: float = 60.0
@export_range(0.05, 60.0, 0.05, "suffix:s") var interval: float = 1.0
@export_range(1, 100) var batch_size: int = 1


func is_active(elapsed: float) -> bool:
	return elapsed >= start_time and elapsed < end_time


## Total number of batches that should have fired once [param elapsed]
## seconds have passed. Batch k fires at start_time + k * interval.
func batches_due(elapsed: float) -> int:
	if elapsed < start_time or end_time <= start_time:
		return 0
	var safe_interval := maxf(interval, 0.001)
	# Epsilon absorbs float error, e.g. 0.3 / 0.1 == 2.9999999999999996.
	var fired := floori((elapsed - start_time) / safe_interval + FLOAT_EPSILON) + 1
	var total := ceili((end_time - start_time) / safe_interval - FLOAT_EPSILON)
	return mini(fired, total)
