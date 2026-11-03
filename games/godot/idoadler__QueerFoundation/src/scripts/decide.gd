class_name Decide
extends Sprite2D

@export var note_left:Label
@export var note_right:Label
@export var decision_buttons:Array[DecisionButton]
@export var stamps:Node2D
@export var approved:Node2D
@export var denied:Node2D
@export var no_funds:Node2D
@export var next:Button

@export var current_funds: int = 50000
var target_project:CandidateRes

func _ready():
	hide()
	for node in decision_buttons:
		node.pressed.connect(check_ready)

func reset(candidate:CandidateRes):
	target_project = candidate
	for node in decision_buttons:
		node.reset()
	stamps.hide()
	approved.hide()
	denied.hide()
	no_funds.hide()
	next.hide()
	#SET NOTES
	note_left.text = target_project.costumer + ":\n" + target_project.project + "\n" + str(target_project.required_funds) + "$"
	note_right.text = "Current\nFunds:\n" + str(current_funds) + "$"
	hide()

func check_ready():
	for node in decision_buttons:
		if not node.is_set or node.frozen:
			return
	stamps.show()
	
func stamp(approved_stamp:bool):
	for node in decision_buttons:
		node.freeze()
	stamps.hide()
	if not approved_stamp:
		target_project.state = CandidateRes.State.REJECTED
		denied.show()
	elif current_funds > target_project.required_funds:
		current_funds -= target_project.required_funds
		target_project.state = CandidateRes.State.FOUNDED
		approved.show()
	else:
		target_project.state = CandidateRes.State.DELAYED
		no_funds.show()
	stamps.hide()
	next.show()
