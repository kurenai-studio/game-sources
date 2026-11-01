# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name ShotPieces
extends RefCounted
## The small pictures that shots and their marks are put together from: discs, rings, stars,
## beads, puffs, bars, trails, arcs and the shots themselves. Each is drawn once into the MapAtlas
## sheet, and MapShots draws them as tinted, scaled and turned quads of that one texture, so the
## Compatibility renderer batches every mark into a very few draw calls (docs/ARCHITECTURE.md 9.3).
## Pieces that are plain white take their color from the quad's modulate color. Internal to
## src/render/.

enum Piece {
	DISC, RING, DASH, STAR4, STAR8, SPLAT, BEAD, PUFF, BAR, TRAIL, ARC,
	PUMPKIN, JAR, PEBBLE, STONE, ARROW, ROCKET, ROCKET_HONEY, FLAME, THORN, SNOWBALL,
}

## Tile size in cells, and the anchor (the point the piece is placed by) in cells.
const TILES: Array[Vector2] = [
	Vector2(1.0, 1.0), Vector2(2.0, 2.0), Vector2(2.0, 2.0), Vector2(1.0, 1.0), Vector2(1.0, 1.0),
	Vector2(1.0, 1.0), Vector2(0.6, 0.6), Vector2(1.0, 1.0), Vector2(1.0, 0.2), Vector2(1.0, 0.4), Vector2(2.0, 2.0),
	Vector2(1.2, 1.2), Vector2(1.2, 1.2), Vector2(0.6, 0.6), Vector2(0.6, 0.6), Vector2(1.0, 0.4),
	Vector2(0.7, 0.3), Vector2(0.7, 0.3), Vector2(0.5, 0.2), Vector2(0.56, 0.3), Vector2(0.9, 0.9),
]
const ANCHORS: Array[Vector2] = [
	Vector2(0.5, 0.5), Vector2(1.0, 1.0), Vector2(1.0, 1.0), Vector2(0.5, 0.5), Vector2(0.5, 0.5),
	Vector2(0.5, 0.5), Vector2(0.3, 0.3), Vector2(0.5, 0.5), Vector2(0.0, 0.1), Vector2(1.0, 0.2), Vector2(1.0, 1.0),
	Vector2(0.6, 0.6), Vector2(0.6, 0.6), Vector2(0.3, 0.3), Vector2(0.3, 0.3), Vector2(0.85, 0.2),
	Vector2(0.55, 0.15), Vector2(0.55, 0.15), Vector2(0.4, 0.1), Vector2(0.06, 0.15), Vector2(0.45, 0.45),
]
## What size 1.0 means for the round pieces, as a radius in cells.
const DISC_R: float = 0.46
const RING_R: float = 0.9
const PUMPKIN_R: float = 0.38
const JAR_R: float = 0.28
const PEBBLE_R: float = 0.2
const STONE_R: float = 0.2
## The Snow Fort's snowball at size 1.0, as a radius in cells.
const SNOW_R: float = 0.3
## A thorn at size 1.0 reaches this far from its base, in cells.
const THORN_LENGTH: float = 0.4

static func key(piece: int) -> String:
	return "s:%d" % piece


