class_name AtomicFile
extends RefCounted
## Writing a JSON file so a crash or a full disk never leaves a half-written or missing file: the
## text goes to `<path>.tmp` first, is read back to check it, and then replaces the real file.
## The destination is never deleted before it has been replaced. Optionally the previous good
## copy is kept as `<path>.bak`.


## Writes `value` as JSON to `path`. Returns false when the write failed; the previous file is
## then still in place.
static func write_json(path: String, value: Variant, keep_backup: bool = false) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(value))
	file.flush()
	file.close()
	if read_json(tmp) == null:
		DirAccess.remove_absolute(tmp)
		return false
	if keep_backup and read_json(path) != null:
		DirAccess.copy_absolute(path, path + ".bak")
	if DirAccess.rename_absolute(tmp, path) == OK:
		return true
	# Some platforms refuse to rename over an existing file. Overwrite it in place instead of
	# deleting it first, so a failure here still leaves the old file.
	var copied := DirAccess.copy_absolute(tmp, path) == OK
	DirAccess.remove_absolute(tmp)
	return copied


## The parsed JSON in `path`, or null when it is missing or unreadable (no engine error logged).
static func read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return parser.data
