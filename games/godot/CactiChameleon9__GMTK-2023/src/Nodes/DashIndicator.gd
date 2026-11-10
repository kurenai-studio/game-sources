extends Control

signal can_dash

@export var dash_reset_time: float = 5

func _ready():
	$FadeShapeControl.split_offset = 0


func _dashed():
	var tween := create_tween() \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_trans(Tween.TRANS_LINEAR)
	
	$FadeShapeControl.split_offset = size.x
	tween.tween_property($FadeShapeControl, "split_offset", 0, dash_reset_time)
	
	tween.connect("finished", func(): can_dash.emit())


func _disable_indicator():
	var tween := create_tween() \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "modulate", Color(0,0,0,0), 0.25)
	hide()
	
