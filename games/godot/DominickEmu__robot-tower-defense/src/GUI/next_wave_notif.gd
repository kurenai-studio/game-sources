extends Control

@onready var bonus_label = $BonusLabel
@onready var bonus = 100+Global.wave*4

# call wave mechanic, the later the wave is called the less bonus money gained 
func ready():
	update_label()

func _on_next_wave_notif_pressed():
	Global.update_curr(bonus,0)
	next_wave()

func _on_bonus_timer_timeout():
	bonus -= 1;
	update_label()
	if bonus <= 0:
		next_wave()

func update_label():
	bonus_label.text = str(bonus)

func next_wave():
	Global.new_wave()
	queue_free()

# so that the point always faces the dir of enemy spawn
func rotate_bubble(degs):
	$Bubble.rotation = -degs
