# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndPanel
extends Modal
## The end of a level, won or lost. A win shows the three stars with a word for each
## ("New star", "Earned", "Earned before" or "Not earned"), so color is never the only
## signal, and offers the next level, a replay and the level list. A loss offers
## another try. The back button goes to the level list. A Twist (`result["twist"]`) has no
## stars: a win says the Twist is cleared, and a loss does not point to Relaxed.

signal next_requested()
signal retry_requested()
signal levels_requested()

var won: bool = false
## True when the game was a Twist: no stars, no next level.
var twist: bool = false
var next_button: TapButton
var retry_button: TapButton
var levels_button: TapButton
var star_states: Array[Label] = []
var star_icons: Array[StarIcon] = []
var summary_label: Label
## The line that points a stuck player to Relaxed. Null unless this is a Normal loss.
var relaxed_label: Label


## `result` is Battle.result() plus "relaxed" and "twist". `previous_bits` are the stars the level
## already had before this try. `next_id` is the next level of the region, or &"".
func _init(game: GameData, level_id: StringName, result: Dictionary, previous_bits: int, next_id: StringName) -> void:
	won = bool(result.get("won", false))
	twist = bool(result.get("twist", false))
	var title_text: String = "Level won" if won else "Level lost"
	if twist:
		title_text = "Twist cleared" if won else "Twist lost"
	super(title_text)
	var level: LevelData = game.levels[level_id]
	var name_label: Label = UiKit.label(CampaignText.title(game, level_id), &"Label")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(name_label)
	if twist:
		var twist_label: Label = UiKit.label("Twist: %s" % level.twist_name, &"SoftLabel")
		twist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(twist_label)
	if twist and won:
		summary_label = UiKit.label("The Twist is cleared. Lives left: %d" % int(result.get("lives_left", 0)))
	elif won:
		_add_stars(game, level, int(result.get("stars", 0)), previous_bits)
		summary_label = UiKit.label("Lives left: %d" % int(result.get("lives_left", 0)))
		if bool(result.get("relaxed", false)):
			summary_label.text += ". Relaxed wins earn the first star only."
	else:
		summary_label = UiKit.label("%d of %d waves cleared." % [int(result.get("waves_cleared", 0)), level.waves.size()])
	body.add_child(summary_label)
	if not won and not bool(result.get("relaxed", false)) and not bool(result.get("twist", false)):
		# After a Normal loss, a stuck player is told Relaxed exists (RULES 11, FUN_REVIEW_R1 item 9).
		relaxed_label = UiKit.label(relaxed_hint(game), &"SoftLabel")
		body.add_child(relaxed_label)
	if won and next_id != &"":
		next_button = UiKit.button("Next level", &"PrimaryButton")
		next_button.tapped.connect(func() -> void: _answer(next_requested))
		body.add_child(next_button)
	retry_button = UiKit.button("Play again" if won else "Try again", &"Button" if won and next_id != &"" else &"PrimaryButton")
	retry_button.tapped.connect(func() -> void: _answer(retry_requested))
	body.add_child(retry_button)
	levels_button = UiKit.button("Levels")
	levels_button.tapped.connect(request_close)
	body.add_child(levels_button)


## "Stuck? Relaxed gives 40 lives and more gold." The number is worked out from rules.json.
static func relaxed_hint(game: GameData) -> String:
	var rules: GameRules = game.catalog.rules
	@warning_ignore("integer_division")
	var lives: int = rules.start_lives * rules.relaxed_lives_pct / 100
	return "Stuck? Relaxed gives %d lives and more gold." % lives


func request_close() -> void:
	_answer(levels_requested)


## The panel closes first, so the screens the answer opens are not hidden by it.
func _answer(answer: Signal) -> void:
	closed.emit()
	answer.emit()


func _add_stars(game: GameData, level: LevelData, earned_now: int, previous_bits: int) -> void:
	var lines: PackedStringArray = StarText.lines(level, game.catalog)
	for i: int in 3:
		var now: bool = (earned_now >> i) & 1 == 1
		var before: bool = (previous_bits >> i) & 1 == 1
		var state_text: String
		if now and not before:
			state_text = "New star"
		elif now:
			state_text = "Earned"
		elif before:
			state_text = "Earned before"
		else:
			state_text = "Not earned"
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 18)
		var icon: StarIcon = StarIcon.new(64.0, now or before)
		star_icons.append(icon)
		row.add_child(icon)
		var text: VBoxContainer = VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text.add_theme_constant_override(&"separation", 0)
		text.add_child(UiKit.label(lines[i]))
		var state: Label = UiKit.label(state_text, &"Label" if now else &"SoftLabel")
		if now and not before:
			state.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_HEAVY))
		star_states.append(state)
		text.add_child(state)
		row.add_child(text)
		body.add_child(row)
