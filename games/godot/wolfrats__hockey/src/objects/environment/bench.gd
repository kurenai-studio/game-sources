extends Area2D
@export var home: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_bench_body_entered(body: Node2D) -> void:
	if not body is Skater and not body is Goalie:
		return

	if body is Goalie:
		var goalie: Goalie = body
		if goalie.home_team == home and not goalie.pulled:
			goalie.pull()
		return

	var skater: Skater = body
	if skater.home_team == home and skater.anim_state != "swapping":
		skater.anim_state = "swapping"
		skater.health = skater.statbook.max_health
		
