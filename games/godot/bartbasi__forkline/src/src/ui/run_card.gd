# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RunCard
extends PageFrame
## The card before a run (docs/ARCHITECTURE.md 3.6, RULES 14, 15). A normal run: what a run is,
## Normal or Relaxed with Normal always chosen when the card opens, then Start. The daily: the
## day, its best result so far and the streak, then Start (always Normal, so no choice). A run
## with a saved game offers Resume first, and Start becomes "Start over". The card never
## remembers Relaxed. A daily with no usable day says "Check the phone's date." and has no Start.
## The App passes in everything it knows (the day, the best, the shown streak); this card reads
## no clock and no file.

## Start a fresh run. `relaxed` is the choice on the card (always false for the daily).
signal start_requested(relaxed: bool)
## Go back to the saved game.
signal resume_requested()

## Waves in a run (RULES 14.1): 6 bands of 3.
const WAVES: int = RunData.BANDS * 3

var daily: bool = false
var relaxed: bool = false
var start_button: TapButton
var resume_button: TapButton
var normal_button: TapButton
var relaxed_button: TapButton
var difficulty_label: Label
var day_label: Label
var best_label: Label
var streak_label: Label
var notice_label: Label
var saved_label: Label
var saved_difficulty_label: Label
var regions_label: Label
var difficulty_heading: Label

var _normal_text: String = ""
var _relaxed_text: String = ""


## `data` is the run files (for the lives and gold the run starts with). `day` is the day key of a
## daily ("" when the phone's date is no good), `best` that day's best ({} for none) and `streak` the
## shown streak. `saved_line` is a sentence about the saved game, or "" when there is none, and
## `saved_relaxed` is that game's difficulty. `regions` is the daily's regions sentence ("Regions 1 to 6").
func _init(game: GameData, data: RunData, daily_run: bool = false, day: String = "", best: Dictionary = {}, streak: int = 0, saved_line: String = "", saved_relaxed: bool = false, regions: String = "") -> void:
	super("Daily" if daily_run else "Roguelite")
	daily = daily_run
	if daily:
		_add_daily(day, best, streak, regions)
	else:
		column.add_child(_intro())
	var normal: Dictionary = start_numbers(game, data, false)
	var easy: Dictionary = start_numbers(game, data, true)
	if daily:
		if not normal.is_empty():
			column.add_child(UiKit.label("%d lives and %d gold." % [int(normal["lives"]), int(normal["gold"])], &"SoftLabel"))
	else:
		column.add_child(_difficulty(normal, easy, not saved_line.is_empty()))
	if not saved_line.is_empty():
		saved_label = UiKit.label(saved_line, &"Label")
		column.add_child(saved_label)
		if not daily:
			saved_difficulty_label = UiKit.label("Your saved run is on %s." % ("Relaxed" if saved_relaxed else "Normal"), &"Label")
			column.add_child(saved_difficulty_label)
		resume_button = UiKit.button("Resume", &"PrimaryButton")
		resume_button.tapped.connect(func() -> void: resume_requested.emit())
		column.add_child(resume_button)
	if daily and day.is_empty():
		notice_label = UiKit.label("Check the phone's date.", &"Label")
		column.add_child(notice_label)
		return
	var text: String = "Start over" if not saved_line.is_empty() else ("Start the daily" if daily else "Start the run")
	var primary: bool = saved_line.is_empty()
	start_button = UiKit.button(text, &"PrimaryButton" if primary else &"Button")
	start_button.custom_minimum_size.y = 200.0
	start_button.tapped.connect(func() -> void: start_requested.emit(relaxed))
	column.add_child(start_button)


## Chooses Normal or Relaxed, as a tap on its button does. The daily has no choice.
func choose(is_relaxed: bool) -> void:
	if daily or normal_button == null:
		return
	relaxed = is_relaxed
	BattlePanel.mark_chosen(normal_button, not relaxed)
	BattlePanel.mark_chosen(relaxed_button, relaxed)
	difficulty_label.text = _relaxed_text if relaxed else _normal_text


## The lives and gold a run starts with: {"lives", "gold"}, or {} when the run files cannot make
## a map. They come from the sim itself, so Relaxed's numbers are never worked out here.
static func start_numbers(game: GameData, data: RunData, is_relaxed: bool) -> Dictionary:
	if data == null:
		return {}
	var level: LevelData = MapAssembler.assemble(0, data, game.catalog)
	if level == null:
		return {}
	var battle: Battle = Battle.create(level, game.catalog, is_relaxed, [] as Array[Dictionary])
	if battle == null:
		return {}
	return {"lives": battle.lives, "gold": battle.gold}


