# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Compares the raw JSON files of two bot runs, file by file, for the same jobs.
##
##   godot --headless --path . --script res://tools/balance/compare_raw.gd -- old=res://docs/balance/raw/2026-10-24 new=res://docs/balance/raw/2026-10-24-bots
##
## Every .json file in `new` that has a file of the same name in `old` is compared. The "seconds"
## field is ignored. `ignore=digest,chain_hash,search_hash` drops those keys everywhere: a digest is
## a hash of the saved battle, and the save format changed in phase 7, so digests differ from older
## files although every play is the same. Exit code 0 when every pair matches.

var _differences: int = 0
var _ignore: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var old_dir: String = ""
	var new_dir: String = ""
	var show: int = 6
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		if parts.size() == 2:
			if parts[0] == "old":
				old_dir = parts[1]
			elif parts[0] == "new":
				new_dir = parts[1]
			elif parts[0] == "show":
				show = int(parts[1])
			elif parts[0] == "ignore":
				_ignore = parts[1].split(",", false)
	var names: PackedStringArray = DirAccess.get_files_at(new_dir)
	names.sort()
	var compared: int = 0
	var identical: int = 0
	for file_name: String in names:
		if not file_name.ends_with(".json") or file_name == "errors.txt":
			continue
		if not FileAccess.file_exists(old_dir + "/" + file_name):
			continue
		var old_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(old_dir + "/" + file_name))
		var new_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(new_dir + "/" + file_name))
		if old_value == null or new_value == null:
			print("%s: cannot be read" % file_name)
			_differences += 1
			continue
		compared += 1
		var lines: PackedStringArray = PackedStringArray()
		_diff(_norm(old_value), _norm(new_value), "", lines)
		if lines.is_empty():
			identical += 1
			print("%s: identical" % file_name)
		else:
			_differences += 1
			print("%s: DIFFERENT (%d places)" % [file_name, lines.size()])
			for i: int in mini(show, lines.size()):
				print("    " + lines[i])
	print("compared %d files, %d identical" % [compared, identical])
	quit(0 if _differences == 0 and compared > 0 else 1)


func _norm(value: Variant) -> Variant:
	if value is Dictionary:
		var src: Dictionary = value
		var out: Dictionary = {}
		for key: Variant in src:
			var item: Variant = src[key]
			if key == "seconds" or _ignore.has(String(key)):
				continue
			out[key] = _norm(item)
		return out
	if value is Array:
		var list_out: Array = []
		for item: Variant in value:
			list_out.append(_norm(item))
		return list_out
	return value


func _diff(a: Variant, b: Variant, path: String, lines: PackedStringArray) -> void:
	if a is Dictionary and b is Dictionary:
		var da: Dictionary = a
		var db: Dictionary = b
		var keys: Array = []
		for key: Variant in da:
			keys.append(key)
		for key: Variant in db:
			if not keys.has(key):
				keys.append(key)
		keys.sort()
		for key: Variant in keys:
			if not da.has(key):
				lines.append("%s/%s: only in new" % [path, key])
			elif not db.has(key):
				lines.append("%s/%s: only in old" % [path, key])
			else:
				_diff(da[key], db[key], "%s/%s" % [path, key], lines)
	elif a is Array and b is Array:
		var xa: Array = a
		var xb: Array = b
		if xa.size() != xb.size():
			lines.append("%s: length %d against %d" % [path, xa.size(), xb.size()])
			return
		for i: int in xa.size():
			_diff(xa[i], xb[i], "%s[%d]" % [path, i], lines)
	elif typeof(a) != typeof(b) or a != b:
		lines.append("%s: %s against %s" % [path, str(a), str(b)])
