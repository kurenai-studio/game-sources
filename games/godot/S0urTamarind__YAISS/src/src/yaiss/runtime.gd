extends RefCounted
const Log = preload("res://src/yaiss/logging.gd")

# TODO: Look into whether we need an assert wrapper? I dont think so.

static func yaiss_error(msg: String, tags: Array[String] = []) -> void:
	Log.record_error(msg, tags)
	push_error(msg)
	Log.record_error("--- stacktrace printed below ---")
	print_stack()
	return

static func yaiss_fatal(msg: String, tree: SceneTree, tags: Array[String] = []) -> void:
	Log.record_fatal(msg, tags)
	push_error(msg)
	Log.record_error("--- stacktrace printed below ---")
	print_stack()
	tree.quit(1)
	return

	
	
