extends CharacterBody2D
class_name Player

signal high_damage()
signal died()
signal level_up(level: int)

enum LevelUpChoiceType{
	HEALTH_UP,
	DAMAGE_UP,
	ADD_AXES,
	HIGH_DAMAGE_UP
}

const axe_inst: PackedScene = preload("res://Scene/axe.tscn")

# 配置数据（游戏启动时由 Config 一次性写入，见 _apply_config）
var SPEED: float
var RECOVERY_SPEED: float
var DAMAGED_SPEED_FACTOR: float
var LOW_HEALTH_THRESHOLD: float
var BLINK_TIMES: int
var BLINK_INTERVAL: float

var LEVEL_UP_XP: Array
var HEALTH_BAR_MAX: Array
var LEVEL_EXP_BAR_MAX: Array
var LEVEL_UP_CHOICES: Array

#player game properties
@export_group("Properties")
var health: int = 12:
	set(v):
		health=clamp(v,0.0,health_bar.max_value)
		health_bar.value=v
		var t=create_tween()
		t.tween_property(health_bar, "value", v, 0.2).set_ease(Tween.EASE_OUT)
		t.tween_property(health_bar_eased, "value", v, 0.4).set_ease(Tween.EASE_OUT)
var experience: float = 0.0:
	set(v):
		experience = v
		create_tween().tween_property($StandaloneLayer/UI/H/V/ExperienceBar, "value", v, 0.2).set_ease(Tween.EASE_IN)
var axe_rotate_speed: float = PI * 1.5
var axe_count: int = 1
var base_damage: float = 2.0
var high_damage_rate: float = 1.5
var high_damage_chance: float = 0.12
var recovery_time: float = 1.0
var invincible_time:float = 5.0

var damaged: bool = false
#var game_level: int = 1
var dying: bool = false
var level_up_vals:=[]
var choice:int
var selected:bool=false
var selecting:bool=false
var invincible:bool=false
var explosion:bool=false

@onready var animation: AnimationPlayer = $Animation
@onready var sprite: Sprite2D = $Texture
@onready var camera: = $"../PhantomCamera2D"
@onready var axes: Node2D = $Axes
@onready var invincible_bar: ProgressBar = $ProgressBar
@onready var shader := $StandaloneLayer/Vignette.material as ShaderMaterial
@onready var health_bar: TextureProgressBar = $StandaloneLayer/UI/H/V/H/HealthBar
@onready var health_bar_eased: TextureProgressBar = $StandaloneLayer/UI/H/V/H/HealthBar/HealthBarEased
@onready var experience_bar: TextureProgressBar = $StandaloneLayer/UI/H/V/ExperienceBar
@onready var crit_label: Label = $StandaloneLayer/UI/Label
@onready var mask: TextureRect = $StandaloneLayer/Mask
@onready var game_over_label: Label = $StandaloneLayer/Label
@onready var level_label: Label = $StandaloneLayer/UI/H/V/H/Label
@onready var item_1: Button = $StandaloneLayer/SelectPanel/H/Button1
@onready var item_2: Button = $StandaloneLayer/SelectPanel/H/Button2
@onready var item_3: Button = $StandaloneLayer/SelectPanel/H/Button3
@onready var game: Node2D = $".."
@onready var enemies: EnemySpawner = $"../Enemies"
@onready var phantom_camera_2d: PhantomCamera2D = $"../PhantomCamera2D"



func _ready() -> void:
	$StandaloneLayer/UI/H.modulate.a=0.0
	_apply_config()
	get_tree().paused = false
	update_axes.call_deferred()
	for bar in [health_bar, health_bar_eased]:
		bar.max_value = health
		bar.value = health
	experience_bar.max_value = Config.data["player"]["exp_bar_initial_max"]
	level_up.connect(_on_level_up)
	phantom_camera_2d.append_follow_targets(self)
	$InvincibleTimer.timeout.connect(func ():
		invincible=false
		create_tween().tween_property($InvincibleCover,"modulate:a",0.0,0.2)
		)
	game.game_started.connect(func():
		get_tree().create_tween().tween_property($StandaloneLayer/UI/H,"modulate:a",1.0,0.4)
		)
	


