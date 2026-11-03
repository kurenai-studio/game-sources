extends CharacterBody2D

const MAX_SPEED = 75
const ACCELERATION_SMOOTHING = 25

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent
@onready var health_bar = $HealthBar
@onready var abilities = $Abilities
@onready var animation_player = $AnimationPlayer
@onready var visuals = $Visuals

var number_of_attackers = 0


func _ready() -> void:
	add_to_group("player")
	$HurtboxArea.body_entered.connect(_on_hurtbox_area_body_entered)
	$HurtboxArea.body_exited.connect(_on_hurtbox_area_body_exited)
	damage_interval_timer.timeout.connect(_on_damage_interval_timer_timeout)
	health_component.health_changed.connect(_on_health_changed)
	GameEvents.ability_upgrade_added.connect(_on_ability_upgrade_added)
	_update_health_display()


func _process(delta: float) -> void:
	var movement_vector = _get_movement_vector()
	var direction = movement_vector.normalized()
	var target_velocity = direction * MAX_SPEED
	velocity = velocity.lerp(target_velocity, 1 - exp(-delta * ACCELERATION_SMOOTHING))
	
	move_and_slide()
	
	if movement_vector.x != 0.0 || movement_vector.y != 0.0:
		animation_player.play("walk")
	else:
		animation_player.play("RESET")
	
	var move_sign = sign(movement_vector.x)
	
	if move_sign != 0:
		visuals.scale = Vector2(move_sign, 1)


func _get_movement_vector():
	var x_movement = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y_movement = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	return Vector2(x_movement, y_movement)


func _check_deal_damage():
	if number_of_attackers == 0 || !damage_interval_timer.is_stopped():
		return
	health_component.damage(1)
	damage_interval_timer.start()


func _update_health_display():
	health_bar.value = health_component.get_health_percent()


func _on_hurtbox_area_body_entered(other_body: Node2D):
	number_of_attackers +=1
	_check_deal_damage()


func _on_hurtbox_area_body_exited(other_body: Node2D):
	number_of_attackers -=1


func _on_damage_interval_timer_timeout():
	_check_deal_damage()


func _on_health_changed():
	_update_health_display()


func _on_ability_upgrade_added(ability_upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if not ability_upgrade is Ability:
		return
	
	var ability = ability_upgrade as Ability
	abilities.add_child(ability_upgrade.ability_controller_scene.instantiate())
