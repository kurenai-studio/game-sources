extends Label


func _on_money_money_updated(money: int) -> void:
	text = str(money)
