# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RoutePieces
extends RefCounted
## The three small pictures route lines move: the arrow chevron, the dot of a flyer's line and
## the dash of a gate breaker's line. Each is drawn once into the MapAtlas sheet with the same
## widths and colors as MapArt.draw_route (a dark casing and a light core), and MapRoutes draws
## them as turned quads of that one texture, so a route's arrows, dashes and dots cost one draw
## call for the whole layer instead of two for each (docs/ARCHITECTURE.md 9.3). The lines
## themselves stay polylines. Internal to src/render/.

enum Piece { CHEVRON, DOT, DASH }

## The length of a dash, as a fraction of a cell: MapArt.draw_route's period 0.36 times 0.55.
const DASH_LENGTH: float = 0.198
## MapArt.draw_route's widths, as fractions of a cell.
const CASING: float = 0.11
const CORE: float = 0.055
## The chevron's size s, as a fraction of a cell. It points right, its tip 0.7 s ahead of the anchor.
const CHEVRON_S: float = 0.13

## Tile size in cells, and the anchor (the point the piece is placed by) in cells.
const TILES: Array[Vector2] = [Vector2(0.55, 0.55), Vector2(0.25, 0.25), Vector2(0.4, 0.25)]
const ANCHORS: Array[Vector2] = [Vector2(0.275, 0.275), Vector2(0.125, 0.125), Vector2(0.2, 0.125)]


static func key(piece: int) -> String:
	return "r:%d" % piece


## Draws `piece` with its anchor at `at`, `px` pixels to a cell.
static func draw(canvas: CanvasItem, piece: int, at: Vector2, px: float) -> void:
	var casing: float = CASING * px
	var core: float = CORE * px
	match piece:
		Piece.CHEVRON:
			var s: float = CHEVRON_S * px
			var chevron: PackedVector2Array = PackedVector2Array([at + Vector2(-0.3 * s, s), at + Vector2(0.7 * s, 0.0), at + Vector2(-0.3 * s, -s)])
			canvas.draw_polyline(chevron, Palette.INK_LINE, casing, true)
			canvas.draw_polyline(chevron, Palette.ROUTE, core, true)
		Piece.DOT:
			canvas.draw_circle(at, casing * 0.5, Palette.INK_LINE, true, -1.0, true)
			canvas.draw_circle(at, core * 0.62, Palette.ROUTE, true, -1.0, true)
		Piece.DASH:
			var half: Vector2 = Vector2(DASH_LENGTH * px * 0.5, 0.0)
			var seg: PackedVector2Array = PackedVector2Array([at - half, at + half])
			canvas.draw_polyline(seg, Palette.INK_LINE, casing, true)
			canvas.draw_polyline(seg, Palette.ROUTE, core, true)
