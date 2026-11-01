# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name DataCheck
extends RefCounted
## Field by field checks for parsed JSON data and saved battles (docs/ARCHITECTURE.md 2.12).
## Used by src/sim/, src/save/ and src/run/. Nobody else. Each reader checks one field,
## records a plain problem line when it is wrong, and returns a safe fallback so the
## caller can keep checking.
## Godot's JSON parser gives every number as a non-integer type, so a number is
## accepted when it is whole, finite and in range, and is then converted to int.

## Any number past this size is refused before it is converted.
const LIMIT: int = 1000000000000000
const ID_MAX: int = 32

var file: String = ""
var problems: PackedStringArray = PackedStringArray()


func _init(file_name: String = "") -> void:
	file = file_name


func fail(path: String, why: String) -> void:
	if file.is_empty():
		problems.append("%s: %s" % [path, why])
	else:
		problems.append("%s: %s: %s" % [file, path, why])


func ok() -> bool:
	return problems.is_empty()


static func join(path: String, key: String) -> String:
	return key if path.is_empty() else path + "." + key


## True for an int, or a whole, finite JSON number below LIMIT.
static func is_whole(value: Variant) -> bool:
	var kind: int = typeof(value)
	if kind == TYPE_INT:
		return true
	if kind != TYPE_FLOAT:
		return false
	if not (value > -LIMIT and value < LIMIT):
		return false
	return value == int(value)


static func is_string(value: Variant) -> bool:
	var kind: int = typeof(value)
	return kind == TYPE_STRING or kind == TYPE_STRING_NAME


## An id: 1 to 32 characters of a to z, 0 to 9 and _, starting with a letter.
static func is_id(value: Variant) -> bool:
	if not is_string(value):
		return false
	var text: String = String(value)
	if text.length() < 1 or text.length() > ID_MAX:
		return false
	for i: int in text.length():
		var c: int = text.unicode_at(i)
		var letter: bool = c >= 97 and c <= 122
		if i == 0 and not letter:
			return false
		if not (letter or (c >= 48 and c <= 57) or c == 95):
			return false
	return true


## Display text: 1 to max_len characters of printable ASCII.
static func is_text(value: Variant, max_len: int) -> bool:
	if not is_string(value):
		return false
	var text: String = String(value)
	if text.length() < 1 or text.length() > max_len:
		return false
	for i: int in text.length():
		var c: int = text.unicode_at(i)
		if c < 32 or c > 126:
			return false
	return true


## Checks that value is a Dictionary whose keys are all strings in required or
## optional, and that every required key is there. Returns true when value is a
## Dictionary, so the caller can go on reading its fields.
func object(value: Variant, path: String, required: PackedStringArray, optional: PackedStringArray = PackedStringArray()) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		fail(path, "must be an object")
		return false
	var data: Dictionary = value
	for key: Variant in data.keys():
		if typeof(key) != TYPE_STRING or (not required.has(key) and not optional.has(key)):
			fail(path, "unknown key %s" % str(key).left(ID_MAX).c_escape())
	for key: String in required:
		if not data.has(key):
			fail(join(path, key), "is missing")
	return true


## A whole number lo to hi, a multiple of step. Missing gives fallback with no problem
## (object() reports missing required keys).
func integer(data: Dictionary, key: String, path: String, lo: int, hi: int, step: int = 1, fallback: int = 0) -> int:
	if not data.has(key):
		return fallback
	return whole(data[key], join(path, key), lo, hi, step, fallback)


func whole(value: Variant, path: String, lo: int, hi: int, step: int = 1, fallback: int = 0) -> int:
	if not is_whole(value):
		fail(path, "must be a whole number")
		return fallback
	var number: int = int(value)
	if number < lo or number > hi:
		fail(path, "must be %d to %d" % [lo, hi])
		return fallback
	if step > 1 and number % step != 0:
		fail(path, "must be a multiple of %d" % step)
		return fallback
	return number


func boolean(data: Dictionary, key: String, path: String, fallback: bool = false) -> bool:
	if not data.has(key):
		return fallback
	if typeof(data[key]) != TYPE_BOOL:
		fail(join(path, key), "must be true or false")
		return fallback
	return data[key]


func ident(data: Dictionary, key: String, path: String) -> StringName:
	if not data.has(key):
		return &""
	return ident_value(data[key], join(path, key))


func ident_value(value: Variant, path: String) -> StringName:
	if not is_id(value):
		fail(path, "must be an id")
		return &""
	return StringName(String(value))


func text(data: Dictionary, key: String, path: String, max_len: int) -> String:
	if not data.has(key):
		return ""
	if not is_text(data[key], max_len):
		fail(join(path, key), "must be 1 to %d characters of printable ASCII" % max_len)
		return ""
	return String(data[key])


## An array of lo to hi items, or [] with a problem.
func array(data: Dictionary, key: String, path: String, lo: int, hi: int) -> Array:
	if not data.has(key):
		return []
	return array_value(data[key], join(path, key), lo, hi)


func array_value(value: Variant, path: String, lo: int, hi: int) -> Array:
	if typeof(value) != TYPE_ARRAY:
		fail(path, "must be an array")
		return []
	var items: Array = value
	if items.size() < lo or items.size() > hi:
		fail(path, "must hold %d to %d items" % [lo, hi])
		return []
	return items


## A cell [column, row] inside a map of 7 columns and the given rows. (-1, -1) when wrong.
func cell(value: Variant, path: String, rows: int) -> Vector2i:
	var bad: Vector2i = Vector2i(-1, -1)
	if typeof(value) != TYPE_ARRAY:
		fail(path, "must be a cell [column, row]")
		return bad
	var pair: Array = value
	if pair.size() != 2 or not is_whole(pair[0]) or not is_whole(pair[1]):
		fail(path, "must be a cell [column, row]")
		return bad
	var c: int = int(pair[0])
	var r: int = int(pair[1])
	if c < 0 or c >= Sim.MAP_COLUMNS or r < 0 or r >= rows:
		fail(path, "must be inside the map")
		return bad
	return Vector2i(c, r)


## A pair of whole numbers [x, y], each lo to hi. (lo - 1, lo - 1) when wrong.
func pair(value: Variant, path: String, lo: int, hi: int) -> Vector2i:
	var bad: Vector2i = Vector2i(lo - 1, lo - 1)
	if typeof(value) != TYPE_ARRAY:
		fail(path, "must be a pair of numbers")
		return bad
	var items: Array = value
	if items.size() != 2:
		fail(path, "must be a pair of numbers")
		return bad
	var x: int = whole(items[0], path, lo, hi, 1, lo - 1)
	var y: int = whole(items[1], path, lo, hi, 1, lo - 1)
	return Vector2i(x, y)


static func cell_data(cell_value: Vector2i) -> Array:
	return [cell_value.x, cell_value.y]
