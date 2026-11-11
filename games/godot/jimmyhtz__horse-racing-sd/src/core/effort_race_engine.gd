extends RefCounted
## Serial microturn prototype. Horse dynamics never inspect positions, wagers or past wins.
const RandomStream = preload("res://core/random_stream.gd")
const MODEL_VERSION := "effort-0.2.0-prototype-uncalibrated"
const DEFAULTS := {
	"finish_steps":1000.0, "base_speed":30.0, "speed_spread":0.12,
	"acceleration":0.08, "round_seconds":0.005, "surge_seconds":4.0,
	"recovery_seconds":3.5, "phase_min":1.0, "phase_max":3.0,
	"strengths":[0.10,0.05,0.0,-0.05,-0.10], "record_trace":false
}
var _config: Dictionary
var _seed: int
var _scheduler: RefCounted
var _streams: Array = []
var _positions := [0.0,0.0,0.0,0.0,0.0]
var _speeds: Array = []
var _effort: Array = []
var _phases := [0,0,0,0,0]
var _targets: Array = []
var _phase_remaining := [0.0,0.0,0.0,0.0,0.0]
var _order: Array = []
var _slot := 5
var _round := 0
var _clock := 0.0
var _event_count := 0
var _finishers: Array = []
var _result: Dictionary = {}
var _trace: Array[PackedFloat64Array] = []
var _last_selected := -1
var _last_before := 0.0
var _last_start := 0.0
var finished := false

static func validate_config(configuration: Dictionary) -> String:
	for key in configuration:
		if not DEFAULTS.has(key):
			return "Unknown movement setting: " + str(key)
	var c := DEFAULTS.duplicate(true)
	c.merge(configuration, true)
	for key in ["finish_steps","base_speed","speed_spread","acceleration","round_seconds","surge_seconds","recovery_seconds","phase_min","phase_max"]:
		var value = c[key]
		if not (value is int or value is float) or not is_finite(float(value)):
			return "Movement values must be finite numbers"
	if c.finish_steps <= 0 or c.base_speed <= 0 or c.speed_spread < 0 or c.speed_spread > 0.4:
		return "Positive distance/pace and speed spread from 0 to 0.4 required"
	if c.acceleration <= 0 or c.acceleration > 1 or c.round_seconds < 0.001 or c.round_seconds > 0.1:
		return "Acceleration or tick resolution outside supported range"
	if c.surge_seconds <= 0 or c.recovery_seconds <= 0 or c.phase_min <= 0 or c.phase_max < c.phase_min:
		return "Invalid effort or phase duration"
	if not c.record_trace is bool or not c.strengths is Array or c.strengths.size() != 5:
		return "Five strengths and a boolean trace flag required"
	for strength in c.strengths:
		if not (strength is int or strength is float) or not is_finite(float(strength)) or absf(float(strength)) > 0.3:
			return "Strengths must be finite numbers from -0.3 to 0.3"
	var maximum_speed: float = c.base_speed*(1.0+c.speed_spread)
	var minimum_quantum: float = c.base_speed*(1.0-c.speed_spread)*c.round_seconds
	var maximum_quantum: float = maximum_speed*c.round_seconds
	if not is_finite(maximum_speed) or not is_finite(maximum_quantum) or minimum_quantum <= 0.0 or not is_finite(c.finish_steps+maximum_quantum):
		return "Derived movement values exceed finite numerical limits"
	var estimated_rounds: float = c.finish_steps/minimum_quantum
	if not is_finite(estimated_rounds) or ceilf(estimated_rounds)*5.0 > 300000:
		return "Configuration exceeds the bounded prototype event limit"
	return ""

func _init(seed_value: int, configuration: Dictionary = {}) -> void:
	assert(validate_config(configuration).is_empty())
	_seed = seed_value
	_config = DEFAULTS.duplicate(true)
	_config.merge(configuration.duplicate(true), true)
	_scheduler = RandomStream.new(seed_value)
	for horse in range(5):
		var stream := RandomStream.new(seed_value + 7919*(horse+1))
		_streams.append(stream)
		_speeds.append(float(_config.base_speed))
		_targets.append(float(_config.base_speed))
		_effort.append(0.45 + 0.4*stream.unit())
	if _config.record_trace:
		_trace.append(PackedFloat64Array(_positions))

