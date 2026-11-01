extends GutTest


func _make_state(mage_hps: Array) -> BattleState:
	var s := BattleState.new()
	var es := EnemyState.new()
	es.combatant.hp = 200
	s.enemies["troll_1"] = es
	for hp in mage_hps:
		var ms := MageState.new()
		ms.combatant.hp = hp
		s.mages.append(ms)
	return s


func _make_setup(mage_count: int) -> BattleSetup:
	var enemies: Array[EnemyData] = [Troll.new()]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	var mages: Array[MageData] = []
	var wands: Array[WandData] = []
	for i in mage_count:
		mages.append(MageData.new("Mage %d" % i, 30))
		wands.append(null)
	return BattleSetup.new(enemies, positions, mages, wands, 10)


func test_cleave_damages_all_mages() -> void:
	var setup := _make_setup(2)
	var state := _make_state([30, 30])
	var cleave := MonsterActionCleave.new("Cleave", 8)
	var result := cleave.execute(state, setup, "troll_1", -1)
	assert_eq((result.mages[0] as MageState).combatant.hp, 22)
	assert_eq((result.mages[1] as MageState).combatant.hp, 22)


func test_cleave_does_not_overkill_below_zero() -> void:
	var setup := _make_setup(2)
	var state := _make_state([5, 30])
	var cleave := MonsterActionCleave.new("Cleave", 8)
	var result := cleave.execute(state, setup, "troll_1", -1)
	assert_eq((result.mages[0] as MageState).combatant.hp, 0)
	assert_eq((result.mages[1] as MageState).combatant.hp, 22)


func test_cleave_respects_attack_mult() -> void:
	var setup := _make_setup(2)
	var state := _make_state([30, 30])
	(state.enemies["troll_1"] as EnemyState).attack_mult = 2.0
	var cleave := MonsterActionCleave.new("Cleave", 8)
	var result := cleave.execute(state, setup, "troll_1", -1)
	assert_eq((result.mages[0] as MageState).combatant.hp, 14)
	assert_eq((result.mages[1] as MageState).combatant.hp, 14)
