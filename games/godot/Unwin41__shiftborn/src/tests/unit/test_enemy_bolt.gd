extends TestCase


func test_hits_when_touching_the_target() -> void:
	assert_true(EnemyBolt.touches(Vector2.ZERO, Vector2(5, 0), 3.0, 7.0))
	assert_false(EnemyBolt.touches(Vector2.ZERO, Vector2(20, 0), 3.0, 7.0))


func test_bolt_damages_a_target_it_reaches_and_expires() -> void:
	var bolt := EnemyBolt.create(Vector2.ZERO, Vector2.RIGHT, 2.0)
	var dummy := DamageDummy.new()
	dummy.position = Vector2(4, 0)
	bolt.target = dummy
	assert_true(bolt.step(0.0), "bolt should hit the dummy right away")
	assert_almost_eq(dummy.taken, 2.0)
	bolt.free()
	dummy.free()


func test_bolt_expires_after_its_lifetime() -> void:
	var bolt := EnemyBolt.create(Vector2.ZERO, Vector2.RIGHT, 1.0)
	assert_false(bolt.step(EnemyBolt.LIFETIME * 0.5))
	assert_true(bolt.step(EnemyBolt.LIFETIME), "bolt should expire")
	bolt.free()


class DamageDummy extends Node2D:
	var taken := 0.0
	func take_damage(amount: float) -> void:
		taken += amount


func test_new_bolts_join_the_cleanup_group() -> void:
	var bolt := EnemyBolt.create(Vector2.ZERO, Vector2.RIGHT, 1.0)
	assert_true(bolt.is_in_group(EnemyBolt.GROUP))
	bolt.free()
