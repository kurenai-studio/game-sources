extends SceneTree
# Механики новых боссов: Перегрузка Громовника (громоотвод), дыхание Ётуна (вмерзание),
# Затмение и чёрная дыра Тёмного Лорда, рывок Цербера.
var main
var f := 0
var arena
var waves := [65, 70, 75, 80]
var wi := -1
var t0 := 0
var fight0 := -1
var shots := "/tmp/claude-0/st/far/"

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	if OS.get_environment("WAVES") != "":
		waves = Array(OS.get_environment("WAVES").split(",")).map(func(x): return int(x))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(shots + "mech_w%d_%s.png" % [waves[wi], n])

func _next() -> bool:
	wi += 1
	if wi >= waves.size():
		return false
	t0 = f
	fight0 = -1
	main.sel = [0, 0]
	main.start_arena(false, waves[wi])
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode: arena = n
	return true

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		_next()
	if arena == null or not is_instance_valid(arena):
		return false
	var hero: Player = arena.players[0]
	hero.hp = hero.max_hp
	var b: Player = arena._boss
	if fight0 < 0:
		hero._protect = 1.0
		if b and is_instance_valid(b) and not b.frozen and not b.cutscene_shield and arena._cut_cam == null:
			fight0 = f
			b._bot_cd.clear()
			for ab in b.bot_abilities.keys():
				b._bot_cd[ab] = 999.0           # сами способности — только по команде теста
		return false
	var k := f - fight0
	var w: int = waves[wi]
	var br: FarBrain = b.get_node_or_null("FarBrain") if b and is_instance_valid(b) else null
	match w:
		65:
			if k == 10:
				hero.global_position = b.global_position + Vector2(b.facing * 260.0, b.body_size.y / 2 - hero.body_size.y / 2)
				hero.chill(5.0)
				print("w65 hero chilled=", hero.is_chilled())
				br.start_breath()
			if k == 90:
				shot("breath")
				print("w65 frozen_in_ice=", hero.is_frozen_in_ice(), " hp=", hero.hp, "/", hero.max_hp)
			if k == 120:
				print("w65 icicle_rain=", FarAbilities.try(b, "icicle_rain", hero.global_position - b.global_position),
						" ice_armor=", FarAbilities.try(b, "ice_armor", Vector2.ZERO), " crust=", b.crust)
			if k == 200:
				shot("icicles")
		70:
			var rods: Array = arena.info.get("rods", [])
			if k == 10:
				var rod: Node2D = rods[1]
				hero.global_position = Vector2(rod.global_position.x + 60.0, rod.global_position.y - hero.body_size.y / 2 - 2)
				print("w70 can_overload=", br.can_overload())
				br.start_overload()
			if k == 150:
				shot("overload")
				hero.global_position.x = rods[1].global_position.x + 40.0
			if k == 260:
				print("w70 boss stunned after overload=", b.is_stunned(), " cutscene_shield=", b.cutscene_shield, " hero hp=", hero.hp)
				shot("overload_after")
			if k == 300:
				print("w70 tornado=", FarAbilities.try(b, "tornado", hero.global_position - b.global_position), " storm_call=", FarAbilities.try(b, "storm_call", hero.global_position - b.global_position))
			if k == 360:
				shot("storm")
		75:
			if k == 10:
				hero.global_position.x = b.global_position.x + 500.0
			if k == 20:
				br.start_lava_charge(1.0)
			if k == 70:
				shot("charge")
			if k == 150:
				print("w75 triple_fire=", FarAbilities.try(b, "triple_fire", hero.global_position - b.global_position), " howl=", FarAbilities.try(b, "howl_imps", Vector2.ZERO))
			if k == 190:
				shot("fire")
		80:
			if k == 10:
				br.start_eclipse()
			if k == 200:
				shot("eclipse")
			if k == 600:
				var cm: CanvasModulate = null
				for n in main.world.get_children():
					if n is CanvasModulate: cm = n
				print("w80 after eclipse cm=", cm.color if cm else "none", " boss frozen=", b.frozen)
				br.start_black_hole()
			if k == 700:
				shot("blackhole")
			if k == 820:
				print("w80 after black hole stunned=", b.is_stunned())
	if k == 900 or (w == 65 and k == 260) or (w == 75 and k == 260):
		if not _next():
			print("DONE")
			return true
	return false
