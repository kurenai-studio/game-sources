extends RefCounted
class_name GuildLog

var hero: Hero

const RANK_ORDER = ["F", "E", "D", "C", "B", "A", "S"]

func _init(p_hero: Hero) -> void:
	hero = p_hero

func join_guild(guild_id: StringName) -> bool:
	if hero.guild_joined != &"":
		return false  # Já membro
	var guild = Guilds.get_guild(guild_id)  # API estática de core/guilds.gd (class_name Guilds)
	if not guild:
		return false
	hero.guild_joined = guild_id
	hero.guild_rank = "F"
	hero.guild_xp = 0
	return true

func leave_guild() -> bool:
	hero.guild_joined = &""
	hero.guild_rank = "F"
	hero.guild_xp = 0
	hero.contracts_active.clear()
	return true

func get_rank() -> String:
	return hero.guild_rank if hero.guild_rank else "F"

func add_xp(amount: int) -> void:
	hero.guild_xp += amount
	_check_rank_up()

func complete_contract(contract_id: StringName) -> void:
	hero.contracts_active.erase(contract_id)
	hero.contracts_completed += 1

func _check_rank_up() -> void:
	# Verifica se deve subir de rank baseado em conquistas
	RankSystem.check_advancement(hero)
