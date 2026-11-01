# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name TowerPanel
extends BattlePanel
## The panel for a tapped tower (RULES 4.6, 8.2, 9.3, 9.5): its real numbers and
## targeting, the upgrade with before and after numbers, the two tier 3 paths side
## by side, and selling with the exact refund.
##
## Choosing a tier 3 path is permanent, so a tap on a path only chooses it. The
## panel then says so and a second button confirms: the player is asked once.
## Selling asks the same way, with a second tap on the same button. That second tap only
## counts after a short wait (SELL_DELAY_MS), so a quick double tap never sells.
## Everything works while paused: the panel only sends commands to the Battle.

## The map should draw this tower's range ring (see BuildPanel.range_changed).
signal range_changed(cell: Vector2i, reach: int, boost: bool)
## The tower was sold.
signal sold(cell: Vector2i)

const NO_CELL: Vector2i = Vector2i(-1, -1)
## A second tap on Sell that comes sooner than this after the first is ignored.
const SELL_DELAY_MS: int = 600
const STAR_WARNING: String = StarNote.TEXT

var cell: Vector2i = NO_CELL
## The tier 3 path chosen but not yet confirmed, -1 for none.
var picked_spec: int = -1
var sell_armed: bool = false
## When Sell was armed, in Time.get_ticks_msec(). Tests move it back to skip the wait.
var armed_at_msec: int = 0
## The cost line of each tier 3 path card, updated in place as gold changes.
var cost_labels: Dictionary[int, Label] = {}

var name_label: Label = null
var tier_label: Label = null
var aim_buttons: Array[TapButton] = []
var upgrade_button: TapButton = null
var confirm_button: TapButton = null
var path_cards: Array[TapRow] = []
var sell_button: TapButton = null
var refund_label: Label = null
var star_warning_label: Label = null
var permanent_label: Label = null
## The value of the "Dozing" row, or null while the tower is awake. Updated in place every tick,
## so the panel is never rebuilt under a finger while a tower dozes.
var doze_label: Label = null

var _signature: Array = []
var _open: bool = false
var _last_range: Array = []
var _refund_shown: int = 0


## Opens the panel on the tower at `new_cell`.
func show_tower(new_cell: Vector2i) -> void:
	cell = new_cell
	picked_spec = -1
	sell_armed = false
	_signature = []
	_last_range = []
	_open = true
	clear_feedback()
	refresh()


func is_open() -> bool:
	return _open


func set_wide(value: bool) -> void:
	if value != wide:
		super(value)
		_signature = []
		refresh()


## Closes the panel and hides the range ring.
func close() -> void:
	if not _open:
		return
	_open = false
	_last_range = []
	range_changed.emit(NO_CELL, 0, false)
	closed.emit()


## Changes the targeting mode, as a tap on its button does.
func set_aim(aim: TowerState.Aim) -> void:
	if battle == null or not _open:
		return
	sell_armed = false
	finish(battle.set_aim(cell, aim))
	_signature = []
	refresh()


## Chooses a tier 3 path to look at. Nothing is bought until it is confirmed.
func pick_path(spec: int) -> void:
	if battle == null or not _open:
		return
	sell_armed = false
	picked_spec = spec
	clear_feedback()
	refresh()


## Buys the next tier for a tier 1 tower, as a tap on the Upgrade button does.
func upgrade() -> void:
	if battle == null or not _open:
		return
	sell_armed = false
	var price: int = _price(-1)
	var result: StringName = battle.upgrade_tower(cell)
	finish(result, BattleText.shortfall(result, price, battle.gold))
	refresh()


## Buys the picked tier 3 path, as a tap on the confirm button does.
func confirm_path() -> void:
	if battle == null or not _open or picked_spec < 0:
		return
	var price: int = _price(picked_spec)
	var result: StringName = battle.upgrade_tower(cell, picked_spec)
	if finish(result, BattleText.shortfall(result, price, battle.gold)):
		picked_spec = -1
	refresh()


