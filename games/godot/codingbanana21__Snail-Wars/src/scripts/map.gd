class_name Map
extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var map: TileMapLayer = $Map
@onready var image: Sprite2D = $Image
@onready var water: Polygon2D = $Water

var remote_id: int
var rng = RandomNumberGenerator.new()


func _ready() -> void:
	multiplayer_spawner.spawn_function = spawn
	rng.seed = 1000
	
	if multiplayer.is_server():
		if Globals.is_multiplayer:
			remote_id = multiplayer.get_peers()[0]
		else:
			remote_id = 1
	
	image.texture = load("res://maps/map_"+Globals.map+".png") 
	make_map()
	
	Globals.team_turn = randi_range(0, Globals.number_of_teams)
	Globals.teams_turns[Globals.team_turn - 1] = randi_range(0, Globals.players_in_team)


func _process(_delta: float) -> void:
	water.global_position.y = Globals.water_level + cos(Engine.get_physics_frames() / 100.0) * 20
	water.global_position.x = sin(Engine.get_physics_frames() / 100.0) * 50


func make_map():
	var data = image.get_texture().get_image()
	var player_number: int = 0
	var team_colors: Array[Color]
	var teams: Array[int]
	
	for y in image.texture.get_width():
		for x in image.texture.get_height():
			var pixel_color = data.get_pixel(x,y)
			var offset: Vector2i = Vector2i(x -128, y -256)
			
			if pixel_color == Color(0.0, 1.0, 0.0, 1.0):
				map.set_cell(offset, 0 ,Vector2i(4 * rng.randi_range(0,1), 0))
			elif pixel_color == Color(1.0, 0.0, 0.0, 1.0):
				map.set_cell(offset, 0 ,Vector2i(1 + 4 * rng.randi_range(0,1), 0))
			elif pixel_color == Color(0.0, 0.0, 1.0, 1.0):
				map.set_cell(offset, 0 ,Vector2i(2 + 4 * rng.randi_range(0,1), 0))
			elif pixel_color == Color(1.0, 0.0, 1.0, 1.0):
				map.set_cell(offset, 0 ,Vector2i(3, 0))
			elif pixel_color == Color(1.0, 1.0, 0.0, 1.0):
				if Globals.map == "g1" and multiplayer.is_server():
					multiplayer_spawner.spawn({"id":1,
						"global_position":offset,
						"node_path":"res://projectiles/super_mine.tscn",
						"team_color":pixel_color,
						})
				elif multiplayer.is_server():
					multiplayer_spawner.spawn({"id":1,
						"global_position":offset,
						"node_path":"res://projectiles/mine.tscn",
						"team_color":pixel_color,
						})
			elif pixel_color.a != 0:
				if team_colors.find(pixel_color) == -1:
					if len(teams) >= Globals.number_of_teams:
						continue
					
					team_colors.append(pixel_color)
					teams.append(-1)
					Globals.teams_turns.append(0)
				
				var team_number: int = team_colors.find(pixel_color)
				
				if teams[team_number] >= Globals.players_in_team - 1:
					continue
				
				teams[team_number] += 1
				player_number = teams[team_number]
				
				if !multiplayer.is_server(): continue
				#print(pixel_color)
				
				if team_number == 0:
					multiplayer_spawner.spawn({"id":1,
						"global_position":offset,
						"node_path":"res://scenes/player.tscn",
						"team_color":pixel_color,
						"player_number":player_number,
						"team_number":team_number,
						})
				else:
					multiplayer_spawner.spawn({"id":remote_id,
						"global_position":offset,
						"node_path":"res://scenes/player.tscn",
						"team_color":pixel_color,
						"player_number":player_number,
						"team_number":team_number,
						})
			else:
				map.set_cell(offset, 0 ,Vector2i(0, 2))
	
	#print(teams)


func spawn(inputs: Dictionary = {"id":1,
		"global_position":Vector2.ZERO,
		"node_path":"res://scenes/player.tscn",
		"team_color":Color(),
		"player_number":0,
		"team_number":0,
		}):
	
	var new_node = load(inputs["node_path"]).instantiate()
	new_node.id = inputs["id"]
	new_node.global_position = inputs["global_position"] * 8
	
	if inputs["node_path"] == "res://scenes/player.tscn":
		new_node.team_color = inputs["team_color"]
		new_node.player_number = inputs["player_number"]
		new_node.team_number = inputs["team_number"]
		new_node.add_to_group("Player")
	return new_node


@rpc("any_peer","reliable","call_local")
func explode_tile(target_position: Vector2, power: int):
	var tile_position: Vector2 = round(target_position / 8.0)
	var explosion_accuracy: float = PI * 2
	
	for explosion_size in range(power):
		for number in range(explosion_accuracy * 16 * explosion_size):
			var tile: Vector2 = tile_position + Vector2(sin(number / explosion_accuracy) * explosion_size, cos(number / explosion_accuracy) * explosion_size)
			var tile_type: Vector2i = map.get_cell_atlas_coords(tile)
			
			if tile_type.y == 0:
				map.set_cell(tile, 0, tile_type + Vector2i(0, 1))


func _on_timer_timeout() -> void:
	Globals.next_player()
