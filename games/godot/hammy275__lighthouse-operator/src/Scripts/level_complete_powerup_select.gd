extends Control


var left_powerup: Global.Powerup = Global.Powerup.BETTER_OIL
var right_powerup: Global.Powerup = Global.Powerup.FASTER_MOVEMENT

## Signal fired when a powerup has been selected to begin the next level.
signal start_next_level()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func setup() -> void:
	if Global.level_num == 2:
		# Left powerup is whatever wasn't already taken in level 1
		if Global.Powerup.BETTER_OIL in Global.powerups:
			$LeftDescription.text = $RightDescription.text
			$LeftButton.text = $RightButton.text
			left_powerup = right_powerup
		$RightDescription.text = "Study the ships to see if\nthey're reacting to an obstacle."
		$RightButton.text = "Study Ships"
		right_powerup = Global.Powerup.STUDY_SHIP_VIEW


func _on_left_button_pressed() -> void:
	Global.powerups[left_powerup] = true
	self.start_next_level.emit()


func _on_right_button_pressed() -> void:
	Global.powerups[right_powerup] = true
	self.start_next_level.emit()
