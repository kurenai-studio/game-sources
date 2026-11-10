class_name _LoreInitializer
extends Node
## Lore system autoload — instancia o LoreSystemManager (scripts/lore/).

var _lore: LoreSystemManager


func _ready() -> void:
	_lore = LoreSystemManager.new()
	add_child(_lore)
	print("[OK] Lore system initialized — lacos=%d brasa=%d" % [
		_lore.bonds_system.active_bonds.size(),
		_lore.brasa_system.brasa_level
	])
