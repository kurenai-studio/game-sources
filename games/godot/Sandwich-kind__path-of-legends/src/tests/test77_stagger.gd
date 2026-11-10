extends SceneTree
# Босс Арены пошатывается от урона и оглушается (урон ×2); Охотница копит быстрее Кузнеца.
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func arena() -> ArenaMode:
	for n in main.world.get_children():
		if n is ArenaMode: return n
	return null
func _process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.start_arena(false, 5)
	if f > 30 and f % 30 == 0:
		var a := arena()
		if a and a._boss and is_instance_valid(a._boss) and a._boss.is_alive():
			var b: Player = a._boss
			var me: Player = a.players[0]
			print("boss=", b.get_meta("kind"), " stagger_max=", b.stagger_max, " hunter mods: boss_dmg=", me.get_meta("boss_dmg"), " stagger=", me.get_meta("stagger"))
			var hp0 := b.hp
			b.cutscene_shield = false
			for i in 8:
				b.take_damage(10, me)
			print("after 8 hits of 10: hp lost=", hp0 - b.hp, " stagger=", snappedf(b.stagger, 0.1), " stunned=", b.is_stunned())
			var hp1 := b.hp
			b.take_damage(10, me)
			print("hit while stunned: ", hp1 - b.hp)
			return true
	return f > 1500
