class_name SaveService extends RefCounted
## Reads and writes the two save files (docs/ARCHITECTURE.md section 10):
## run.json holds the current run and is deleted when the run ends;
## profile.json holds the settings and records and is kept forever. Both live
## in user://, or in a test folder inside user://.
##
## Reading. A file over 256 KB (MAX_BYTES) is refused before any of it is
## read. A run at the score ceiling holds about 60 KB of digits, so every
## valid file fits (docs/ARCHITECTURE.md section 17). A NUL byte
## (the UTF-8 decoder would silently stop there), any byte of 0x80 or above
## (SEC-05) or nesting deeper than _MAX_NESTING (our files nest 3 deep) is
## refused before parsing. Then Godot's JSON class parses the text into plain
## values and SaveCodec checks every field. Nothing here can turn file data
## into an object or code.
##
## The files are plain ASCII (SEC-05). Every key is a fixed ASCII name. Every
## value is a bool, an int (exponents), a string of ASCII digits (scores) or a skin
## id of a to z and underscore (SaveCodec refuses anything else on load). The
## JSON writer adds only tabs, newlines, quotes and ASCII punctuation, and
## _encode refuses to write anything else. So a byte of 0x80 or above never
## comes from this game. Refusing it up front also keeps the UTF-8 decoder
## from logging one error per bad byte, which made such a file slow to refuse.
##
## A file that exists but cannot be opened (SEC-04). On Windows another
## program can hold a file with no sharing, and a file can be briefly
## unopenable right after a process ends. Opening is tried _OPEN_TRIES times,
## _OPEN_RETRY_MSEC apart. When the temp or real file of run.json or
## profile.json still cannot be opened (a temp file may be the newest save),
## that kind is not judged at all: no older file is used, and none of its
## files is written, renamed or deleted for as long as this service lives
## (_blocked). load_run then returns no run, load_profile leaves the values in
## memory as they are, and the next load reads the files as they are.
##
## Writing. The whole file goes to <name>.tmp, is flushed, closed, read back
## and compared byte for byte, and only then renamed over the real file. On
## Windows, Godot's rename deletes the old file before it moves the new one
## in, and fails while another program holds the old file open; with the
## temp file held open, it deletes the old file and then fails. On Android,
## Godot uses POSIX rename, which replaces the file in one step.
##
## The newest complete save wins (QA6-07). Every write rewrites <name>.tmp
## before its rename, so a temp file that parses and passes SaveCodec's checks
## is always newer than <name>. Loading uses such a temp file first and
## renames it into place. A temp file that fails to parse or validate is
## deleted, and <name> is used. A rename that fails is tried again before the
## next write and on flush(), and only while the temp file still holds exactly
## the bytes that were written. So a kill or a held file at any moment leaves
## the newest complete save, never an older one.
##
## The last good copy (SEC-02). Godot has no call that forces a file to
## storage, so after a power cut or OS crash a file renamed moments earlier can
## come back empty or cut short. So before a save replaces <name>, the current
## <name> becomes <name>.bak, but only when it holds exactly the bytes of a
## save that passed every check (one this service wrote or loaded). It is a
## rename, so the .bak keeps data written a save ago, which has very likely
## reached storage. Loading uses the .bak only when neither a valid temp file
## nor a valid <name> exists, and checks it exactly as strictly. A run from
## the .bak is one save behind.
##
## Deleting. delete_run removes the temp file first, then the .bak, then the
## real one, so a kill between steps leaves at most the newest file. A file
## Windows will not delete (held open by another program) is emptied instead,
## so it can never load, and the next load discards it. So a deleted run never
## comes back.
##
## Queued writes (QA4-02). queue_run and queue_profile check and encode the
## data at once on the calling thread, which is cheap, and leave the file work
## to one WorkerThreadPool task, so a move's save never stalls its frame:
## - one write at a time, in one task that drains the queue;
## - the newest data for a file wins: a queued file not yet written is
##   replaced, never written twice;
## - a queued file whose bytes match what was last written is skipped;
## - every other call (the synchronous saves, delete_run and the reads) first
##   waits for the task, so nothing ever interleaves and reads see every
##   earlier save. flush() waits on its own, for app pause, focus loss and
##   close.
## is_idle() tells, without waiting, whether a queued write is still to land
## (QA6-06: the board shows a move only once its save is on disk).
## Call the service from one thread only (the main thread in the game).