func _apply_config() -> void:
	var c: Dictionary = Config.data["player"]
	SPEED = c["speed"]
	RECOVERY_SPEED = c["recovery_speed"]
	DAMAGED_SPEED_FACTOR = c["damaged_speed_factor"]
	LOW_HEALTH_THRESHOLD = c["low_health_threshold"]
	BLINK_TIMES = int(c["blink_times"])
	BLINK_INTERVAL = c["blink_interval"]
	LEVEL_UP_XP = c["level_up_xp"]
	HEALTH_BAR_MAX = c["health_bar_max"]
	LEVEL_EXP_BAR_MAX = c["level_exp_bar_max"]
	LEVEL_UP_CHOICES = []
	for entry in c["level_up_choices"]:
		LEVEL_UP_CHOICES.append([int(entry[0]), entry[1]])
	health = int(c["health"])
	experience = c["experience"]
	axe_rotate_speed = c["axe_rotate_speed"]
	axe_count = int(c["axe_count"])
	base_damage = c["base_damage"]
	high_damage_rate = c["high_damage_rate"]
	high_damage_chance = c["high_damage_chance"]
	recovery_time = c["recovery_time"]
	invincible_time = c["invincible_time"]


func _process(delta: float) -> void:
	if selecting:
		return
	_update_vignette_pulse()
	if dying:
		return
	_update_game_level()


func _physics_process(delta: float) -> void:
	if dying or selecting or (not game.started):
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		var speed := move_toward(velocity.length(),SPEED * (DAMAGED_SPEED_FACTOR if damaged else 1.0),SPEED*0.1)
		velocity = speed * dir
		_face_direction()
	else:
		velocity.x=move_toward(velocity.x,0,SPEED*0.1)
		velocity.y=move_toward(velocity.y,0,SPEED*0.1)
		animation.play("RESET")
	move_and_slide()




func apply_buff(property: StringName, value: Variant) -> void:
	set(property, value)
	if property == &"axe_rotate_speed" or property == &"axe_count":
		update_axes.call_deferred()
	if property == &"invincible":
		create_tween().tween_property($InvincibleCover,"modulate:a",0.5,0.2)
		$InvincibleTimer.wait_time=invincible_time
		$InvincibleTimer.start()
	if property == &"explosion":
		for enemy:Enemy in enemies.get_children():
			var dist:=(enemy.global_position-global_position).length_squared()
			if dist <= 14400.0:
				var damage := 5.0
				enemy.take_hit(damage, true)
				shock_camera(Config.data["axe"]["hit_camera_shake"])
				SoundManager.play_sound("laser", "enemy")
				notify_high_damage()
		$ExplosionCover.modulate.a=0.7
		create_tween().tween_property($ExplosionCover,"modulate:a",0.0,0.3)
		



func get_damage(amount: int) -> void:
	if dying or damaged or invincible:
		return
	damaged = true
	health -= amount
	_play_hurt_feedback()
	if health <= 0:
		die()


func shock_camera(amount: float) -> void:
	phantom_camera_2d.noise.amplitude=amount*10.0
	create_tween().tween_property(phantom_camera_2d,"noise:amplitude",0.0,0.5)


func notify_high_damage() -> void:
	high_damage.emit()


func update_axes() -> void:
	if axes.get_child_count() < axe_count:
		for i in range(axe_count - axes.get_child_count()):
			axes.add_child(axe_inst.instantiate())
		_configure_axes(true)
	else:
		_configure_axes(false)


func die() -> void:
	dying = true
	animation.play("dying")
	await get_tree().create_timer(0.7).timeout
	var t = create_tween()
	t.tween_property(mask, "modulate:a", 0.5, 0.2)
	t.tween_property(game_over_label, "visible_characters", 4, 0.4)
	await get_tree().create_timer(0.6).timeout
	get_tree().paused = true
	died.emit()


func _face_direction() -> void:
	var anim := ""
	if velocity.y > 0:
		anim = "down"
	elif velocity.y < 0:
		anim = "up"
	elif velocity.x > 0:
		anim = "right"
	elif velocity.x < 0:
		anim = "left"
	if animation.current_animation != anim:
		animation.play(anim)


func _update_vignette_pulse() -> void:
	if health <= LOW_HEALTH_THRESHOLD and health > 0.0:
		shader.set_shader_parameter("alpha", sin(Time.get_ticks_msec() * 0.01) * 0.7 + 0.7)
	else:
		shader.set_shader_parameter("alpha", 0.0)




func _update_game_level() -> void:
	while GameManager.game_level <= LEVEL_UP_XP.size() and experience >= LEVEL_UP_XP[GameManager.game_level - 1]:
		GameManager.game_level += 1
		level_label.text="Lv."+str(GameManager.game_level)
		experience_bar.max_value = LEVEL_EXP_BAR_MAX[GameManager.game_level - 2]
		for bar:TextureProgressBar in [health_bar,health_bar_eased]:
			bar.max_value=HEALTH_BAR_MAX[GameManager.game_level - 2]
		level_up.emit(GameManager.game_level)


