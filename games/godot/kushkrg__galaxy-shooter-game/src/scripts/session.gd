extends Node
## Session (autoload) — player identity, settings and the on-device
## leaderboard. Persists to user://galaxy_shooter.cfg so a guest or a
## logged-in pilot stays signed in between launches (Web + mobile).

const SAVE_PATH := "user://galaxy_shooter.cfg"
const DEFAULT_API_URL := "http://127.0.0.1:8900"

var token: String = ""
var user: Dictionary = {}            # {id, username, display_name, is_guest}
var api_url: String = DEFAULT_API_URL
var sound: bool = true
var local_scores: Array = []         # [{name, score, level, date}] best first

func _ready() -> void:
	load_data()

func is_logged_in() -> bool:
	return token != "" and not user.is_empty()

func display_name() -> String:
	if user.has("display_name"):
		return str(user["display_name"])
	return "Guest Pilot"

func set_user(new_user: Dictionary, new_token: String) -> void:
	user = new_user
	token = new_token
	save_data()

func logout() -> void:
	user = {}
	token = ""
	save_data()

func add_local_score(score: int, level: int) -> void:
	local_scores.append({
		"name": display_name(), "score": score, "level": level,
		"date": Time.get_date_string_from_system(),
	})
	local_scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["score"]) > int(b["score"]))
	if local_scores.size() > 10:
		local_scores.resize(10)
	save_data()

func local_best() -> int:
	if local_scores.is_empty():
		return 0
	return int(local_scores[0]["score"])

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("auth", "token", token)
	cfg.set_value("auth", "user", user)
	cfg.set_value("settings", "api_url", api_url)
	cfg.set_value("settings", "sound", sound)
	cfg.set_value("local", "scores", local_scores)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	token = str(cfg.get_value("auth", "token", ""))
	user = cfg.get_value("auth", "user", {})
	api_url = str(cfg.get_value("settings", "api_url", DEFAULT_API_URL))
	sound = bool(cfg.get_value("settings", "sound", true))
	local_scores = cfg.get_value("local", "scores", [])
