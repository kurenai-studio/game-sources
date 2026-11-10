extends TileMap

@export var placable_ground_tiles = [Vector2i(0,0), Vector2i(0,3)] 
@export var placable_water_tiles = [Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(1,3), Vector2i(2,3)]

var occupied_tiles = [];