## The day's best as a sentence: "Won with 14 lives left." or "Lost on wave 9 of 18." A best is
## {"won", "waves", "lives"}; an empty one is no result yet.
static func best_text(best: Dictionary) -> String:
	if best.is_empty():
		return "No result yet today."
	if bool(best.get("won", false)):
		return "Won with %d lives left." % int(best.get("lives", 0))
	return "Lost with %d of %d waves cleared." % [int(best.get("waves", 0)), WAVES]


## "Streak: 3 days", "Streak: 1 day", or "No streak yet."
static func streak_text(streak: int) -> String:
	if streak <= 0:
		return "No streak yet."
	return "Streak: %d %s" % [streak, "day" if streak == 1 else "days"]


func _intro() -> Control:
	var box: VBoxContainer = UiKit.section()
	box.add_child(UiKit.heading("%d waves" % WAVES))
	box.add_child(UiKit.label("After each wave you pick one card. Lose all your lives and the run ends. You can leave and come back at any wave."))
	return box.get_parent() as Control


## The regions a daily covers, as the Daily button and the daily card say it (RULES 15).
static func regions_text(last_region: int) -> String:
	return "Regions 1 to %d" % maxi(last_region, 1)


## The number of the last campaign region a daily of this tier covers (contract 14.8): the region
## that holds the tier's `level`; for tier 0 one less than the region of tier 1's `level`, or the
## number of regions when run.json has no tiers. At least 1.
static func regions_last(game: GameData, tier: int) -> int:
	var count: int = game.campaign.size()
	if game.run == null or game.run.tiers.is_empty():
		return maxi(count, 1)
	var capped: int = clampi(tier, 0, game.run.tiers.size())
	var region: int = _region_number(game, game.run.tiers[maxi(capped, 1) - 1]["level"])
	if region < 1:
		return maxi(count, 1)
	return maxi(region if capped > 0 else region - 1, 1)


## 1 based number of the campaign region that holds level `id`, or 0.
static func _region_number(game: GameData, id: StringName) -> int:
	for r: int in game.campaign.size():
		if (game.campaign[r]["levels"] as Array).has(id):
			return r + 1
	return 0


func _add_daily(day: String, best: Dictionary, streak: int, regions: String) -> void:
	var box: VBoxContainer = UiKit.section()
	day_label = UiKit.heading("Today: %s" % day if not day.is_empty() else "Today")
	box.add_child(day_label)
	box.add_child(UiKit.label("%d waves. The same run for everyone today, always on Normal." % WAVES))
	if not regions.is_empty():
		regions_label = UiKit.label("%s." % regions, &"Label")
		box.add_child(regions_label)
	best_label = UiKit.label("Best today: %s" % best_text(best), &"Label")
	box.add_child(best_label)
	streak_label = UiKit.label(streak_text(streak), &"Label")
	box.add_child(streak_label)
	column.add_child(box.get_parent() as Control)


func _difficulty(normal: Dictionary, easy: Dictionary, saved: bool) -> Control:
	var box: VBoxContainer = UiKit.section()
	difficulty_heading = UiKit.heading("Difficulty if you start over" if saved else "Difficulty")
	box.add_child(difficulty_heading)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	normal_button = UiKit.button("Normal")
	normal_button.tapped.connect(choose.bind(false))
	row.add_child(normal_button)
	relaxed_button = UiKit.button("Relaxed")
	relaxed_button.tapped.connect(choose.bind(true))
	row.add_child(relaxed_button)
	box.add_child(row)
	_normal_text = "Normal: %d lives and %d gold." % [int(normal.get("lives", 0)), int(normal.get("gold", 0))] if not normal.is_empty() else "Normal."
	_relaxed_text = "Relaxed: %d lives and %d gold." % [int(easy.get("lives", 0)), int(easy.get("gold", 0))] if not easy.is_empty() else "Relaxed: more lives and more gold."
	difficulty_label = UiKit.label(_normal_text, &"SoftLabel")
	box.add_child(difficulty_label)
	choose(false)
	return box.get_parent() as Control
