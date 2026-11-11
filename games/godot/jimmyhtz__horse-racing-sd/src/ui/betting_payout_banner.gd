extends HBoxContainer
const Sigma = preload("res://ui/sigma_style.gd")
const LED = preload("res://ui/led_display.gd")
const PAIRS := ["1-2","1-3","1-4","1-5","2-3","2-4","2-5","3-4","3-5","4-5"]
var shown := {}

func set_board(payouts: Dictionary) -> void:
	if payouts == shown: return
	shown = payouts.duplicate()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_theme_constant_override("separation",5)
	for pair in PAIRS:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		var plate := Sigma.plate(Sigma.GOLD,Color("84531e"),3)
		plate.set_content_margin_all(4)
		plate.shadow_size = 0
		panel.add_theme_stylebox_override("panel",plate)
		add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",4)
		panel.add_child(row)
		var label := Label.new()
		label.text = pair
		label.add_theme_font_size_override("font_size",16)
		label.add_theme_color_override("font_color",Sigma.INK)
		row.add_child(label)
		var odds := LED.new()
		odds.name = "BannerOdds_"+pair.replace("-","_")
		odds.value = payouts[pair]
		odds.digits = 3 if odds.value >= 100 else 2
		odds.compact = true
		odds.custom_minimum_size = Vector2(42,34)
		odds.size_flags_horizontal = SIZE_EXPAND_FILL
		odds.ink = Color("ff4150") if odds.value >= 50 else (Color("ffe037") if odds.value >= 10 else Color("63f17b"))
		odds.tooltip_text = "%s pays %dx total return" % [pair,odds.value]
		row.add_child(odds)
