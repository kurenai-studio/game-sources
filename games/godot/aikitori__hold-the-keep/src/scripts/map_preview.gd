class_name MapPreview
extends Control
## Draufsicht einer Karte fürs Menü: Gelände als Kacheln, der Grundweg der Gegner als Linie, dazu Friedhof,
## Burg und Kontrollpunkte. Gezeichnet statt gerendert, damit das Menü auch auf schwachen Geräten sofort steht.

const COLORS := {
	".": Color("#6f9a4a"), "=": Color("#c8a96a"), "^": Color("#9c9478"), "#": Color("#2f4a2c"),
	"r": Color("#7d7a72"), "g": Color("#56604f"), "S": Color("#4b3f5a"), "K": Color("#b8873a"),
}
const PATH_COLOR := Color(0.75, 0.15, 0.1, 0.8)

var map: MapData
var _path: Array[Vector2i] = []


func _init(map_data: MapData) -> void:
	map = map_data
	_path = Board.new(map).full_path()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Breite festlegen, die Höhe folgt dem Seitenverhältnis der Karte.
func set_width(width: float) -> void:
	custom_minimum_size = Vector2(width, width * map.size.y / map.size.x)


func _draw() -> void:
	var cell := size.x / map.size.x
	for y in map.size.y:
		for x in map.size.x:
			var glyph := map.glyph(Vector2i(x, y))
			var color: Color = COLORS.get(glyph, COLORS["."])
			draw_rect(Rect2(x * cell, y * cell, cell + 0.5, cell + 0.5), color)
	var points := PackedVector2Array()
	for at in _path:
		points.append(_center(at, cell))
	if points.size() > 1:
		draw_polyline(points, PATH_COLOR, maxf(2.0, cell * 0.3), true)
	var font := get_theme_default_font()
	var font_size := int(cell * 1.6)
	for i in map.waypoints.size() - 1:
		var at := _center(map.waypoints[i], cell)
		draw_circle(at, cell * 1.1, Hud.GOLD)
		draw_circle(at, cell * 1.1, Hud.INK, false, 1.5, true)
		_label(font, font_size, at, str(i + 1))
	_marker(map.spawn, cell, Color("#4b3f5a"), "S", font, font_size)
	_marker(map.keep, cell, Color("#b8873a"), "B", font, font_size)
	draw_rect(Rect2(Vector2.ZERO, size), Hud.INK, false, 2.0)


func _marker(at: Vector2i, cell: float, color: Color, text: String, font: Font, font_size: int) -> void:
	# Friedhof und Burg liegen oft am Rand: ganz ins Bild rücken.
	var half := cell * 1.2
	var center := _center(at, cell).clamp(Vector2.ONE * half, size - Vector2.ONE * half)
	var rect := Rect2(center - Vector2.ONE * cell * 1.2, Vector2.ONE * cell * 2.4)
	draw_rect(rect, color)
	draw_rect(rect, Hud.PARCHMENT, false, 1.5)
	_label(font, font_size, center, text, Hud.PARCHMENT)


func _label(font: Font, font_size: int, center: Vector2, text: String, color := Hud.INK) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, center + Vector2(-text_size.x / 2.0, font.get_ascent(font_size) - text_size.y / 2.0),
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _center(at: Vector2i, cell: float) -> Vector2:
	return (Vector2(at) + Vector2(0.5, 0.5)) * cell