const RUN_FILE: String = "run.json"
const PROFILE_FILE: String = "profile.json"
const TEMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"
const MAX_BYTES: int = 262144    # 256 KB (AT-95 (k), ARCHITECTURE.md section 17)

const _MAX_NESTING: int = 16    # our files nest 3 deep; a wrong typed field may add a little
const _ROOT: String = "user://"
const _BYTE_NUL: int = 0
const _BYTE_HIGH: int = 0x80    # the first byte that is not ASCII
const _BYTE_QUOTE: int = 0x22
const _BYTE_BACKSLASH: int = 0x5C
const _BYTE_OPEN_SQUARE: int = 0x5B
const _BYTE_CLOSE_SQUARE: int = 0x5D
const _BYTE_OPEN_CURLY: int = 0x7B
const _BYTE_CLOSE_CURLY: int = 0x7D
const _OPEN_TRIES: int = 5
const _OPEN_RETRY_MSEC: int = 40    # 160 ms in all before giving up

enum _Status { MISSING, UNREADABLE, BROKEN, PARSED }


## What reading one file found. data is set only when status is PARSED, bytes
## whenever the file was read whole.
class FileRead extends RefCounted:
	var status: int = 0    # a _Status value
	var data: Variant = null
	var bytes: PackedByteArray = PackedByteArray()


var _directory: String = ""

## The write queue, the only thing the writer task holds. The task never
## touches the service, so a service dropped mid write stays safe: it waits
## for its task when it is freed. mutex guards the other fields.
class WriteQueue extends RefCounted:
	var directory: String = ""
	var mutex: Mutex = Mutex.new()
	## Bytes waiting to be written, by file name.
	var pending: Dictionary[String, PackedByteArray] = {}
	## The bytes last handed to a write, by file name, dropped when that
	## write fails. Lets an unchanged file be skipped.
	var written: Dictionary[String, PackedByteArray] = {}
	## Files whose rename failed, by file name, with the bytes their temp file
	## holds. The rename is tried again before the next write and on flush.
	var stuck: Dictionary[String, PackedByteArray] = {}
	## SEC-02. Bytes that passed every check and that the real file was last
	## known to hold, by file name: set by a rename into place and by a load
	## that found the real file valid. Only such a file becomes the .bak.
	var good: Dictionary[String, PackedByteArray] = {}
	## True while a writer is draining the queue.
	var writing: bool = false


var _q: WriteQueue = WriteQueue.new()
## The writer task started last; only the calling thread touches it.
var _task_id: int = -1
## TH23: while true, queued writes wait and is_idle() is false.
var _hold: bool = false
## SEC-04. Files (RUN_FILE, PROFILE_FILE) whose temp or real file existed at
## the last load but could not be opened. This service never writes, renames
## or deletes any of their files.
var _blocked: Dictionary[String, bool] = {}
## For tests only: opens that fail, by path. A count above 0 fails that many
## more opens; -1 fails every open.
var _unopenable: Dictionary[String, int] = {}


## directory must be inside user://. Tests pass a temp folder there. Any other
## folder is a programming error: the service then refuses every call and
## touches nothing.
func _init(directory: String = _ROOT) -> void:
	if directory.begins_with(_ROOT) and not directory.contains(".."):
		_directory = directory
		_q.directory = directory
	else:
		push_error("SaveService: refusing a save folder outside user://: %s" % directory)


## Writes the run now, after any queued write. Returns false, and leaves the
## last good save in place, when the state would not load back (SaveCodec
## refuses it) or the write fails. When only the rename fails, the new run
## stays in the temp file, which wins on the next load.
func save_run(state: RunState) -> bool:
	if _blocked.has(RUN_FILE):
		return false
	flush()
	var bytes: PackedByteArray = _run_bytes(state)
	if bytes.is_empty():
		return false
	return _write_now(RUN_FILE, bytes)


