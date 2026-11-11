extends "res://core/step_motion.gd"
# Presentation/account adapter around the oracle-checked positive-step process.
const Odds = preload("res://core/calibrated_odds.gd")
var _labels: Array
var _history: Array = []
var _captured_second := false
var _last_steps := [1.0,1.0,1.0,1.0,1.0]
var _official_velocities: Array = []
var _second_priority: Array = []
var _continuation: Array = []
var _end_velocities := [0.0,0.0,0.0,0.0,0.0]

func _init(master: String, board: Dictionary, controls: Dictionary = {}) -> void:
	assert(Odds.new().valid_board(board,int(board.requested_rtp)))
	_labels=board.permutation.duplicate()
	super(master,Odds.catalog_for_board(board),int(board.requested_rtp),false,controls)

func _map_positions(values: Array) -> Array:
	var mapped := [0.0,0.0,0.0,0.0,0.0]
	for h in range(5): mapped[_labels[h]]=values[h]
	return mapped

func advance_event() -> void:
	if finished: return
	super()
	var full_event: Dictionary=super.last_event()
	var selected: int=full_event.selected
	_end_velocities[selected]=(full_event.end_positions[selected]-full_event.start_positions[selected])/maxf(0.000000001,5.0*(full_event.end_time-full_event.start_time))
	if not _captured_second:
		var event: Dictionary=super.last_event()
		var h: int=event.selected
		_last_steps[h]=(event.end_positions[h]-event.start_positions[h])/maxf(0.000000001,5.0*(event.end_time-event.start_time)) if _control.active else roundi((event.end_positions[h]-event.start_positions[h])/_scale)*_scale/ROUND_SECONDS
		event.selected=_labels[h]
		event.start_positions=_map_positions(event.start_positions)
		event.end_positions=_map_positions(event.end_positions)
		if _finishers.size()>=2:
			_captured_second=true
			event.end_time=_finishers[1].time
			event.end_positions=_map_positions(_second_positions)
			_second_priority=_order.duplicate()
			for speed in _last_steps: _official_velocities.append(float(speed))
			_continuation.append({"time":event.end_time,"positions":event.end_positions.duplicate()})
		_history.append(event)
		if _history.size()>10: _history.pop_front()
	if _captured_second and full_event.end_time>_continuation.back().time:
		_continuation.append({"time":full_event.end_time,"positions":_map_positions(full_event.end_positions)})

func _seal() -> void:
	super()
	var canonical_order: Array=_result.full_order.duplicate()
	_result.first=_labels[_result.first]
	_result.second=_labels[_result.second]
	_result.full_order=[]
	for horse in canonical_order: _result.full_order.append(_labels[horse])
	for crossing in _result.crossings: crossing.horse=_labels[crossing.horse]
	_result.positions=_map_positions(_result.positions)
	_result.final_positions=_map_positions(_result.final_positions)
	_result.velocities=_map_positions(_official_velocities)
	var pair := [_result.first+1,_result.second+1]
	pair.sort()
	_result.pair="%d-%d" % pair
	var rest: Array=[]
	for h in range(5):
		if h not in canonical_order.slice(0,2): rest.append(h)
	rest.sort_custom(func(a,b):
		return _second_positions[a]>_second_positions[b] if _second_positions[a]!=_second_positions[b] else _second_priority.find(a)<_second_priority.find(b))
	_result.order=[_result.first,_result.second]
	for horse in rest: _result.order.append(_labels[horse])
	_result.margin=_result.positions[_result.second]-_result.positions[_result.order[2]]
	_result.schema=2
	_result.calibrated=true

func snapshot() -> Dictionary:
	var state: Dictionary=super()
	state.positions=_map_positions(state.positions)
	return state

func last_event() -> Dictionary:
	var event: Dictionary=super()
	if event.is_empty(): return event
	event.selected=_labels[event.selected]
	event.start_positions=_map_positions(event.start_positions)
	event.end_positions=_map_positions(event.end_positions)
	return event

func replay_events() -> Array:
	return _history.duplicate(true)

func post_positions(elapsed: float) -> Array:
	assert(finished and elapsed>=0.0)
	var time: float=_result.second_time+elapsed
	var last: Dictionary=_continuation.back()
	if time>=last.time:
		var positions: Array=last.positions.duplicate()
		var velocities: Array=_map_positions(_end_velocities)
		for h in range(5):positions[h]+=velocities[h]*(time-last.time)
		return positions
	var low:=0;var high:=_continuation.size()-1
	while high-low>1:
		var middle: int=(low+high)/2
		if _continuation[middle].time<=time:low=middle
		else:high=middle
	var a: Dictionary=_continuation[low];var b: Dictionary=_continuation[high]
	var alpha: float=clampf((time-a.time)/(b.time-a.time),0,1)
	var positions: Array=[]
	for h in range(5):positions.append(lerpf(a.positions[h],b.positions[h],alpha))
	return positions
