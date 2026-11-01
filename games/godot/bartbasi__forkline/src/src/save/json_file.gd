# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name JsonFile
extends RefCounted
## The only JSON file reader and writer (docs/ARCHITECTURE.md 2.12, 3.5, 5.2, 5.3).
## Reading takes a size cap, refuses any byte that is not plain ASCII, and goes
## through Godot's JSON parser only. Nothing here can make an object from file data.

const OK_STATUS: StringName = &"ok"
const MISSING: StringName = &"missing"
const LOCKED: StringName = &"locked"
const BAD: StringName = &"bad"
const TMP: String = ".tmp"
const BAK: String = ".bak"


## {"status": StringName, "data": Variant, "text": String}. Status: &"ok", &"missing",
## &"locked" (exists, cannot be opened) or &"bad" (over max_bytes, a NUL byte or a byte
## of 0x80 or above, or not valid JSON). "data" is null and "text" is "" unless ok.
static func read(path: String, max_bytes: int) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var why: int = FileAccess.get_open_error()
		return _result(MISSING if why == ERR_FILE_NOT_FOUND else LOCKED)
	var size: int = file.get_length()
	if size > max_bytes:
		file.close()
		return _result(BAD)
	var bytes: PackedByteArray = file.get_buffer(size)
	var read_error: int = file.get_error()
	file.close()
	if bytes.size() != size or (read_error != OK and read_error != ERR_FILE_EOF):
		return _result(BAD)
	if not is_ascii(bytes):
		return _result(BAD)
	var text: String = bytes.get_string_from_ascii()
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK:
		return _result(BAD)
	return {"status": OK_STATUS, "data": parser.data, "text": text}


## &"missing", &"locked" or &"ok" (it opens), without reading anything.
static func probe(path: String) -> StringName:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return MISSING if FileAccess.get_open_error() == ERR_FILE_NOT_FOUND else LOCKED
	file.close()
	return OK_STATUS


## No NUL byte and no byte of 0x80 or above. Each check is one native scan.
static func is_ascii(bytes: PackedByteArray) -> bool:
	if bytes.has(0):
		return false
	for value: int in range(128, 256):
		if bytes.has(value):
			return false
	return true


## The text a write would store: JSON with sorted keys. "" when it is not plain ASCII.
static func to_text(data: Dictionary) -> String:
	var text: String = JSON.stringify(data, "", true)
	if text.is_empty() or text.to_utf8_buffer().size() != text.length():
		return ""
	return text


## Writes data atomically (section 5.3). The file now at path moves to path.bak only
## when it holds exactly backup_of, the text the caller last wrote or loaded as valid.
## False when nothing was written or the final rename failed. After a failed rename the
## .tmp holds the newest complete save, and the next load uses it.
static func write_atomic(path: String, data: Dictionary, backup_of: String = "") -> bool:
	var text: String = to_text(data)
	if text.is_empty():
		return false
	return write_text(path, text, backup_of)


## write_atomic for text already made by to_text().
static func write_text(path: String, text: String, backup_of: String = "") -> bool:
	if text.is_empty() or not path.begins_with("user://"):
		return false
	var expected: PackedByteArray = text.to_ascii_buffer()
	if expected.size() != text.length() or not is_ascii(expected):
		return false
	var tmp_path: String = path + TMP
	var out: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if out == null:
		return false
	var stored: bool = out.store_buffer(expected)
	out.flush()
	var write_error: int = out.get_error()
	out.close()
	if not stored or write_error != OK or not _holds(tmp_path, expected):
		DirAccess.remove_absolute(tmp_path)
		return false
	if not backup_of.is_empty() and _holds(path, backup_of.to_ascii_buffer()):
		# A failed backup rename is fine: carry on without a fresh backup.
		DirAccess.rename_absolute(path, path + BAK)
	return DirAccess.rename_absolute(tmp_path, path) == OK


## Removes one file if it is there. True when it is gone afterwards.
static func remove(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK


## True when the file at path holds exactly these bytes.
static func _holds(path: String, expected: PackedByteArray) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	if file.get_length() != expected.size():
		file.close()
		return false
	var bytes: PackedByteArray = file.get_buffer(expected.size())
	file.close()
	return bytes == expected


static func _result(status: StringName) -> Dictionary:
	return {"status": status, "data": null, "text": ""}
