class_name Account
extends RefCounted
## The signed-in account on this device: the email, the refresh token, and when progress was last
## synced. It lives in one small file in the app's private storage and is written atomically.
## Signed out, the file is empty and nothing about the player ever leaves the device.

var path: String
var email := ""
var refresh_token := ""
## Unix seconds of the last successful sync, 0 when never.
var last_sync_at := 0.0


func _init(file_path: String = "user://account.json") -> void:
	path = file_path


func signed_in() -> bool:
	return not refresh_token.is_empty()


func load_data() -> void:
	email = ""
	refresh_token = ""
	last_sync_at = 0.0
	# The file, or the last good copy when the file is damaged.
	for candidate in [path, path + ".bak"]:
		if _apply(AtomicFile.read_json(candidate)):
			return


## Takes the fields of a parsed account file. False when it is not a usable account.
func _apply(parsed: Variant) -> bool:
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	if typeof(data.get("email")) != TYPE_STRING or typeof(data.get("refreshToken")) != TYPE_STRING:
		return false
	email = data["email"]
	refresh_token = data["refreshToken"]
	if typeof(data.get("lastSyncAt")) == TYPE_FLOAT:
		last_sync_at = float(data["lastSyncAt"])
	return true


## Remembers a new session (sign-in or registration).
func start(account_email: String, token: String) -> void:
	email = account_email
	refresh_token = token
	last_sync_at = 0.0
	save()


## Atomic write: a temporary file, then a rename, so a crash never leaves a half-written file.
func save() -> bool:
	var data := {"email": email, "refreshToken": refresh_token, "lastSyncAt": last_sync_at}
	return AtomicFile.write_json(path, data, true)


## Signs out on this device: forgets the session. Local progress is not touched.
func clear() -> void:
	email = ""
	refresh_token = ""
	last_sync_at = 0.0
	save()