## Checks and encodes the run now and queues the write. Returns false, and
## queues nothing, when the state would not load back. A write that fails
## later is reported with push_warning and leaves the last good save.
func queue_run(state: RunState) -> bool:
	if _blocked.has(RUN_FILE):
		return false
	var bytes: PackedByteArray = _run_bytes(state)
	if bytes.is_empty():
		return false
	_queue(RUN_FILE, bytes)
	return true


## Waits until every queued write is on disk (or has failed and been
## reported), then tries again any rename that failed. Held writes (set_hold)
## are written too, so a flush never waits forever and never lets an older
## save land after a newer one.
func flush() -> void:
	_reap()
	_q.mutex.lock()
	var left: bool = not _q.pending.is_empty() and not _q.writing
	if left:
		_q.writing = true
	_q.mutex.unlock()
	if left:
		_drain(_q)
	_retry_stuck(_q)


## QA6-06. True when no queued write is still to land: nothing waiting and no
## writer running. A write that failed counts as landed, so a failing disk
## never freezes the game. Never waits. False while set_hold(true) is on.
func is_idle() -> bool:
	if _hold:
		return false
	if _task_id >= 0 and WorkerThreadPool.is_task_completed(_task_id):
		_reap()
	_q.mutex.lock()
	var idle: bool = _q.pending.is_empty() and not _q.writing
	_q.mutex.unlock()
	return idle


## TH23, for tests only. While on, queued writes wait (no writer starts) and
## is_idle() is false. Turning it off starts the writer for anything waiting.
## flush() and every call that flushes still write what is waiting, so the
## hold never blocks a caller or reorders saves.
func set_hold(on: bool) -> void:
	_hold = on
	if not on:
		_start_writer()


## SEC-04, for tests only. The next failures reads of the file at path fail
## to open, as if another program held it; -1 makes every read fail and 0
## ends it. Only the reads in load_run and load_profile are affected.
func set_unopenable(path: String, failures: int) -> void:
	if failures == 0:
		_unopenable.erase(path)
	else:
		_unopenable[path] = failures


## The saved run, or null when there is none or it is invalid. A complete,
## valid temp file is the newest save and wins: it is renamed into place and
## used. Next comes the real file, then the .bak (SEC-02), each checked the
## same way. A temp, real or .bak file whose content is invalid is discarded
## (deleted). A file that exists but cannot be opened is left alone, because
## the cause may not last. When that file is run.json.tmp or run.json, there
## is no run this time: no older file is used, and no run file is written or
## deleted while this service lives (SEC-04).
func load_run(config: GameConfig) -> RunState:
	if _directory.is_empty():
		return null
	flush()
	_blocked.erase(RUN_FILE)
	var main_path: String = _path(RUN_FILE)
	var temp_path: String = main_path + TEMP_SUFFIX
	var temp: FileRead = _read_json(temp_path)
	if temp.status == _Status.UNREADABLE:
		_block(RUN_FILE, temp_path)
		return null
	if temp.status == _Status.PARSED:
		var newest: RunState = SaveCodec.data_to_run(temp.data, config)
		if newest != null:
			_promote(RUN_FILE, temp.bytes)
			return newest
	if temp.status == _Status.PARSED or temp.status == _Status.BROKEN:
		_remove(temp_path)
	var main: FileRead = _read_json(main_path)
	if main.status == _Status.UNREADABLE:
		_block(RUN_FILE, main_path)
		return null
	if main.status == _Status.PARSED:
		var state: RunState = SaveCodec.data_to_run(main.data, config)
		if state != null:
			_set_good(RUN_FILE, main.bytes)
			return state
	if main.status == _Status.PARSED or main.status == _Status.BROKEN:
		_remove(main_path)
	var backup_path: String = main_path + BACKUP_SUFFIX
	var backup: FileRead = _read_json(backup_path)
	if backup.status == _Status.PARSED:
		var older: RunState = SaveCodec.data_to_run(backup.data, config)
		if older != null:
			push_warning("SaveService: %s was damaged or missing; using the last good copy" % RUN_FILE)
			return older
	if backup.status == _Status.PARSED or backup.status == _Status.BROKEN:
		_remove(backup_path)
	return null


