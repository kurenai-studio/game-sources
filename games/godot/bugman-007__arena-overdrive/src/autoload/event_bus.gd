extends Node
## Global decoupled signal hub. Gameplay systems emit, UI/FX/audio listen.

@warning_ignore_start("unused_signal")
signal enemy_killed(enemy_id: StringName, position: Vector2)
signal player_damaged(amount: int, current: int, maximum: int)
signal player_healed(current: int, maximum: int)
signal player_died
signal wave_started(wave: int, is_boss: bool, enemy_total: int)
signal wave_cleared(wave: int)
signal level_up(level: int)
signal upgrade_chosen(upgrade_id: StringName)
signal boss_spawned(boss: Node)
signal boss_phase_changed(phase: int)
signal run_coins_changed(coins: int)
signal screen_shake(strength: float)
signal hit_stop(duration: float)
signal screen_flash(color: Color)
signal achievement_unlocked(id: StringName)
signal settings_changed
signal wallet_changed(coins: int)
@warning_ignore_restore("unused_signal")
