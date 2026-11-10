class_name Shards
# Взрыв осколками: кристаллы разлетаются во все стороны и ранят врагов
# (приманка и броня Призмы, кристальные существа).

static func burst(world: Node, at: Vector2, team: int, attacker, n := 8, dmg := 10, tint := Color(0.75, 0.9, 1.0)) -> void:
	Fx.sparks(world, at, tint, 14, 260.0, 4.0, true)
	Fx.ring(world, at, 70.0, Color(tint, 0.8), 0.3, 4.0)
	for k in n:
		var sh := Spear.new()
		sh.shooter = attacker
		sh.team = team
		sh.payload = "shard"
		sh.damage = dmg
		sh.set_meta("tint", tint)
		var a := TAU * k / n - PI / 2 + randf_range(-0.1, 0.1)
		sh.velocity = Vector2.from_angle(a) * 620.0 + Vector2(0, -120)
		sh.position = at
		world.call_deferred("add_child", sh)
