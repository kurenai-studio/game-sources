extends Area2D
class_name Item

enum ItemType{
	BLOOD_UP = 2,
	ADD_AXE = 7,
	ADD_ROTATE_SPEED = 4,
	ADD_HIGH_DAMAGE_RATE = 3,
	ADD_HIGH_DAMAGE_CHANCE = 1,
	INVINCIBLE = 0,
	EXPLOSION = 8
}
var chances: Array = []

var id:=ItemType.BLOOD_UP
var timer:float=0.0
static var inited:bool=false

static var _alias_prob: Array = []
static var _alias_target: Array = []
static var _item_types: Array = []

	# 初始化别名表（在游戏启动或权重变化时调用一次）
static func init_weighted_random(weights: Array) -> void:
	var n = weights.size()
	if n == 0:
		push_error("权重数组不能为空")
		return

	# 获取所有 ItemType 枚举值
	_item_types = []
	for i in range(n):
		_item_types.append(i as ItemType)  # 直接使用枚举索引值

	# 计算总权重
	var total = 0.0
	for w in weights:
		total += w

	# 归一化并缩放
	var scaled = []
	for w in weights:
		scaled.append(w * n / total)

	# 初始化概率和别名数组
	_alias_prob = []
	_alias_target = []
	for i in range(n):
		_alias_prob.append(1.0)
		_alias_target.append(i)

	# 分拆大块和小块
	var small = []
	var large = []
	for i in range(n):
		if scaled[i] < 1.0:
			small.append(i)
		else:
			large.append(i)

	# 构建别名表
	while small.size() > 0 and large.size() > 0:
		var s = small.pop_back()
		var l = large.pop_back()

		_alias_prob[s] = scaled[s]
		_alias_target[s] = l

		scaled[l] = scaled[l] - (1.0 - scaled[s])
		if scaled[l] < 1.0:
			small.append(l)
		else:
			large.append(l)	

	# 处理剩余项
	while large.size() > 0:
		_alias_prob[large.pop_back()] = 1.0
	while small.size() > 0:
		_alias_prob[small.pop_back()] = 1.0


static func pick_weighted() -> ItemType:
	if _item_types.size() == 0:
		push_error("请先调用 init_weighted_random() 初始化")
		return ItemType.BLOOD_UP  # 返回默认值

	var n = _item_types.size()
	var idx = randi() % n

	if randf() < _alias_prob[idx]:
		return _item_types[idx] as ItemType
	else:
		return _item_types[_alias_target[idx]] as ItemType
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chances = Config.data["item"]["chances"]
	if not inited:
		init_weighted_random(chances)
		inited=true
	id = pick_weighted()
	$Texture.frame=id
	$Texture.modulate.a=0.0
	create_tween().tween_property($Texture,"modulate:a",1.0,0.1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer+=delta
	if timer>=10.0:
		var t=create_tween()
		t.tween_property(self,"modulate:a",0.0,0.2)
		t.tween_callback(queue_free)



func buff(player:Player):
	var b: Dictionary = Config.data["item"]["buffs"]
	var property:StringName
	var amount:Variant
	match id:
		ItemType.INVINCIBLE:
			property="invincible"
			amount=true
		ItemType.BLOOD_UP:
			property="health"
			amount=(player.get("health")+b["blood_up"]) as float
		ItemType.ADD_AXE:
			property="axe_count"
			amount=(clamp(player.get("axe_count")+b["add_axe"],b["axe_count_min"],b["axe_count_max"])) as int
		ItemType.ADD_ROTATE_SPEED:
			property="axe_rotate_speed"
			amount=(clamp(player.get("axe_rotate_speed")+b["add_rotate_speed"],b["rotate_speed_min"],b["rotate_speed_max"])) as float
		ItemType.ADD_HIGH_DAMAGE_RATE:
			property="high_damage_rate"
			amount=(player.get("high_damage_rate")+b["add_high_damage_rate"]) as float
		ItemType.ADD_HIGH_DAMAGE_CHANCE:
			property="high_damage_chance"
			amount=(clamp(player.get("high_damage_chance")+b["add_high_damage_chance"],b["high_damage_chance_min"],b["high_damage_chance_max"])) as float
		ItemType.EXPLOSION:
			property="explosion"
			amount=true
	player.apply_buff(property,amount)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		buff(body)
		SoundManager.play_sound("pickup","item")
		var t=create_tween()
		t.tween_property(self,"scale",Vector2.ZERO,0.2)
		t.tween_callback(queue_free)
