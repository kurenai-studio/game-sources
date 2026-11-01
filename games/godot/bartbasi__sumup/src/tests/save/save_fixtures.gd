extends RefCounted
## Shared helpers for the save tests: boards, states, and a temp folder inside
## user:// that each test creates and removes. No test touches the real save
## files (user://run.json and user://profile.json).

const TEMP_ROOT: String = "user://test_save_tmp"
## Placeholder that raw_text swaps for a literal the JSON writer cannot make.
const RAW: String = "@RAW@"

static var _made: int = 0


## A fresh empty folder for one test.
static func make_temp_dir() -> String:
	_made += 1
	var path: String = TEMP_ROOT.path_join("%d_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec(), _made])
	DirAccess.make_dir_recursive_absolute(path)
	return path


## Deletes a folder made by make_temp_dir and everything in it, then the
## shared root when it is empty. Refuses any path outside TEMP_ROOT.
static func remove_temp_dir(path: String) -> void:
	if not path.begins_with(TEMP_ROOT + "/"):
		return
	_remove_tree(path)
	if DirAccess.dir_exists_absolute(TEMP_ROOT) and DirAccess.get_files_at(TEMP_ROOT).is_empty() and DirAccess.get_directories_at(TEMP_ROOT).is_empty():
		DirAccess.remove_absolute(TEMP_ROOT)


static func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub_dir: String in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(sub_dir))
	for file_name: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	DirAccess.remove_absolute(path)


static func write_text(path: String, text: String) -> void:
	write_bytes(path, text.to_utf8_buffer())


static func write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


## The file's bytes, or an empty array when it cannot be read.
static func read_bytes(path: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	return bytes


static func read_text(path: String) -> String:
	return read_bytes(path).get_string_from_utf8()


## data as JSON text, the way SaveService writes it.
static func to_text(data: Variant) -> String:
	return JSON.stringify(data, "\t", false)


## data as JSON text with the string "@RAW@" replaced by raw, unquoted. Used
## for literals the JSON writer never makes, such as 1e400.
static func raw_text(data: Variant, raw: String) -> String:
	return to_text(data).replace("\"%s\"" % RAW, raw)


## text followed by spaces until it is size bytes long. Trailing spaces are
## valid JSON, so only the size changes.
static func padded(text: String, size: int) -> String:
	var bytes: int = text.to_utf8_buffer().size()
	return text + " ".repeat(maxi(0, size - bytes))


## GDD 19.0 Board D as exponents: no valid move, H = 16 (exponent 4).
static func board_d() -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	for row: int in 8:
		for column: int in 5:
			if row % 2 == 0:
				cells.append(1 if column % 2 == 0 else 2)
			else:
				cells.append(3 if column % 2 == 0 else 4)
	return cells


## board with one cell changed to exponent. The board passed in is not changed.
static func with_cell(board: PackedInt64Array, cell: Vector2i, exponent: int) -> PackedInt64Array:
	var cells: PackedInt64Array = board.duplicate()
	cells[cell.y * 5 + cell.x] = exponent
	return cells


## A board of 40 different exponents from max_exponent (65535) down, then a 2
## in the last cell: the largest tiles the save format allows.
static func board_huge() -> PackedInt64Array:
	var top: int = GameConfig.new().max_exponent
	var cells: PackedInt64Array = PackedInt64Array()
	for index: int in 39:
		cells.append(top - index)
	cells.append(1)
	return cells


## value as a BigNum: an int (0 or more) is converted, a digit String is
## parsed, a BigNum is kept, and null or -1 is null (unknown).
static func num(value: Variant) -> BigNum:
	match typeof(value):
		TYPE_INT:
			var whole: int = value
			return null if whole < 0 else BigNum.from_int(whole)
		TYPE_STRING:
			return BigNum.parse(value, 100000)
		TYPE_OBJECT:
			return value as BigNum
	return null


## A BigNum as its digits, or "null" for none, for assert_eq.
static func text(value: BigNum) -> String:
	return "null" if value == null else value.to_decimal()


## The digits of 2^bits plus delta (delta may be negative), built exactly.
static func pow2_plus(bits: int, delta: int) -> BigNum:
	var power: BigNum = BigNum.pow2(bits)
	if delta >= 0:
		return power.add(BigNum.from_int(delta))
	return power.sub(BigNum.from_int(-delta))


## A run state that can be saved: like RunState.create, but the Best Score
## when the run began defaults to 0 (known) instead of null (unknown), as
## GameSession sets it for every live run. A state with null is never
## written. Scores take an int, a digit String or a BigNum (see num).
static func run(cells: PackedInt64Array, score: Variant, snapshot_cells: PackedInt64Array = PackedInt64Array(), snapshot_points: Variant = 0, run_highest: int = 0, free_used: int = 0, best_at_start: Variant = 0) -> RunState:
	return RunState.create(cells, num(score), snapshot_cells, num(snapshot_points), run_highest, 5, free_used, num(best_at_start))


## The AT-95 control run: Board D with a 1024 (exponent 10) on (2,0), score
## 41,286, run highest 2048 (exponent 11), an Undo snapshot of Board D worth
## 96 points, no free booster used, and a Best Score of 38,500 when the run
## began.
static func control_run() -> RunState:
	return run(with_cell(board_d(), Vector2i(2, 0), 10), 41286, board_d(), 96, 11, 0, 38500)


## A run with no snapshot.
static func plain_run() -> RunState:
	return run(with_cell(board_d(), Vector2i(0, 0), 5), 1500, PackedInt64Array(), 0, 0, 0, 1000)


## A run file as a build before D-46 wrote it: format 1, without free_used and
## best_at_start. Built from state's format 2 data, with ints as from code.
static func format_1_data(state: RunState) -> Dictionary:
	var data: Dictionary = SaveCodec.run_to_data(state)
	data["format"] = 1
	data.erase("free_used")
	data.erase("best_at_start")
	return data


## state as it loads from a format 1 file: free_used 0, best_at_start null.
static func as_format_1(state: RunState) -> RunState:
	var loaded: RunState = state.copy()
	loaded.free_used = 0
	loaded.best_at_start = null
	return loaded
