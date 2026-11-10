class_name SimConfig
extends Resource
## Tunable numbers for the settlement simulation. Everything that decides pacing lives here
## so it can be retuned in the inspector without touching code.

@export_group("Time")
## Real seconds that make one game day (1200 = 20 real minutes). The single pacing knob.
@export_range(60.0, 86400.0, 1.0, "or_greater") var real_seconds_per_game_day: float = 1200.0
## Simulation steps per game day. One tick is one "hour" of settlement life when this is 24.
@export_range(4, 96) var ticks_per_day: int = 24
## Longest stretch simulated after being away, in ticks. Anything longer is dropped, so a
## months-long absence cannot stall start-up. 8760 is 365 game days at 24 ticks per day.
@export var max_catch_up_ticks: int = 8760

@export_group("Seasons")
## Game days in one season; a year is four of them (20 days is about 6.7 real hours at the
## default pace).
@export_range(1, 200) var days_per_season: int = 20
## The season the first day falls in (see Season).
@export_range(0, 3) var first_season: int = Season.SPRING
## Game days a damaged building takes to be mended by the villagers' own hands, if nobody has
## repaired it sooner. Damage never waits for ever.
@export_range(1, 60) var self_repair_days: int = 6
## A damaged building produces this share of its output until it is mended.
@export_range(0.0, 1.0, 0.05) var damaged_output: float = 0.5

@export_group("Tide")
## Ticks from one high tide to the next. It is not a whole number of hours, so low tide drifts
## through the day instead of always falling at the same hour (12.4 ticks is two tides a day).
@export_range(4.0, 48.0, 0.1) var tide_period_ticks: float = 12.4
## The tide counts as low below this level (0 is the lowest, 1 the highest).
@export_range(0.0, 0.5, 0.01) var low_tide_level: float = 0.2

@export_group("Daily rhythm")
@export_range(0, 23) var wake_hour: int = 6
@export_range(0, 23) var sleep_hour: int = 22

@export_group("Decisions")
## Decisions that may wait for the player at once. They wait indefinitely; nothing expires.
@export_range(1, 10) var max_pending_decisions: int = 3
## Minimum ticks between one decision opening and the next.
@export_range(0, 240) var decision_cooldown_ticks: int = 12

@export_group("Work")
## Units of a resource a villager gathers per tick while gathering.
@export_range(0.0, 5.0, 0.05) var gather_rate: float = 0.5
@export_range(1.0, 3.0, 0.05) var industrious_multiplier: float = 1.5
@export_range(1, 24) var min_activity_ticks: int = 2
@export_range(1, 24) var max_activity_ticks: int = 4
## A group does not keep chopping what the cave already holds plenty of: once a resource is at
## least this much, villagers rarely choose to gather it (see VillagerSystem) and buildings stop
## adding to it (ConstructionSystem), so stock hovers instead of piling up for ever.
@export_range(1, 1000) var comfortable_stock: int = 40
## Construction progress added per builder per tick.
@export_range(0.1, 5.0, 0.1) var build_rate_per_builder: float = 1.0

@export_group("Food and room")
## Food one villager eats per game day. Everyone eats the same, and nobody starves when it runs
## out (docs/gameplay.md P13): the group just spends more of its time foraging and less on
## everything else.
@export_range(0.0, 5.0, 0.01) var food_per_villager_per_day: float = 0.35
## The foraging ground is shared: with this many more foragers out at the same time, each brings
## back this much less (0.6 means two foragers bring back 1/1.6 of one's catch each, three 1/2.2).
## Hunters share their ground the same way. Those building or cutting wood are not affected.
@export_range(0.0, 2.0, 0.01) var forage_crowding: float = 0.6
## Most villagers the group can ever have, whatever the content says: a safety net for the cost
## of the simulation and the view. Room for newcomers normally runs out long before: each age
## has its own, smaller ceiling (`EraDef.max_villagers`, applied by WorldState.room).
@export_range(3, 100) var max_villagers: int = 14

@export_group("Strip")
## How the wood and food icons on the strip read a stock (StockGauge), as fractions of
## `comfortable_stock`: below the first is "low", from the second up is "plenty".
@export_range(0.0, 1.0, 0.05) var low_stock_fraction: float = 0.25
@export_range(0.0, 1.0, 0.05) var plenty_stock_fraction: float = 0.75


func seconds_per_tick() -> float:
	return real_seconds_per_game_day / float(ticks_per_day)


func day_of(tick: int) -> int:
	return floori(float(tick) / float(ticks_per_day))


## The season (a Season constant) a tick falls in.
func season_at(tick: int) -> int:
	var elapsed: int = floori(float(day_of(tick)) / float(days_per_season))
	return posmod(elapsed + first_season, Season.COUNT)


## Which day of its season a tick falls in, from 0.
func day_of_season(tick: int) -> int:
	return posmod(day_of(tick), days_per_season)


## The sea's level at a tick, from 0 (lowest) to 1 (highest). A pure function of the tick, so it
## needs no saving and offline catch-up lands on the same tide as playing through.
func tide_at(tick: int) -> float:
	return 0.5 + 0.5 * cos(TAU * float(tick) / tide_period_ticks)


func is_low_tide(tick: int) -> bool:
	return tide_at(tick) < low_tide_level


## Hour of day, 0-23, whatever the tick resolution.
func hour_of(tick: int) -> int:
	var into_day: int = posmod(tick, ticks_per_day)
	return floori(float(into_day) * 24.0 / float(ticks_per_day))


func tick_for_hour(hour: int) -> int:
	return floori(float(hour) * float(ticks_per_day) / 24.0)


func is_sleeping_hour(hour: int) -> bool:
	return hour >= sleep_hour or hour < wake_hour
