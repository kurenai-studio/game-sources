extends Node

#kerno events
@warning_ignore("unused_signal")
signal kerno_merged(tier: int, score: int, location: Vector2)
@warning_ignore("unused_signal")
signal kerno_dropped(tier: int)
@warning_ignore("unused_signal")
signal kerno_fell_out_of_bounds(tier: int)

#progression and dungeon events
@warning_ignore("unused_signal")
signal boss_defeated(dungeon_level: int)
@warning_ignore("unused_signal")
signal level_finished(level_passed: bool)

#achievement events
@warning_ignore("unused_signal")
signal achievement_earned(achievement_name: String)

#scoring events
@warning_ignore("unused_signal")
signal score_milestone_reached(milestone_number: int)

#endless mode particular signals
@warning_ignore("unused_signal")
signal game_over_endless_mode(level_stats: LevelStats)
