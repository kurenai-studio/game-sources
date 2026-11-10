extends SceneTree
var main
var f := 0
var arena: ArenaMode
var bots := []
const REG := ["grunt", "runner", "soldier", "tank", "gunner", "breacher", "goblin", "sneak", "bomber", "shaman", "brute"]
const BOSS := ["gladiator", "colossus", "chief", "treant", "totem"]
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + name + ".png")
	print("shot ", name)
func clear():
	for b in bots:
		if is_instance_valid(b): b.queue_free()
	bots.clear()
func row(kinds, x0, step, frozen):
	for i in kinds.size():
		var k = kinds[i]
		var sz: Vector2 = Bots.TYPES[k]["size"]
		var b = arena._make_bot(k, Vector2(x0 + i * step, 940 - sz.y / 2 - 2))
		arena._alive.erase(b)
		b.frozen = frozen
		b.bot_abilities = {}
		bots.append(b)
func _process(_d: float) -> bool:
	f += 1
	if arena:
		var p = arena.players[0]
		p._protect = 5.0
		p.position = Vector2(1300, 600)
		p.velocity = Vector2.ZERO
		p.visible = false
	match f:
		3:
			main.sel = [0, 0]
			main.start_arena(false, 1)
			for n in main.world.get_children():
				if n is ArenaMode: arena = n
		10:
			for t in arena.get_children(): t.queue_free()
			arena._state = "test"
			arena.hud.visible = false
		20:
			row(REG, 560, 150, true)
			arena.set_process(false)
			arena._cam.position = Vector2(1300, 780)
			arena._cam.zoom = Vector2(1.0, 1.0)
		60: shot("r1_regular_idle")
		62:
			for i in bots.size():
				var a = ["shoot", "punch", "shoot", "shoot_big", "cast", "shoot_big", "throw", "throw_smoke", "throw", "shoot", "slam"][i]
				bots[i].rig.play(a)
		66: shot("r2_regular_actions_a")
		70: shot("r3_regular_actions_b")
		72:
			for b in bots: b.velocity.x = 250.0
		90:
			shot("r4_walk")
		92:
			clear()
			row(BOSS, 650, 330, true)
		130: shot("r5_bosses_idle")
		132:
			bots[0].rig.play("swing"); bots[1].rig.play("stomp"); bots[2].rig.play("roar"); bots[3].rig.play("roots")
		146: shot("r6_bosses_actions")
		160:
			bots[0].stun(3.0); bots[1].rig.play("shoot_big"); bots[2].rig.play("volley"); bots[3].rig.play("summon")
		170: shot("r7_bosses_b")
		200:
			bots[0]._stun_t = 0.0
			bots[0].rig.play("windup")
		215: shot("r8_glad_windup")
		220:
			bots[0]._charging = 1.0
			bots[0].velocity.x = 820
		232:
			shot("r9_glad_charge")
			return true
	return false