## The first tap arms the sale, the second sells. The refund is the exact amount.
func sell() -> void:
	if battle == null or not _open:
		return
	if _selling_off():
		finish(&"no_selling")
		return
	if not sell_armed:
		sell_armed = true
		armed_at_msec = Time.get_ticks_msec()
		_signature = []
		clear_feedback()
		refresh()
		return
	if Time.get_ticks_msec() - armed_at_msec < SELL_DELAY_MS:
		return
	var refund: int = battle.sell_value(cell)
	var sold_cell: Vector2i = cell
	if finish(battle.sell_tower(cell)):
		sold.emit(sold_cell)
		_refund_shown = refund
		close()
	else:
		sell_armed = false
		_signature = []
		refresh()


## The gold the last sale paid, for the screen's floating text.
func last_refund() -> int:
	return _refund_shown


func refresh() -> void:
	if battle == null or not _open:
		return
	var tower: TowerState = battle.tower_at(cell)
	if tower == null:
		close()
		return
	var numbers: Dictionary = _numbers()
	var options: Array[Dictionary] = battle.upgrade_options(cell)
	if tower.tier != 2 and picked_spec >= 0:
		picked_spec = -1
	var warn: Array[bool] = [warns(&"upgrade", &"", 2), warns(&"upgrade", &"", 3)]
	# The time left dozing changes every tick, so only whether the tower dozes is part of the signature.
	var shown: Dictionary = numbers.duplicate()
	shown["doze_ms"] = int(numbers.get("doze_ms", 0)) > 0
	var signature: Array = [cell, wide, shown, options, picked_spec, sell_armed, tower.spent_now, tower.spent_before, warn]
	if signature != _signature:
		_signature = signature
		_rebuild(tower, numbers, options)
		_announce_range(numbers)
	_update_costs(options)
	if doze_label != null:
		doze_label.text = BattleText.doze_text(int(numbers.get("doze_ms", 0)))


## The tapped tower's numbers. Tests replace this to give a tower a doze time.
func _numbers() -> Dictionary:
	return battle.tower_numbers(cell)


## "need N more" on a path card is the gold still missing now.
func _update_costs(options: Array[Dictionary]) -> void:
	for option: Dictionary in options:
		var label: Label = cost_labels.get(int(option["spec"]))
		if label != null:
			label.text = _cost_text(option)


func _cost_text(option: Dictionary) -> String:
	var text: String = "Cost %d" % int(option["cost"])
	if option["refusal"] == &"too_poor":
		text += ", need %d more" % maxi(0, int(option["cost"]) - battle.gold)
	return text


func _rebuild(tower: TowerState, numbers: Dictionary, options: Array[Dictionary]) -> void:
	clear_column()
	aim_buttons.clear()
	path_cards.clear()
	cost_labels.clear()
	star_warning_label = null
	upgrade_button = null
	confirm_button = null
	permanent_label = null
	doze_label = null
	var type: TowerType = battle.catalog.tower(tower.type)
	column.add_child(_header(tower, type))
	column.add_child(_stats(numbers, type))
	if has_aim(numbers, type):
		column.add_child(_aim_row(tower))
	column.add_child(_upgrade_section(tower, type, numbers, options))
	column.add_child(_sell_section(tower))
	column.add_child(feedback_box)


func _header(tower: TowerState, type: TowerType) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	row.add_child(GlyphIcon.new(128.0).show_tower(tower.type, tower.tier, tower.spec))
	var names: VBoxContainer = VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_theme_constant_override(&"separation", 0)
	name_label = UiKit.heading(type.name)
	names.add_child(name_label)
	var tier_text: String = "Tier %d" % tower.tier
	if tower.tier >= 3:
		tier_text += ": %s" % type.spec_name(tower.spec)
	tier_label = UiKit.label(tier_text, &"SoftLabel")
	names.add_child(tier_label)
	row.add_child(names)
	var close_it: TapButton = UiKit.icon_button(&"close")
	close_it.tapped.connect(close)
	row.add_child(close_it)
	return row


func _stats(numbers: Dictionary, type: TowerType) -> Control:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 48)
	grid.add_theme_constant_override(&"v_separation", 6)
	var rows: Array[PackedStringArray] = BattleText.tower_rows(numbers, type.kind)
	rows.append(PackedStringArray(["Total spent", str(int(numbers["spent"]))]))
	if wide and not _selling_off():
		# The narrow side panel leaves it out: the Sell button right below shows the same number.
		rows.append(PackedStringArray(["Sell value", str(int(numbers["sell"]))]))
	for row: PackedStringArray in rows:
		var r: StatRow = StatRow.pair(row[0], row[1])
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if row[0] == "Dozing":
			doze_label = r.value_label
		grid.add_child(r)
	return grid


