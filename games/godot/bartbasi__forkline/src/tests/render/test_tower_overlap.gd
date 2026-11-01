# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Towers on neighbouring build spots: on every campaign map and every run map the assembler can
## make, with a tier 3 tower (the tallest) on every spot, towers draw in row order, a tower never
## covers the stone steps of the one above it, neighbours keep apart sideways, boost and status
## marks draw over every tower, and each tower still belongs to exactly its own cell.
## The reach and width constants come from tests/render/tower_extent.gd (needs a display).

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")

var _views: Array[MapView] = []


func after_each() -> void:
	for v: MapView in _views:
		if is_instance_valid(v):
			if v.get_parent() != null:
				v.get_parent().remove_child(v)
			v.free()
	_views.clear()


## Every real map, as [label, LevelData].
func _maps(stats: Catalog) -> Array:
	var out: Array = []
	var dir: DirAccess = DirAccess.open("res://data/levels")
	var files: PackedStringArray = dir.get_files()
	files.sort()
	for f: String in files:
		if f.begins_with("r") and f.ends_with(".json"):
			var level: LevelData = Fx.level(f.get_basename(), stats, 100000)
			level.towers = Fx.ALL_TOWER_IDS.duplicate()
			out.append([f.get_basename(), level])
	var runs: Array[LevelData] = Fx.run_levels(stats)
	for i: int in runs.size():
		out.append(["run map %d" % i, runs[i]])
	return out


func _view_with_towers(level: LevelData, stats: Catalog, shift: int) -> MapView:
	var b: Battle = Fx.level_battle(level, stats)
	var v: MapView = MapView.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(v)
	_views.append(v)
	v.setup(b)
	v.fit(Rect2(0, 0, 1080, 1080.0 / 7.0 * float(level.rows)))
	# A headless window has no real size, so ask for the sharper sheet a phone gets (1.25 texels a pixel).
	v.set("_bake_scale", 1.25)
	v.call("_rebake")
	assert_near(v.get("_atlas").texel_scale, 1.25, 0.0001, "the sheet is baked above 1")
	var n: int = Fx.fill(b, shift)
	assert_eq(n, level.spots.size(), "a tower on every spot")
	v.sync(0.0)
	return v


func test_there_are_maps_to_check() -> void:
	var stats: Catalog = Fx.catalog()
	var maps: Array = _maps(stats)
	assert_true(maps.size() >= 18 + 40, "campaign and run maps found: %d" % maps.size())


func test_the_tallest_tower_stays_below_the_ground_line_of_the_cell_above() -> void:
	# The only way a tower can cover the stone steps of the one above is by reaching past the
	# upper tower's ground line, one cell up from its own.
	var top: float = MapAtlas.TOWER_REACH * MapAtlas.TOWER_SCALE
	assert_true(top <= 1.0, "reach at scale %.3f is at most one cell" % top)
	assert_true(top >= 0.8, "towers are not drawn needlessly small: %.3f" % top)
	assert_true(2.0 * MapAtlas.TOWER_HALF_WIDTH * MapAtlas.TOWER_SCALE <= 1.0, "side neighbours do not touch")


func test_towers_draw_in_row_order_and_no_neighbour_hides_a_base() -> void:
	var stats: Catalog = Fx.catalog()
	var pairs: int = 0
	var cell_px: float = MapView.CELL
	for item: Array in _maps(stats):
		var label: String = item[0]
		var level: LevelData = item[1]
		for shift: int in 2:
			var v: MapView = _view_with_towers(level, stats, shift * 2)
			var towers: Dictionary = v.get("_towers")
			assert_eq(towers.size(), level.spots.size(), "%s: a node for every tower" % label)
			var entities: Node2D = v.get("_entities") as Node2D
			assert_true(entities.y_sort_enabled, "%s: towers and creatures sort by their ground line" % label)
			var atlas: MapAtlas = v.get("_atlas") as MapAtlas
			for cell: Vector2i in towers:
				var tv: MapView.TowerView = towers[cell]
				assert_eq(tv.sprite.z_index, 0, "%s %s: one layer, so only the row decides" % [label, cell])
				assert_near(tv.sprite.scale.x * atlas.texel_scale, 1.0, 0.0001, "%s %s: drawn at the sheet's own scale" % [label, cell])
				assert_near(tv.sprite.position.y, (float(cell.y) + 0.5 + Silhouettes.TOWER_GROUND) * cell_px, 0.01, "%s %s: stands on its ground line" % [label, cell])
				assert_eq(v.cell_at(v.get_global_transform() * tv.sprite.position), cell, "%s %s: the tap target is its own cell" % [label, cell])
			for a: Vector2i in towers:
				for c: Vector2i in towers:
					var up: MapView.TowerView = towers[a]
					var down: MapView.TowerView = towers[c]
					if c.y > a.y:
						assert_true(down.sprite.position.y > up.sprite.position.y, "%s: %s draws in front of %s" % [label, c, a])
					var d: Vector2i = c - a
					if d.y == 1 and absi(d.x) <= 1:
						pairs += 1
						if d.x == 0:
							# The lower tower's highest point against the upper tower's ground line.
							var lowest_top: float = down.sprite.position.y - MapAtlas.TOWER_REACH * MapAtlas.TOWER_SCALE * cell_px
							assert_true(lowest_top >= up.sprite.position.y, "%s: %s covers the base of %s" % [label, c, a])
					if d.x == 1 and d.y >= 0 and d.y <= 1:
						pairs += 1
						var gap: float = cell_px - 2.0 * MapAtlas.TOWER_HALF_WIDTH * MapAtlas.TOWER_SCALE * cell_px
						assert_true(gap >= 0.0, "%s: %s and %s keep apart sideways" % [label, a, c])
	assert_true(pairs > 0, "the maps have neighbouring spots to check: %d" % pairs)


func test_marks_draw_over_every_tower() -> void:
	var stats: Catalog = Fx.catalog()
	var level: LevelData = Fx.run_levels(stats)[0]
	var v: MapView = _view_with_towers(level, stats, 0)
	var entities: Node2D = v.get("_entities") as Node2D
	var status: Node2D = v.get("_status") as Node2D
	var top: int = 0
	for child: Node in entities.get_children():
		top = maxi(top, (child as Node2D).z_index)
	assert_true(status.z_index > top, "boost, bubble and drowsy marks sit above every tower and creature")
	assert_true(status.get_index() > entities.get_index(), "and later in the tree")
	var marks: Node2D = v.get("_marks") as Node2D
	assert_true(marks.get_index() < entities.get_index(), "range and selection rings sit under the towers")


func test_muzzles_stay_on_the_drawn_tower() -> void:
	var cell: Vector2i = Vector2i(3, 5)
	var ground_y: float = (float(cell.y) + 0.5 + Silhouettes.TOWER_GROUND) * MapView.CELL
	var top_y: float = ground_y - MapAtlas.TOWER_REACH * MapAtlas.TOWER_SCALE * MapView.CELL
	for tower: StringName in [&"sling_post", &"pumpkin_catapult", &"longbow_loft", &"firework_tower"]:
		for tier: int in [1, 3]:
			var m: Vector2 = MapShots.muzzle(tower, cell, tier, -1, 0)
			assert_true(m.y < ground_y and m.y >= top_y - 0.05 * MapView.CELL, "%s tier %d: the muzzle is on the tower (%s)" % [tower, tier, m])
			assert_true(absf(m.x - (float(cell.x) + 0.5) * MapView.CELL) <= MapAtlas.TOWER_HALF_WIDTH * MapView.CELL, "%s tier %d: and inside its width" % [tower, tier])
