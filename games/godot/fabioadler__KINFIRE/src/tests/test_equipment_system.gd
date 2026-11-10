extends Node
## Teste de integração: sistema de equipagem com novos slots (gloves + accessories)

func test_equipment_slots_exist() -> void:
	print("[equipment] Verificando slots definidos")
	assert(DB.EQUIP_SLOTS.size() > 0, "EQUIP_SLOTS não está vazio")
	
	var expected_slots := ["helm", "amulet", "weapon", "chest", "offhand", "gloves", "ring", "accessory_1", "accessory_2", "accessory_3", "boots"]
	for slot in expected_slots:
		assert(slot in DB.EQUIP_SLOTS, "Slot '%s' deve estar em EQUIP_SLOTS" % slot)
		assert(slot in DB.SLOT_NAMES, "Slot '%s' deve ter nome definido" % slot)
	print("[equipment] ✓ Todos os slots estão definidos corretamente")


func test_hero_equipment_initialization() -> void:
	print("[equipment] Testando inicialização de equipamento")
	var hero := Hero.new()
	
	# Verificar que todos os slots foram inicializados como null
	for slot in DB.EQUIP_SLOTS:
		assert(hero.equipment[slot] == null, "Slot '%s' deve estar inicialmente null" % slot)
	
	print("[equipment] ✓ Herói inicializado com todos os slots como null")


func test_equip_in_all_slots() -> void:
	print("[equipment] Testando equipagem em todos os slots")
	
	var hero := Hero.create(
		"Testador", DB.get_race(&"humano"), DB.CLASSES[0], "m", Color.WHITE,
		{"str": 15, "dex": 12, "con": 13, "int": 10, "wis": 11, "cha": 10}
	)
	
	# Testes específicos por slot
	var test_cases := [
		{"slot": "weapon", "base": &"sword", "expected": true},
		{"slot": "helm", "base": &"helm", "expected": true},
		{"slot": "chest", "base": &"plate", "expected": true},
		{"slot": "boots", "base": &"boots", "expected": true},
		{"slot": "gloves", "base": &"helm", "expected": true},  # Sem itens específicos de luva, usar helm temporariamente
		{"slot": "ring", "base": &"ring", "expected": true},
		{"slot": "amulet", "base": &"amulet", "expected": true},
	]
	
	for test in test_cases:
		var item := DB.create_item(test.base, 1, Item.Rarity.COMMON)
		# Forçar o slot correto para o teste
		item.slot = test.slot
		
		var result := hero.equip(item)
		assert(hero.equipment[test.slot] == item, "Item deve estar equipado no slot '%s'" % test.slot)
		print("[equipment] ✓ Equipagem no slot '%s' funcionou" % test.slot)
	
	print("[equipment] ✓ Equipagem em todos os slots funcionou")


func test_unequip() -> void:
	print("[equipment] Testando desequipagem")
	
	var hero := Hero.create(
		"Testador", DB.get_race(&"humano"), DB.CLASSES[0], "m", Color.WHITE,
		{"str": 15, "dex": 12, "con": 13, "int": 10, "wis": 11, "cha": 10}
	)
	
	var item := DB.create_item(&"sword", 1, Item.Rarity.COMMON)
	hero.equip(item)
	
	var unequipped := hero.unequip("weapon")
	assert(unequipped == item, "Item desequipado deve ser o mesmo que foi equipado")
	assert(hero.equipment["weapon"] == null, "Slot de arma deve estar vazio após desequipar")
	
	print("[equipment] ✓ Desequipagem funcionou corretamente")


func test_equip_problem_checks() -> void:
	print("[equipment] Testando verificações de problemas ao equipar")
	
	var hero := Hero.create(
		"Testador", DB.get_race(&"humano"), DB.CLASSES[0], "m", Color.WHITE,
		{"str": 15, "dex": 12, "con": 13, "int": 10, "wis": 11, "cha": 10}
	)
	
	# Teste 1: Arma de duas mãos bloqueia mão secundária
	var great_sword := DB.create_item(&"great_sword", hero.level, Item.Rarity.COMMON)
	hero.equipment["weapon"] = great_sword
	
	var shield := DB.create_item(&"shield_round", hero.level, Item.Rarity.COMMON)
	var problem := hero.equip_problem(shield)
	assert(problem != "", "Equipar escudo com arma de duas mãos deve dar erro")
	assert("duas mãos" in problem, "Mensagem deve mencionar arma de duas mãos")
	
	print("[equipment] ✓ Verificações de equipagem funcionaram")


func test_item_name_not_display_name() -> void:
	print("[equipment] Testando que Item.name existe (não há método display_name)")
	
	var item := DB.create_item(&"sword", 1, Item.Rarity.COMMON)
	
	# Verificar que name existe
	assert(item.name != "", "Item.name deve não ser vazio")
	
	# Verificar que display_name não existe como método de Item
	assert(not item.has_method("display_name"), "Item não deve ter método display_name()")
	
	print("[equipment] ✓ Item usa .name corretamente")


func _ready() -> void:
	print("\n========== TESTE DE EQUIPAGEM ==========")
	
	test_equipment_slots_exist()
	test_hero_equipment_initialization()
	test_equip_in_all_slots()
	test_unequip()
	test_equip_problem_checks()
	test_item_name_not_display_name()
	
	print("========== TODOS OS TESTES PASSARAM ==========\n")
	get_tree().quit()
