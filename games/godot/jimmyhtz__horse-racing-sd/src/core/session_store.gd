extends RefCounted
const GameSession = preload("res://core/game_session.gd")
const GameSettings = preload("res://core/game_settings.gd")
var error := ""

func save(session: RefCounted, settings: RefCounted, path: String) -> bool:
	var invalid: String = session.validate_state()
	if not invalid.is_empty():
		error = invalid
		return false
	var bytes := var_to_bytes({"session":session.export_data(),"settings":settings.export_data()})
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	var envelope := {"format":"sigma-snapshot-1","sha256":hash.finish().hex_encode(),"payload":Marshalls.raw_to_base64(bytes)}
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		error = "Cannot create save file: " + error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(envelope))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error = "Could not finish save file"
		return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak") and DirAccess.remove_absolute(path+".bak") != OK:
			error = "Cannot rotate previous backup"
			return false
		if DirAccess.rename_absolute(path,path+".bak") != OK:
			error = "Cannot preserve previous snapshot"
			return false
	if DirAccess.rename_absolute(temporary,path) != OK:
		error = "Cannot replace save snapshot; prior snapshot remains in .bak"
		return false
	return true

func load_session(path: String, allow_recovery: bool=true) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok":false,"error":"No save snapshot at " + path}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > 67108864:
		return {"ok":false,"error":"Save file unreadable or exceeds 64 MiB"}
	var parser := JSON.new()
	var parse_status := parser.parse(file.get_as_text())
	var parsed: Variant = parser.data if parse_status == OK else null
	file.close()
	if not parsed is Dictionary or parsed.get("format") != "sigma-snapshot-1" or not parsed.get("payload") is String or not parsed.get("sha256") is String:
		return {"ok":false,"error":"Malformed snapshot; preserve file and backup for recovery"}
	var bytes := Marshalls.base64_to_raw(parsed.payload)
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	if hash.finish().hex_encode() != parsed.sha256:
		return {"ok":false,"error":"Snapshot checksum failed; play blocked"}
	var payload: Variant = bytes_to_var(bytes)
	if not payload is Dictionary or not payload.get("session") is Dictionary or not payload.get("settings") is Dictionary:
		return {"ok":false,"error":"Snapshot payload invalid"}
	if not allow_recovery and payload.session.get("phase") in ["RACING","RESULTS"]:
		return {"ok":false,"error":"This save contains a locked race. Use normal startup recovery for it."}
	var session := GameSession.new()
	if not session.restore(payload.session):
		return {"ok":false,"error":session.error}
	var settings := GameSettings.new()
	if not settings.restore(payload.settings):
		return {"ok":false,"error":"Stored settings invalid"}
	return {"ok":true,"session":session,"settings":settings}
