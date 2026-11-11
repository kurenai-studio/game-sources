extends RefCounted
# Oracle-checked movement kernel. The account adapter supplies the locked card.
const Stream = preload("res://core/crypto_stream.gd")
const PAIRS := [[0,1],[0,2],[0,3],[0,4],[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
const ROUND_SECONDS := 0.005
const TURN_SECONDS := ROUND_SECONDS/5.0
var finished := false
var _master: String
var _percent: int
var _distance: int
var _scale: float
var _thresholds: Array = []
var _streams: Array = []
var _scheduler: RefCounted
var _units := [0,0,0,0,0]
var _positions := [0.0,0.0,0.0,0.0,0.0]
var _order: Array = []
var _slot := 5
var _round := 0
var _events := 0
var _finishers: Array = []
var _result := {}
var _event := {}
var _record: bool
var _trace: Array[PackedFloat64Array] = []
var _times: PackedFloat64Array = []
var _second_positions: Array = []
var _profile: int
var _component: int
var _control: RefCounted

func _init(master: String, catalog: Dictionary, percent: int = 90, record_trace: bool = false, controls: Dictionary = {}) -> void:
	assert(master.length() == 64 and master.is_valid_hex_number(false))
	assert(catalog.schema == 1 and catalog.cards.has(str(percent)))
	assert(float(catalog.round_seconds) == ROUND_SECONDS and int(catalog.distance_units) >= 2)
	_master=master
	_percent=percent
	_record=record_trace
	_distance=int(catalog.distance_units)
	_scale=1000.0/_distance
	var card: Dictionary = catalog.cards[str(percent)]
	_component=int(card.component)
	var component: Dictionary = catalog.components[_component]
	var parameters = Stream.new(master,"payback-v1:parameters")
	var draw: int = (parameters.raw()<<16) | (parameters.raw() & 65535)
	var cumulative := 0
	_profile=-1
	for i in range(10):
		cumulative += int(card.profile_units[i])
		if _profile < 0 and draw < cumulative:
			_profile=i
	assert(cumulative == 281474976710656 and _profile >= 0)
	_scheduler=Stream.new(master,"payback-v1:scheduler")
	for horse in range(5):
		_thresholds.append(int(component.high_threshold if horse in PAIRS[_profile] else component.low_threshold))
		assert(_thresholds.back() > 0 and _thresholds.back() < 4294967296)
		_streams.append(Stream.new(master,"payback-v1:horse:%d" % horse))
	_control=preload("res://core/full_course_pacing.gd").new(master,_streams,_thresholds,_distance,controls)
	if _record:
		_trace.append(PackedFloat64Array(_positions))
		_times.append(0.0)

func advance_event() -> void:
	if finished:
		return
	if _slot == 5:
		_order=_scheduler.permutation(5)
		_slot=0
		_round+=1
	var horse: int = _order[_slot]
	var before: Array = _positions.duplicate()
	var step: float=2 if _streams[horse].raw() < _thresholds[horse] else 1
	var previous: float = _units[horse]
	_units[horse] += step
	_positions[horse]=_control.position(horse,_units[horse]) if _control.active else _units[horse]*_scale
	var effort_start := _events*TURN_SECONDS
	var start_time: float=_control.clock(effort_start)
	var end_time: float=_control.clock((_events+1)*TURN_SECONDS)
	if previous < _distance and _units[horse] >= _distance:
		var fraction: float=(1000.0-before[horse])/(_positions[horse]-before[horse]) if _control.active else float(_distance-previous)/step
		_finishers.append({"horse":horse,"time":lerpf(start_time,end_time,fraction)})
		if _finishers.size() == 2:
			_second_positions=_positions.duplicate()
			_second_positions[horse]=1000.0
	_events+=1
	_slot+=1
	_event={"event":_events,"round":_round,"slot":_slot-1,"selected":horse,
		"start_time":start_time,"end_time":_control.clock(_events*TURN_SECONDS),
		"start_positions":before,"end_positions":_positions.duplicate()}
	if _record:
		_trace.append(PackedFloat64Array(_positions))
		_times.append(end_time)
	if _finishers.size() == 5:
		finished=true
		_seal()

func _seal() -> void:
	var order: Array = []
	for crossing in _finishers:
		order.append(crossing.horse)
	var pair := [order[0]+1,order[1]+1]
	pair.sort()
	_result={"model_version":"positive-step-mixture-v1","seed":_master,"percent":_percent,
		"movement_component":_component,"trajectory_version":"full-course-positive-stride-v1",
		"events":_events,"rounds":_round,"round_seconds":ROUND_SECONDS,
		"first":order[0],"second":order[1],"first_time":_finishers[0].time,
		"second_time":_finishers[1].time,"full_order":order,"crossings":_finishers.duplicate(true),
		"pair":"%d-%d" % pair,"positions":_second_positions.duplicate(),
		"final_positions":_positions.duplicate(),"calibrated":false}

func run() -> Dictionary:
	while not finished:
		advance_event()
	return result()

func result() -> Dictionary:
	return _result.duplicate(true)

func race_control_summary() -> Dictionary:
	return _control.summary()

func snapshot() -> Dictionary:
	return {"time":_control.clock(_events*TURN_SECONDS),"positions":_positions.duplicate(),"finished":finished}

func last_event() -> Dictionary:
	return _event.duplicate(true)

func positions_at(time: float) -> Array:
	assert(_record and not _trace.is_empty())
	if time <= 0:
		return Array(_trace[0])
	if time >= _control.clock(_events*TURN_SECONDS):
		return _positions.duplicate()
	var low:=0
	var high:=_times.size()-1
	while high-low>1:
		var middle: int=(low+high)/2
		if _times[middle]<=time: low=middle
		else: high=middle
	var index := mini(low,_trace.size()-2)
	var alpha := clampf((time-_times[index])/(_times[index+1]-_times[index]),0.0,1.0)
	var values: Array = []
	for h in range(5):
		values.append(lerpf(_trace[index][h],_trace[index+1][h],alpha))
	return values