## Targeting belongs to attacking towers that aim. A pulse (the Bramble Cottage) aims at nothing,
## and the Bell, Scarecrow and Bakery are not attackers (RULES 9.3).
func has_aim(numbers: Dictionary, type: TowerType) -> bool:
	return type.kind == &"attack" and not bool(numbers.get("pulse", false))


func _aim_row(tower: TowerState) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	box.add_child(UiKit.label("Targeting", &"SoftLabel"))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	for aim: int in BattleText.AIM_NAMES.size():
		var b: TapButton = UiKit.button(BattleText.aim_name(aim))
		if not wide:
			# The side column has no width to spare: with its scroll bar, 664 px for the row.
			b.add_theme_font_size_override(&"font_size", UiTheme.FONT_BODY)
		mark_chosen(b, tower.aim == aim)
		b.tapped.connect(set_aim.bind(aim))
		aim_buttons.append(b)
		row.add_child(b)
	box.add_child(row)
	return box


func _upgrade_section(tower: TowerState, type: TowerType, numbers: Dictionary, options: Array[Dictionary]) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	if options.is_empty():
		box.add_child(UiKit.label("Fully upgraded.", &"SoftLabel"))
		return box
	if _at_cap(options):
		var cap_label: Label = UiKit.label("At the tier cap. This level stops towers at tier %d." % tower.tier, &"SoftLabel")
		cap_label.name = "CapLabel"
		box.add_child(cap_label)
		return box
	var got_pct: int = int(numbers.get("got_pct", 0))
	if tower.tier == 1:
		var option: Dictionary = options[0]
		box.add_child(UiKit.label("Upgrade to tier 2", &"SoftLabel"))
		for change: Dictionary in BattleText.change_rows(option["before"], option["after"], type.kind, got_pct):
			box.add_child(StatRow.change(change["label"], change["before"], change["after"]))
		_add_star_warning(box, 2)
		upgrade_button = UiKit.wrapped(UiKit.button("Upgrade for %d" % int(option["cost"]), &"PrimaryButton" if option["refusal"] == &"" else &"Button"))
		_lock_if_refused(upgrade_button, option["refusal"])
		upgrade_button.tapped.connect(upgrade)
		box.add_child(upgrade_button)
		return box
	if picked_spec < 0:
		box.add_child(UiKit.label("Pick a path for tier 3. The choice is permanent.", &"SoftLabel"))
		_add_star_warning(box, 3)
	# Side by side in the roomy portrait sheet. In the narrow side panel they stack, so the
	# numbers (with their units) are never squeezed.
	var cards: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
	cards.add_theme_constant_override(&"separation", 14)
	for option: Dictionary in options:
		var card: TapRow = _path_card(type, option, got_pct)
		path_cards.append(card)
		cards.add_child(card)
	box.add_child(cards)
	if picked_spec >= 0:
		var chosen: Dictionary = _option_for(options, picked_spec)
		var note: HBoxContainer = HBoxContainer.new()
		note.add_theme_constant_override(&"separation", 12)
		var lock: TextureRect = TextureRect.new()
		lock.texture = IconTex.make(&"lock", 64)
		lock.custom_minimum_size = Vector2(52.0, 52.0)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lock.modulate = Palette.HONEY
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		note.add_child(lock)
		permanent_label = UiKit.label("This choice is permanent for this tower. Only selling it lets you choose again.", &"SoftLabel")
		permanent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.add_child(permanent_label)
		box.add_child(note)
		var ready: bool = chosen["refusal"] == &""
		_add_star_warning(box, 3)
		confirm_button = UiKit.wrapped(UiKit.button("Choose %s for %d" % [type.spec_name(picked_spec), int(chosen["cost"])], &"PrimaryButton" if ready else &"Button"))
		_lock_if_refused(confirm_button, chosen["refusal"])
		confirm_button.tapped.connect(confirm_path)
		box.add_child(confirm_button)
	return box


