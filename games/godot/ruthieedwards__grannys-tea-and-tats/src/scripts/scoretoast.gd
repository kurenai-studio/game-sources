extends Control

@export var slide_duration: float = 0.5 #how long it takes the modal to pop up
@export var score_duration: float = 2.0 #how long it takes to count up the score 
@export var slide_distance: float = 200.0 #dist from bottom of screen to slide up the modal

@onready var score_label: Label = $ScoreLabel
@onready var next_button: Button = $NextButton
@onready var count_sfx: AudioStreamPlayer = $CountSFX


var target_score: int = 0
var displayed_score: int = 0:
	set(value):
		displayed_score = value
		if score_label:
			score_label.text = str(displayed_score)

func _ready() -> void:
	next_button.visible = false
	next_button.pressed.connect(_on_next_pressed)
	print("modal ready")

func show_score(final_score: int) -> void:
	print("showing score modal")
	target_score = final_score
	displayed_score = 0
	next_button.visible = false
	
	### TWEEN CHAIN ###

	# i gave up trying to use screen positions so i just did it the cheap way
	var target_y: float = global_position.y - slide_distance

	var tween = create_tween().set_parallel(false)
	
	#slide up the toast 
	tween.tween_property(self, "global_position:y", target_y, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# play drumroll sound effect
	tween.tween_callback(func(): if count_sfx: count_sfx.play())

	# count up the score
	tween.tween_property(self, "displayed_score", target_score, score_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# show next button
	tween.tween_callback(func(): next_button.visible = true)

func _on_next_pressed() -> void:
	
	var target_y: float = global_position.y + slide_distance
	
	var tween = create_tween().set_parallel(false)

	tween.tween_property(self, "global_position:y", target_y, slide_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
