class_name IfIcons
extends RefCounted
## Icons for the IF tile and the sensors: "if" (a path that forks), "ahead", "sense_left" and
## "sense_right" (a straight arrow up, left, right: where the sensor looks) and "goal" (a ring
## with a dot). UiKit.icon calls this for the kinds it does not draw itself.


## Draws the icon `kind` in a square of side `s` centered on `c`. False for an unknown kind.
static func draw(canvas: CanvasItem, kind: String, c: Vector2, s: float, color: Color) -> bool:
	var w := maxf(2.0, s * 0.12)
	match kind:
		"if":
			# A stem that forks into two arrows: one branch is taken, the other is not.
			canvas.draw_line(c + Vector2(0, s * 0.42), c + Vector2(0, s * 0.02), color, w)
			canvas.draw_line(c + Vector2(0, s * 0.02), c + Vector2(-s * 0.28, -s * 0.18), color, w)
			canvas.draw_line(c + Vector2(0, s * 0.02), c + Vector2(s * 0.28, -s * 0.18), color, w)
			_arrow_head(canvas, c + Vector2(-s * 0.28, -s * 0.18), Vector2(0, -1), s, color)
			_arrow_head(canvas, c + Vector2(s * 0.28, -s * 0.18), Vector2(0, -1), s, color)
		"ahead", "sense_left", "sense_right":
			var direction := Vector2(0, -1)
			if kind == "sense_left":
				direction = Vector2(-1, 0)
			elif kind == "sense_right":
				direction = Vector2(1, 0)
			canvas.draw_line(c - direction * s * 0.4, c + direction * s * 0.1, color, w)
			_arrow_head(canvas, c + direction * s * 0.42, direction, s, color)
		"goal":
			canvas.draw_arc(c, s * 0.36, 0.0, TAU, 24, color, w)
			canvas.draw_circle(c, s * 0.14, color)
		_:
			return false
	return true


## A filled triangle whose tip is at `tip` and which points along `direction`.
static func _arrow_head(
	canvas: CanvasItem, tip: Vector2, direction: Vector2, s: float, color: Color
) -> void:
	var base := tip - direction * s * 0.34
	var side := Vector2(-direction.y, direction.x) * s * 0.18
	canvas.draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)
