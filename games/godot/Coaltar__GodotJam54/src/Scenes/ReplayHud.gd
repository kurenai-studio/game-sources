extends CanvasLayer

var score = 0

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_GameManager_game_over():
	var final_score = "Final Score: " + String(score)
	$Label.text = final_score
	pass # Replace with function body.
