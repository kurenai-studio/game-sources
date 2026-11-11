extends PanelContainer
## Presentation only. Awards have already been settled and saved by the caller.
signal completed
const Sigma = preload("res://ui/sigma_style.gd")
const Banner = preload("res://ui/player_banner.gd")
const LED = preload("res://ui/led_display.gd")
var audio := preload("res://ui/result_audio.gd").new()
var preferences := {}
var awards: Array = []
var counters := {}
var elapsed := 0.0
var count_seconds := 3.0
var hold_seconds := 2.5
var kind := "small"
var complete := false
var heading: Label
var progress_note: Label
var grid: GridContainer

func configure(log_entry: Dictionary, players: Array, profiles: Array, prefs: Dictionary) -> void:
	name = "PayoutScreen"
	preferences = prefs
	awards = log_entry.accounting.duplicate()
	var winners := 0
	for award in awards:
		if award > 0: winners += 1
	var multiplier: int = log_entry.odds.payouts[log_entry.pair]
	kind = "none" if winners == 0 else ("jackpot" if multiplier >= 50 else "small")
	count_seconds = 6.0 if kind == "jackpot" else (0.0 if kind == "none" else 3.0)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	var plate := Sigma.plate(Color("35151d"),Sigma.GOLD,8)
	plate.set_content_margin_all(24)
	plate.set_border_width_all(4)
	add_theme_stylebox_override("panel",plate)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	add_child(content)
	heading = make_label("No winners this race" if kind == "none" else ("JACKPOT!" if kind == "jackpot" else "WINNERS"),40)
	content.add_child(heading)
	content.add_child(make_label("Winning combination %s  |  %dx total return" % [log_entry.pair,multiplier],24))
	var scroll := ScrollContainer.new()
	scroll.name = "PayoutScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(scroll)
	grid = GridContainer.new()
	grid.name = "WinnerCards"
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",14)
	scroll.add_child(grid)
	for i in range(awards.size()):
		if awards[i] <= 0: continue
		var card := PanelContainer.new()
		card.name = "Winner%d" % i
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",Sigma.plate())
		grid.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation",10)
		card.add_child(box)
		var banner := Banner.new()
		banner.configure(profiles[i],players[i].nickname,44,roundi(18*minf(prefs.ui_scale,1.5)))
		box.add_child(banner)
		var count := LED.new()
		count.name = "AwardCount%d" % i
		count.digits = maxi(2,str(awards[i]).length())
		count.custom_minimum_size = Vector2(190,66)
		count.ink = Color.WHITE
		box.add_child(count)
		counters[i] = count
		var caption := make_label("%s won" % prefs.credit_label,18)
		caption.add_theme_color_override("font_color",Sigma.INK)
		box.add_child(caption)
	progress_note = make_label("",20)
	content.add_child(progress_note)
	resized.connect(update_columns)
	update_columns()
	add_child(audio)
	audio.play_result(kind,preferences)
	advance(0.0)

func make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color",Color.WHITE)
	label.add_theme_font_size_override("font_size",font_size)
	return label

func update_columns() -> void:
	if grid == null: return
	grid.columns = 4 if size.x >= 1250 and counters.size() > 4 else (2 if size.x >= 650 else 1)

func update_preferences(prefs: Dictionary) -> void:
	preferences = prefs
	audio.update_preferences(prefs)
	queue_redraw()

func advance(delta: float) -> void:
	if complete: return
	elapsed += maxf(delta,0.0)
	if preferences.get("reduced_motion",false): elapsed = maxf(elapsed,count_seconds)
	var fraction := 1.0 if count_seconds == 0.0 else clampf(elapsed/count_seconds,0.0,1.0)
	for index in counters:
		var amount := int(floor(float(awards[index])*fraction))
		if counters[index].value != amount:
			counters[index].value = amount
			counters[index].queue_redraw()
	progress_note.text = "Counting winnings..." if fraction < 1.0 else ("Returning to betting..." if kind == "none" else "Winnings paid. Returning to betting...")
	if kind == "jackpot": queue_redraw()
	if elapsed >= count_seconds+hold_seconds:
		complete = true
		completed.emit()

func _draw() -> void:
	if kind != "jackpot": return
	var moving: bool = not preferences.get("reduced_motion",false) and elapsed < count_seconds
	var flashing: bool = not preferences.get("reduce_flashing",false)
	for i in range(28):
		var x := 12.0 if i % 2 == 0 else size.x-12.0
		var y := fposmod(i*37.0+(elapsed*42.0 if moving else 0.0),maxf(size.y-24.0,1.0))+12.0
		var radius := 3.5+(sin(elapsed*TAU+i)*1.5 if flashing and moving else 0.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x,y-radius),Vector2(x+radius,y),Vector2(x,y+radius),Vector2(x-radius,y)]),Color.WHITE if i%3 == 0 else Sigma.GOLD)
