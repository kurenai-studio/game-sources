extends SceneTree
# Баланс: простой автоигрок проходит Арену. Стоит в центре, поворачивается
# к ближайшему боту, стреляет, прыгает, жмёт способности и ульту.
var main
var f := 0
var arena: ArenaMode
var dmg_log := {}
var last_hp := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 0]
		main.start_arena()
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null or f < 10:
		return false
	var p: Player = arena.player
	for a in ["p1_left", "p1_right", "p1_jump", "p1_shoot", "p1_a1", "p1_a2", "p1_a3", "p1_ult"]:
		Input.action_release(a)
	if is_instance_valid(p) and p.is_alive() and not p.frozen:
		var best = null
		var bd := INF
		for b in arena._alive:
			if is_instance_valid(b) and b.is_alive():
				var d := absf(b.global_position.x - p.global_position.x) + absf(b.global_position.y - p.global_position.y) * 2.0
				if d < bd:
					bd = d
					best = b
		if best:
			var dx: float = best.global_position.x - p.global_position.x
			var dy: float = best.global_position.y - p.global_position.y
			if (dx > 0) != (p.facing > 0):
				Input.action_press("p1_right" if dx > 0 else "p1_left")
			elif absf(dx) > 500:
				Input.action_press("p1_right" if dx > 0 else "p1_left")
			if absf(dy) < 70:
				Input.action_press("p1_shoot")
			elif dy < -70 and f % 40 == 0:
				Input.action_press("p1_jump")
			if f % 90 == 0: Input.action_press("p1_a1")
			if f % 90 == 30: Input.action_press("p1_a2")
			if f % 90 == 60: Input.action_press("p1_a3")
			Input.action_press("p1_ult")
		# тянется к лечению, когда мало здоровья
		if p.hp < p.max_hp * 0.35 and f % 120 < 60:
			Input.action_press("p1_left" if p.global_position.x < 1300 else "p1_right")
		if p.hp < last_hp:
			dmg_log[arena.wave] = dmg_log.get(arena.wave, 0) + (last_hp - p.hp)
		last_hp = p.hp
	if arena._state == "over" or f > 60 * 60 * 20:
		print("0 ", 0, " RESULT wave=", arena.wave, " lives=", arena.lives, " kills=", arena.kills,
				" time=", f / 60, "s state=", arena._state)
		print("   damage taken per wave: ", dmg_log)
		return true
	return false
