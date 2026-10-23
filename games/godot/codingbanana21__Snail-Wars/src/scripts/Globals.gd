extends Node2D

const WEAPONS: Array[String] = ["rocket","grenade","drill","bomb","air_strike","drill_strike","tnt","bullet","teleporta","pumkin_grenade","present","cake_tnt","leaf"]
const WEAPONS_NAMES: Array[String] = ["Rocket Launcher","Grenade","Drill Rocket","Bomb","Air Strike","Drill Strike","TNT","Gun","Teleporta","Pumkin Grenade","Present Strike","Cake TNT","Healing Leaf"]
const SAVE_PATH = "user://Save.tres"
const GAME_VERSION: float = 0.4

#save data
var save_data: SaveDataResource = SaveDataResource.new()
var save_version: float
var saved_ip_address: String
var high_fps_mode: bool = false

#teams
var teams_turns: Array[int]
var team_turn: int = -1
var players_in_team: int
var number_of_teams: int

#settings
var player_hp: int
var water_level: int
var water_rise: int
var is_multiplayer: bool = false
var wind: int = 0
var teams_weapons: Array[Array]
var map: String = "1m"

var rng = RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 1000
	load_game()


@rpc("any_peer", "call_local", "reliable")
func next_player(skip_player: bool = false):
	if !skip_player:
		wind = rng.randi_range(-4,4)
		water_level += water_rise
	
	if !multiplayer.is_server(): return
	
	Mouse.show()
	
	if !skip_player:
		team_turn = (team_turn + 1) % number_of_teams
	
	teams_turns[team_turn] = (teams_turns[team_turn] + 1) % players_in_team
	
	for player: Player in get_tree().get_nodes_in_group("Player"):
		player.next_player.rpc(teams_turns, team_turn)


func save_game(force_save: bool = false):
	if save_version == GAME_VERSION or force_save:
		save_data.save_version = save_version
		save_data.saved_ip_address = saved_ip_address
		ResourceSaver.save(save_data, SAVE_PATH)


func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		save_data = ResourceLoader.load(SAVE_PATH).duplicate(true)
		save_version = save_data.save_version
		
		if save_version:
			if save_version < GAME_VERSION:
				print("Out of date save")
				save_version = GAME_VERSION
			elif save_version > GAME_VERSION:
				push_error("Save is to new is use")
				return
		else:
			push_warning("No save version")
			save_version = GAME_VERSION
		
		#set data
		saved_ip_address = save_data.saved_ip_address
	else:
		save_game(true)
		load_game()
