extends Control

@onready var game_manager: Node = GameManager

var win = false
var cooldown = false

const EMAIL_BUTTON = preload("res://assets/nodes/email_button.tscn")

var emails: Array[Dictionary] = [ #TODO: Write the emails
	{
		"Title": "How do I make a good brisket?",
		"Subject": 'From: Tom "Texas" Coulkem\nSubject: How do I make a good brisket?', 
		"Body": "My name's Tommy Texas and I love my brisket. But when I bought a smoker from y'all it failed to work. When I put some brisket meat into it it came out completely uncooked. I did cut off a long, black, two pronged snake at the back of the smoker and hung it on my doorstep as a trophy. And now when I press the on button nothing happens. Help me, I can't survive without my brisket."
	},
	{
		"Title": "Regarding the meeting on the 25th",
		"Subject": "From: Maple Seral\nSubject: Regarding the meeting on the 25th", 
		"Body": 'Why did we meet up for one minute? Like genuinely why did you call us all out saying it was an "important" meeting just to essentially only say "hi guys" and just leave? What are we even doing anymore.'
	},
	{
		"Title": "Work Without Pay",
		"Subject": "From: Manager\nSubject: Work Without Pay", 
		"Body": "I need you to work an extra hour for the next two weeks. Will not be considered as overtime."
	},
	{
		"Title": "Regarding the remaining supplies in the office",
		"Subject": "From: Johnny Denson\nSubject: Regarding the remaining supplies in the office", 
		"Body": "We have 10 staples left. How are we still alive as a company. Please buy more."
	},
	{
		"Title": "What am I supposed to do around here?",
		"Subject": "From: Garret Kim\nSubject: What am I supposed to do around here?", 
		"Body": 'Why does it say on my job details that I am a Bagel boy? I graduated from Harvard. I went into student debt. I have a Masters Degree in Neuroscience. Why am I labeled nothing more than a child who brings the "workers" a morning snack?',
	},
	{
		"Title": "You are a perfect fit for our company",
		"Subject": "From: Evelyn Marione\nSubject: You are a perfect fit for our company", 
		"Body": 'Hello, we have reviewed your application and resume extensively, and took your interview into consideration. We have deemed you a perfect fit for our company and invite you to join us.',
	},
	{
		"Title": "Filling in for a week",
		"Subject": "From: James Stone\nSubject: Filling in for a week", 
		"Body": "I have gotten severely injured from rock climbing. I need you to stand in for me for the next two week. I'll repay the favor sometime soon.",
	},
]

var responses: Array[Dictionary] = [ #TODO: Write responses
	{
		1: "Hello Tommy Texas. Regarding your 'faulty' smoker, I believe that you cut off the power supply.",
		2: "Wassup Tommy Texas. I love my brisket but like maybe you should just try different meat.",
		3: "Hey Tommy, Have you tried turning it off and on again?",
		"Correct": 1
	},
	{
		2: "Hi Maple! I love your voice, that's why I call you in!",
		1: "Hi Maple. I have no respect for your time whatsoever so I just call you into office because it's funny when you get mad.",
		3: "Hi Maple, I just like making meetings for fun.",
		"Correct": 2
	},
	{
		3: "Sorry, but I require overtime to work an extra hour. Or a raise.",
		2: "Of course, I have extra time on my hands. I will clock in an hour earlier.",
		1: "No, I'd like to go home on time.",
		"Correct": 2
	},
	{
		3: "Hey Denson. I agree that staples are a crucial element in a successful office. I will create a new order ASAP.",
		2: "Hey Denson. I agree staples are very useful for us because we can like staple someone's shirt to itself while they sleep.",
		1: "Hello Denson, I think we can all agree that staples are tasty.",
		"Correct": 3
	},
	{
		1: "Hey Garret, Despite your position, I think you are very beneficial for the company and we wish to see you succeed.",
		2: "Hi Garret. This job position would be great to get you out of debt.",
		3: "Yo Garret! Thats kinda unfortunate man...",
		"Correct": 1
	},
	{
		1: "How did you find my corporate email",
		2: "Sorry, I am unable to accept your position at this time. I have found myself in a better position.",
		3: "Yes, I will gladly accept this position because my current position sucks.",
		"Correct": 2
	},
	{
		1: "I apologize James, but I am unable to fill in for your position at this time.",
		2: "James, how did you do that? I'm not doing that.",
		3: "Of course, James. I will gladly fill in for you. You don't need to worry about it too much.",
		"Correct": 3
	}
]
	
func _ready():
	var randid = randi_range(0, 6)
	var email = emails[randid]
	var reponse = responses[randid]
	$Subject/Label.text = email.Subject
	$Body/Label.text = email.Body
	for i in range(1, 4):
		var but : Button = EMAIL_BUTTON.instantiate()
		but.text = reponse[i]
		$Left/ItemList/Page/VBoxContainer.add_child(but)
		but.pressed.connect(func():
			if not cooldown:
				cooldown = true
				if i == reponse.Correct:
					if not win:
						win = true
						GameManager.gameWin()
					but.add_theme_color_override("font_color", Color(0.0, 0.78, 0.0, 1.0))
				else:
					get_tree().get_first_node_in_group("wrongsfx").play()
					but.add_theme_color_override("font_color", Color(0.569, 0.0, 0.0, 1.0))
				await get_tree().create_timer(2).timeout
				cooldown = false
				
		)
		
	
	
