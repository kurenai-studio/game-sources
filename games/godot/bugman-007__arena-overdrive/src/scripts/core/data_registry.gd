class_name DataRegistry
extends RefCounted
## Loads every .tres in a data folder (export-safe: handles .remap).


static func load_dir(dir_path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("DataRegistry: missing folder %s" % dir_path)
		return out
	var files := dir.get_files()
	files.sort()
	for f in files:
		var file := f.trim_suffix(".remap")
		if file.ends_with(".tres"):
			var res := load(dir_path.path_join(file))
			if res:
				out.append(res)
	return out


static func characters() -> Dictionary:
	var d := {}
	for r in load_dir("res://data/characters"):
		d[(r as CharacterData).id] = r
	return d


static func enemies() -> Dictionary:
	var d := {}
	for r in load_dir("res://data/enemies"):
		d[(r as EnemyData).id] = r
	return d


static func upgrades() -> Array[UpgradeData]:
	var out: Array[UpgradeData] = []
	for r in load_dir("res://data/upgrades"):
		out.append(r as UpgradeData)
	return out
