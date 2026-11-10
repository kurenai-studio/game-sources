extends RefCounted
## Original code-drawn pixel character. All geometry lands on a pixel grid.

const INK: Color = Color("10121e")
const FUR: Color = Color("26c7d4")
const SHADE: Color = Color("16829c")
const EYE: Color = Color("dfff48")
const CREAM: Color = Color("f3ebce")

static func poly(c: CanvasItem, points: Array, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array(points), color)

static func rect(c: CanvasItem, x: float, y: float, w: float, h: float, color: Color) -> void:
	c.draw_rect(Rect2(x, y, w, h), color)

static func draw(c: CanvasItem, at: Vector2, size: float, tick: float, air: bool, trick: float, tint: Color = Color.WHITE, beat: float = -1.0) -> void:
	var bob: float = 0.0 if air else roundf(sin(beat*TAU) if beat >= 0.0 else sin(tick*8.0))
	c.draw_set_transform(at + Vector2(0, bob), -0.10 if air else -0.035, Vector2.ONE * size)
	var fur: Color = FUR * tint
	var ink: Color = INK * tint
	var cream: Color = CREAM * tint
	# Tail, behind the body.
	var tail: float = roundf(sin(tick * 5.0) * 2.0)
	poly(c, [Vector2(9, -18), Vector2(-3, -19), Vector2(-9, -30 + tail), Vector2(-9, -38 + tail), Vector2(-3, -40 + tail), Vector2(4, -37 + tail), Vector2(3, -33 + tail), Vector2(-4, -34 + tail), Vector2(-3, -28), Vector2(11, -25)], ink)
	# Shoes, shorts and oversized shirt.
	poly(c, [Vector2(4,-18), Vector2(21,-19), Vector2(29,-8), Vector2(17,-5), Vector2(9,-9), Vector2(-1,-8)], ink)
	poly(c, [Vector2(8,-17), Vector2(22,-17), Vector2(25,-10), Vector2(17,-8), Vector2(13,-11), Vector2(5,-10)], cream)
	poly(c, [Vector2(7,-37), Vector2(22,-37), Vector2(30,-27), Vector2(25,-19), Vector2(11,-17), Vector2(1,-24)], ink)
	poly(c, [Vector2(2,-29), Vector2(-5,-24), Vector2(-6,-19), Vector2(0,-17), Vector2(5,-23)], ink)
	poly(c, [Vector2(-5,-22), Vector2(-7,-19), Vector2(-4,-15), Vector2(1,-16), Vector2(2,-20)], fur)
	poly(c, [Vector2(26,-29), Vector2(34,-24), Vector2(39,-24), Vector2(41,-19), Vector2(37,-17), Vector2(32,-20), Vector2(27,-19)], fur)
	rect(c, 0,-9,13,5,ink)
	rect(c, 18,-8,14,5,ink)
	rect(c, 2,-5,11,2,cream)
	rect(c, 20,-4,13,2,cream)
	# Silver necklace.
	c.draw_line(Vector2(11,-31),Vector2(16,-25),Color("77778e"),1)
	c.draw_line(Vector2(16,-25),Vector2(23,-30),Color("77778e"),1)
	rect(c,15,-25,2,3,cream)
	# Angular ears and head.
	poly(c,[Vector2(4,-36),Vector2(0,-57),Vector2(12,-50),Vector2(21,-51),Vector2(32,-58),Vector2(30,-39),Vector2(34,-34),Vector2(24,-30),Vector2(12,-32)],ink)
	poly(c,[Vector2(6,-38),Vector2(4,-52),Vector2(13,-47),Vector2(22,-48),Vector2(29,-53),Vector2(27,-39),Vector2(30,-35),Vector2(23,-33),Vector2(13,-35)],fur)
	poly(c,[Vector2(6,-50),Vector2(8,-44),Vector2(12,-46)],SHADE*tint)
	poly(c,[Vector2(26,-49),Vector2(23,-45),Vector2(27,-45)],SHADE*tint)
	# Huge yellow eyes, with half-lidded, sideways swagger.
	poly(c,[Vector2(8,-43),Vector2(16,-41),Vector2(15,-36),Vector2(10,-37)],EYE*tint)
	poly(c,[Vector2(19,-41),Vector2(28,-44),Vector2(26,-37),Vector2(20,-36)],EYE*tint)
	rect(c,13,-41,2,5,ink)
	rect(c,23,-42,2,5,ink)
	poly(c,[Vector2(16,-36),Vector2(20,-36),Vector2(18,-33)],ink)
	c.draw_line(Vector2(19,-32),Vector2(23,-33),ink,1)
	rect(c,2,-41,4,1,ink)
	rect(c,28,-39,4,1,ink)
	# Board rotates independently for a kickflip on successful rhythm hits.
	var flip: float = sin(trick * PI) * 0.85
	c.draw_set_transform(at + Vector2(15 * size, 0), flip, Vector2(size, size * maxf(0.22, absf(cos(trick * TAU)))))
	poly(c,[Vector2(-24,-1),Vector2(-21,2),Vector2(19,2),Vector2(25,-2),Vector2(25,-4),Vector2(18,-1),Vector2(-18,-1),Vector2(-24,-5)],ink)
	rect(c,-19,-1,37,2,Color("e36b8e")*tint)
	rect(c,-12,2,3,2,cream)
	rect(c,10,2,3,2,cream)
	rect(c,-14,4,6,4,ink)
	rect(c,8,4,6,4,ink)
	rect(c,-13,5,3,2,EYE*tint)
	rect(c,9,5,3,2,EYE*tint)
	c.draw_set_transform(Vector2.ZERO)
