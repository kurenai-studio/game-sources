extends SceneTree
# Модели новых противников крупно: сетка фигур (как в бестиарии)
var f := 0
var kinds := ["snow_wolf", "frost_archer", "yeti", "ice_wraith", "frost_knight", "jotun",
		"storm_acolyte", "temple_guard", "harpy", "ball_lightning", "thunder_priest", "storm_lord",
		"fire_imp", "magma_blob", "magma_blob_s", "salamander", "obsidian_golem", "ash_walker", "fire_cultist", "cerberus",
		"dark_knight", "warlock", "shade", "gargoyle", "executioner", "dark_lord"]
var page := 0

func _initialize() -> void:
	_build()

func _build() -> void:
	for c in root.get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.45, 0.48, 0.52)
	bg.size = Vector2(1600, 720)
	root.add_child(bg)
	var per := 7
	var list := kinds.slice(page * 7, page * 7 + 7)
	for i in list.size():
		var k: String = list[i]
		var fig := BestiaryScreen.make_figure(k, Vector2(210, 420))
		fig.position = Vector2(115 + (i % per) * 228, 360)
		root.add_child(fig)
		var l := Label.new()
		l.text = k
		l.position = fig.position + Vector2(-100, 10)
		l.add_theme_font_size_override("font_size", 16)
		root.add_child(l)

func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/far/rigs_%d.png" % page)
		page += 1
		if page * 7 >= kinds.size():
			return true
		_build()
		f = 0
	return false
