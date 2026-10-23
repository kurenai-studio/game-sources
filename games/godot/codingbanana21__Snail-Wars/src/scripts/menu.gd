class_name MainMenu
extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var menu: Node2D = $Menu
@onready var ip: LineEdit = %IP
@onready var ip_check_box: CheckBox = %IPCheckBox

#map settings
@onready var per_team_h_slider: HSlider = %PerTeamHSlider
@onready var per_team_label: Label = %PerTeamLabel
@onready var weapons_h_slider: HSlider = %WeaponsHSlider
@onready var weapons_label: Label = %WeaponsLabel
@onready var teams_h_slider: HSlider = %TeamsHSlider
@onready var teams_label: Label = %TeamsLabel
@onready var player_hp: LineEdit = %PlayerHP
@onready var water_level: LineEdit = %WaterLevel
@onready var water_rise: LineEdit = %WaterRise

const SERVER_PORT = 3100
const CONNECT_TIMEOUT: float = 5.0

var peer = ENetMultiplayerPeer.new()
var upnp
var teams_weapons: int


func _ready() -> void:
	multiplayer_spawner.spawn_function = make_map
	ip.text = Globals.saved_ip_address


func _process(_delta: float) -> void:
	if menu.is_visible_in_tree():
		per_team_label.text = str(int(per_team_h_slider.value)) + " Players Per Team"
		Globals.players_in_team = int(per_team_h_slider.value)
		
		weapons_label.text = "Weapon set " + str(int(weapons_h_slider.value))
		teams_weapons = int(weapons_h_slider.value)
		
		teams_label.text = str(int(teams_h_slider.value)) + " Teams"
		Globals.number_of_teams = int(teams_h_slider.value)
		
		Globals.player_hp = int(player_hp.text)
		Globals.water_level = -int(water_level.text)
		Globals.water_rise = -int(water_rise.text)


func make_map(inputs: Dictionary = {"multiplayer":false,
		"map":"m1",
		"players_in_team":1,
		"teams_weapons":[],
		"number_of_teams":1,
		"player_hp":1,
		"water_level":1,
		"water_rise":1
		}):
	
	Globals.map = inputs["map"]
	
	if inputs["multiplayer"]:
		Globals.players_in_team = inputs["players_in_team"]
		teams_weapons = inputs["teams_weapons"]
		Globals.number_of_teams = inputs["number_of_teams"]
		Globals.player_hp = inputs["player_hp"]
		Globals.water_level = inputs["water_level"]
		Globals.water_rise = inputs["water_rise"]
	
	#team weapon sets
	if teams_weapons == 1:
		Globals.teams_weapons = [[-1,-1,2,3,1,1,1,3,2,1,1,1,1]]
	elif teams_weapons == 2:
		Globals.teams_weapons = [[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]]
	elif teams_weapons == 3:
		Globals.teams_weapons = [[-1,-1,3,4,0,0,2,4,3,2,0,2,0]]
	elif teams_weapons == 4:
		Globals.teams_weapons = [[0,0,0,0,0,0,0,0,0,-1,-1,-1,-1]]
	
	for i in range(Globals.number_of_teams -1):
		Globals.teams_weapons.append([])
		for k in range(len(Globals.teams_weapons[0])):
			Globals.teams_weapons[i+1].append(Globals.teams_weapons[0][k])
	
	menu.hide()
	Mouse.ui.show()
	Mouse.can_move = true
	var map_file = preload("res://maps/map.tscn").instantiate()
	
	if inputs["multiplayer"]:
		Globals.is_multiplayer = true
		return map_file
	else:
		add_child(map_file)


func _on_client_pressed() -> void:
	var ip_address = ip.text.strip_edges()
	
	if ip_check_box.button_pressed:
		Globals.saved_ip_address = ip_address
	
	Globals.save_game()
	
	if ip_address == "":
		ip_address = "localhost"
	
	if !ip_address.is_valid_ip_address() and !ip_address == "localhost":
		push_error("IP address is invalid ", ip_address)
		return
	
	var new_peer = ENetMultiplayerPeer.new()
	var cerr = new_peer.create_client(ip_address, SERVER_PORT)
	
	if cerr != OK:
		push_error("create_client failed: ", cerr)
		return
	
	if !multiplayer.connected_to_server.is_connected(_on_connected):
		multiplayer.connected_to_server.connect(_on_connected)
		multiplayer.connection_failed.connect(_on_connection_failed)
	
	peer = new_peer
	multiplayer.multiplayer_peer = new_peer
	print("trying to connect to ", ip_address)
	
	await get_tree().create_timer(CONNECT_TIMEOUT).timeout
	if new_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		push_error("Connection timed out after %d seconds" % CONNECT_TIMEOUT)
		new_peer.close()
		if multiplayer.multiplayer_peer == new_peer:
			multiplayer.multiplayer_peer = null


func make_server(ip_address):
	if !ip_address.is_valid_ip_address():
		push_error("There was a error when creating the server ", ip_address)
		ip.text = "There was a error when creating the server " + str(ip_address)
		return
	else:
		ip.text = ip_address 
	
	var serr = peer.create_server(SERVER_PORT, 1)
	
	if serr != OK:
		push_error("create_server failed: ", serr)
		return
	
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(
		func(_id):
			multiplayer_spawner.spawn({"multiplayer":true,
				"map":"m1",
				"players_in_team":Globals.players_in_team,
				"teams_weapons":teams_weapons,
				"number_of_teams":Globals.number_of_teams,
				"player_hp":Globals.player_hp,
				"water_level":Globals.water_level,
				"water_rise":Globals.water_rise})
	)


func upnp_setup(server_port):
	upnp = UPNP.new()
	
	var err = upnp.discover(5000, 2, "InternetGatewayDevice")
	
	if err != UPNP.UPNP_RESULT_SUCCESS:
		push_error("UPNP discover failed ", err)
		return ""
	
	var gatway = upnp.get_gateway()
	if !upnp.get_gateway() or !gatway.is_valid_gateway():
		push_error("UPNP: no valid gateway")
		return ""
	
	var map_err = upnp.add_port_mapping(server_port, server_port, "snailwars", "UDP", 0)
	if map_err != UPNP.UPNP_RESULT_SUCCESS:
		push_warning("Permanent mapping failed, retrying with non-permanent")
		map_err = upnp.add_port_mapping(server_port, server_port, "snailwars", "UDP", 3600)
		
		if map_err != UPNP.UPNP_RESULT_SUCCESS:
			push_error("UPNP mapping failed")
			return
	
	var addr = upnp.query_external_address()
	return addr


func _on_connected() -> void:
	print("connected")


func _on_connection_failed() -> void:
	push_error("Can't connect to ", ip.text)


func _exit_tree() -> void:
	if upnp:
		upnp.delete_port_mapping(SERVER_PORT, "UDP")


func _on_local_server_pressed() -> void:
	make_server(IP.get_local_addresses()[1])


func _on_online_server_pressed() -> void:
	make_server(upnp_setup(SERVER_PORT))


func _on_map_button_make_map(map: Variant) -> void:
	make_map({"multiplayer":false,"map":map})