## Deletes the saved run, after any queued write, so a queued run can never
## land after the delete. A failed rename waiting to be tried again is
## dropped. The temp file goes first and the real file last, so a kill
## between the steps can never leave a lone temp or .bak file that would bring
## an ended run back. While the run is blocked (SEC-04) this service never
## wrote the run files, so they are left as they are.
func delete_run() -> void:
	if _directory.is_empty() or _blocked.has(RUN_FILE):
		return
	flush()
	_q.mutex.lock()
	_q.written.erase(RUN_FILE)
	_q.stuck.erase(RUN_FILE)
	_q.good.erase(RUN_FILE)
	_q.mutex.unlock()
	var main_path: String = _path(RUN_FILE)
	_discard(main_path + TEMP_SUFFIX)
	_discard(main_path + BACKUP_SUFFIX)
	_discard(main_path)


## True when a run file is on disk, including a temp or .bak file that
## load_run could recover. load_run decides whether it is valid.
func has_run() -> bool:
	if _directory.is_empty():
		return false
	flush()
	var main_path: String = _path(RUN_FILE)
	return FileAccess.file_exists(main_path) or FileAccess.file_exists(main_path + TEMP_SUFFIX) or FileAccess.file_exists(main_path + BACKUP_SUFFIX)


## Writes the profile now, after any queued write.
func save_profile(settings: Settings, records: Records) -> bool:
	if _directory.is_empty() or _blocked.has(PROFILE_FILE) or settings == null or records == null:
		return false
	flush()
	var bytes: PackedByteArray = _encode(SaveCodec.profile_to_data(settings, records))
	if bytes.is_empty():
		return false
	return _write_now(PROFILE_FILE, bytes)


## Encodes the profile now and queues the write, like queue_run.
func queue_profile(settings: Settings, records: Records) -> bool:
	if _directory.is_empty() or _blocked.has(PROFILE_FILE) or settings == null or records == null:
		return false
	var bytes: PackedByteArray = _encode(SaveCodec.profile_to_data(settings, records))
	if bytes.is_empty():
		return false
	_queue(PROFILE_FILE, bytes)
	return true


## Applies the saved profile to settings and records. A temp file that is a
## fully valid profile is the newest save and wins: it is renamed into place
## and used. Otherwise a temp file that parsed or is broken is deleted. Then
## a fully valid real file is used, else a fully valid .bak (SEC-02), else
## the real file as it is: each part that is missing or invalid keeps the
## value the objects already hold, which is the default for fresh objects
## (SaveCodec.data_to_profile). A broken real profile is not deleted: the next
## save_profile replaces it. A .bak that is not fully valid is deleted. A
## temp or real file that exists but cannot be opened leaves settings and
## records as they are, and no profile file is written while this service
## lives (SEC-04), so its records can never be replaced by older ones.
func load_profile(settings: Settings, records: Records) -> void:
	if _directory.is_empty():
		return
	flush()
	_blocked.erase(PROFILE_FILE)
	var main_path: String = _path(PROFILE_FILE)
	var temp_path: String = main_path + TEMP_SUFFIX
	var temp: FileRead = _read_json(temp_path)
	if temp.status == _Status.UNREADABLE:
		_block(PROFILE_FILE, temp_path)
		return
	if _is_valid_profile(temp):
		_promote(PROFILE_FILE, temp.bytes)
		SaveCodec.data_to_profile(temp.data, settings, records)
		return
	if temp.status == _Status.PARSED or temp.status == _Status.BROKEN:
		_remove(temp_path)
	var main: FileRead = _read_json(main_path)
	if main.status == _Status.UNREADABLE:
		_block(PROFILE_FILE, main_path)
		return
	if _is_valid_profile(main):
		_set_good(PROFILE_FILE, main.bytes)
		SaveCodec.data_to_profile(main.data, settings, records)
		return
	var backup_path: String = main_path + BACKUP_SUFFIX
	var backup: FileRead = _read_json(backup_path)
	if _is_valid_profile(backup):
		push_warning("SaveService: %s was damaged or missing; using the last good copy" % PROFILE_FILE)
		SaveCodec.data_to_profile(backup.data, settings, records)
		return
	if backup.status == _Status.PARSED or backup.status == _Status.BROKEN:
		_remove(backup_path)
	SaveCodec.data_to_profile(main.data if main.status == _Status.PARSED else null, settings, records)


