extends Node

signal server_started(port: int, max_players: int)
signal client_started(host: String, port: int)
signal connected_to_server
signal connection_failed
signal disconnected_from_server
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const DEFAULT_PORT: int = 2456
const DEFAULT_MAX_PLAYERS: int = 100
const DEFAULT_PLAYER_NAME: String = "Player"

enum Mode { OFFLINE, SERVER, CLIENT }

var mode: Mode = Mode.OFFLINE
var host: String = "127.0.0.1"
var port: int = DEFAULT_PORT
var max_players: int = DEFAULT_MAX_PLAYERS
var display_name: String = DEFAULT_PLAYER_NAME

var _galaxy: Node
var _is_connected_to_server: bool = false


func _ready() -> void:
	_parse_user_args()
	_connect_multiplayer_signals()
	if mode == Mode.SERVER:
		_start_server()
	elif mode == Mode.CLIENT:
		_start_client()


func register_galaxy(galaxy: Node) -> void:
	_galaxy = galaxy
	if _galaxy == null:
		return

	if is_server():
		if _galaxy.has_method("network_server_started"):
			_galaxy.call("network_server_started")
	elif is_client() and _is_connected_to_server:
		if _galaxy.has_method("network_connected_to_server"):
			_galaxy.call("network_connected_to_server")


func is_multiplayer_enabled() -> bool:
	return mode != Mode.OFFLINE


func is_server() -> bool:
	return mode == Mode.SERVER and multiplayer.multiplayer_peer != null


func is_client() -> bool:
	return mode == Mode.CLIENT and multiplayer.multiplayer_peer != null


func get_local_peer_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 1
	return multiplayer.get_unique_id()


func leave_session() -> void:
	_is_connected_to_server = false
	_galaxy = null

	var peer := multiplayer.multiplayer_peer
	if peer != null:
		peer.close()
		multiplayer.multiplayer_peer = null

	mode = Mode.OFFLINE


func _parse_user_args() -> void:
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg := str(args[index])
		match arg:
			"--server":
				mode = Mode.SERVER
			"--join":
				mode = Mode.CLIENT
				if index + 1 < args.size():
					host = str(args[index + 1])
					index += 1
			"--port":
				if index + 1 < args.size():
					port = maxi(int(args[index + 1]), 1)
					index += 1
			"--max-players":
				if index + 1 < args.size():
					max_players = clampi(int(args[index + 1]), 1, DEFAULT_MAX_PLAYERS)
					index += 1
			"--name":
				if index + 1 < args.size():
					display_name = str(args[index + 1]).strip_edges()
					if display_name.is_empty():
						display_name = DEFAULT_PLAYER_NAME
					index += 1
		index += 1


func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _start_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, max_players)
	if error != OK:
		push_error("Failed to start ENet server on port %d: %s" % [port, error_string(error)])
		mode = Mode.OFFLINE
		return

	multiplayer.multiplayer_peer = peer
	server_started.emit(port, max_players)
	print("Unobserved server listening on UDP %d for up to %d players." % [port, max_players])


func _start_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(host, port)
	if error != OK:
		push_error("Failed to connect ENet client to %s:%d: %s" % [host, port, error_string(error)])
		mode = Mode.OFFLINE
		return

	multiplayer.multiplayer_peer = peer
	client_started.emit(host, port)
	print("Connecting to Unobserved server %s:%d as %s." % [host, port, display_name])


func _on_peer_connected(peer_id: int) -> void:
	peer_joined.emit(peer_id)
	if _galaxy != null and _galaxy.has_method("network_peer_connected"):
		_galaxy.call("network_peer_connected", peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	peer_left.emit(peer_id)
	if _galaxy != null and _galaxy.has_method("network_peer_disconnected"):
		_galaxy.call("network_peer_disconnected", peer_id)


func _on_connected_to_server() -> void:
	_is_connected_to_server = true
	connected_to_server.emit()
	if _galaxy != null and _galaxy.has_method("network_connected_to_server"):
		_galaxy.call("network_connected_to_server")


func _on_connection_failed() -> void:
	_is_connected_to_server = false
	connection_failed.emit()


func _on_server_disconnected() -> void:
	_is_connected_to_server = false
	disconnected_from_server.emit()
	if _galaxy != null and _galaxy.has_method("network_server_disconnected"):
		_galaxy.call("network_server_disconnected")