## The upgrade that would lose the third star says so before it is tapped. The sim decides
## (Battle.loses_star3), so a tower that went above the cap and was sold is counted too.
func _add_star_warning(box: VBoxContainer, new_tier: int) -> void:
	if not breaks_star3(new_tier):
		return
	var note: StarNote = StarNote.new()
	star_warning_label = note.label
	box.add_child(note)


## True when a tower reaching `new_tier` would end a third star that is still possible.
func breaks_star3(new_tier: int) -> bool:
	return warns(&"upgrade", &"", new_tier)


func _path_card(type: TowerType, option: Dictionary, got_pct: int) -> TapRow:
	var spec: int = option["spec"]
	var affordable: bool = option["refusal"] == &""
	var card: TapRow = TapRow.new(&"CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chosen: bool = spec == picked_spec
	card.set_look(Palette.CARD if affordable else Palette.CARD_DIM, Palette.HONEY if chosen else Palette.INK_LINE, 12 if chosen else 4, 12)
	var top: HBoxContainer = HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override(&"separation", 8)
	top.add_child(GlyphIcon.new(80.0).show_tower(type.id, 3, spec))
	var path_name: Label = UiKit.label(type.spec_name(spec), &"CardLabel")
	path_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	path_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(path_name)
	card.body.add_child(top)
	card.body.add_child(UiKit.label(type.spec_info(spec), &"CardMutedLabel"))
	for change: Dictionary in BattleText.change_rows(option["before"], option["after"], type.kind, got_pct):
		# "Affects" holds whole words, too long for the narrow card beside its name.
		card.body.add_child(StatRow.change(change["label"], change["before"], change["after"], &"CardMutedLabel", &"CardLabel", Palette.TEXT_DARK, 36, change["label"] == "Affects"))
	var cost_line: Label = UiKit.label(_cost_text(option), &"CardLabel")
	cost_labels[spec] = cost_line
	card.body.add_child(cost_line)
	card.tapped.connect(pick_path.bind(spec))
	return card


func _sell_section(tower: TowerState) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	sell_button = null
	refund_label = null
	if _selling_off():
		# The No Selling Twist: say so once, with no value and no button.
		var off: Label = UiKit.label(BattleText.refusal(&"no_selling"), &"SoftLabel")
		off.name = "NoSellLabel"
		box.add_child(off)
		return box
	var refund: int = battle.sell_value(cell)
	refund_label = UiKit.label(BattleText.refund_text(tower.spent_now, tower.spent_before, battle.catalog.rules.refund_pct), &"SoftLabel")
	box.add_child(refund_label)
	if sell_armed:
		sell_button = UiKit.wrapped(UiKit.button("Tap again to sell for %d" % refund, &"PrimaryButton"))
	else:
		sell_button = UiKit.wrapped(UiKit.button("Sell for %d" % refund))
	sell_button.tapped.connect(sell)
	box.add_child(sell_button)
	return box


## True under the No Selling Twist. Battle refuses the sale too; the panel just does not offer it.
func _selling_off() -> bool:
	return Modifiers.has_type(battle.twist_effects, "no_selling")


## True when every upgrade is refused for the level's tier cap (a Twist).
func _at_cap(options: Array[Dictionary]) -> bool:
	for option: Dictionary in options:
		if option["refusal"] != &"tier_cap":
			return false
	return not options.is_empty()


func _lock_if_refused(button: TapButton, refusal: StringName) -> void:
	if refusal == &"":
		return
	# The button stays tappable so a tap explains the refusal, and it wears a lock.
	button.icon = IconTex.make(&"lock", 56)
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_hover_pressed_color"]:
		button.add_theme_color_override(state, Palette.TEXT_SOFT)


func _option_for(options: Array[Dictionary], spec: int) -> Dictionary:
	for option: Dictionary in options:
		if option["spec"] == spec:
			return option
	return {}


func _price(spec: int) -> int:
	return int(_option_for(battle.upgrade_options(cell), spec).get("cost", 0))


## Tells the map this tower's range, when it changed.
func _announce_range(numbers: Dictionary) -> void:
	var kind: StringName = battle.catalog.tower(battle.tower_at(cell).type).kind
	var now: Array = [cell, int(numbers["reach"]), kind == &"boost"]
	if now != _last_range:
		_last_range = now
		range_changed.emit(cell, int(numbers["reach"]), kind == &"boost")
