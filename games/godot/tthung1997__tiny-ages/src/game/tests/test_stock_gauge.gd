extends McpTestSuite
## The wood and food gauges on the strip (docs/gameplay.md P2): a coarse level and a trend, never
## a number, and a trend that does not flicker.


func suite_name() -> String:
	return "stock_gauge"


func _config() -> SimConfig:
	return SimFixture.load_config()


## Records a stock that changes by `step` every tick for `ticks` ticks, starting at `from_tick`.
func _ramp(gauge: StockGauge, from_tick: int, start: int, step: int, ticks: int) -> void:
	for offset: int in ticks + 1:
		gauge.record(from_tick + offset, start + step * offset)


# ---- level ----------------------------------------------------------------------------------

func test_a_stock_reads_as_low_fine_or_plenty() -> void:
	var config: SimConfig = _config()
	var low_edge: int = ceili(config.comfortable_stock * config.low_stock_fraction)
	var plenty_edge: int = ceili(config.comfortable_stock * config.plenty_stock_fraction)
	assert_eq(StockGauge.level_for(0, config), StockGauge.Level.LOW)
	assert_eq(StockGauge.level_for(low_edge - 1, config), StockGauge.Level.LOW)
	assert_eq(StockGauge.level_for(low_edge, config), StockGauge.Level.FINE)
	assert_eq(StockGauge.level_for(plenty_edge - 1, config), StockGauge.Level.FINE)
	assert_eq(StockGauge.level_for(plenty_edge, config), StockGauge.Level.PLENTY)
	assert_eq(StockGauge.level_for(config.comfortable_stock, config), StockGauge.Level.PLENTY)


func test_the_edges_follow_the_comfortable_stock() -> void:
	var config: SimConfig = _config().duplicate() as SimConfig
	config.comfortable_stock = 100
	assert_eq(StockGauge.level_for(24, config), StockGauge.Level.LOW)
	assert_eq(StockGauge.level_for(25, config), StockGauge.Level.FINE)
	assert_eq(StockGauge.level_for(75, config), StockGauge.Level.PLENTY)


# ---- trend ----------------------------------------------------------------------------------

func test_a_new_gauge_has_no_trend() -> void:
	var gauge: StockGauge = StockGauge.new()
	assert_eq(gauge.trend(), StockGauge.Trend.STEADY)
	gauge.record(100, 20)
	assert_eq(gauge.trend(), StockGauge.Trend.STEADY, "One sample says nothing")


func test_a_clear_rise_or_fall_shows_after_enough_time() -> void:
	var rising: StockGauge = StockGauge.new()
	_ramp(rising, 0, 10, 1, StockGauge.MIN_SPAN_TICKS - 2)
	assert_eq(rising.trend(), StockGauge.Trend.STEADY, "Too short a stretch to judge")
	_ramp(rising, StockGauge.MIN_SPAN_TICKS - 1, 10 + StockGauge.MIN_SPAN_TICKS - 1, 1, 6)
	assert_eq(rising.trend(), StockGauge.Trend.UP)
	var falling: StockGauge = StockGauge.new()
	_ramp(falling, 0, 30, -1, 10)
	assert_eq(falling.trend(), StockGauge.Trend.DOWN)


func test_small_wobbles_never_show() -> void:
	var gauge: StockGauge = StockGauge.new()
	for tick: int in 60:
		gauge.record(tick, 20 + (tick % 2))
		assert_eq(gauge.trend(), StockGauge.Trend.STEADY, "Tick %d" % tick)


func test_the_arrow_stays_until_the_change_has_faded() -> void:
	var gauge: StockGauge = StockGauge.new()
	_ramp(gauge, 0, 10, 1, 10)
	assert_eq(gauge.trend(), StockGauge.Trend.UP)
	# The stock stops at 20. The change over the window shrinks as the climb leaves it.
	for tick: int in range(11, 10 + StockGauge.WINDOW_TICKS):
		gauge.record(tick, 20)
	assert_eq(gauge.trend(), StockGauge.Trend.UP, "Not dropped the moment the climb stopped")
	gauge.record(10 + StockGauge.WINDOW_TICKS, 20)
	assert_eq(gauge.trend(), StockGauge.Trend.STEADY, "...but gone once the stock has settled")


func test_the_pace_of_real_gathering_shows_a_rise() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var gauge: StockGauge = StockGauge.new()
	var rose: bool = false
	for _tick: int in SimFixture.TICKS_PER_DAY * 6:
		sim.advance_ticks(1)
		gauge.record(sim.world.tick, sim.world.resource_amount(&"wood"))
		rose = rose or gauge.trend() == StockGauge.Trend.UP
	assert_true(rose, "Stock grows a unit every few ticks, and the arrow must be able to see that")


func test_spending_shows_as_falling() -> void:
	var gauge: StockGauge = StockGauge.new()
	for tick: int in 12:
		gauge.record(tick, 40)
	gauge.record(12, 40)
	gauge.record(13, 28)
	assert_eq(gauge.trend(), StockGauge.Trend.DOWN)


func test_the_same_tick_again_updates_instead_of_adding() -> void:
	var gauge: StockGauge = StockGauge.new()
	for tick: int in 10:
		gauge.record(tick, 30)
	gauge.record(10, 30)
	gauge.record(10, 20)
	assert_eq(gauge.trend(), StockGauge.Trend.DOWN, "Spent in the same tick")


func test_a_long_absence_starts_over() -> void:
	var gauge: StockGauge = StockGauge.new()
	_ramp(gauge, 0, 10, 1, 10)
	assert_eq(gauge.trend(), StockGauge.Trend.UP)
	gauge.record(500, 50)
	assert_eq(gauge.trend(), StockGauge.Trend.STEADY, "No false arrow after being away")


# ---- the icon on the strip ------------------------------------------------------------------

func test_the_icon_shows_the_level_and_only_a_clear_trend() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var icons: StripIcons = StripIcons.new()
	sim.world.resources[&"wood"] = 3
	sim.world.resources[&"food"] = 30
	icons.update_stock(sim.world, sim.config)
	assert_eq(icons.wood_gauge().level(), StockGauge.Level.LOW)
	assert_eq(icons.food_gauge().level(), StockGauge.Level.PLENTY)
	assert_eq(icons.wood_gauge().trend(), StockGauge.Trend.STEADY)
	sim.world.resources[&"wood"] = 20
	icons.update_stock(sim.world, sim.config)
	assert_eq(icons.wood_gauge().level(), StockGauge.Level.FINE)
	icons.free()


func test_the_gauges_never_show_a_number() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var icons: StripIcons = StripIcons.new()
	sim.world.resources[&"wood"] = 27
	icons.update_stock(sim.world, sim.config)
	assert_eq(icons.wood_gauge().text, "", "No number on the button")
	assert_eq(icons.wood_gauge().find_children("*", "Label", true, false).size(), 0, "...or beside it")
	icons.free()


func test_picking_a_gauge_asks_for_the_stores() -> void:
	var icons: StripIcons = StripIcons.new()
	var asked: Array[int] = []
	icons.stores_pressed.connect(func() -> void: asked.append(1))
	icons.wood_gauge().pressed.emit()
	icons.food_gauge().pressed.emit()
	assert_eq(asked.size(), 2)
	icons.free()


func test_no_two_icons_overlap() -> void:
	var icons: StripIcons = StripIcons.new()
	icons.update_pending(3)
	var regions: Array[Rect2i] = icons.clickable_regions()
	for first: int in regions.size():
		for second: int in range(first + 1, regions.size()):
			assert_false(regions[first].intersects(regions[second]), "%d and %d overlap" % [first, second])
	icons.free()
