class_name QuestPanel
extends PanelContainer
## Diário de missões (Fase 4.2): ativas com progresso por objetivo,
## concluídas esmaecidas e contagem de Fragmentos da Verdade.

var hud: HUD
var _list: VBoxContainer
var _frags: Label


func setup(p_hud: HUD) -> void:
	hud = p_hud
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var w := UIKit.window_panel("Missões", Vector2(460, 0), func(): hud.toggle_quests())
	add_child(w.panel)
	var body: VBoxContainer = w.body
	# Scroll: a lista de missões cresce sem limite (20 principais + 8
	# mistérios + concluídas); os Fragmentos ficam fixos, fora do scroll
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 14)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_frags = UIKit.label("", 15, Color(0.75, 0.55, 1.0), true)
	_frags.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_frags)
	refresh()
	visible = false


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var ql := Game.quest_log
	var actives: Array[QuestData] = []
	var done: Array[QuestData] = []
	for qid in DB.quest_ids():
		var q: QuestData = DB.quest(qid)
		if q == null:
			continue
		if ql.is_active(q.id):
			actives.append(q)
		elif ql.is_completed(q.id):
			done.append(q)
	if actives.is_empty() and done.is_empty():
		_list.add_child(UIKit.label("Nenhuma missão ainda - fale com os habitantes do mundo.", 15, UIKit.TEXT_DIM))
		_frags.text = ""
		return
	for q in actives:
		_add_quest(q, true)
	for q in done:
		_add_quest(q, false)
	_frags.text = "◆ Fragmentos da Verdade: %d/8%s" % [ql.fragments(),
		"" if ql.golden_ending_unlocked() else "  -  reúna todos para o Final Dourado"]


func _add_quest(q: QuestData, active: bool) -> void:
	var ql := Game.quest_log
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_list.add_child(box)
	# Título (rastreada em destaque; concluída esmaecida)
	var title := UIKit.label(q.title, 18, UIKit.GOLD if active else UIKit.TEXT_DIM, true)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	box.add_child(title)
	if active:
		var st := ql.stage_of(q)
		var stage: QuestStage = q.stages[st]
		var desc := UIKit.label(stage.description, 14, UIKit.TEXT_DIM)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.x = 420
		box.add_child(desc)
		var p := ql.progress_of(q)
		for i in stage.objectives.size():
			var o: QuestObjective = stage.objectives[i]
			var prog := int(p[i])
			var col: Color = Color(0.5, 1, 0.5) if prog >= o.count else Color.WHITE
			var line := UIKit.label("- %s" % stage.objective_text(i, prog), 14, col)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.custom_minimum_size.x = 420
			box.add_child(line)
		if q.stages.size() > 1:
			box.add_child(UIKit.label("Estágio %d de %d" % [st + 1, q.stages.size()], 12, UIKit.TEXT_DIM))
	else:
		var ok := UIKit.label("✔ Concluída", 13, Color(0.5, 1, 0.5))
		box.add_child(ok)
