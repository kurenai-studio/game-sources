extends ItemList

signal popup_building_selected(Name:String)

func _on_item_selected(index: int) -> void:
	emit_signal("popup_building_selected",get_item_text(index))
