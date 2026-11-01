# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Measures how far every tower look reaches from its ground line, at full size, by drawing it
## and reading the pixels. Needs a display, so no --headless:
##
##     godot --path . --script res://tests/render/tower_extent.gd
##
## It prints one line per look and exits 1 when a look reaches higher than MapAtlas.TOWER_REACH,
## sticks out sideways more than MapAtlas.TOWER_HALF_WIDTH, or hangs below the ground line by more
## than 0.1 of a cell. tests/render/test_tower_overlap.gd trusts those two constants, so run this
## again after src/theme/silhouettes.gd changes.

const SIZE: float = 256.0
const SHEET: int = 1024
const LOOKS: Array[Vector2i] = [Vector2i(1, -1), Vector2i(2, -1), Vector2i(3, 0), Vector2i(3, 1)]
const BELOW_LIMIT: float = 0.1
## Pixels fainter than this are not counted (the soft shadow).
const SOLID: float = 0.3


class Painter:
	extends Node2D
	var type: StringName = &""
	var tier: int = 1
	var spec: int = -1

	func _draw() -> void:
		Silhouettes.draw_tower(self, type, tier, spec, Vector2(SHEET * 0.5, SHEET * 0.5), SIZE)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("tower_extent.gd needs a display.")
		quit(1)
		return
	var worst_reach: float = 0.0
	var worst_half: float = 0.0
	var worst_below: float = 0.0
	var ground: float = SHEET * 0.5 + Silhouettes.TOWER_GROUND * SIZE
	for type: StringName in Silhouettes.TOWERS:
		for look: Vector2i in LOOKS:
			var host: SubViewport = SubViewport.new()
			host.size = Vector2i(SHEET, SHEET)
			host.transparent_bg = true
			host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(host)
			var painter: Painter = Painter.new()
			painter.type = type
			painter.tier = look.x
			painter.spec = look.y
			host.add_child(painter)
			await process_frame
			await RenderingServer.frame_post_draw
			var img: Image = host.get_texture().get_image()
			var top: int = SHEET
			var bottom: int = -1
			var left: int = SHEET
			var right: int = -1
			for y: int in SHEET:
				for x: int in SHEET:
					if img.get_pixel(x, y).a > SOLID:
						top = mini(top, y)
						bottom = maxi(bottom, y)
						left = mini(left, x)
						right = maxi(right, x)
			var reach: float = (ground - float(top)) / SIZE
			var half: float = maxf(SHEET * 0.5 - float(left), float(right) - SHEET * 0.5) / SIZE
			var below: float = (float(bottom) - ground) / SIZE
			worst_reach = maxf(worst_reach, reach)
			worst_half = maxf(worst_half, half)
			worst_below = maxf(worst_below, below)
			print("%s tier %d spec %d: reach %.3f half width %.3f below ground %.3f" % [type, look.x, look.y, reach, half, below])
			host.queue_free()
			await process_frame
	var ok: bool = worst_reach <= MapAtlas.TOWER_REACH and worst_half <= MapAtlas.TOWER_HALF_WIDTH and worst_below <= BELOW_LIMIT
	print("worst: reach %.3f (limit %.3f), half width %.3f (limit %.3f), below ground %.3f (limit %.3f): %s" % [
		worst_reach, MapAtlas.TOWER_REACH, worst_half, MapAtlas.TOWER_HALF_WIDTH, worst_below, BELOW_LIMIT, "OK" if ok else "FAIL"])
	quit(0 if ok else 1)