## Draws `piece` with its anchor at `at`, `px` pixels to a cell.
static func draw(canvas: CanvasItem, piece: int, at: Vector2, px: float) -> void:
	var ink: Color = Palette.INK_LINE
	match piece:
		Piece.DISC:
			canvas.draw_circle(at, DISC_R * px, Color.WHITE, true, -1.0, true)
		Piece.RING:
			canvas.draw_arc(at, RING_R * px, 0.0, TAU, 72, ink, 0.12 * px, true)
			canvas.draw_arc(at, RING_R * px, 0.0, TAU, 72, Color.WHITE, 0.055 * px, true)
		Piece.DASH:
			for j: int in 8:
				var a0: float = TAU * float(j) / 8.0
				var a1: float = a0 + TAU / 8.0 * 0.55
				canvas.draw_arc(at, RING_R * px, a0, a1, 10, ink, 0.12 * px, true)
				canvas.draw_arc(at, RING_R * px, a0, a1, 10, Color.WHITE, 0.055 * px, true)
		Piece.STAR4:
			_star(canvas, at, px, 4, 0.5, 0.5, 0.11)
		Piece.STAR8:
			_star(canvas, at, px, 8, 0.5, 0.33, 0.13)
		Piece.SPLAT:
			var pts: PackedVector2Array = PackedVector2Array()
			var outer: PackedVector2Array = PackedVector2Array()
			for j: int in 16:
				var rr: float = 0.34 * (1.0 if j % 2 == 0 else 0.62) * (1.0 + 0.08 * float(j % 3))
				var v: Vector2 = Vector2.from_angle(TAU * float(j) / 16.0 + 0.3)
				pts.append(at + v * rr * px)
				outer.append(at + v * rr * 1.2 * px)
			canvas.draw_colored_polygon(outer, ink)
			canvas.draw_colored_polygon(pts, Color.WHITE)
		Piece.BEAD:
			canvas.draw_circle(at, 0.25 * px, ink, true, -1.0, true)
			canvas.draw_circle(at, 0.17 * px, Color.WHITE, true, -1.0, true)
		Piece.PUFF:
			canvas.draw_circle(at, 0.46 * px, Color(ink, 0.45), true, -1.0, true)
			canvas.draw_circle(at, 0.38 * px, Palette.SMOKE, true, -1.0, true)
		Piece.BAR:
			canvas.draw_rect(Rect2(at + Vector2(0.0, -0.1) * px, Vector2(1.0, 0.2) * px), ink)
			canvas.draw_rect(Rect2(at + Vector2(0.0, -0.055) * px, Vector2(1.0, 0.11) * px), Color.WHITE)
		Piece.TRAIL:
			canvas.draw_polygon(
				PackedVector2Array([at + Vector2(-1.0, 0.0) * px, at + Vector2(0.0, -0.15) * px, at + Vector2(0.0, 0.15) * px]),
				PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE]))
		Piece.ARC:
			canvas.draw_arc(at, 0.8 * px, -1.0, 1.0, 24, ink, 0.12 * px, true)
			canvas.draw_arc(at, 0.8 * px, -1.0, 1.0, 24, Color.WHITE, 0.055 * px, true)
		Piece.PUMPKIN:
			_pumpkin(canvas, at, px)
		Piece.JAR:
			_jar(canvas, at, px)
		Piece.PEBBLE:
			canvas.draw_circle(at, 0.26 * px, ink, true, -1.0, true)
			canvas.draw_circle(at, PEBBLE_R * px, Palette.PLASTER, true, -1.0, true)
			canvas.draw_circle(at + Vector2(-0.06, -0.06) * px, 0.05 * px, Palette.SPARKLE, true, -1.0, true)
		Piece.STONE:
			canvas.draw_circle(at, 0.26 * px, ink, true, -1.0, true)
			canvas.draw_circle(at, STONE_R * px, Palette.STONE, true, -1.0, true)
			canvas.draw_arc(at, 0.14 * px, 0.5, 2.6, 8, Palette.STONE_DARK, 0.06 * px, true)
			canvas.draw_circle(at + Vector2(-0.07, -0.07) * px, 0.045 * px, Palette.PLASTER, true, -1.0, true)
		Piece.ARROW:
			_arrow(canvas, at, px)
		Piece.ROCKET:
			_rocket(canvas, at, px, Palette.ROOF_CLAY)
		Piece.ROCKET_HONEY:
			_rocket(canvas, at, px, Palette.HONEY)
		Piece.FLAME:
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -0.07) * px, at + Vector2(-0.3, 0.0) * px, at + Vector2(0.0, 0.07) * px]), Palette.GLOW)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -0.035) * px, at + Vector2(-0.17, 0.0) * px, at + Vector2(0.0, 0.035) * px]), Palette.LANTERN_CORE)
		Piece.THORN:
			# A spike pointing right from its base at the anchor, white so a quad can tint it.
			var ink_spike: PackedVector2Array = PackedVector2Array([at + Vector2(-0.05, -0.14) * px, at + Vector2(THORN_LENGTH + 0.04, 0.0) * px, at + Vector2(-0.05, 0.14) * px])
			var spike: PackedVector2Array = PackedVector2Array([at + Vector2(0.0, -0.085) * px, at + Vector2(THORN_LENGTH - 0.03, 0.0) * px, at + Vector2(0.0, 0.085) * px])
			canvas.draw_colored_polygon(ink_spike, ink)
			canvas.draw_colored_polygon(spike, Color.WHITE)
		Piece.SNOWBALL:
			_snowball(canvas, at, px)


