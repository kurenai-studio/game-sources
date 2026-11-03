class_name ObjectPool
extends RefCounted
## Generic node pool. Released nodes are hidden and their processing disabled
## instead of being freed, so hot paths (bullets, pickups, numbers) don't allocate.

var _factory: Callable
var _parent: Node
var _free: Array[Node] = []
var active: Array[Node] = []
var created: int = 0


func _init(factory: Callable, parent: Node, prewarm: int = 0) -> void:
	_factory = factory
	_parent = parent
	for i in prewarm:
		var n := _create()
		_deactivate(n)
		_free.append(n)


func _create() -> Node:
	var n: Node = _factory.call()
	created += 1
	_parent.add_child(n)
	return n


func _deactivate(n: Node) -> void:
	n.process_mode = Node.PROCESS_MODE_DISABLED
	if n is CanvasItem:
		(n as CanvasItem).visible = false


func acquire() -> Node:
	var n: Node = _free.pop_back() if not _free.is_empty() else _create()
	n.process_mode = Node.PROCESS_MODE_INHERIT
	if n is CanvasItem:
		(n as CanvasItem).visible = true
	active.append(n)
	if n.has_method("on_acquire"):
		n.on_acquire()
	return n


func release(n: Node) -> bool:
	var idx := active.find(n)
	if idx == -1:
		return false
	active.remove_at(idx)
	if n.has_method("on_release"):
		n.on_release()
	_deactivate(n)
	_free.append(n)
	return true


func release_all() -> void:
	for n in active.duplicate():
		release(n)


func active_count() -> int:
	return active.size()


func free_count() -> int:
	return _free.size()
