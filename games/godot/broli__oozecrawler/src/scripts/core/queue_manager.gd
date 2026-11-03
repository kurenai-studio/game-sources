class_name QueueManager

extends RefCounted

#buffer a and b for queueing up the kernoj
var _primary: Array[int]
var _secondary: Array[int]

func _init():
	_primary = initialize_queue()
	_secondary = initialize_queue()

func initialize_queue() -> Array[int]:
	var temp_queue: Array[int] = [1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,4,4,5]
	temp_queue.shuffle()
	return temp_queue

func get_next() -> int:
	if _primary.size() == 0:
		_primary = _secondary
		_secondary = initialize_queue()
	return _primary.pop_front()

func peek(index: int) -> int:
	if index < _primary.size():
		return _primary[index]
	elif index < _primary.size() + _secondary.size():
		return _secondary[index - _primary.size()]
	else:
		return -1