## A star of `n` points: tips of `tip` and `short` cells (even and odd), notches of `notch`, with an
## ink edge.
static func _star(canvas: CanvasItem, at: Vector2, px: float, n: int, tip: float, short: float, notch: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var outer: PackedVector2Array = PackedVector2Array()
	for j: int in n:
		var a: float = TAU * float(j) / float(n) - PI * 0.5
		var r: float = tip if j % 2 == 0 else short
		var between: float = a + PI / float(n)
		pts.append(at + Vector2.from_angle(a) * r * 0.82 * px)
		pts.append(at + Vector2.from_angle(between) * notch * px)
		outer.append(at + Vector2.from_angle(a) * r * px)
		outer.append(at + Vector2.from_angle(between) * notch * 1.9 * px)
	canvas.draw_colored_polygon(outer, Palette.INK_LINE)
	canvas.draw_colored_polygon(pts, Color.WHITE)


static func _pumpkin(canvas: CanvasItem, at: Vector2, px: float) -> void:
	var r: float = PUMPKIN_R * px
	canvas.draw_circle(at, r * 1.18, Palette.INK_LINE, true, -1.0, true)
	canvas.draw_circle(at, r, Palette.PUMPKIN, true, -1.0, true)
	canvas.draw_arc(at, r * 0.62, -1.1, 1.1, 8, Palette.ROOF_CLAY, r * 0.12, true)
	canvas.draw_arc(at, r * 0.62, PI - 1.1, PI + 1.1, 8, Palette.ROOF_CLAY, r * 0.12, true)
	canvas.draw_line(at + Vector2(0.0, -r * 0.85), at + Vector2(r * 0.1, -r * 1.3), Palette.INK_LINE, r * 0.42, true)
	canvas.draw_line(at + Vector2(0.0, -r * 0.85), at + Vector2(r * 0.1, -r * 1.3), Palette.TREE_DARK, r * 0.3, true)
	canvas.draw_circle(at + Vector2(-0.38, -0.3) * r, r * 0.17, Color(Palette.HONEY, 0.9), true, -1.0, true)


## A round pot with a flat lid and a pale shine, so it never reads as a pumpkin.
static func _jar(canvas: CanvasItem, at: Vector2, px: float) -> void:
	var r: float = JAR_R * px
	var lid: PackedVector2Array = PackedVector2Array([Vector2(-0.62, -1.18), Vector2(0.62, -1.18), Vector2(0.62, -0.72), Vector2(-0.62, -0.72)])
	var lid_ink: PackedVector2Array = PackedVector2Array()
	var lid_fill: PackedVector2Array = PackedVector2Array()
	for v: Vector2 in lid:
		lid_ink.append(at + v * r * 1.25 + Vector2(0.0, -r * 0.06))
		lid_fill.append(at + v * r)
	canvas.draw_circle(at, r * 1.2, Palette.INK_LINE, true, -1.0, true)
	canvas.draw_colored_polygon(lid_ink, Palette.INK_LINE)
	canvas.draw_circle(at, r, Palette.JAM, true, -1.0, true)
	canvas.draw_colored_polygon(lid_fill, Palette.PLASTER)
	canvas.draw_arc(at, r * 0.62, 2.4, 4.2, 8, Palette.SPARKLE_LILAC, r * 0.2, true)


## An arrow pointing right, its head at the anchor, with fletching at the back.
static func _arrow(canvas: CanvasItem, at: Vector2, px: float) -> void:
	var tail: Vector2 = at + Vector2(-0.46, 0.0) * px
	canvas.draw_line(tail, at, Palette.INK_LINE, 0.095 * px, true)
	canvas.draw_line(tail, at, Palette.WOOD, 0.05 * px, true)
	var tip_ink: PackedVector2Array = PackedVector2Array([at + Vector2(0.15, 0.0) * px, at + Vector2(0.0, 0.085) * px, at + Vector2(0.0, -0.085) * px])
	var tip: PackedVector2Array = PackedVector2Array([at + Vector2(0.125, 0.0) * px, at + Vector2(0.0, 0.06) * px, at + Vector2(0.0, -0.06) * px])
	canvas.draw_colored_polygon(tip_ink, Palette.INK_LINE)
	canvas.draw_colored_polygon(tip, Palette.IRON)
	canvas.draw_line(tail, tail + Vector2(-0.1, 0.1) * px, Palette.BONE, 0.04 * px, true)
	canvas.draw_line(tail, tail + Vector2(-0.1, -0.1) * px, Palette.BONE, 0.04 * px, true)


## A rocket pointing right, its nose at the anchor.
static func _rocket(canvas: CanvasItem, at: Vector2, px: float, body: Color) -> void:
	var tail: Vector2 = at + Vector2(-0.18, 0.0) * px
	canvas.draw_line(tail, at, Palette.INK_LINE, 0.11 * px, true)
	canvas.draw_line(tail, at, body, 0.065 * px, true)
	canvas.draw_line(at + Vector2(-0.05, 0.0) * px, at, Palette.PLASTER, 0.065 * px, true)
	canvas.draw_circle(at, 0.04 * px, Palette.LANTERN_CORE, true, -1.0, true)


## A round ball of warm snow with a shaded curve that shows it roll.
static func _snowball(canvas: CanvasItem, at: Vector2, px: float) -> void:
	var r: float = SNOW_R * px
	canvas.draw_circle(at, r * 1.18, Palette.INK_LINE, true, -1.0, true)
	canvas.draw_circle(at, r, Palette.SNOW_WARM, true, -1.0, true)
	canvas.draw_arc(at, r * 0.62, 0.5, 3.3, 10, Palette.SNOW_WARM_SHADE, r * 0.16, true)
	canvas.draw_arc(at, r * 0.3, 3.8, 5.6, 6, Palette.SNOW_WARM_SHADE, r * 0.12, true)
	canvas.draw_circle(at + Vector2(-0.36, -0.4) * r, r * 0.16, Color.WHITE, true, -1.0, true)
