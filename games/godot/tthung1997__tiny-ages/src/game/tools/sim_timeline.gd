extends SceneTree
## Plays the simulation with a stand-in player and prints the world journal, to eyeball pacing:
##   & $env:GODOT --headless --path game --script res://tools/sim_timeline.gd -- [seed] [days]
## The bot (DecisionBot) answers every decision immediately, so the timeline also shows the
## Cave -> Settled turn. Real-time columns use the configured pace (SimConfig).


func _init() -> void:
	var rng_seed: int = 1
	var days: int = 30
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		rng_seed = args[0].to_int()
	if args.size() > 1:
		days = args[1].to_int()
	var config: SimConfig = load("res://resources/sim/sim_config.tres") as SimConfig
	var content: ContentLibrary = load("res://resources/sim/content.tres") as ContentLibrary
	var world: WorldState = WorldFactory.create_new(content, config, rng_seed, 0.0)
	var sim: Simulation = Simulation.new(world, config, content)
	var bot: DecisionBot = DecisionBot.new()
	var start_tick: int = world.tick
	var asked: Array[String] = []
	var stock: Array[String] = []
	var last_ask_tick: int = start_tick
	var longest_gap: int = 0
	for step: int in days * config.ticks_per_day:
		sim.advance_ticks(1)
		for decision: PendingDecision in world.pending:
			var event: EventDef = content.get_event(decision.event_id)
			var real_hours: float = (
				float(world.tick - start_tick) * config.seconds_per_tick() / 3600.0
			)
			asked.append("  day %3d  (+%5.1f real h)  %s" % [
				config.day_of(world.tick) + 1, real_hours, event.title,
			])
			longest_gap = maxi(longest_gap, world.tick - last_ask_tick)
			last_ask_tick = world.tick
		bot.answer_all(sim)
		if step % (config.ticks_per_day * 30) == 0:
			stock.append("day %d: wood %d food %d" % [
				config.day_of(world.tick) + 1, world.resource_amount(&"wood"),
				world.resource_amount(&"food"),
			])
	print("Seed %d, %d days at %.0f real minutes per day" % [
		rng_seed, days, config.real_seconds_per_game_day / 60.0,
	])
	for entry: JournalEntry in world.journal:
		var real_minutes: float = float(entry.tick - start_tick) * config.seconds_per_tick() / 60.0
		print("  day %2d %02d:00  (+%5.0f real min)  %s" % [
			entry.day + 1, config.hour_of(entry.tick), real_minutes, entry.text,
		])
	print("Decisions asked (%d):" % asked.size())
	for line: String in asked:
		print(line)
	print("Longest wait between decisions: %.1f real hours" % [
		float(longest_gap) * config.seconds_per_tick() / 3600.0,
	])
	print("Stock every 30 days: %s" % ", ".join(stock))
	print("Stock: wood %d, food %d. Achievements: %s" % [
		world.resource_amount(&"wood"), world.resource_amount(&"food"), world.achievements,
	])
	quit()
