class_name StockIcon
extends Button
## One resource on the strip, with no number (docs/gameplay.md P2): its icon, a row of three pips
## (one lit is low, two fine, three plenty) and a small arrow while the stock is clearly rising or
## falling (StockGauge). Picking it asks for the stores panel, where the numbers are. Everything
## here is in viewport art pixels.

signal stores_requested

## The footprint, which is also the clickable area.
const SIZE: Vector2 = Vector2(20.0, 17.0)
const ARROW_POSITION: Vector2 = Vector2(13.0, 2.0)
const PIPS_POSITION: Vector2 = Vector2(1.0, 13.0)

var _gauge: StockGauge = StockGauge.new()
var _level: StockGauge.Level = StockGauge.Level.FINE
var _last_tick: int = -1
var _last_amount: int = -1
var _arrow: TextureRect = TextureRect.new()
var _pips: TextureRect = TextureRect.new()
var _arrow_textures: Array[Texture2D] = []
var _pip_textures: Array[Texture2D] = []
var _resource: StringName = &""


## `arrows` is the up arrow then the down arrow; `pips` is one, two and three lit.
func _init(
	resource: StringName = &"", icon: Texture2D = null,
	arrows: Array[Texture2D] = [], pips: Array[Texture2D] = [],
) -> void:
	_resource = resource
	_arrow_textures = arrows
	_pip_textures = pips
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = SIZE
	size = SIZE
	var picture: TextureRect = TextureRect.new()
	picture.texture = icon
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	_arrow.position = ARROW_POSITION
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.visible = false
	add_child(_arrow)
	_pips.position = PIPS_POSITION
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pips)
	pressed.connect(func() -> void: stores_requested.emit())
	_show_level(StockGauge.Level.FINE)


## Reads the world's stock of this icon's resource. Cheap to call every frame: nothing happens
## unless the tick or the amount changed.
func update_from(world: WorldState, config: SimConfig) -> void:
	var amount: int = world.resource_amount(_resource)
	if world.tick == _last_tick and amount == _last_amount:
		return
	_last_tick = world.tick
	_last_amount = amount
	_gauge.record(world.tick, amount)
	_show_level(StockGauge.level_for(amount, config))
	var trend: StockGauge.Trend = _gauge.trend()
	_arrow.visible = trend != StockGauge.Trend.STEADY
	if _arrow.visible and not _arrow_textures.is_empty():
		_arrow.texture = _arrow_textures[0 if trend == StockGauge.Trend.UP else 1]


func level() -> StockGauge.Level:
	return _level


func trend() -> StockGauge.Trend:
	return _gauge.trend()


func _show_level(level_value: StockGauge.Level) -> void:
	_level = level_value
	if not _pip_textures.is_empty():
		_pips.texture = _pip_textures[int(level_value)]
