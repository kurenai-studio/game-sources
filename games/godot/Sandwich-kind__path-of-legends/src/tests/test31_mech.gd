extends SceneTree
# Механики боссов: Гладиатор оглушается о стену, Колосс — броня спереди, Энт — тотемы.
var main
var f := 0
var arena: ArenaMode
var p: Player
var b: Player
var log := []
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 0]
		main.start_arena(false, 1)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
		arena._queue = []
		arena._state = "test"
	if f < 10: return false
	p = arena.players[0]
	p._protect = 10.0
	p.frozen = false
	if f == 20:
		for t in arena.get_children(): t.queue_free()
		arena._state = 'test'
		p.position = Vector2(300, 900)
		b = arena._make_bot("gladiator", Vector2(1200, 880))
		b.bot_abilities = {"charge": 1.0}
		b._bot_cd = {"charge": 0.2}
	if f > 20 and f < 400 and is_instance_valid(b):
		if f == 80:
			p.position = Vector2(250, 750)  # прыгнул на край — гладиатор врезается в стену
			p.velocity.y = -900
		if b.is_stunned() and not log.has("gladiator stunned"):
			log.append("gladiator stunned")
			var hp0: int = b.hp
			b.take_damage(10, p)
			log.append("stunned dmg %d" % (hp0 - b.hp))
	if f == 400:
		if is_instance_valid(b): b.queue_free()
		p.position = Vector2(1300, 900)
		b = arena._make_bot("colossus", Vector2(1700, 870))
		b.bot_abilities = {}
	if f == 430:
		b.facing = -1
		var h0: int = b.hp
		b.take_damage(100, p)    # спереди
		log.append("colossus front dmg %d" % (h0 - b.hp))
		p.position = Vector2(2100, 900)
		h0 = b.hp
		b.take_damage(100, p)    # сзади
		log.append("colossus back dmg %d" % (h0 - b.hp))
		b.queue_free()
	if f == 440:
		for n in main.world.get_children():
			if not n.is_in_group('persist'): n.queue_free()
		arena._build_stage(3)
		print('built stage ', arena.stage, ' ', arena.info.keys())
	if f == 1000:
		b = arena._make_bot("treant", Vector2(1300, 840))
		arena._boss = b
		b.tree_exiting.connect(func(): print('EXIT at ', f, ' hp ', b.hp, ' alive ', b.is_alive()); print_stack())
		b.died.connect(func(i): print('DIED at ', f))
		b.invulnerable = true
		arena._grow_totems()
		log.append("totems %d spots %s stage %d" % [arena._totems.size(), str(arena.info.get('totems')), arena.stage])
	if f > 1000 and f % 60 == 0:
		print(f, ' treant valid=', is_instance_valid(b), ' ', b.hp if is_instance_valid(b) else -1, ' pos ', b.position if is_instance_valid(b) else Vector2.ZERO)
	if f == 1040:
		var h0: int = b.hp
		b.take_damage(100, p)
		log.append("treant invuln dmg %d" % (h0 - b.hp))
		for t in arena._totems: t.take_damage(9999, p)
	if f == 1080:
		log.append("treant invulnerable after totems: %s" % b.invulnerable)
		var h0: int = b.hp
		b.take_damage(100, p)
		log.append("treant dmg %d" % (h0 - b.hp))
	if f == 1080 + 60 * 13:
		log.append("regrown: invuln=%s totems=%d" % [b.invulnerable, arena._totems.size()])
		print(log)
		return true
	return false