## True when read parsed and every part of it is a valid profile.
static func _is_valid_profile(read: FileRead) -> bool:
	return read.status == _Status.PARSED and SaveCodec.data_to_profile(read.data, Settings.new(), Records.new()).is_empty()


## SEC-04: path, the temp or real file of file_name, exists but cannot be
## opened. Every file of file_name is left exactly as it is for as long as
## this service lives.
func _block(file_name: String, path: String) -> void:
	_blocked[file_name] = true
	push_warning("SaveService: %s cannot be opened; %s is left as it is and not used or saved until the next launch" % [path.get_file(), file_name])


## Records bytes, which passed every check, as what the real file holds.
func _set_good(file_name: String, bytes: PackedByteArray) -> void:
	_q.mutex.lock()
	_q.good[file_name] = bytes
	_q.mutex.unlock()


func _path(file_name: String) -> String:
	return _directory.path_join(file_name)


## Reads and parses one file with every limit applied before parsing. A file
## that cannot be opened, or reads short, is tried again (SEC-04).
func _read_json(path: String) -> FileRead:
	var result: FileRead = FileRead.new()
	result.status = _Status.UNREADABLE
	var bytes: PackedByteArray = PackedByteArray()
	for attempt: int in _OPEN_TRIES:
		if attempt > 0:
			OS.delay_msec(_OPEN_RETRY_MSEC)
		if not FileAccess.file_exists(path):
			result.status = _Status.MISSING
			return result
		var file: FileAccess = _open_to_read(path)
		if file == null:
			continue
		var length: int = file.get_length()
		if length < 1 or length > MAX_BYTES:
			file.close()
			result.status = _Status.BROKEN
			return result
		bytes = file.get_buffer(length)
		file.close()
		if bytes.size() == length:
			result.status = _Status.BROKEN
			break
	if result.status == _Status.UNREADABLE:
		return result
	result.bytes = bytes
	if not _is_plain_ascii(bytes) or not _nesting_within(bytes, _MAX_NESTING):
		return result
	var json: JSON = JSON.new()
	if json.parse(bytes.get_string_from_utf8()) != OK:
		return result
	result.status = _Status.PARSED
	result.data = json.data
	return result


## FileAccess.open for reading, unless a test made path unopenable.
func _open_to_read(path: String) -> FileAccess:
	if _unopenable.has(path):
		var left: int = _unopenable[path]
		if left == 1:
			_unopenable.erase(path)
		elif left > 1:
			_unopenable[path] = left - 1
		return null
	return FileAccess.open(path, FileAccess.READ)


## True when bytes holds no NUL and no byte of 0x80 or above (SEC-05). Our
## files are plain ASCII; see the header.
static func _is_plain_ascii(bytes: PackedByteArray) -> bool:
	for byte: int in bytes:
		if byte == _BYTE_NUL or byte >= _BYTE_HIGH:
			return false
	return true


## True when no array or object in the JSON text nests deeper than max_depth.
## Brackets inside strings do not count. Malformed text is left for the parser
## to refuse.
static func _nesting_within(bytes: PackedByteArray, max_depth: int) -> bool:
	var depth: int = 0
	var in_string: bool = false
	var escaped: bool = false
	for byte: int in bytes:
		if in_string:
			if escaped:
				escaped = false
			elif byte == _BYTE_BACKSLASH:
				escaped = true
			elif byte == _BYTE_QUOTE:
				in_string = false
		elif byte == _BYTE_QUOTE:
			in_string = true
		elif byte == _BYTE_OPEN_SQUARE or byte == _BYTE_OPEN_CURLY:
			depth += 1
			if depth > max_depth:
				return false
		elif byte == _BYTE_CLOSE_SQUARE or byte == _BYTE_CLOSE_CURLY:
			depth -= 1
	return true


