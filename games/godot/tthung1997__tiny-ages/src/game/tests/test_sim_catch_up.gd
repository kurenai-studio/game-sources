extends McpTestSuite
## Offline catch-up: being away is the same as the ticks that would have happened.

const TICK_SECONDS: float = 50.0


func suite_name() -> String:
	return "sim_catch_up"


func test_catching_up_equals_ticking_the_same_amount() -> void:
	var away: Simulation = SimFixture.new_sim(9)
	var present: Simulation = SimFixture.new_sim(9)
	var report: CatchUpReport = away.advance_real_time(SimFixture.START_UNIX + TICK_SECONDS * 72.0)
	present.advance_ticks(72)
	assert_eq(report.ticks_simulated, 72)
	assert_eq(report.ticks_dropped, 0)
	assert_eq(SimFixture.snapshot(away.world), SimFixture.snapshot(present.world))


func test_partial_ticks_carry_over() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var report: CatchUpReport = sim.advance_real_time(SimFixture.START_UNIX + 25.0)
	assert_eq(report.ticks_simulated, 0)
	report = sim.advance_real_time(SimFixture.START_UNIX + 50.0)
	assert_eq(report.ticks_simulated, 1, "Two half-ticks make a tick")


func test_a_very_long_absence_is_capped_not_stalled() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var cap: int = sim.config.max_catch_up_ticks
	var report: CatchUpReport = sim.advance_real_time(
		SimFixture.START_UNIX + TICK_SECONDS * float(cap + 500)
	)
	assert_eq(report.ticks_simulated, cap)
	assert_eq(report.ticks_dropped, 500)


func test_report_summarises_what_happened() -> void:
	var sim: Simulation = SimFixture.new_sim(4)
	var report: CatchUpReport = sim.advance_real_time(
		SimFixture.START_UNIX + TICK_SECONDS * float(SimFixture.TICKS_PER_DAY * 12)
	)
	assert_false(report.is_empty())
	assert_gt(report.decisions_opened.size(), 0, "A decision that opened while away is reported")


func test_the_clock_running_backwards_changes_nothing() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var before: int = sim.world.tick
	var report: CatchUpReport = sim.advance_real_time(SimFixture.START_UNIX - 5000.0)
	assert_eq(report.ticks_simulated, 0)
	assert_eq(sim.world.tick, before)


func test_being_away_is_never_punished() -> void:
	var sim: Simulation = SimFixture.new_sim(6)
	var wood_before: int = sim.world.resource_amount(&"wood")
	var report: CatchUpReport = sim.advance_real_time(
		SimFixture.START_UNIX + TICK_SECONDS * float(SimFixture.TICKS_PER_DAY * 20)
	)
	assert_eq(report.ticks_dropped, 0)
	assert_true(sim.world.resource_amount(&"wood") >= wood_before)
	assert_eq(sim.world.villagers.size(), 3)
	assert_true(sim.world.pending.size() <= sim.config.max_pending_decisions)
