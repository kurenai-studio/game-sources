extends Control
class_name Level

@export_range(1, 9) var liar_number: int = 1

@onready var persons : Array = %GridContainer.get_children()
@onready var stopwatch : Label = %Stopwatch

var time_passed: float = 0.0
var stopped: bool = false

func _ready() -> void:
	%LiarLabel.text = "Find the 1 liar" if liar_number == 1 else "Find the " + str(liar_number) + " liars" 


func _process(delta: float) -> void:
	if !stopped:
		time_passed += delta
		var minutes : int = int(time_passed / 60.0)
		var min_string: String = "0" + str(minutes) if minutes < 10 else str(minutes)
		var seconds : float = time_passed - 60 * minutes
		var sec_string: String = "0" + str(seconds).pad_decimals(1) if seconds < 10 else str(seconds).pad_decimals(1)
		stopwatch.text = min_string + ":" + sec_string + "s"


func _on_validate_button_pressed() -> void:
	var correct: bool = true
	var idx: int = 0
	for person: Person in persons:
		if !person.is_guess_correct():
			print("Incorrect for person:", idx_to_position(idx, %GridContainer.columns))
			correct = false
		idx += 1
	if correct:
		print("Correct!")
	else: 
		print("You made at least one mistake")


func _on_hint_button_pressed() -> void:
	pass


static func idx_to_position(idx: int, nb_columns: int) -> String:
	var column_str : String = String.chr(65 + (idx % nb_columns))
	@warning_ignore("integer_division")
	return column_str + str((idx / nb_columns) + 1)
