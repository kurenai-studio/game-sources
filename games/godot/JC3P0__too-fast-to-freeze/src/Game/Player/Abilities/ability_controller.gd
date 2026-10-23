class_name AbilityController
extends Node

## Strategy + Template Method base for all player abilities.
## Concrete abilities (AxeAbility, SawAbility, HammerAbility) override
## _perform_effect() only - cooldown, stacks, and HUD data all live here.
##
## Attach a concrete subclass script to a Node child of Player (e.g.
## "AxeAbility"), then assign an AbilityResource .tres to `stats` in the
## Inspector. test/timed-abilities branch - see Notes/TEST-TIMED-ABILITIES.md §4.

@export var stats: AbilityResource

## Stacks are PERMANENT - using the ability never spends one. Only add_stack()
## (called from a pickup) changes this. Capped at stats.max_stacks.
var current_stacks: int = 0
var _cooldown_remaining: float = 0.0

func _ready() -> void:
	if stats:
		current_stacks = stats.start_stacks

func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = max(0.0, _cooldown_remaining - delta)

## Call from player._input() on the mapped input_action's "pressed" event.
func try_activate(player: CharacterBody3D) -> void:
	if stats == null or _cooldown_remaining > 0.0:
		return
	# Can't use an ability while stunned - matches the old fire_saw() guard.
	if player.player_state_manager.current_state_name == "Vuln":
		return
	_perform_effect(player, get_area_scale())
	_play_swing(player)
	_cooldown_remaining = get_cooldown()
	EventBus.ability_fired.emit(stats.id)

## Timed-abilities test - purely cosmetic, fire-and-forget. Delegates to
## player.play_ability_swing(), which spins the whole character (Player4)
## and shows this ability's weapon mesh pieces for the duration of the
## spin. Deliberately does NOT delay or gate _perform_effect() above, and
## does NOT grant any invincibility while it plays - the player can still
## get hit mid-swing, same as before. If hit mid-swing,
## player.interrupt_ability_swing() (called from vulnerable.gd) snaps the
## spin back and hides the weapon immediately.
func _play_swing(player: CharacterBody3D) -> void:
	if stats.swing_weapon_paths.is_empty():
		return
	player.play_ability_swing(stats.swing_weapon_paths, stats.swing_duration)

func add_stack() -> void:
	if stats == null or current_stacks >= stats.max_stacks:
		return
	current_stacks += 1
	EventBus.ability_stack_changed.emit(stats.id, current_stacks)

func is_maxed() -> bool:
	return stats != null and current_stacks >= stats.max_stacks

func get_cooldown() -> float:
	if stats == null:
		return 0.0
	return max(stats.min_cooldown, stats.base_cooldown - current_stacks * stats.cooldown_decrease_per_stack)

func get_area_scale() -> float:
	if stats == null:
		return 1.0
	return min(stats.max_area_scale, stats.base_area_scale + current_stacks * stats.area_growth_per_stack)

## For the test HUD - "power" as a percentage of max stacks.
func get_power_percent() -> float:
	if stats == null or stats.max_stacks == 0:
		return 0.0
	return float(current_stacks) / float(stats.max_stacks)

## For the HUD - seconds left before this ability can fire again.
func get_cooldown_remaining() -> float:
	return _cooldown_remaining

## For the HUD - true once the cooldown has finished and the ability can fire.
func is_ready() -> bool:
	return _cooldown_remaining <= 0.0

## Timed-abilities test - keeps catching bodies that enter `area` for the
## next `duration` seconds, not just whatever was already inside at the
## instant the ability fired. Connects body_entered, filters to `group`,
## calls `callback` with the body, and disconnects itself once the window
## ends. Call this from _perform_effect() alongside the existing
## get_overlapping_bodies() check (that check still matters for the very
## first frame - body_entered only fires for bodies that enter AFTER this
## connects). See Notes/TEST-TIMED-ABILITIES.md.
func _watch_area_for_duration(area: Area3D, group: StringName, duration: float, callback: Callable) -> void:
	var handler: Callable
	handler = func(body: Node3D) -> void:
		if body.is_in_group(group):
			callback.call(body)
	area.body_entered.connect(handler)
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if area.body_entered.is_connected(handler):
			area.body_entered.disconnect(handler)
	)

## Template Method hook - subclasses implement the actual gameplay effect.
func _perform_effect(_player: CharacterBody3D, _area_scale: float) -> void:
	pass
