class_name StripIcons
extends Control
## The icons floating at the top right of the viewport, left to right: the wood and food gauges
## (a quiet level and trend, never a number: docs/gameplay.md P2), the idea bulb (only while a
## decision waits, with a count when several do), the journal book and the menu gear. The bulb
## comes and goes at the left end of its group, so the book and gear never move. They stay put
## while the world scrolls. Everything here is in viewport art pixels.

signal bulb_pressed
signal journal_pressed
signal menu_pressed
## A wood or food gauge was picked: the numbers are in the stores panel.
signal stores_pressed
## The pointer has rested on the season glyph (`text` is its name) or moved off it (`text` is
## empty). `at` is the pointer in viewport pixels. The name is drawn by `WorldTooltip` inside the
## viewport, because a native tooltip window is cut off by the strip's click region.
signal hover_changed(text: String, at: Vector2)

const SHEET_PATH: String = "res://assets/ui/icons.png"
const BULB_FRAME: Vector2i = Vector2i(18, 20)
const JOURNAL_REGION: Rect2i = Rect2i(36, 0, 16, 20)
const GEAR_REGION: Rect2i = Rect2i(52, 0, 16, 20)
const WOOD_REGION: Rect2i = Rect2i(68, 0, 12, 12)
const FOOD_REGION: Rect2i = Rect2i(80, 0, 12, 12)
const ARROW_UP_REGION: Rect2i = Rect2i(92, 0, 7, 5)
const ARROW_DOWN_REGION: Rect2i = Rect2i(92, 6, 7, 5)
## One, two and three pips lit, stacked.
const PIPS_REGIONS: Array[Rect2i] = [
	Rect2i(100, 0, 10, 4), Rect2i(100, 6, 10, 4), Rect2i(100, 12, 10, 4),
]
const WOOD_POSITION: Vector2 = Vector2(285.0, 3.0)
const FOOD_POSITION: Vector2 = Vector2(307.0, 3.0)
## The season glyph sits left of the gauges: one 12x12 cell of its own sheet.
const GLYPH_SHEET_PATH: String = "res://assets/ui/season_glyphs.png"
const GLYPH_SIZE: Vector2i = Vector2i(12, 12)
const GLYPH_POSITION: Vector2 = Vector2(264.0, 3.0)
const GLYPH_QUIET: Color = Color(1.0, 1.0, 1.0, 0.85)
const BULB_POSITION: Vector2 = Vector2(331.0, 3.0)
const JOURNAL_POSITION: Vector2 = Vector2(349.0, 3.0)
const GEAR_POSITION: Vector2 = Vector2(366.0, 3.0)
const GEAR_QUIET: Color = Color(1.0, 1.0, 1.0, 0.7)
const BLINK_SECONDS: float = 0.5

var _sheet: Texture2D
var _bulb: TextureButton = TextureButton.new()
var _journal: TextureButton = TextureButton.new()
var _gear: TextureButton = TextureButton.new()
var _wood: StockIcon
var _food: StockIcon
var _badge: Label = Label.new()
var _glyph: TextureButton = TextureButton.new()
var _glyph_cell: int = -1
var _glyph_frames: Array[AtlasTexture] = []
var _glyph_text: String = ""
var _glyph_tip: String = ""
var _dwell: HoverDwell = HoverDwell.new()
var _time: float = 0.0
var _frames: Array[AtlasTexture] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(WorldLayout.VIEW_SIZE)
	_sheet = load(SHEET_PATH) as Texture2D
	_wood = _stock_icon(&"wood", WOOD_REGION, WOOD_POSITION)
	_food = _stock_icon(&"food", FOOD_REGION, FOOD_POSITION)
	var glyph_sheet: Texture2D = load(GLYPH_SHEET_PATH) as Texture2D
	for cell: int in WeatherLook.GLYPH_COUNT:
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = glyph_sheet
		frame.region = Rect2(Vector2(cell * GLYPH_SIZE.x, 0), Vector2(GLYPH_SIZE))
		_glyph_frames.append(frame)
	_glyph.position = GLYPH_POSITION
	_glyph.self_modulate = GLYPH_QUIET
	_glyph.pressed.connect(func() -> void:
		_stop_glyph_hover()
		stores_pressed.emit()
	)
	_glyph.mouse_entered.connect(func() -> void: _dwell.point_at(&"season"))
	_glyph.mouse_exited.connect(_stop_glyph_hover)
	add_child(_glyph)
	for frame: int in 2:
		_frames.append(_atlas(Rect2i(Vector2i(frame * BULB_FRAME.x, 0), BULB_FRAME)))
	_bulb.texture_normal = _frames[0]
	_bulb.position = BULB_POSITION
	_bulb.visible = false
	_bulb.pressed.connect(func() -> void: bulb_pressed.emit())
	_badge.add_theme_font_size_override("font_size", 7)
	_badge.add_theme_color_override("font_color", UiTheme.PAPER_LIGHT)
	_badge.add_theme_color_override("font_outline_color", UiTheme.INK)
	_badge.add_theme_constant_override("outline_size", 3)
	_badge.position = Vector2(8.0, 10.0)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bulb.add_child(_badge)
	_journal.texture_normal = _atlas(JOURNAL_REGION)
	_journal.position = JOURNAL_POSITION
	_journal.pressed.connect(func() -> void: journal_pressed.emit())
	add_child(_journal)
	_gear.texture_normal = _atlas(GEAR_REGION)
	_gear.position = GEAR_POSITION
	_gear.self_modulate = GEAR_QUIET
	_gear.mouse_entered.connect(func() -> void: _gear.self_modulate = Color.WHITE)
	_gear.mouse_exited.connect(func() -> void: _gear.self_modulate = GEAR_QUIET)
	_gear.pressed.connect(func() -> void: menu_pressed.emit())
	add_child(_gear)
	add_child(_bulb)


