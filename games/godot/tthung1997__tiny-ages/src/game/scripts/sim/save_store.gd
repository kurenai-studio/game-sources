class_name SaveStore
extends RefCounted
## Saves and loads a WorldState as a text resource. Loading executes script references inside
## the file, so only load saves this game wrote, never files from untrusted sources.

const DEFAULT_PATH: String = "user://tiny_ages_save.tres"


static func save_world(world: WorldState, path: String = DEFAULT_PATH) -> Error:
	world.save_version = WorldState.SAVE_VERSION
	var error: Error = ResourceSaver.save(world, path)
	if error != OK:
		push_error("Could not save world to %s (error %d)" % [path, error])
	return error


## Returns the saved world, or null if there is none or it cannot be read.
static func load_world(path: String = DEFAULT_PATH) -> WorldState:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var world: WorldState = loaded as WorldState
	if world == null:
		push_error("Save at %s is not a WorldState" % path)
		return null
	if world.save_version > WorldState.SAVE_VERSION:
		push_error("Save at %s is from a newer version (%d)" % [path, world.save_version])
		return null
	return world


static func exists(path: String = DEFAULT_PATH) -> bool:
	return ResourceLoader.exists(path)
