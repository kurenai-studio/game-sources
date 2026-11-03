extends Control

const StarShape := preload("res://scripts/star_shape.gd")

const GOAL := 5
const STAR_SIZE := 40.0
const GAP := 16.0
const EMPTY_COLOR := Color(0.22, 0.26, 0.42)
const FILL_COLOR := Color(1.0, 0.8, 0.28)

var filled: int = 0: set = set_filled


func _ready() -> void:
	custom_minimum_size = Vector2(GOAL * STAR_SIZE + (GOAL - 1) * GAP, STAR_SIZE + 8.0)


func set_filled(value: int) -> void:
	filled = value
	queue_redraw()


func _draw() -> void:
	var step := STAR_SIZE + GAP
	var total := GOAL * STAR_SIZE + (GOAL - 1) * GAP
	var left := (size.x - total) * 0.5 + STAR_SIZE * 0.5
	for i in GOAL:
		var center := Vector2(left + i * step, size.y * 0.5)
		var color := FILL_COLOR if i < filled else EMPTY_COLOR
		draw_colored_polygon(StarShape.points(center, STAR_SIZE * 0.5, STAR_SIZE * 0.22), color)