func _play_hurt_feedback() -> void:
	SoundManager.play_sound("pain", "player")
	_spawn_hurt_clone_flash()
	await _blink_red()
	_run_invincibility_drain()


func _spawn_hurt_clone_flash() -> void:
	var tex_alt := sprite.duplicate() as Sprite2D
	tex_alt.position = sprite.position
	add_child(tex_alt)
	var t1 := create_tween()
	t1.tween_property(tex_alt, "modulate:a", 0.0, 0.3)
	t1.parallel().tween_property(tex_alt, "scale", Vector2.ONE * 1.5, 0.3)
	t1.tween_callback(tex_alt.queue_free)


func _blink_red() -> void:
	for i in range(BLINK_TIMES):
		sprite.modulate = Color.RED
		await get_tree().create_timer(BLINK_INTERVAL).timeout
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(BLINK_INTERVAL).timeout


func _run_invincibility_drain() -> void:
	invincible_bar.value = 0.0
	invincible_bar.visible = true
	var t = get_tree().create_tween()
	t.tween_property(invincible_bar, "value", 100.0, recovery_time)
	t.tween_property(self, "damaged", false, 0.0)
	t.tween_property(invincible_bar, "visible", false, 0.0)


func _configure_axes(rephase: bool) -> void:
	var ct: int = 0
	for a: Axe in axes.get_children():
		a.player = self
		a.rotate_speed = axe_rotate_speed
		a.BASE_DAMAGE=base_damage
		if rephase:
			a.angular = TAU / axe_count * ct
		ct += 1


func _on_high_damage() -> void:
	if dying:
		return
	var clone_body := crit_label.duplicate(DuplicateFlags.DUPLICATE_USE_INSTANTIATION) as Label
	clone_body.modulate.a = 0.0
	clone_body.offset_transform_scale = Vector2.ONE * 0.4
	clone_body.offset_transform_position = Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	crit_label.get_parent().add_child(clone_body)
	var t := create_tween()
	t.tween_property(clone_body, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(clone_body, "offset_transform_scale", Vector2.ONE * 0.95, 0.3)
	t.tween_property(clone_body, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(clone_body, "offset_transform_scale", Vector2.ONE * 1.5, 0.3)
	t.tween_callback(clone_body.queue_free)

func _on_level_up(level:int):
	var choices:Array=[]
	for a in LEVEL_UP_CHOICES:
		choices.append(a)
	choices.shuffle()
	for a in [item_1,item_2,item_3]:
		var rand:Array= choices[0]
		choices.remove_at(0)
		level_up_vals.append(rand)
		match(rand[0]):
			LevelUpChoiceType.HEALTH_UP:
				a.text="生命值提升至100%"
			LevelUpChoiceType.DAMAGE_UP:
				a.text="攻击力提升1.5"
			LevelUpChoiceType.ADD_AXES:
				a.text="增加一个武器"
			LevelUpChoiceType.HIGH_DAMAGE_UP:
				a.text="暴击伤害倍率提升100%"
	get_tree().paused=true
	selecting=true
	var t:= create_tween()
	t.tween_property(mask,"modulate:a",0.5,0.5)
	$StandaloneLayer/SelectPanel.show()
	t.tween_property($StandaloneLayer/SelectPanel,"modulate:a",1.0,0.2)

func select_level_up_buff(c:int):
	if selected:
		return
	selected=true
	var cho=level_up_vals[c]
	match(cho[0]):
		LevelUpChoiceType.HEALTH_UP:
			health=health_bar.max_value*cho[1]
		LevelUpChoiceType.DAMAGE_UP:
			base_damage+=cho[1]
			update_axes()
		LevelUpChoiceType.ADD_AXES:
			axe_count+=1
			update_axes()
		LevelUpChoiceType.HIGH_DAMAGE_UP:
			high_damage_rate+=cho[1]
	var t=create_tween()
	t.tween_property($StandaloneLayer/SelectPanel,"modulate:a",0.0,0.2)
	$StandaloneLayer/SelectPanel.hide()
	t.tween_property($StandaloneLayer/Mask,"modulate:a",0.0,0.5)
	selected=false
	level_up_vals.clear()
	t.tween_property(get_tree(),"paused",false,0.0)
	selecting=false

func _on_label1_gui_input():
	if not selecting:
		return
	choice=0
	select_level_up_buff(choice)

func _on_label2_gui_input():
	if not selecting:
		return
	choice=1
	select_level_up_buff(choice)

func _on_label3_gui_input():
	if not selecting:
		return
	choice=2
	select_level_up_buff(choice)