func _advance_effort(horse: int) -> void:
	var dt: float = _config.round_seconds
	var stream: RefCounted = _streams[horse]
	var spread: float = _config.speed_spread
	var relative: float = (_speeds[horse]/_config.base_speed-1.0)/maxf(spread,0.000001)
	if relative > 0:
		_effort[horse] = maxf(0.0, _effort[horse]-relative*dt/_config.surge_seconds)
	elif relative < 0:
		_effort[horse] = minf(1.0, _effort[horse]-relative*dt/_config.recovery_seconds)
	else:
		_effort[horse] = minf(1.0, _effort[horse]+0.02*dt)
	_phase_remaining[horse] -= dt
	if _phase_remaining[horse] <= 0:
		var surge_probability: float = clampf(0.12+0.70*_effort[horse]+_config.strengths[horse],0.02,0.95)
		var draw: float = stream.unit()
		var amplitude: float = spread*(0.4+0.6*stream.unit())
		if draw < surge_probability:
			_phases[horse] = 1
			_targets[horse] = _config.base_speed*(1.0+amplitude)
		elif draw < surge_probability+(1.0-surge_probability)*0.75:
			_phases[horse] = -1
			_targets[horse] = _config.base_speed*(1.0-amplitude)
		else:
			_phases[horse] = 0
			_targets[horse] = _config.base_speed
		_phase_remaining[horse] = lerpf(_config.phase_min,_config.phase_max,stream.unit())
	# Exhaustion affects only this horse's ability to sustain effort, regardless of its standing.
	if _effort[horse] <= 0.01 and _targets[horse] > _config.base_speed:
		_targets[horse] = _config.base_speed*(1.0-0.5*spread)
		_phases[horse] = -1
	_speeds[horse] = move_toward(_speeds[horse], _targets[horse], _config.base_speed*_config.acceleration*dt)

func advance_event() -> void:
	if finished:
		return
	if _slot == 5:
		_order = _scheduler.permutation(5)
		_slot = 0
		_round += 1
	var horse: int = _order[_slot]
	_last_selected = horse
	_last_before = _positions[horse]
	_last_start = _clock
	_advance_effort(horse)
	var turn_seconds: float = _config.round_seconds/5.0
	# One round grants each horse speed * round_seconds distance. Order only assigns its microturn.
	var distance: float = _speeds[horse]*_config.round_seconds
	var fraction := 1.0
	if _last_before < _config.finish_steps and _last_before+distance >= _config.finish_steps:
		var crossing_fraction: float = (_config.finish_steps-_last_before)/distance
		_finishers.append({"horse":horse,"time":_clock+turn_seconds*crossing_fraction})
		if _finishers.size() == 2:
			fraction = crossing_fraction
			finished = true
	_positions[horse] += distance*fraction
	_clock += turn_seconds*fraction
	_slot += 1
	_event_count += 1
	if _config.record_trace:
		_trace.append(PackedFloat64Array(_positions))
	if finished:
		_seal()

func _seal() -> void:
	var order: Array = [_finishers[0].horse,_finishers[1].horse]
	var rest: Array = []
	for horse in range(5):
		if horse not in order:
			rest.append(horse)
	rest.sort_custom(func(a,b): return _positions[a] > _positions[b] if _positions[a] != _positions[b] else _order.find(a) < _order.find(b))
	order.append_array(rest)
	var pair: Array = [order[0]+1,order[1]+1]
	pair.sort()
	var saved_config := _config.duplicate(true)
	saved_config.erase("record_trace")
	_result = {"schema":1,"model_version":MODEL_VERSION,"seed":_seed,"settings":saved_config,
		"events":_event_count,"rounds":_round,"first":order[0],"second":order[1],
		"first_time":_finishers[0].time,"second_time":_finishers[1].time,"order":order,
		"pair":"%d-%d" % pair,"positions":_positions.duplicate(),"velocities":_speeds.duplicate(),
		"margin":_positions[order[1]]-_positions[order[2]],"calibrated":false}

func run() -> Dictionary:
	while not finished:
		advance_event()
	return result()

func result() -> Dictionary:
	return _result.duplicate(true)

func snapshot() -> Dictionary:
	return {"time":_clock,"positions":_positions.duplicate(),"velocities":_speeds.duplicate(),
		"effort":_effort.duplicate(),"phases":_phases.duplicate(),"finished":finished}

func last_event() -> Dictionary:
	var before := _positions.duplicate()
	if _last_selected >= 0:
		before[_last_selected] = _last_before
	return {"event":_event_count,"round":_round,"slot":_slot-1,"selected":_last_selected,
		"start_time":_last_start,"end_time":_clock,"start_positions":before,"end_positions":_positions.duplicate()}

func positions_at(time: float) -> Array:
	assert(_config.record_trace and not _trace.is_empty())
	if time <= 0:
		return Array(_trace[0])
	if time >= _clock:
		return _positions.duplicate()
	var turn_seconds: float = _config.round_seconds/5.0
	var index := mini(int(floorf(time/turn_seconds)),_trace.size()-2)
	var start_time: float = index*turn_seconds
	var end_time: float = minf((index+1)*turn_seconds,_clock)
	var alpha := clampf((time-start_time)/(end_time-start_time),0.0,1.0)
	var positions: Array = []
	for horse in range(5):
		positions.append(lerpf(_trace[index][horse],_trace[index+1][horse],alpha))
	return positions
