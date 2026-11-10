extends Object
class_name MerchantGuild

const ESSENCE_TO_GOLD_RATE = 500

static func get_sell_price_bonus(hero: Hero) -> float:
	if hero.guild_joined != &"mercadores":
		return 0.40
	return 0.60

static func get_auction_slots_bonus(hero: Hero) -> int:
	if hero.guild_joined != &"mercadores":
		return 0
	return 4

static func apply_loan(hero: Hero, amount: int) -> bool:
	if hero.guild_joined != &"mercadores":
		return false
	if hero.gold + amount > 100000:
		return false
	hero.gold += amount
	return true

static func exchange_essence_for_gold(hero: Hero, essencia: int) -> int:
	if hero.guild_joined != &"mercadores":
		return 0
	if hero.essence < essencia:
		return 0
	var ouro = essencia * ESSENCE_TO_GOLD_RATE
	hero.essence -= essencia
	hero.gold += ouro
	return ouro