## Reads the wood and food stocks. Cheap to call every frame.
func update_stock(world: WorldState, config: SimConfig) -> void:
	_wood.update_from(world, config)
	_food.update_from(world, config)


## The wood gauge, and the food one, for looking at what they show.
func wood_gauge() -> StockIcon:
	return _wood


func food_gauge() -> StockIcon:
	return _food


## The glyph for the season (the tooltip also names rain or snow). Cheap to call every frame.
func update_season(world: WorldState, config: SimConfig) -> void:
	var cell: int = WeatherLook.glyph_cell(world, config)
	if cell != _glyph_cell:
		_glyph_cell = cell
		_glyph.texture_normal = _glyph_frames[cell]
	var text: String = WeatherLook.describe(world, config)
	if _glyph_text != text:
		_glyph_text = text
		if not _glyph_tip.is_empty():
			_glyph_tip = text
			hover_changed.emit(text, get_local_mouse_position())


## Which glyph cell is showing, for looking at what the strip says.
func glyph_cell() -> int:
	return _glyph_cell


## `waiting` is how many decisions are pending.
func update_pending(waiting: int) -> void:
	_bulb.visible = waiting > 0
	_badge.text = str(waiting) if waiting > 1 else ""


func has_bulb() -> bool:
	return _bulb.visible


## The count shown on the bulb ("" for a single decision).
func badge_text() -> String:
	return _badge.text


## The areas that must stay clickable in strip mode, in viewport art pixels.
func clickable_regions() -> Array[Rect2i]:
	var regions: Array[Rect2i] = [
		Rect2i(Vector2i(_glyph.position), GLYPH_SIZE),
		Rect2i(Vector2i(_wood.position), Vector2i(StockIcon.SIZE)),
		Rect2i(Vector2i(_food.position), Vector2i(StockIcon.SIZE)),
		Rect2i(Vector2i(_journal.position), JOURNAL_REGION.size),
		Rect2i(Vector2i(_gear.position), GEAR_REGION.size),
	]
	if _bulb.visible:
		regions.append(Rect2i(Vector2i(_bulb.position), BULB_FRAME))
	return regions


func _process(delta: float) -> void:
	_update_glyph_hover(delta)
	if not _bulb.visible:
		return
	_time += delta
	_bulb.texture_normal = _frames[int(_time / BLINK_SECONDS) % 2]
	_bulb.position.y = BULB_POSITION.y + (1.0 if fmod(_time, 1.4) > 0.7 else 0.0)


## The season's name shows once the pointer has rested on the glyph, like the world's names.
func _update_glyph_hover(delta: float) -> void:
	_dwell.advance(delta)
	var tip: String = _glyph_text if _dwell.is_ready() else ""
	if tip == _glyph_tip:
		return
	_glyph_tip = tip
	hover_changed.emit(tip, get_local_mouse_position())


func _stop_glyph_hover() -> void:
	_dwell.clear()
	_update_glyph_hover(0.0)


func _stock_icon(resource: StringName, region: Rect2i, at: Vector2) -> StockIcon:
	var arrows: Array[Texture2D] = [_atlas(ARROW_UP_REGION), _atlas(ARROW_DOWN_REGION)]
	var pips: Array[Texture2D] = []
	for pips_region: Rect2i in PIPS_REGIONS:
		pips.append(_atlas(pips_region))
	var icon: StockIcon = StockIcon.new(resource, _atlas(region), arrows, pips)
	icon.position = at
	icon.stores_requested.connect(func() -> void: stores_pressed.emit())
	add_child(icon)
	return icon


func _atlas(region: Rect2i) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = _sheet
	atlas.region = Rect2(region)
	return atlas
