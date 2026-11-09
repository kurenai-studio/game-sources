extends TestCase
## Eye (ranged), Beast (charger) and Slime (splits on death).

const EYE_SCENE := preload("res://scenes/enemy_eye.tscn")
const BEAST_SCENE := preload("res://scenes/enemy_beast.tscn")
const SLIME_SCENE := preload("res://scenes/enemy_slime.tscn")
const SMALL_SLIME_SCENE := preload("res://scenes/enemy_slime_small.tscn")


func test_eye_closes_in_backs_off_and_holds_its_range() -> void:
	assert_eq(RangedEnemy.range_step(RangedEnemy.PREFERRED_DISTANCE + 50.0), 1)
	assert_eq(RangedEnemy.range_step(RangedEnemy.PREFERRED_DISTANCE - 50.0), -1)
	assert_eq(RangedEnemy.range_step(RangedEnemy.PREFERRED_DISTANCE), 0)


func test_beast_winds_up_only_when_close_and_rested() -> void:
	assert_true(ChargerEnemy.should_wind_up(ChargerEnemy.TRIGGER_DISTANCE - 1.0, 0.0))
	assert_false(ChargerEnemy.should_wind_up(ChargerEnemy.TRIGGER_DISTANCE + 1.0, 0.0), "too far")
	assert_false(ChargerEnemy.should_wind_up(ChargerEnemy.TRIGGER_DISTANCE - 1.0, 0.5), "still resting")


func test_resistances_match_the_design() -> void:
	var eye := EYE_SCENE.instantiate() as Enemy
	var beast := BEAST_SCENE.instantiate() as Enemy
	var slime := SLIME_SCENE.instantiate() as Enemy
	assert_eq(eye.resisted_form, Player.Form.KNIGHT, "eye resists the warrior")
	assert_eq(beast.resisted_form, Player.Form.MAGE, "beast resists magic")
	assert_eq(slime.resisted_form, Enemy.NO_FORM, "slime resists nothing")
	eye.free()
	beast.free()
	slime.free()


func test_slime_splits_into_small_slimes_that_do_not_split() -> void:
	var slime := SLIME_SCENE.instantiate() as Enemy
	var small := SMALL_SLIME_SCENE.instantiate() as Enemy
	assert_true(slime.split_scene != null, "slime should split")
	assert_eq(slime.split_count, 2)
	assert_true(small.split_scene == null, "small slimes should not split again")
	assert_true(small.max_health < slime.max_health, "small slimes are weaker")
	slime.free()
	small.free()


func test_split_offsets_spread_around_the_corpse() -> void:
	var offsets := Run.split_offsets(2)
	assert_eq(offsets.size(), 2)
	assert_true(offsets[0].distance_to(offsets[1]) > 4.0, "split slimes should not stack")
