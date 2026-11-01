# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The security baseline from CLAUDE.md, checked on every script: no network
## code, no loader that can create objects from file data, and only one file
## that hands an address to the phone.

## Words that must never appear in a script. Matched as whole words.
const FORBIDDEN: PackedStringArray = [
	"HTTPRequest", "HTTPClient", "StreamPeerTCP", "StreamPeerTLS", "TCPServer",
	"PacketPeerUDP", "UDPServer", "PacketPeerDTLS", "DTLSServer",
	"WebSocketPeer", "WebSocketMultiplayerPeer", "WebRTCPeerConnection",
	"WebRTCMultiplayerPeer", "WebRTCDataChannel", "ENetConnection",
	"ENetMultiplayerPeer", "ENetPacketPeer", "MultiplayerPeer", "JavaScriptBridge",
	"str_to_var", "bytes_to_var", "bytes_to_var_with_objects", "get_var",
	"ConfigFile", "dict_to_inst", "base64_to_variant", "UPNP", "UPNPDevice",
	"resolve_hostname", "resolve_hostname_addresses", "resolve_hostname_queue_item",
	"JavaClassWrapper", "JNISingleton", "decode_var", "to_native", "Expression",
	"source_code", "load_resource_pack", "shell_show_in_file_manager",
	"request_permission", "request_permissions",
]
## Calls the game itself must never make. Tests and tools may load scenes and
## run Godot, so these are checked only in the game's own folders.
const GAME_FORBIDDEN: PackedStringArray = [
	"ResourceLoader", "OS\\.execute", "OS\\.execute_with_pipe", "OS\\.create_process",
	"OS\\.create_instance", "Engine\\.get_singleton", "ClassDB\\.instantiate",
]
## The game's own folders.
const GAME_DIRS: PackedStringArray = ["res://src/", "res://scenes/"]
## Files scanned: scripts, shaders, and scenes and resources, which can hold scripts.
const SCANNED: PackedStringArray = ["gd", "gdshader", "tscn", "tres"]
## The only file allowed to call OS.shell_open (docs/ARCHITECTURE.md section 8).
const LINKS_FILE: String = "res://src/ui/links.gd"
const SKIPPED_DIRS: PackedStringArray = [".godot", ".git", ".claude", "android", "build", "docs"]
## This folder names the forbidden words on purpose.
const OWN_DIR: String = "res://tests/project"


func test_no_network_code_or_unsafe_loaders() -> void:
	var regex: RegEx = RegEx.create_from_string("\\b(" + "|".join(FORBIDDEN) + ")\\b")
	for path: String in _scripts():
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for i: int in lines.size():
			var found: RegExMatch = regex.search(lines[i])
			if found != null:
				fail("%s:%d uses %s" % [path, i + 1, found.get_string(1)])


func test_the_game_never_loads_resources_or_runs_programs() -> void:
	# A bare load( call, but not preload(), which only takes paths written in the
	# code, and not a method of our own such as SaveStore.load_daily.
	var regex: RegEx = RegEx.create_from_string(
		"(\\b(?:" + "|".join(GAME_FORBIDDEN) + ")\\b|(?<![\\w.])load\\s*\\()")
	var checked: int = 0
	for path: String in _scripts():
		if not (path.begins_with(GAME_DIRS[0]) or path.begins_with(GAME_DIRS[1])):
			continue
		checked += 1
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for i: int in lines.size():
			var found: RegExMatch = regex.search(lines[i])
			if found != null:
				fail("%s:%d uses %s" % [path, i + 1, found.get_string(1)])
	assert_true(checked > 50, "the game's own files were scanned")


func test_no_scene_or_resource_holds_a_script() -> void:
	# A script written inside a scene or resource would dodge the checks above.
	for path: String in _scripts():
		if path.get_extension() != "tscn" and path.get_extension() != "tres":
			continue
		if FileAccess.get_file_as_string(path).contains("type=\"GDScript\""):
			fail("%s holds a script; put it in a .gd file" % path)


func test_only_the_links_file_opens_addresses() -> void:
	for path: String in _scripts():
		if path == LINKS_FILE:
			continue
		if FileAccess.get_file_as_string(path).contains("shell_open"):
			fail("%s calls shell_open; only %s may" % [path, LINKS_FILE])


func _scripts() -> PackedStringArray:
	var files: PackedStringArray = PackedStringArray()
	_collect("res://", files)
	return files


func _collect(dir_path: String, out: PackedStringArray) -> void:
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		var sub_path: String = dir_path.path_join(sub_dir)
		if SKIPPED_DIRS.has(sub_dir) or sub_path == OWN_DIR:
			continue
		_collect(sub_path, out)
	for file_name: String in DirAccess.get_files_at(dir_path):
		if SCANNED.has(file_name.get_extension()):
			out.append(dir_path.path_join(file_name))
