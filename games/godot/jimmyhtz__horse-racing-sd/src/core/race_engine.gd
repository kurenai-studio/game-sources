extends RefCounted
## No bets, odds, account balances, render delta or selected winners enter this engine.
const RandomStream = preload("res://core/random_stream.gd")
const MODEL_VERSION := "movement-0.1.0-uncalibrated"
const HORSES := 5
var _rng: RefCounted
var _seed: int
var _config: Dictionary
var _positions := [0.0, 0.0, 0.0, 0.0, 0.0]
var _levels := [2, 2, 2, 2, 2]
var _tie_priority: Array
var _clock := 0.0
var _finishers: Array = []
var _events: Array = []
var _result: Dictionary = {}
var _event_count := 0
var finished := false

static func validate_config(configuration: Dictionary) -> String:
	var allowed := ["finish_steps", "speeds", "initial_levels", "adjustment_chance", "up_bias"]
	for key in configuration:
		if key not in allowed:
			return "Unknown movement setting: " + str(key)
	var speeds: Array = configuration.get("speeds", [0.5, 1.0, 1.5, 2.0, 2.5])
	if speeds.size() != 5:
		return "Exactly five speed levels required"
	var previous := 0.0
	for speed in speeds:
		if not (speed is float or speed is int) or not is_finite(float(speed)) or speed <= previous:
			return "Speed levels must be finite, positive and increasing"
		previous = speed
	var levels: Array = configuration.get("initial_levels", [2,2,2,2,2])
	if levels.size() != 5:
		return "Exactly five initial levels required"
	for level in levels:
		if not level is int or level < 0 or level > 4:
			return "Initial levels must be integers from zero to four"
	var finish: float = configuration.get("finish_steps", 1000.0)
	if not is_finite(finish) or finish <= 0.0:
		return "Finish distance must be positive and finite"
	var chance: float = configuration.get("adjustment_chance", 0.65)
	if not is_finite(chance) or chance < 0.0 or chance > 1.0:
		return "Adjustment chance must be between zero and one"
	var biases: Array = configuration.get("up_bias", [0.54,0.52,0.50,0.48,0.44])
	if biases.size() != 5:
		return "Five movement biases required"
	for bias in biases:
		if not (bias is float or bias is int) or not is_finite(float(bias)) or bias < 0 or bias > 1:
			return "Movement biases must be probabilities"
	return ""

func _init(seed_value: int, configuration: Dictionary = {}) -> void:
	assert(validate_config(configuration).is_empty())
	_seed = seed_value
	_rng = RandomStream.new(seed_value)
	_config = {"finish_steps":1000.0, "speeds":[0.5,1.0,1.5,2.0,2.5], "initial_levels":[2,2,2,2,2], "adjustment_chance":0.65, "up_bias":[0.54,0.52,0.50,0.48,0.44]}
	_config.merge(configuration.duplicate(true), true)
	_levels = _config.initial_levels.duplicate()
	_tie_priority = _rng.permutation(5)

func advance_event() -> void:
	if finished:
		return
	var before := _positions.duplicate()
	var prior_levels := _levels.duplicate()
	var selected: int = _rng.index(HORSES)
	if _rng.unit() < _config.adjustment_chance:
		var direction := 1 if _rng.unit() < _config.up_bias[selected] else -1
		_levels[selected] = clampi(_levels[selected] + direction, 0, 4)
	var velocities: Array = []
	var crossings: Array = []
	for horse in range(HORSES):
		var speed: float = _config.speeds[_levels[horse]]
		velocities.append(speed)
		if before[horse] < _config.finish_steps and before[horse] + speed >= _config.finish_steps:
			crossings.append({"horse":horse, "time":_clock + (_config.finish_steps - before[horse]) / speed})
	crossings.sort_custom(func(a,b):
		if a.time == b.time:
			return _tie_priority.find(a.horse) < _tie_priority.find(b.horse)
		return a.time < b.time)
	var elapsed := 1.0
	for crossing in crossings:
		_finishers.append(crossing)
		if _finishers.size() == 2:
			elapsed = crossing.time - _clock
			finished = true
			break
	for horse in range(HORSES):
		_positions[horse] = before[horse] + velocities[horse] * elapsed
	_event_count += 1
	_events.append({"event":_event_count,"start_time":_clock,"end_time":_clock+elapsed,"start_positions":before,"end_positions":_positions.duplicate(),"prior_levels":prior_levels,"levels":_levels.duplicate(),"velocities":velocities,"selected":selected})
	if _events.size() > 10:
		_events.pop_front()
	_clock += elapsed
	if finished:
		seal_result(velocities)

func seal_result(velocities: Array) -> void:
	var order: Array = [_finishers[0].horse, _finishers[1].horse]
	var rest: Array = []
	for horse in range(HORSES):
		if horse not in order:
			rest.append(horse)
	rest.sort_custom(func(a,b):
		if _positions[a] == _positions[b]:
			return _tie_priority.find(a) < _tie_priority.find(b)
		return _positions[a] > _positions[b])
	order.append_array(rest)
	var pair := [order[0]+1, order[1]+1]
	pair.sort()
	_result = {"schema":1,"model_version":MODEL_VERSION,"seed":_seed,"settings":_config.duplicate(true),"events":_event_count,"first":order[0],"second":order[1],"first_time":_finishers[0].time,"second_time":_finishers[1].time,"order":order,"pair":"%d-%d" % pair,"positions":_positions.duplicate(),"velocities":velocities.duplicate(),"margin":_positions[order[1]]-_positions[order[2]],"tie_priority":_tie_priority.duplicate(),"exact_tie":_finishers[0].time == _finishers[1].time or _positions[order[1]] == _positions[order[2]],"calibrated":false}

func run() -> Dictionary:
	while not finished:
		advance_event()
	return result()

func snapshot() -> Dictionary:
	return {"time":_clock,"positions":_positions.duplicate(),"levels":_levels.duplicate(),"finished":finished}

func result() -> Dictionary:
	return _result.duplicate(true)

func replay_events() -> Array:
	return _events.duplicate(true)

func post_positions(elapsed: float) -> Array:
	assert(finished and elapsed >= 0.0)
	var positions: Array = _result.positions.duplicate()
	var shared_speed: float = _result.velocities[_result.second]
	for horse in _result.order.slice(0,3):
		positions[horse] += shared_speed * elapsed
	var ceiling: float = positions[_result.order[2]] - 0.000001
	for horse in _result.order.slice(3):
		positions[horse] = minf(positions[horse] + _result.velocities[horse] * elapsed, ceiling)
	return positions
