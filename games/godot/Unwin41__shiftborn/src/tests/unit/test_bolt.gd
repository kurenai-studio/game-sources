extends TestCase

const BOLT_SCENE := preload("res://scenes/bolt.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")


func test_dying_enemy_does_not_consume_the_bolt() -> void:
	var bolt := BOLT_SCENE.instantiate() as Bolt
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.health = 0.0
	bolt.pierce = 1
	bolt._on_area_entered(enemy)
	assert_eq(bolt.pierce, 1, "pierce should not be spent on a corpse")
	assert_false(bolt._spent, "bolt should keep flying")
	enemy.free()
	bolt.free()
