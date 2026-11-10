extends SceneTree
var main
var f := 0
var arena
var hero := 4
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [6, 5]
		main.start_arena(true, 9)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null: return false
	for p in arena.players:
		p._protect = 5.0
		if f % 120 == 0:
			p._cd = [0.0, 0.0, 0.0]
			p.ult_charge = 999
	var acts := ["p1_a1", "p1_a2", "p1_ult", "p2_a1", "p2_a2", "p2_ult", "p1_shoot", "p2_shoot"]
	for a in acts: Input.action_release(a)
	if f % 30 == 0: Input.action_press(acts[(f / 30) % acts.size()])
	Input.action_press("p1_shoot"); Input.action_press("p2_shoot")
	if arena._state == "cutscene" and arena._boss and is_instance_valid(arena._boss):
		if not has_meta("hp0"):
			set_meta("hp0", arena._boss.hp)
			print("cutscene start boss hp=", arena._boss.hp, " allies=", main.world.get_tree().get_nodes_in_group("allies").size())
		elif arena._boss.hp != get_meta("hp0"):
			print("BOSS HURT IN CUTSCENE ", arena._boss.hp)
	elif has_meta("hp0") and not has_meta("done"):
		set_meta("done", true)
		print("cutscene end boss hp=", arena._boss.hp if is_instance_valid(arena._boss) else -1)
	if f % 600 == 0:
		var allies: int = main.world.get_tree().get_nodes_in_group("allies").size()
		print("f=", f, " wave=", arena.wave, " state=", arena._state, " alive=", arena._alive.size(), " allies=", allies, " boss=", arena._boss != null)
	return f > 60 * 90
