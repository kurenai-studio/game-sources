extends SceneTree
# Бестиарий (новые вкладки), карты Дуэли дальних земель, смена локации 60→61 и победа на 80-й
var main
var f := 0
var bs
var arena
var stage_seen := -1
var shots := "/tmp/claude-0/st/far/"

func _initialize() -> void:
	Save.load_game()
	Save.see_all()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func find(t):
	for n in main.world.get_children():
		if is_instance_of(n, t): return n
	return null

func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		5: main._on_mode_chosen("bestiary")
		15:
			bs = find(BestiaryScreen)
			bs._tab_btns[8].pressed.emit()
		25:
			root.get_viewport().get_texture().get_image().save_png(shots + "best_ice.png")
			bs._tab_btns[14 - 3].pressed.emit()
		35:
			root.get_viewport().get_texture().get_image().save_png(shots + "best_throne.png")
			bs._tab_btns[10].pressed.emit()
		45:
			root.get_viewport().get_texture().get_image().save_png(shots + "best_lava.png")
			# карты Дуэли дальних земель строятся без ошибок
			for id in ["arena_ice", "arena_storm", "arena_lava", "arena_throne"]:
				var w := Node2D.new()
				root.add_child(w)
				var info: Dictionary = Maps.build(w, id)
				print("duel map ", id, " p1=", info["p1"], " children=", w.get_child_count())
				w.queue_free()
		60:
			main.sel = [0, 0]
			main.start_arena(false, 60)
			arena = find(ArenaMode)
	if arena and is_instance_valid(arena):
		for p in arena.players:
			p._protect = 1.0
			p.hp = p.max_hp
		if arena.stage != stage_seen:
			stage_seen = arena.stage
			print("f=", f, " wave=", arena.wave, " stage=", arena.stage, " ", ArenaMode.STAGE_NAMES[arena.stage])
		# быстро добиваем всех, чтобы пройти волну 60 и увидеть переход
		if arena._boss and is_instance_valid(arena._boss) and not arena._boss.frozen and not arena._boss.cutscene_shield and arena.wave in [60, 80]:
			arena._boss.take_damage(99999999, arena.players[0])
		if arena.wave == 61 and arena._state == "fight" and not has_meta("jumped"):
			set_meta("jumped", true)
			root.get_viewport().get_texture().get_image().save_png(shots + "trans_61.png")
			print("wave 61 started on stage ", arena.stage, " — переходим к волне 80")
			main.start_arena(false, 80)
			arena = find(ArenaMode)
		if arena and arena._state == "over" and not has_meta("over"):
			set_meta("over", true)
			print("state over at wave ", arena.wave, " progress=", Save.arena_progress("solo"))
	if f > 60 * 120 or has_meta("over") and f % 600 == 0:
		print("END f=", f)
		return true
	return false
