# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name ModeScreen
extends PageFrame
## "Play" opens this: Campaign, Roguelite and Daily, with a Continue card on top
## when a game is saved. Roguelite and Daily show as locked, with the number of stars
## they need, until the App says they are open. Once open, the Daily button also shows
## the day's best and the streak. (A build with no run mode shows "Coming in a later
## update" instead.) The App fills in the numbers; this screen names no level, region
## or tower.

signal continue_pressed()
signal campaign_pressed()
signal roguelite_pressed()
signal daily_pressed()

var continue_button: TapButton
var campaign_button: TapButton
var roguelite_button: TapButton
var daily_button: TapButton

var _slot: VBoxContainer
var _runs_open: bool = false
var _runs_built: bool = true
var _stars_needed: int = 12
var _stars: int = 0
var _daily_detail: String = ""
var _daily_regions: String = ""


func _init() -> void:
	super("Play")
	_slot = VBoxContainer.new()
	column.add_child(_slot)
	campaign_button = UiKit.two_line_button("Campaign", "Hand-built levels. Earn stars to open more.", &"CardButton", &"CardLabel", &"CardMutedLabel")
	campaign_button.tapped.connect(func() -> void: campaign_pressed.emit())
	column.add_child(campaign_button)
	_build_runs()


## Shows the Continue card with a title and a line under it. Empty `title`
## removes the card.
func set_continue(title: String, detail: String) -> void:
	if continue_button != null:
		_slot.remove_child(continue_button)
		continue_button.queue_free()
		continue_button = null
	if title.is_empty():
		return
	continue_button = UiKit.two_line_button(title, detail, &"PrimaryButton", &"CardLabel", &"CardLabel")
	continue_button.tapped.connect(func() -> void: continue_pressed.emit())
	_slot.add_child(continue_button)


## Roguelite and Daily: not built yet, or open, or locked until `stars_needed` stars
## are earned. `built` false wins over everything else. `daily_detail` is the Daily
## button's second line once it is open; "" keeps the plain line. `daily_regions` is the regions
## sentence ("Regions 1 to 6", RULES 15) that goes in front of that line; "" leaves it out.
func set_runs(runs_open: bool, stars: int, stars_needed: int, built: bool = true, daily_detail: String = "", daily_regions: String = "") -> void:
	_runs_open = runs_open and built
	_runs_built = built
	_stars = stars
	_stars_needed = stars_needed
	_daily_detail = daily_detail
	_daily_regions = daily_regions
	if roguelite_button != null:
		column.remove_child(roguelite_button)
		roguelite_button.queue_free()
	if daily_button != null:
		column.remove_child(daily_button)
		daily_button.queue_free()
	_build_runs()


func _build_runs() -> void:
	roguelite_button = _run_card("Roguelite", "One run. Pick a card after each wave.")
	roguelite_button.tapped.connect(func() -> void: roguelite_pressed.emit())
	column.add_child(roguelite_button)
	var daily_line: String = _daily_detail if not _daily_detail.is_empty() else "One run a day. The same for everyone."
	if not _daily_regions.is_empty() and _runs_open:
		daily_line = "%s. %s" % [_daily_regions, daily_line]
	daily_button = _run_card("Daily", daily_line)
	daily_button.tapped.connect(func() -> void: daily_pressed.emit())
	column.add_child(daily_button)


## The Daily button's second line from the day's best ({} for none) and the shown streak:
## "Best today: Won with 14 lives left. Streak: 3 days." Without a streak that part is left
## out. With neither a best nor a streak it is "", and the plain line shows. While today's daily
## is saved (`saved_today`) and has no result yet, it says "No result yet today.", as the Continue
## card above it does not say "not played".
static func daily_detail(best: Dictionary, streak: int, saved_today: bool = false) -> String:
	if best.is_empty() and streak <= 0 and not saved_today:
		return ""
	var none_yet: String = "No result yet today." if saved_today else "Not played today."
	var text: String = none_yet if best.is_empty() else "Best today: %s" % RunCard.best_text(best)
	if streak > 0:
		text += " %s." % RunCard.streak_text(streak)
	return text


func _run_card(title: String, detail: String) -> TapButton:
	if _runs_open:
		return UiKit.two_line_button(title, detail, &"CardButton", &"CardLabel", &"CardMutedLabel")
	var locked_text: String = "Locked. Needs %d stars, you have %d." % [_stars_needed, _stars]
	if not _runs_built:
		locked_text = "Coming in a later update."
	var b: TapButton = UiKit.two_line_button(title, locked_text, &"Button", &"Label", &"SoftLabel")
	b.disabled = true
	var margin: MarginContainer = b.get_child(0) as MarginContainer
	margin.add_theme_constant_override(&"margin_right", 160)
	var lock: TextureRect = TextureRect.new()
	lock.texture = IconTex.make(&"lock", 72)
	lock.modulate = Palette.TEXT_SOFT
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	lock.offset_left = -108.0
	lock.offset_right = -36.0
	lock.offset_top = -36.0
	lock.offset_bottom = 36.0
	b.add_child(lock)
	return b