## The run as file bytes, or empty when the state would not load back.
@warning_ignore("integer_division")
func _run_bytes(state: RunState) -> PackedByteArray:
	if _directory.is_empty() or state == null or state.columns < 1:
		return PackedByteArray()
	var data: Dictionary = SaveCodec.run_to_data(state)
	var shape: GameConfig = GameConfig.new()
	shape.columns = state.columns
	shape.rows = state.cells.size() / state.columns
	if SaveCodec.data_to_run(data, shape) == null:
		return PackedByteArray()
	return _encode(data)


## data as file bytes, or empty when it would pass the size limit or hold a
## byte that is not plain ASCII (SEC-05), and so never load back.
static func _encode(data: Dictionary) -> PackedByteArray:
	var bytes: PackedByteArray = JSON.stringify(data, "\t", false).to_utf8_buffer()
	if bytes.size() > MAX_BYTES or not _is_plain_ascii(bytes):
		return PackedByteArray()
	return bytes


## Writes on the calling thread (the queue is empty: the caller flushed).
func _write_now(file_name: String, bytes: PackedByteArray) -> bool:
	_retry_stuck(_q)
	var ok: bool = _write_file(_q, file_name, bytes)
	_q.mutex.lock()
	if ok:
		_q.written[file_name] = bytes
	else:
		_q.written.erase(file_name)
	_q.mutex.unlock()
	return ok


## Queues bytes for file_name, replacing older bytes still waiting, and
## starts the writer task when none is running and no hold is on.
func _queue(file_name: String, bytes: PackedByteArray) -> void:
	_q.mutex.lock()
	if not _q.pending.has(file_name) and _q.written.has(file_name) and _q.written[file_name] == bytes:
		_q.mutex.unlock()
		return
	_q.pending[file_name] = bytes
	_q.mutex.unlock()
	_start_writer()


## Starts the writer task when something is waiting, none is running and no
## hold is on.
func _start_writer() -> void:
	if _hold:
		return
	_q.mutex.lock()
	var start: bool = not _q.pending.is_empty() and not _q.writing
	if start:
		_q.writing = true
	_q.mutex.unlock()
	if start:
		_reap()
		_task_id = WorkerThreadPool.add_task(_drain.bind(_q), false, "SaveService writes")


## The writer: takes one queued file at a time and writes it, until the
## queue is empty. Runs on a worker thread, or on the caller during flush.
## Static, and holding only the queue, so it never needs the service.
static func _drain(queue: WriteQueue) -> void:
	while true:
		queue.mutex.lock()
		if queue.pending.is_empty():
			queue.writing = false
			queue.mutex.unlock()
			return
		var file_name: String = queue.pending.keys()[0]
		var bytes: PackedByteArray = queue.pending[file_name]
		queue.pending.erase(file_name)
		queue.written[file_name] = bytes
		queue.mutex.unlock()
		_retry_stuck(queue)
		if not _write_file(queue, file_name, bytes):
			queue.mutex.lock()
			if queue.written.has(file_name) and queue.written[file_name] == bytes:
				queue.written.erase(file_name)
			var kept: bool = queue.stuck.has(file_name)
			queue.mutex.unlock()
			if kept:
				push_warning("SaveService: could not move %s into place; the new save stays in its temp file and wins on the next load" % file_name)
			else:
				push_warning("SaveService: could not save %s; the last good save stays" % file_name)


## Waits for the writer task started last, which drains the whole queue.
func _reap() -> void:
	if _task_id >= 0:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1


func _notification(what: int) -> void:
	# A service dropped with writes queued waits for its writer here, so
	# nothing queued is lost and the task is cleaned up. Inline, because
	# methods cannot be called on an object being deleted. Writes still held
	# by set_hold (tests only) are dropped with the service.
	if what == NOTIFICATION_PREDELETE and _task_id >= 0:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1


