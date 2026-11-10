class_name StockGauge
extends RefCounted
## How a stock reads on the strip without a number (docs/gameplay.md P2): a coarse level (low,
## fine or plenty) and a trend arrow (up, down or none). The trend watches the last stretch of
## ticks and only speaks once the change is clear, and stays until it has mostly faded, so it
## does not flicker with every small change. It is remembered here, not in the world: it is never
## saved, and after a launch or a long absence it starts blank. Pure logic, no nodes.

## Append new members at the end.
enum Level { LOW, FINE, PLENTY }
enum Trend { STEADY, UP, DOWN }

## The stretch the trend looks back over. A tick is about 50 real seconds, so this is two game
## days, about forty real minutes: stock grows slowly (a unit every several ticks), so a shorter
## stretch would rarely show a rise.
const WINDOW_TICKS: int = 48
## The trend is not judged until the samples span at least this much.
const MIN_SPAN_TICKS: int = 6
## A change this big starts a trend; it ends once the change is below the smaller number.
const TREND_STARTS_AT: int = 2
const TREND_ENDS_BELOW: int = 1

var _ticks: PackedInt32Array = PackedInt32Array()
var _amounts: PackedInt32Array = PackedInt32Array()
var _trend: Trend = Trend.STEADY


## Low below `low_stock_fraction` of the comfortable stock, plenty from `plenty_stock_fraction` up.
static func level_for(amount: int, config: SimConfig) -> Level:
	var comfortable: float = float(config.comfortable_stock)
	if float(amount) < comfortable * config.low_stock_fraction:
		return Level.LOW
	if float(amount) >= comfortable * config.plenty_stock_fraction:
		return Level.PLENTY
	return Level.FINE


## Notes the stock as it is at `tick`. Call it as the world changes; the same tick again just
## updates the latest sample, so something spent mid-tick still shows.
func record(tick: int, amount: int) -> void:
	if not _ticks.is_empty():
		var last: int = _ticks[_ticks.size() - 1]
		if tick < last or tick - last > WINDOW_TICKS:
			reset()
		elif tick == last:
			_amounts[_amounts.size() - 1] = amount
			_judge(tick, amount)
			return
	_ticks.append(tick)
	_amounts.append(amount)
	while _ticks[0] < tick - WINDOW_TICKS:
		_ticks.remove_at(0)
		_amounts.remove_at(0)
	_judge(tick, amount)


## Forgets everything: no trend until there is a new stretch to look at.
func reset() -> void:
	_ticks.clear()
	_amounts.clear()
	_trend = Trend.STEADY


func trend() -> Trend:
	return _trend


func _judge(tick: int, amount: int) -> void:
	if tick - _ticks[0] < MIN_SPAN_TICKS:
		return
	var change: int = amount - _amounts[0]
	match _trend:
		Trend.UP:
			if change < TREND_ENDS_BELOW:
				_trend = Trend.STEADY
		Trend.DOWN:
			if change > -TREND_ENDS_BELOW:
				_trend = Trend.STEADY
		_:
			if change >= TREND_STARTS_AT:
				_trend = Trend.UP
			elif change <= -TREND_STARTS_AT:
				_trend = Trend.DOWN
