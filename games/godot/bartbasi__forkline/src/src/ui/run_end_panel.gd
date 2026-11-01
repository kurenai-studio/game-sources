# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RunEndPanel
extends Modal
## The end of a run or a daily, won or lost (RULES 14.7, 15): the result in words, waves cleared
## and lives left. A daily also shows the day's best and the streak. A Normal run that was lost
## points to Relaxed, as a lost level does. A run has no stars. The back button goes to the menu.
## An abandoned run shows no panel; the App does not build this one for it.

signal retry_requested()
signal menu_requested()

var won: bool = false
var daily: bool = false
var relaxed: bool = false
var summary_label: Label
var lives_label: Label
var best_label: Label
var streak_label: Label
var relaxed_label: Label
var retry_button: TapButton
var menu_button: TapButton


## `result` is RunSession.result(). `relaxed` is the run's difficulty. A daily passes its `day`
## key with the day's `best` ({} for none) and the shown `streak`, both as they stand after this
## run was recorded. `today` is the phone's day key: when it is not the run's day (a daily that
## ended after midnight), the best is called "Best that day". Empty means the same day.
func _init(game: GameData, result: Dictionary, is_relaxed: bool = false, day: String = "", best: Dictionary = {}, streak: int = 0, today: String = "") -> void:
	won = bool(result.get("won", false))
	daily = not day.is_empty()
	relaxed = is_relaxed
	super(("Daily " if daily else "Run ") + ("won" if won else "lost"))
	if daily:
		var day_label: Label = UiKit.label(day, &"Label")
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(day_label)
	summary_label = UiKit.label("Waves cleared: %d of %d" % [int(result.get("waves", 0)), RunCard.WAVES])
	body.add_child(summary_label)
	lives_label = UiKit.label("Lives left: %d" % int(result.get("lives", 0)))
	body.add_child(lives_label)
	if daily:
		var when: String = "today" if today.is_empty() or today == day else "that day"
		best_label = UiKit.label("Best %s: %s" % [when, RunCard.best_text(best)], &"Label")
		body.add_child(best_label)
		streak_label = UiKit.label(RunCard.streak_text(streak), &"Label")
		body.add_child(streak_label)
	elif not won and not relaxed:
		# After a Normal loss, a stuck player is told Relaxed exists (RULES 11).
		relaxed_label = UiKit.label(EndPanel.relaxed_hint(game), &"SoftLabel")
		body.add_child(relaxed_label)
	retry_button = UiKit.button("Try again" if not won else "Play again", &"PrimaryButton")
	retry_button.tapped.connect(func() -> void: _answer(retry_requested))
	body.add_child(retry_button)
	menu_button = UiKit.button("Menu")
	menu_button.tapped.connect(request_close)
	body.add_child(menu_button)


func request_close() -> void:
	_answer(menu_requested)


## The panel closes first, so the screens the answer opens are not hidden by it.
func _answer(answer: Signal) -> void:
	closed.emit()
	answer.emit()
