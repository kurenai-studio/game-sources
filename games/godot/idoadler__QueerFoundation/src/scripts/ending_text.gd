extends Control

@export var candidate:Candidate
@export var label:Label
@export var button:Button

var texts:Array[String] = []
var current_text: = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	disable()

func disable():
	label.text = ""
	hide()

func activate():
	var founded:Array[CandidateRes] = []
	var rejected:Array[CandidateRes] = []
	var delayed:Array[CandidateRes] = []
	for cand in candidate.candidate_list:
		if cand.state == CandidateRes.State.FOUNDED:
			founded.append(cand)
		elif cand.state == CandidateRes.State.REJECTED:
			rejected.append(cand)
		elif cand.state == CandidateRes.State.DELAYED:
			delayed.append(cand)
		else:
			printerr("no state for project: ", cand.costumer, ", ", cand.project)
	
	var text = "Your work is done for today!\n\n"
	
	if founded.size() == 0:
		text += "You couldn't find any project worth investing in"
		texts.append(text)
	else:
		text += "You helped support " + str(founded.size()) + " innovations. The projects you funded were: "
		for f in founded:
			text += f.project + ", "
		texts.append(text)
		
		if (rejected.size() == 0):
			text = "Unfortunately, you tried to approve all the projects, which would bankrupt us. We simply cannot afford to keep you on board with such decisions.\n\nWe cannot afford hiring you. Please reconsider your approach to supporting initiatives more sustainably."
			texts.append(text)
		else:
			text = "You declined " + str(rejected.size()) + " projects that weren't good enough for us."
			if (delayed.size() > 0):
				text += "\n\nThere were "+str(delayed.size())+" projects that you suggested we try again in the next round.\n\nLet's hope your investments yield enough for us to be able to fund them next time!"
			texts.append(text)
		
	text = "Thank you for your hard work and dedication!\n\nIt's now time to reflect:\nDid you choose the best projects?\nThe queerest projects?\nThe most impactful projects?"
	texts.append(text)

	text = "This game was made in 48 hours for the Godot Wild and Proud Jam\n\nThank you for playing!\n~ido.wtf"
	texts.append(text)
	
	label.text = texts[current_text]
	button.pressed.connect(next_text)
	show()
	
func next_text():
	current_text += 1
	if current_text < texts.size():
		label.text = texts[current_text]
	else:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	if current_text + 1 == texts.size():
		button.text = "Replay"
