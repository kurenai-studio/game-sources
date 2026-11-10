extends CenterContainer


func _ready():
	pass # Replace with function body.


func grab_focus():
	get_node("container/back").grab_focus()


func _on_back_pressed():
	visible = false
	get_node("../menu").visible = true
	get_node("../menu").grab_focus()
