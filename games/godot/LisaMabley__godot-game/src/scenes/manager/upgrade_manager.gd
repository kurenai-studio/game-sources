extends Node

@export var experience_manager: Node
@export var upgrade_screen_scene: PackedScene

var current_upgrades = {}
var upgrade_pool: WeightedTable = WeightedTable.new()
var upgrades = {}


func _ready() -> void:
	for id in Balance.UPGRADES:
		upgrades[id] = _create_upgrade(id)
		if not Balance.UPGRADES[id].has("unlocked_by"):
			_add_to_pool(id)
	experience_manager.level_up.connect(_on_level_up)


func _create_upgrade(id: String) -> AbilityUpgrade:
	var data = Balance.UPGRADES[id]
	var upgrade: AbilityUpgrade
	if data.has("ability_controller_scene"):
		upgrade = Ability.new()
		upgrade.ability_controller_scene = load(data["ability_controller_scene"])
	else:
		upgrade = AbilityUpgrade.new()

	upgrade.id = id
	upgrade.name = data["name"]
	upgrade.description = data["description"].format(data)
	upgrade.max_quantity = data["max_quantity"]
	return upgrade


func _add_to_pool(id: String):
	upgrade_pool.add_item(upgrades[id], Balance.UPGRADES[id]["weight"], id)


func _apply_upgrade(upgrade: AbilityUpgrade):
	var has_upgrade = current_upgrades.has(upgrade.id)
	if !has_upgrade:
		current_upgrades[upgrade.id] = {
			"resource": upgrade,
			"quantity": 1
		}
	else:
		current_upgrades[upgrade.id]["quantity"] += 1
	
	if upgrade.max_quantity > 0:
		var current_quantity = current_upgrades[upgrade.id]["quantity"]
		if current_quantity == upgrade.max_quantity:
			upgrade_pool.remove_item(upgrade)
	
	_update_upgrade_pool(upgrade)
	
	GameEvents.emit_ability_upgrade_added(upgrade, current_upgrades)


func _update_upgrade_pool(chosen_upgrade: AbilityUpgrade):
	if current_upgrades[chosen_upgrade.id]["quantity"] != 1:
		return

	for id in Balance.UPGRADES:
		if Balance.UPGRADES[id].get("unlocked_by") == chosen_upgrade.id:
			_add_to_pool(id)


func _pick_upgrades():
	var chosen_upgrades: Array[AbilityUpgrade] = []
	
	for i in 2:
		if upgrade_pool.items.size() == chosen_upgrades.size():
			break
		
		var chosen_upgrade = upgrade_pool.pick_item(chosen_upgrades) as AbilityUpgrade
		if chosen_upgrade == null:
			break

		chosen_upgrades.append(chosen_upgrade)
	
	return chosen_upgrades


func _on_upgrade_selected(upgrade: AbilityUpgrade):
	_apply_upgrade(upgrade)


func _on_level_up(_current_level: int):
	var upgrade_scene_instance = upgrade_screen_scene.instantiate()
	add_child(upgrade_scene_instance)
	var available_upgrades = _pick_upgrades()
	upgrade_scene_instance.set_ability_upgrades(available_upgrades as Array[AbilityUpgrade])
	upgrade_scene_instance.upgrade_selected.connect(_on_upgrade_selected)
