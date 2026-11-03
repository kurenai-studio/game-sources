extends Node

@export var axe_ability_scene: PackedScene

var base_wait_time = Balance.WEAPONS["axe"]["cooldown"]
var base_damage = Balance.WEAPONS["axe"]["damage"]
var additional_damage_percent = 1


func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start(base_wait_time)
	GameEvents.ability_upgrade_added.connect(_on_ability_upgrade_added)


func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
#
	var foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	if foreground_layer == null:
		return
	
	var axe_instance = axe_ability_scene.instantiate() as AxeAbility
	foreground_layer.add_child(axe_instance)
	axe_instance.hitbox_component.damage = base_damage * additional_damage_percent
	
	axe_instance.global_position = player.global_position


func _on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	#if upgrade.id == "sword_attack_rate":
		#var percent_reduction = current_upgrades["sword_attack_rate"]["quantity"] * .1
		#var new_wait_time = base_wait_time * (1 - percent_reduction)
		#$Timer.wait_time = new_wait_time
		#$Timer.start()
	
	if upgrade.id == "axe_damage":
		additional_damage_percent = 1 + (current_upgrades["axe_damage"]["quantity"] * Balance.UPGRADES["axe_damage"]["percent"] / 100.0)
