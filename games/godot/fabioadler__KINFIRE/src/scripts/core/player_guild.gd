extends RefCounted
class_name PlayerGuild

class Member:
	var hero_id: StringName
	var rank: String
	var joined_at: float
	
	func _init(p_hero_id: StringName = &"", p_rank: String = "membro") -> void:
		hero_id = p_hero_id
		rank = p_rank
		joined_at = Time.get_ticks_msec() / 1000.0

class Bank:
	var slots: Array[Item] = []
	var slots_max: int = 50
	
	func add_item(item: Item) -> bool:
		if slots.size() >= slots_max:
			return false
		slots.append(item)
		return true
	
	func remove_item(item: Item) -> bool:
		var idx := slots.find(item)
		if idx < 0:
			return false
		slots.remove_at(idx)
		return true
	
	func get_slots_used() -> int:
		return slots.size()

var id: StringName
var display_name: String
var tag: String
var mestre: StringName
var oficiais: Array[StringName] = []
var membros: Array[Member] = []
var bank: Bank
var xp: int = 0
var nivel: int = 1
var created_at: float

func _init(p_name: String = "", p_tag: String = "") -> void:
	display_name = p_name
	tag = p_tag
	bank = Bank.new()
	created_at = Time.get_ticks_msec() / 1000.0

static func create(founder: Hero, name: String, tag: String) -> PlayerGuild:
	if founder.level < 25 or founder.gold < 5000:
		return null
	
	var guild = PlayerGuild.new(name, tag)
	guild.id = StringName("%s_%d" % [name.to_lower(), Time.get_ticks_msec()])
	guild.mestre = founder.id
	
	var member = Member.new()
	member.hero_id = founder.id
	member.rank = "mestre"
	member.joined_at = Time.get_ticks_msec() / 1000.0
	guild.membros.append(member)
	
	founder.gold -= 5000
	founder.player_guild_id = guild.id
	
	return guild

func can_leave(hero: Hero) -> bool:
	return hero.id != mestre

func set_mestre(hero: Hero) -> bool:
	mestre = hero.id
	for member in membros:
		if member.hero_id == hero.id:
			member.rank = "mestre"
		elif member.rank == "mestre":
			member.rank = "oficial"
	return true
