## ObjectPool.gd
## Object Pool pattern — recycles Node3D instances to avoid the GC pressure
## of repeated instantiate() / queue_free() calls during gameplay.
##
## Usage (via ObstacleFactory — do not call directly from spawner):
##   var node := pool.acquire(my_packed_scene)   # reuse or instantiate
##   pool.release(node)                          # recycle for later
##
## Released nodes are kept as disabled children of this node (invisible,
## physics off). acquire() reactivates them on demand; if no pooled instance
## exists for a given scene, a fresh one is instantiated automatically.

class_name ObjectPool
extends Node


## Internal store: maps scene resource_path (String) → Array[Node3D].
## Only inactive (released) nodes live here.
var _inactive: Dictionary = {}


## Return an instance of `scene`, reusing a pooled node when one is available.
## The returned node has NO parent — the caller must add_child() it.
func acquire(scene: PackedScene) -> Node3D:
	var key: String = scene.resource_path
	if _inactive.has(key) and not (_inactive[key] as Array).is_empty():
		var node: Node3D = (_inactive[key] as Array).pop_back()
		remove_child(node)
		node.process_mode = Node.PROCESS_MODE_INHERIT
		node.visible = true
		return node

	# Pool empty for this scene — allocate a new instance.
	return scene.instantiate() as Node3D


## Return `node` to the pool so it can be reused by a future acquire() call.
## The node is hidden, physics-disabled, and reparented to this pool node.
## Do NOT call queue_free() on a node that has been released to the pool.
func release(node: Node3D) -> void:
	var key: String = node.scene_file_path
	if key.is_empty():
		# Node was not instantiated from a PackedScene — fall back to free.
		push_warning("ObjectPool.release: node '%s' has no scene_file_path; freeing instead." % node.name)
		node.queue_free()
		return

	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.visible = false

	var old_parent: Node = node.get_parent()
	if old_parent:
		old_parent.remove_child(node)
	add_child(node)

	if not _inactive.has(key):
		_inactive[key] = []
	(_inactive[key] as Array).append(node)


## Debug helper — returns total pooled (inactive) node count across all scenes.
func pool_size() -> int:
	var total := 0
	for arr: Array in _inactive.values():
		total += arr.size()
	return total
