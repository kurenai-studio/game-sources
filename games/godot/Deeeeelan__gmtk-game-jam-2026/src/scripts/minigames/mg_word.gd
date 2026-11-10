extends Control

@onready var game_manager: Node = GameManager

var win = false

const TEXTS = [
	"The quick brown fox jumped over the nasty dog. While that's true, I don't really like dogs.",
	"I hate clocking out, so I use my magic stopwatch to stop time and work for eternity.",
	"My button fastening business is bound to succeed, giving us money that can stack to SATURN!",
	"Work emails are lame. Work is lame. Why do I work? I don't know, I'm just an unpaid intern.",
	"Lorem Ipsum...",
	"Sometimes I just feel like working. There's just this strange urge.",
	'All I do everyday is work. "I need you an hour earlier tomorrow" this, "Deadline in two weeks" that, ugh.',
	"Being good at my job rewards me with doing more jobs! This is amazing.",
	"Considering my efforts at this company, I feel like I deserve a raise... Who am I kidding, no I don't.",
	"Everytime I look at the clock, it goes backwards. Am I going insane?",
	"Lorem Ipsum... salt?",
	"Sometimes, I just feel like working. There's just this strange urge.",
	"There's a distinct lack of Gravity and Grace here. We're all working With Reckless Abandon.",
	"If you're feeling burnt out, just don't feel like that. Be normal. And get back to work.",
	"I don't feel like writing."
]

func _ready() -> void:
	play()

func play():
	var cur_text = TEXTS[randi_range(0,len(TEXTS) - 1)]
	$Center/Hide.text = cur_text
	$Center/Input.text = ""
	$Center/Input.text_changed.connect(func():
		if $Center/Input.text == cur_text:
			$Center/Input.add_theme_color_override("font_color", Color(0.0, 0.4, 0.0, 1.0))
			if not win:
				win = true
				game_manager.gameWin()
				print('matched')
		else:
			# Are all current chars correct?
			if $Center/Input.text != cur_text.substr(0, len($Center/Input.text)):
				$Center/Input.add_theme_color_override("font_color", Color(0.396, 0.0, 0.0, 1.0))
			else:
				$Center/Input.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
	)

func _input(event: InputEvent) -> void:
	pass
