class_name SpellSlotData

var id: String
var grid_col: int
var grid_row: int
var next_id: String  # id of the slot this points toward the tip; empty = this is the tip
var is_tip: bool:
	get: return next_id.is_empty()
var spell: SpellData = null


func _init(p_id: String, p_col: int, p_row: int, p_next_id: String = "") -> void:
	id = p_id
	grid_col = p_col
	grid_row = p_row
	next_id = p_next_id
