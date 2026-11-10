extends SceneTree
# Комбо Призмы: ульта + зеркало. Луч сходится у героя, зеркало стоит дальше — луч проходит сквозь него.
var main
var f := 0
var p1: Player
var p2: Player
var h0 := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_ult"]: Input.action_release(a)
	if f == 3: main._on_duel_ready("test_buffs", 9, 99, [10, 2], {})
	if f == 30:
		p1 = main.duel_players[0]
		p2 = main.duel_players[1]
		print("prism duel metas: dmg=", p1.get_meta("bal_dmg"), " cell=", p1.get_meta("cell_mult"), " ult_need=", p1.ult_need, " cds=", p1.ability_cds)
	if f < 30: return false
	p1._protect = 2.0
	p2.max_hp = 99999
	if f < 300: p2.hp = 99999
	if f >= 280 and f <= 300:
		p1.global_position.x = 1000
		p2.global_position = Vector2(1500, p1.global_position.y)
		p1.facing = 1
	if f == 310:
		p1.ult_charge = 9999
		Input.action_press("p1_ult")
	if f == 330: Input.action_press("p1_a1")
	if f == 360:
		h0 = p2.hp
		var w = root.get_tree().get_nodes_in_group("mirror_walls")
		print("wall x=", w[0].global_position.x if w.size() > 0 else -1, " focus x=", p1.kit._ray.focus().x if p1.kit.ulting() else -1)
	if f == 480:
		print("amplified laser: ", (h0 - p2.hp) / 2.0, " dps")
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/prism_combo.png") if root.get_viewport().get_texture() else null
	if f == 700:
		p1._cd = [0, 0, 0]
		for w in root.get_tree().get_nodes_in_group("mirror_walls"): w.life = 0.0
		p1.ult_charge = 9999
		Input.action_press("p1_ult")
	if f == 780: h0 = p2.hp
	if f == 900:
		print("plain laser: ", (h0 - p2.hp) / 2.0, " dps")
		return true
	return false
