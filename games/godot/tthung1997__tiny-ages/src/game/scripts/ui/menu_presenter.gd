class_name MenuPresenter
extends RefCounted
## What the right-click menu, the stores panel and the settings panel show, as plain data so it is
## tested without nodes. The panel draws it and reports the action picked; `Game` applies it.

const MENU_ITEMS: Array = [
	["Journal", &"journal"], ["Villagers", &"villagers"], ["Achievements", &"achievements"],
	["Stores", &"stores"], ["Settings", &"settings"], ["Quit", &"quit"],
]
const MODE_LABELS: Dictionary = {&"strip": "Strip", &"corner": "Corner", &"window": "Window"}
## Resources shown in the stores panel, in this order; anything else the world holds follows.
const STOCK_ORDER: Array[StringName] = [&"wood", &"food"]


class Option:
	extends RefCounted
	var text: String = ""
	## What is reported when it is picked; empty for a label that cannot be picked.
	var action: StringName = &""
	var selected: bool = false


class Row:
	extends RefCounted
	var label: String = ""
	var options: Array[Option] = []


class StockRow:
	extends RefCounted
	var key: StringName = &""
	var amount: int = 0


class Stores:
	extends RefCounted
	## For example "Cave Age - day 12".
	var heading: String = ""
	## For example "Late spring, rain".
	var season_line: String = ""
	var stock: Array[StockRow] = []


static func _option(text: String, action: StringName, selected: bool = false) -> Option:
	var option: Option = Option.new()
	option.text = text
	option.action = action
	option.selected = selected
	return option


## The settings panel's rows for the settings as they are now.
static func settings_rows(settings: UserSettings, screens: int) -> Array[Row]:
	var rows: Array[Row] = []
	var window: Row = Row.new()
	window.label = "Window"
	for mode: StringName in UserSettings.MODES:
		window.options.append(
			_option(MODE_LABELS[mode], StringName("mode:%s" % mode), settings.mode == mode)
		)
	rows.append(window)
	var size: Row = Row.new()
	size.label = "Size"
	size.options.append(_option("-", &"scale:down"))
	size.options.append(_option("x%d" % settings.pixel_scale, &""))
	size.options.append(_option("+", &"scale:up"))
	rows.append(size)
	var on_top: Row = Row.new()
	on_top.label = "On top"
	on_top.options.append(_option("On", &"ontop:on", settings.always_on_top))
	on_top.options.append(_option("Off", &"ontop:off", not settings.always_on_top))
	rows.append(on_top)
	if screens > 1:
		var screen: Row = Row.new()
		screen.label = "Screen"
		screen.options.append(_option("Next screen", &"screen:next"))
		rows.append(screen)
	var shortcuts: Row = Row.new()
	shortcuts.label = "Keys"
	shortcuts.options.append(_option("Edit shortcuts", &"shortcuts"))
	rows.append(shortcuts)
	return rows


## The stores panel: where the settlement is and what it holds.
static func stores(world: WorldState, config: SimConfig, content: ContentLibrary) -> Stores:
	var view: Stores = Stores.new()
	var era: EraDef = content.get_era(world.era)
	view.heading = "%s - day %d" % [
		era.display_name if era != null else "?", config.day_of(world.tick) + 1
	]
	view.season_line = WeatherLook.describe(world, config)
	var keys: Array[StringName] = []
	keys.append_array(STOCK_ORDER)
	for key: StringName in world.resources:
		if not keys.has(key):
			keys.append(key)
	for key: StringName in keys:
		var row: StockRow = StockRow.new()
		row.key = key
		row.amount = world.resource_amount(key)
		if row.amount > 0 or STOCK_ORDER.has(key):
			view.stock.append(row)
	return view
