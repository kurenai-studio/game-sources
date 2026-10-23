class_name Board
extends RefCounted
## Spielfeld-Logik: welche Zelle frei ist, wo Türme stehen und welchen Weg die Gegner nehmen.
## Gegner laufen vom Friedhof über die Kontrollpunkte zur Burg, auch schräg, aber nicht zwischen zwei
## Türmen hindurch (keine Ecken schneiden). Ein Turm darf keinen Abschnitt des Wegs ganz versperren.

signal changed

enum BuildCheck { OK, NOT_GRASS, OCCUPIED, ENEMY_THERE, BLOCKS_PATH }

var map: MapData
var towers: Dictionary = {}  # Vector2i -> Tower (oder true in Tests)
## Länge jedes Abschnitts (Start -> 1, 1 -> 2, ..., -> Burg), nach jedem Bau neu.
var leg_lengths: Array[float] = []
## Flugroute je Abschnitt: Grundweg der Karte ohne Türme, nur die Knickpunkte. Fliegende folgen ihr
## über alles hinweg, damit sie nicht auf Karten ohne Kontrollpunkte direkt in die Burg fliegen.
var flight_legs: Array = []
var flight_lengths: Array[float] = []
var _astar := AStarGrid2D.new()


func _init(map_data: MapData) -> void:
	map = map_data
	_astar.region = Rect2i(Vector2i.ZERO, map.size)
	_astar.cell_size = Vector2.ONE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for y in map.size.y:
		for x in map.size.x:
			var at := Vector2i(x, y)
			_astar.set_point_solid(at, not walkable_terrain(at))
	_measure_legs()
	for leg in map.waypoints.size():
		var route := _corners(_astar.get_id_path(leg_start(leg), map.waypoints[leg]))
		flight_legs.append(route)
		flight_lengths.append(path_length(route))


func walkable_terrain(at: Vector2i) -> bool:
	var kind := map.cell(at)
	return kind != MapData.Cell.BLOCKED and kind != MapData.Cell.HIGH


func walkable(at: Vector2i) -> bool:
	return walkable_terrain(at) and not towers.has(at)


## Startpunkt eines Abschnitts: 0 ist der Friedhof, danach die Kontrollpunkte.
func leg_start(leg: int) -> Vector2i:
	return map.spawn if leg == 0 else map.waypoints[leg - 1]


func path_between(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not walkable(from):
		from = nearest_walkable(from)
	return _astar.get_id_path(from, to)


## Restweg ab dem Ende von Abschnitt `leg` bis zur Burg.
func remaining_after(leg: int) -> float:
	var total := 0.0
	for i in range(leg + 1, leg_lengths.size()):
		total += leg_lengths[i]
	return total


## Restflug ab dem Ende von Abschnitt `leg` bis zur Burg.
func flight_remaining_after(leg: int) -> float:
	var total := 0.0
	for i in range(leg + 1, flight_lengths.size()):
		total += flight_lengths[i]
	return total


## Ganzer Weg vom Friedhof zur Burg (für Tests und Anzeige).
func full_path() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for leg in map.waypoints.size():
		var part := path_between(leg_start(leg), map.waypoints[leg])
		if not out.is_empty() and not part.is_empty():
			part.remove_at(0)
		out.append_array(part)
	return out


static func path_length(path: Array[Vector2i]) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += Vector2(path[i] - path[i - 1]).length()
	return total


## Nur Anfang, Ende und die Zellen, an denen der Weg die Richtung wechselt.
static func _corners(path: Array[Vector2i]) -> Array[Vector2i]:
	if path.size() < 3:
		return path
	var out: Array[Vector2i] = [path[0]]
	for i in range(1, path.size() - 1):
		if path[i] - path[i - 1] != path[i + 1] - path[i]:
			out.append(path[i])
	out.append(path[-1])
	return out


func nearest_walkable(at: Vector2i) -> Vector2i:
	if walkable(at):
		return at
	for radius in range(1, 4):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var other := at + Vector2i(dx, dy)
				if walkable(other):
					return other
	return map.spawn


## Darf hier gebaut werden? `walkers`: [Zelle, Ziel] der Gegner, die gerade unterwegs sind.
func check_build(at: Vector2i, walkers: Array = []) -> BuildCheck:
	if not map.buildable(at):
		return BuildCheck.NOT_GRASS
	if towers.has(at):
		return BuildCheck.OCCUPIED
	for walker: Array in walkers:
		if walker[0] == at:
			return BuildCheck.ENEMY_THERE
	if map.cell(at) == MapData.Cell.HIGH:
		return BuildCheck.OK  # Hochfläche liegt nie auf dem Weg
	_astar.set_point_solid(at, true)
	var ok := true
	for leg in map.waypoints.size():
		if _astar.get_id_path(leg_start(leg), map.waypoints[leg]).is_empty():
			ok = false
			break
	# Auch kein Gegner darf eingesperrt werden.
	for walker: Array in walkers:
		if not ok:
			break
		ok = not _astar.get_id_path(walker[0], walker[1]).is_empty()
	_astar.set_point_solid(at, false)
	return BuildCheck.OK if ok else BuildCheck.BLOCKS_PATH


## Ganzer Weg, als stünde auf `at` schon ein Turm (Vorschau beim Bauen).
func full_path_with(at: Vector2i) -> Array[Vector2i]:
	if map.cell(at) == MapData.Cell.HIGH or not walkable(at):
		return full_path()
	_astar.set_point_solid(at, true)
	var path := full_path()
	_astar.set_point_solid(at, false)
	return path


func place(at: Vector2i, tower: Variant) -> void:
	towers[at] = tower
	if map.cell(at) != MapData.Cell.HIGH:
		_astar.set_point_solid(at, true)
		_measure_legs()
	changed.emit()


func remove(at: Vector2i) -> void:
	towers.erase(at)
	_astar.set_point_solid(at, not walkable_terrain(at))
	_measure_legs()
	changed.emit()


func _measure_legs() -> void:
	leg_lengths.clear()
	for leg in map.waypoints.size():
		leg_lengths.append(path_length(_astar.get_id_path(leg_start(leg), map.waypoints[leg])))


static func cell_of(world: Vector3) -> Vector2i:
	return Vector2i(roundi(world.x), roundi(world.z))


static func world_of(at: Vector2i, height := 0.0) -> Vector3:
	return Vector3(at.x, height, at.y)
