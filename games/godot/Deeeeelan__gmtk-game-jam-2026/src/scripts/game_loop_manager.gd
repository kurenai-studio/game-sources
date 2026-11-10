extends Node

@onready var countdown_text = %Clock
@onready var fade = %Fade
@onready var promotion = %Promotion
@onready var fired = %Fired

var lost = false
const APP = preload("res://assets/nodes/app.tscn")

var max_games: int = 1
const RANKS = [
	"Unpaid Intern",
	"Senior Intern",
	"Junior Janitor",
	"Toilet Lid Boy",
	"Pencil Sharpening Boy",
	"Coffee Boy",
	"Bagel Boy",
	"Senior Janitor",
	"Trainee",
	"Employee",
	"Accountant",
	"Junior Manager",
	"Senior Manager",
	"CEO",
]
var rank: int = -1

func promote():
	rank += 1
	if rank > len(RANKS) - 1:
		rank = len(RANKS) - 1
		promotion.get_node("Label").text = "Good work!\nYour performance is exceptional."
	else:
		promotion.get_node("Label").text = "Congrats!\nYou've been promoted to:\n" + RANKS[rank]
	promotion.modulate = Color(0.0, 0.0, 0.0, 0.0)
	var tween = get_tree().create_tween()
	tween.tween_property(promotion, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	tween.play()
	
	await tween.finished
	await get_tree().create_timer(2.0).timeout
	%SFX.play()
	var tween2 = get_tree().create_tween()
	tween2.tween_property(promotion, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	tween2.play()

func lose():
	if not lost:
		lost = true
		%BGM.stop()
		%SFX_wrong.play()
		fired.get_node("Label").text = "You've been fired!\nRank:\n" + ("Nothing" if rank == -1 else RANKS[rank])
		fired.modulate = Color(0.0, 0.0, 0.0, 0.0)
		var tween = get_tree().create_tween()
		tween.tween_property(fired, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
		tween.play()
		await get_tree().create_timer(8).timeout
		get_tree().quit()

func start():
	%BGM.volume_db = -80.0
	%BGM.play()
	%SFX_start.play()
	fade.color = Color(0.0, 0.0, 0.0, 1.0)
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "color", Color(0.0, 0.0, 0.0, 0.0), 1.0)
	tween.play()
	var tween2 = get_tree().create_tween()
	tween2.tween_property(%BGM, "volume_db", 0.0, 8.0)
	tween2.play()
	
	
	
	await tween.finished
	game_loop()
	

func game_loop() -> void:
	$"../Countdown".start()
	$"../Countdown".timeout.connect(func():
		if GameManager.curr_time == 0:
			lose()
		else:
			GameManager.curr_time -= 1
			countdown_text.text = str(GameManager.curr_time)
	)
	while true:
		GameManager.curr_time = GameManager.max_time
		for i in range(max_games):
			var game_id = randi_range(0, len(GameManager.GAMES) - 1)
			var game = GameManager.GAMES[game_id]
			var app = APP.instantiate()
			app.get_node("Button").game_path = game.path
			app.get_node("Button").game_name = game.name
			app.get_node("List/Title").text = game.name
			app.get_node("List/MarginContainer/Icon").texture = load(game.icon)
			%AppList.add_child(app)
		
		while GameManager.cur_games < max_games: await get_tree().create_timer(0.5).timeout
		print("NEXT")
		promote()
		if GameManager.total_games % 3 == 0 and GameManager.total_games >= 3 and max_games < 4:
			max_games += 1
		GameManager.cur_games = 0
		GameManager.max_time = max(25, floori(GameManager.max_time * .92))
		
		for n in %AppList.get_children():
			n.queue_free()
		for n in %Windows.get_children():
			n.queue_free()
		
func _ready() -> void:
	start()