## Writes bytes to <file_name>.tmp in the queue's folder, checks it, then
## moves it into place (_move_into_place). A failed write or check deletes the
## broken temp file. Safe on any thread; the caller makes sure only one writer
## runs.
static func _write_file(queue: WriteQueue, file_name: String, bytes: PackedByteArray) -> bool:
	var directory: String = queue.directory
	if directory.is_empty() or bytes.is_empty():
		return false
	if not DirAccess.dir_exists_absolute(directory):
		if DirAccess.make_dir_recursive_absolute(directory) != OK:
			return false
	var main_path: String = directory.path_join(file_name)
	var temp_path: String = main_path + TEMP_SUFFIX
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	var stored: bool = file.store_buffer(bytes)
	# flush() hands Godot's and the C library's buffers to the OS. It is not an
	# fsync: Godot exposes none, so the OS may keep the data in memory for a
	# while before it reaches storage. A killed app loses nothing (the OS still
	# writes it); a power cut or OS crash can, which is why the last good copy
	# is kept as <name>.bak.
	file.flush()
	file.close()
	if not stored or not _file_holds(temp_path, bytes):
		_remove(temp_path)
		queue.mutex.lock()
		queue.stuck.erase(file_name)
		queue.mutex.unlock()
		return false
	return _move_into_place(queue, file_name, bytes)


## Renames <file_name>.tmp, which holds bytes, over the real file. First, when
## the real file holds exactly the last good bytes, it is renamed to
## <file_name>.bak (SEC-02); when that rename fails, the save goes on without
## a new .bak. A kill between the two renames leaves the valid temp file,
## which wins the next load. A failed rename of the temp file keeps it and
## marks the file stuck, because the temp file is then the newest good copy
## (on Windows the real file may already be gone).
static func _move_into_place(queue: WriteQueue, file_name: String, bytes: PackedByteArray) -> bool:
	var main_path: String = queue.directory.path_join(file_name)
	var temp_path: String = main_path + TEMP_SUFFIX
	queue.mutex.lock()
	var good: PackedByteArray = queue.good.get(file_name, PackedByteArray())
	queue.mutex.unlock()
	if _file_holds(main_path, good):
		DirAccess.rename_absolute(main_path, main_path + BACKUP_SUFFIX)
	var renamed: bool = DirAccess.rename_absolute(temp_path, main_path) == OK
	queue.mutex.lock()
	if renamed:
		queue.good[file_name] = bytes
	else:
		queue.good.erase(file_name)
	if renamed or not FileAccess.file_exists(temp_path):
		queue.stuck.erase(file_name)
	else:
		queue.stuck[file_name] = bytes
	queue.mutex.unlock()
	return renamed


## Tries again every rename that failed. A temp file that is gone, or no
## longer holds exactly the bytes written, is no longer retried (and never
## renamed, because Godot's rename on Windows deletes the target even when the
## source is missing); the next load judges what is left.
static func _retry_stuck(queue: WriteQueue) -> void:
	queue.mutex.lock()
	var names: Array = queue.stuck.keys()
	queue.mutex.unlock()
	for file_name: String in names:
		queue.mutex.lock()
		var bytes: PackedByteArray = queue.stuck.get(file_name, PackedByteArray())
		queue.mutex.unlock()
		var temp_path: String = queue.directory.path_join(file_name) + TEMP_SUFFIX
		if _file_holds(temp_path, bytes):
			_move_into_place(queue, file_name, bytes)
		else:
			queue.mutex.lock()
			queue.stuck.erase(file_name)
			queue.mutex.unlock()


## True when the file at path holds exactly bytes (and bytes is not empty).
static func _file_holds(path: String, bytes: PackedByteArray) -> bool:
	if bytes.is_empty() or not FileAccess.file_exists(path):
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var same: bool = file.get_length() == bytes.size() and file.get_buffer(bytes.size()) == bytes
	file.close()
	return same


## Finishes the rename of a temp file that load found newest. If it fails,
## the temp file stays, wins the next load again, and the rename is tried
## again before the next write and on flush.
func _promote(file_name: String, bytes: PackedByteArray) -> void:
	_move_into_place(_q, file_name, bytes)


static func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## Removes the file at path. When Windows will not (another program holds it
## open), empties it instead, so it can never load and the next load
## discards it.
static func _discard(path: String) -> void:
	_remove(path)
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.close()
	else:
		push_warning("SaveService: could not delete or empty %s" % path)
