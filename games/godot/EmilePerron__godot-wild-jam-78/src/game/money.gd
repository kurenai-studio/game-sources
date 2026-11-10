extends Node
class_name Money

signal money_updated(money: int)

static var _instance: Money

@export var coins: int = 0:
	set(value):
		var has_changed = value != coins
		coins = value
		
		if has_changed:
			_instance.money_updated.emit(coins)


func _ready() -> void:
	_instance = self


static func gain(count: int) -> void:
	_instance.coins += count


static func has(count: int) -> bool:
	return count <= _instance.coins


static func spend(count: int) -> void:
	_instance.coins -= count


static func set_money(money: int) -> void:
	_instance.coins = money


static func get_money() -> int:
	return _instance.coins
