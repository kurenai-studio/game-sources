extends AcceptDialog
var app: Node
var rows: VBoxContainer
var feedback: Label

func configure(owner_app: Node) -> void:
	app=owner_app
	name="SavedGames"
	title="Saved games"
	size=Vector2i(760,520)
	get_ok_button().text="Back to Settings"
	confirmed.connect(queue_free); canceled.connect(queue_free)
	var box:=VBoxContainer.new(); box.custom_minimum_size=Vector2(700,420); add_child(box)
	var note:=Label.new(); note.text="Each game keeps its players, credits, wagers, card rotation and settings.\nThe current game is saved before switching. Your profile library stays unchanged."
	box.add_child(note)
	feedback=Label.new(); feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(feedback)
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; box.add_child(scroll)
	rows=VBoxContainer.new(); rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(rows)
	var actions:=HBoxContainer.new(); box.add_child(actions)
	var help_button:=Button.new(); help_button.text="Help  F1"; actions.add_child(help_button)
	help_button.pressed.connect(func(): app.show_help("Saved games",self))
	window_input.connect(func(event):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F1:
			app.show_help("Saved games",self)
			set_input_as_handled())
	for caption in ["Import game file","Export current game"]:
		var control:=Button.new(); control.text=caption; actions.add_child(control)
		control.pressed.connect(func():
			hide(); queue_free()
			app.game_file_action("Import Game" if caption=="Import game file" else "Export Game"))
	refresh()

func refresh() -> void:
	for child in rows.get_children(): rows.remove_child(child); child.queue_free()
	var games: Array=app.game_library.games()
	if not games.any(func(g): return g.id==app.session.game_id):
		games.push_front({"id":app.session.game_id,"title":app.game_library.title_for(app.session.game_id),"path":""})
	for game in games:
		var row:=HBoxContainer.new(); rows.add_child(row)
		var current: bool=game.id==app.session.game_id
		var caption:=Label.new(); caption.text=game.title+("  (current)" if current else "")
		caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(caption)
		var load_button:=Button.new(); load_button.text="Open"; load_button.disabled=current; row.add_child(load_button)
		load_button.pressed.connect(func(): confirm("Save the current game and open "+game.title+"? The selected game's settings will be restored.",func():
			if app.load_named_game(game.path): hide(); queue_free()))
		var remove:=Button.new(); remove.text="Delete"; remove.disabled=current; row.add_child(remove)
		remove.tooltip_text="Open another game before deleting the current game." if current else "Remove this game from the list."
		remove.pressed.connect(func(): confirm("Delete "+game.title+" from saved games? An internal recovery copy will be kept.",func():
			if app.game_library.remove_game(game.id,app.session.game_id):
				app.diagnostics.record("saved_game_deleted",{"game_id":game.id}); refresh()
			else: feedback.text=app.game_library.error))

func confirm(text: String, callback: Callable) -> void:
	var dialog:=ConfirmationDialog.new(); dialog.title="Saved games"; dialog.dialog_text=text
	dialog.min_size=Vector2i(610,160); add_child(dialog)
	dialog.confirmed.connect(func(): dialog.queue_free(); callback.call())
	dialog.canceled.connect(dialog.queue_free); dialog.popup_centered()
