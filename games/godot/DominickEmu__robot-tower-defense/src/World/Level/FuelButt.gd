extends Button

var fuel_cost = 25;

func _ready():
	text = "FUEL\n("+str(fuel_cost)+")"

func _on_pressed():
	if Global.money >= fuel_cost:
		Global.update_curr(-fuel_cost,1)
