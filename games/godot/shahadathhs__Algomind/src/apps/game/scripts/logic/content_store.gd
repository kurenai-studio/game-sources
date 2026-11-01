class_name ContentStore
extends RefCounted
## Levels and the campaign tree downloaded from the API, kept on the device so they play offline.
##
## Layout under `root`: `campaign.json` (the catalog as served) and `levels/<slug>.json`
## (`{ levelVersion, schemaVersion, par, content }`). Every write goes to a temporary file first
## and replaces the real file by rename, and callers only store content that already passed
## the validator, so a bad response can never replace a good cached copy. A file that cannot be
## read is treated as missing.

var root: String


func _init(directory: String = "user://content") -> void:
	root = directory


func save_catalog(catalog: Dictionary) -> bool:
	return _write("%s/campaign.json" % root, catalog)


func load_catalog() -> Variant:
	var value: Variant = _read("%s/campaign.json" % root)
	return value if typeof(value) == TYPE_DICTIONARY else null


func save_level(slug: String, record: Dictionary) -> bool:
	if not is_safe_name(slug):
		return false
	return _write(_level_path(slug), record)


## The cached record for a slug, or null when it is missing or unreadable.
func load_level(slug: String) -> Variant:
	if not is_safe_name(slug):
		return null
	var value: Variant = _read(_level_path(slug))
	if typeof(value) != TYPE_DICTIONARY:
		return null
	if typeof(value.get("content")) != TYPE_DICTIONARY:
		return null
	return value


## The cached level version for a slug, or 0.
func cached_version(slug: String) -> int:
	var record: Variant = load_level(slug)
	return int(record.get("levelVersion", 0)) if record != null else 0


func clear() -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	for name in dir.get_files():
		DirAccess.remove_absolute("%s/%s" % [root, name])
	var levels := DirAccess.open("%s/levels" % root)
	if levels != null:
		for name in levels.get_files():
			DirAccess.remove_absolute("%s/levels/%s" % [root, name])


func _level_path(slug: String) -> String:
	return "%s/levels/%s.json" % [root, slug]


## Slugs come from the network; allow only the characters the contract allows.
static func is_safe_name(name: String) -> bool:
	if name.is_empty() or name.length() > 64:
		return false
	for i in name.length():
		var c := name.unicode_at(i)
		var ok := (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 45
		if not ok:
			return false
	return not name.begins_with("-") and not name.ends_with("-")


func _write(path: String, value: Dictionary) -> bool:
	return AtomicFile.write_json(path, value)


func _read(path: String) -> Variant:
	return AtomicFile.read_json(path)
