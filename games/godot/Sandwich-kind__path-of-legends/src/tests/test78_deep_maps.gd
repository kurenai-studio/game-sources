extends SceneTree
# Снимки новых карт (Дуэль): Драгоценные и Кристальные пещеры, плюс Царство скелетов.
var main
var f := 0
var maps := ["arena_village", "arena_forest"]
var mi := 0
var shots := "/tmp/claude-0/st/"
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 3 or (f > 3 and (f - 3) % 150 == 0):
		if f > 3:
			root.get_viewport().get_texture().get_image().save_png(shots + "map_%s.png" % maps[mi])
			mi += 1
			if mi >= maps.size():
				return true
		main._on_duel_ready(maps[mi], 9, 99, [0, 1], {})
	if f > 3 and (f - 3) % 150 == 100:
		var p1: Player = main.duel_players[0]
		p1.position.x = 900
	return false
