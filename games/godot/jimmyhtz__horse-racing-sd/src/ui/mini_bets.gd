extends VBoxContainer
## Read-only wager grid, shared by betting and race summaries.
const LED = preload("res://ui/led_display.gd")
var cells := {}
var dim_zero_bets := true
var tight := false
const PAIRS := ["1-2","2-4","1-3","2-5","1-4","3-4","1-5","3-5","2-3","4-5"]

func configure(bets: Dictionary, credits: int, win: int = 0, pair_columns: int = 2, show_win: bool = true, dim_zeros: bool = true, credit_label: String = "Credits", show_total: bool = true) -> void:
	dim_zero_bets = dim_zeros
	mouse_filter = MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation",2)
	var total := 0
	for value in bets.values(): total += int(value)
	var meters := Label.new()
	meters.text = ("WIN %d   " % win if show_win else "") + "%s %d" % [credit_label.to_upper(),credits]
	if show_total: meters.text += "   BET %d" % total
	meters.add_theme_font_size_override("font_size",11)
	meters.add_theme_color_override("font_color",Color("27221c"))
	meters.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(meters)
	var grid := GridContainer.new()
	grid.columns = pair_columns*2
	grid.mouse_filter = MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation",2)
	grid.add_theme_constant_override("v_separation",1)
	add_child(grid)
	var order: Array = PAIRS if pair_columns == 2 else ["1-2","1-3","1-4","1-5","2-3","2-4","2-5","3-4","3-5","4-5"]
	for pair in order:
		var label := Label.new()
		label.text = pair
		label.add_theme_font_size_override("font_size",11)
		label.add_theme_color_override("font_color",Color("27221c"))
		label.mouse_filter = MOUSE_FILTER_IGNORE
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		grid.add_child(label)
		var amount := LED.new()
		amount.name = "MiniWager_"+pair.replace("-","_")
		amount.value = int(bets.get(pair,0))
		amount.quiet = amount.value == 0 and dim_zero_bets
		amount.ink = base_ink(amount.value)
		cells[pair] = {"amount":amount,"label":label}
		amount.digits = 2
		amount.compact = true
		amount.custom_minimum_size = Vector2(30,(14 if tight else 18) if pair_columns == 2 else 20)
		amount.mouse_filter = MOUSE_FILTER_IGNORE
		grid.add_child(amount)

func show_simulation(win: int, bets: Dictionary) -> void:
	var total:=0
	for amount in bets.values(): total+=int(amount)
	get_child(0).text="V WIN %d   BET %d" % [win,total]

func show_pending(amount: int) -> void:
	get_child(0).text = "PENDING PAYOUT: %d" % amount

func base_ink(amount: int) -> Color:
	return Color("ff6688") if amount > 0 else (Color("24181c") if dim_zero_bets else Color("ff2452"))

func highlight_pair(pair: String, lit: bool) -> void:
	for key in cells:
		var cell: Dictionary = cells[key]
		var winner: bool = key == pair and cell.amount.value > 0
		var ink := (Color("fff78c") if lit else Color("7a6535")) if winner else base_ink(cell.amount.value)
		if cell.amount.ink != ink:
			cell.amount.ink = ink
			cell.amount.queue_redraw()
		var label_color := Color("923400") if winner and lit else Color("27221c")
		if cell.label.get_theme_color("font_color") != label_color:
			cell.label.add_theme_color_override("font_color",label_color)
