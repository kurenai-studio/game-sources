extends Node

const DEFAULT_CONFIG_PATH := "res://Resource/config.json"
const USER_CONFIG_PATH := "user://config.json"

const DEBUG := true

var data: Dictionary = {}


func _ready() -> void:
	_ensure_user_config()
	_load()


func _ensure_user_config() -> void:
	if FileAccess.file_exists(USER_CONFIG_PATH):
		return
	var src := FileAccess.open(DEFAULT_CONFIG_PATH, FileAccess.READ)
	if src == null:
		push_error("找不到默认配置文件: " + DEFAULT_CONFIG_PATH)
		return
	var content := src.get_as_text()
	src.close()
	var dst := FileAccess.open(USER_CONFIG_PATH, FileAccess.WRITE)
	if dst == null:
		push_error("无法写入用户配置文件: " + USER_CONFIG_PATH)
		return
	dst.store_string(content)
	dst.close()


func _load() -> void:
	
	var f := FileAccess.open(USER_CONFIG_PATH if not DEBUG else DEFAULT_CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_error("无法读取配置文件: " + USER_CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("配置文件格式错误: " + USER_CONFIG_PATH)
		return
	data = parsed


func get_value(path: String, default: Variant = null) -> Variant:
	var node: Variant = data
	for key: String in path.split("/"):
		if typeof(node) != TYPE_DICTIONARY or not (node as Dictionary).has(key):
			return default
		node = (node as Dictionary)[key]
	return node
