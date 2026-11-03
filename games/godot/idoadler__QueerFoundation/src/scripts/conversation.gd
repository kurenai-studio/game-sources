class_name Conversation
extends Node2D

@export var question_labels:Array[LabledImage]
@export var answer_label:LabledImage
@export var decision:Button
@export var decide:Decide

var starting_conv:ConvRes
var costumer_name:String
var current_conv:ConvRes
var answer_texts:PackedStringArray
var answer_part: = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	reset()
	decision.pressed.connect(start_decision)

func init(candidate:CandidateRes):
	starting_conv = candidate.first_conversation
	costumer_name = candidate.costumer	
	
func start_decision():
	reset()
	decide.show()
	
func start():
	reset()
	show()
	next()
	decision.visible = false
	
func reset():
	hide()
	decision.visible = false
	for i in question_labels.size():
		question_labels[i].visible = false
	answer_label.visible = false
	current_conv = null
	
func next():
	if answer_part < 0:
		if current_conv == null:
			decision.visible = true
			current_conv = starting_conv
		activate()
	else:
		set_next_answer()

func activate():
	answer_label.visible = false
	for i in question_labels.size():
		if i < current_conv.questions.size():
			question_labels[i].visible = true
			question_labels[i].label.text = current_conv.questions[i]
		else:
			question_labels[i].visible = false

func set_response(response):
	for i in question_labels.size():
		question_labels[i].visible = false
	answer_label.visible = true
	answer_texts = current_conv.answers[response].split("\n")
	answer_part = 0
	set_next_answer()
	if current_conv.goto and current_conv.goto.size() > response:
		current_conv = current_conv.goto[response]
	else:
		current_conv = null

func set_next_answer():
	answer_label.label.text = costumer_name + ": "+ answer_texts[answer_part]
	answer_part += 1
	if answer_part >= answer_texts.size():
		answer_part = -1
