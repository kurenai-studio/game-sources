extends Camera2D

@onready var player = $"../Player"
@onready var targetOffset = Vector2.ZERO
@onready var targetXPos;
@onready var xoffset = 60.0
@onready var moveX = true
@onready var moveY = false

@onready var isChangingRoom = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.position.y = 325.0
	targetXPos = player.position.x

func _physics_process(delta: float) -> void:
	if isChangingRoom: return
	if moveY and not Global.playerInCamlockYArea:
		self.position.y = lerp(self.position.y, player.position.y, 10.0 * delta)
		
	if moveX and not Global.playerInCamlockXArea:
		var playerVelo = Global.player.velocity
		if abs(playerVelo.x) >= 500.0:
			targetOffset = sign(playerVelo.x) * xoffset
		
			targetXPos = player.position.x + targetOffset
			
		self.position.x = lerp(self.position.x, targetXPos, 10.0 * delta)

		targetOffset *= 0
