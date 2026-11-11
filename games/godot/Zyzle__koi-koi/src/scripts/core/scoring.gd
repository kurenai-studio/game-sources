class_name Scoring

enum YAKU_TYPE {
	FIVE_BRIGHT,
	RED_POETRY_BLUE_TANZAKU,
	DRY_FOUR_BRIGHT,
	RAINY_FOUR_BRIGHT,
	DRY_THREE_BRIGHT,
	MOON_VIEWING,
	FLOWER_VIEWING,
	BOAR_DEER_BUTTERFLY,
	RED_POETRY_TANZAKU,
	BLUE_TANZAKU,
	TANE,
	TANZAKU,
	KASU,
	# Instant win yakus (not scored normally)
	TESHI,
	KUTTSUKI
}

const YAKU_NAMES_MAP: Dictionary[YAKU_TYPE, Array] = {
	YAKU_TYPE.FIVE_BRIGHT: ["Five Brights", "(五光)"],
	YAKU_TYPE.RED_POETRY_BLUE_TANZAKU: ["Red Poetry & Blue Tanzaku", "(赤短・青短の重複)"],
	YAKU_TYPE.DRY_FOUR_BRIGHT: ["Dry Four Brights", "(四光)"],
	YAKU_TYPE.RAINY_FOUR_BRIGHT: ["Rainy Four Brights", "(雨四光)"],
	YAKU_TYPE.DRY_THREE_BRIGHT: ["Dry Three Brights", "(三光)"],
	YAKU_TYPE.MOON_VIEWING: ["Moon Viewing", "(月見酒)"],
	YAKU_TYPE.FLOWER_VIEWING: ["Flower Viewing", "(花見酒)"],
	YAKU_TYPE.BOAR_DEER_BUTTERFLY: ["Boar, Deer, Butterfly", "(猪鹿蝶)"],
	YAKU_TYPE.RED_POETRY_TANZAKU: ["Red Poetry Tanzaku", "(赤短)"],
	YAKU_TYPE.BLUE_TANZAKU: ["Blue Tanzaku", "(青短)"],
	YAKU_TYPE.TANE: ["Tane", "(タネ)"],
	YAKU_TYPE.TANZAKU: ["Tanzaku", "(短冊)"],
	YAKU_TYPE.KASU: ["Kasu", "(カス)"],
	YAKU_TYPE.TESHI: ["Teshi (Instant Win)", "(手四)"],
	YAKU_TYPE.KUTTSUKI: ["Kuttsuki (Instant Win)", "(くっつき)"]
}

class ScoreResult:
	var total_score: int
	var yaku_achieved: Array[YAKU_TYPE]
	var yaku_cards: Dictionary[YAKU_TYPE, Array]


	func _to_string() -> String:
		return "ScoreResult(total_score=%d, yaku_achieved=%s)" % [total_score, yaku_achieved]


static func check_instant_hand_win(hand_cards: Array[Card]) -> ScoreResult:
	var month_counts = {}

	for card in hand_cards:
		month_counts[card.month] = month_counts.get(card.month, 0) + 1

	for month in month_counts.keys():
		if month_counts[month] == 4:
			var score_details = ScoreResult.new()
			score_details.total_score = 6
			score_details.yaku_achieved = [YAKU_TYPE.TESHI]
			score_details.yaku_cards[YAKU_TYPE.TESHI] = hand_cards.filter(func(card: Card):
				return card.month == month
			)
			return score_details

	var num_pairs = month_counts.values().filter(func(count: int):
		return count == 2
	).size()

	if num_pairs == 4:
		var score_details = ScoreResult.new()
		score_details.total_score = 6
		score_details.yaku_achieved = [YAKU_TYPE.KUTTSUKI]
		var kuttsuki_cards = []
		for month in month_counts.keys():
			if month_counts[month] == 2:
				kuttsuki_cards += hand_cards.filter(func(card: Card):
					return card.month == month
				)
		score_details.yaku_cards[YAKU_TYPE.KUTTSUKI] = kuttsuki_cards
		return score_details

	return null


static func calculate_score(captured_cards: Array[Card]) -> ScoreResult:
	var score_details = ScoreResult.new()
	
	var type_counts = {
		Card.CardType.BRIGHT: 0,
		Card.CardType.RIBBON: 0,
		Card.CardType.ANIMAL: 0,
		Card.CardType.PLAIN: 0
	}
	
	var bright_cards = []
	var ribbon_cards = []
	var animal_cards = []

	for card in captured_cards:
		type_counts[card.type] += 1
		match card.type:
			Card.CardType.BRIGHT:
				bright_cards.append(card)
			Card.CardType.RIBBON:
				ribbon_cards.append(card)
			Card.CardType.ANIMAL:
				animal_cards.append(card)

	# Special cards presence
	var has_sake_cup = captured_cards.find_custom(func(card: Card):
		return card.month == 9 and card.number == 4
	) != -1

	var has_boar = animal_cards.find_custom(func(card: Card):
		return card.month == 7 and card.number == 4
	) != -1

	var has_deer = animal_cards.find_custom(func(card: Card):
		return card.month == 10 and card.number == 4
	) != -1

	var has_butterfly = animal_cards.find_custom(func(card: Card):
		return card.month == 6 and card.number == 4
	) != -1

	var has_cherry_blossom = bright_cards.find_custom(func(card: Card):
		return card.month == 3 and card.number == 4
	) != -1

	var has_moon = bright_cards.find_custom(func(card: Card):
		return card.month == 8 and card.number == 4
	) != -1

	var has_rain_man = bright_cards.find_custom(func(card: Card):
		return card.month == 11 and card.number == 4
	) != -1
	
	
	# Kasu
	if type_counts[Card.CardType.PLAIN] >= 10 or (has_sake_cup and type_counts[Card.CardType.PLAIN] >= 9):
		score_details.total_score += 1

		if has_sake_cup:
			score_details.total_score += type_counts[Card.CardType.PLAIN] - 9
		else:
			score_details.total_score += max(type_counts[Card.CardType.PLAIN] - 10, 0)

		score_details.yaku_achieved.append(YAKU_TYPE.KASU)
		score_details.yaku_cards[YAKU_TYPE.KASU] = captured_cards.filter(func(card: Card):
			return card.type == Card.CardType.PLAIN or (has_sake_cup and card.month == 9 and card.number == 4)
		)

	# Tanzaku
	if type_counts[Card.CardType.RIBBON] >= 5:
		score_details.total_score += type_counts[Card.CardType.RIBBON] - 4
		score_details.yaku_achieved.append(YAKU_TYPE.TANZAKU)
		score_details.yaku_cards[YAKU_TYPE.TANZAKU] = captured_cards.filter(func(card: Card):
			return card.type == Card.CardType.RIBBON
		)

	# Tane
	if type_counts[Card.CardType.ANIMAL] >= 5:
		score_details.total_score += type_counts[Card.CardType.ANIMAL] - 4
		score_details.yaku_achieved.append(YAKU_TYPE.TANE)
		score_details.yaku_cards[YAKU_TYPE.TANE] = captured_cards.filter(func(card: Card):
			return card.type == Card.CardType.ANIMAL
		)

	# Aotan
	if ribbon_cards.size() >= 3:
		var num_blue = ribbon_cards.filter(func(card: Card):
			return card.month in [6, 9, 10]
		).size()

		if num_blue == 3:
			score_details.total_score += 5
			score_details.yaku_achieved.append(YAKU_TYPE.BLUE_TANZAKU)
			score_details.yaku_cards[YAKU_TYPE.BLUE_TANZAKU] = captured_cards.filter(func(card: Card):
				return card.month in [6, 9, 10] and card.type == Card.CardType.RIBBON
			)

	# Akatan
	if ribbon_cards.size() >= 3:
		var num_red = ribbon_cards.filter(func(card: Card):
			return card.month in [1, 2, 3]
		).size()

		if num_red == 3:
			score_details.total_score += 5
			score_details.yaku_achieved.append(YAKU_TYPE.RED_POETRY_TANZAKU)
			score_details.yaku_cards[YAKU_TYPE.RED_POETRY_TANZAKU] = captured_cards.filter(func(card: Card):
				return card.month in [1, 2, 3] and card.type == Card.CardType.RIBBON
			)

	# Boar, Deer, Butterfly
	if has_boar and has_deer and has_butterfly:
		score_details.total_score += 5
		score_details.yaku_achieved.append(YAKU_TYPE.BOAR_DEER_BUTTERFLY)
		score_details.yaku_cards[YAKU_TYPE.BOAR_DEER_BUTTERFLY] = captured_cards.filter(func(card: Card):
			return (card.month == 7 and card.number == 4) or (card.month == 10 and card.number == 4) or (card.month == 6 and card.number == 4)
		)

	# Flower Viewing
	if has_cherry_blossom and has_sake_cup:
		score_details.total_score += 5
		score_details.yaku_achieved.append(YAKU_TYPE.FLOWER_VIEWING)
		score_details.yaku_cards[YAKU_TYPE.FLOWER_VIEWING] = captured_cards.filter(func(card: Card):
			return (card.month == 3 and card.number == 4) or (card.month == 9 and card.number == 4)
		)

	# Moon Viewing
	if has_moon and has_sake_cup:
		score_details.total_score += 5
		score_details.yaku_achieved.append(YAKU_TYPE.MOON_VIEWING)
		score_details.yaku_cards[YAKU_TYPE.MOON_VIEWING] = captured_cards.filter(func(card: Card):
			return (card.month == 8 and card.number == 4) or (card.month == 9 and card.number == 4)
		)

	# dry 3 bright
	if bright_cards.size() == 3 and not has_rain_man:
		score_details.total_score += 5
		score_details.yaku_achieved.append(YAKU_TYPE.DRY_THREE_BRIGHT)
		score_details.yaku_cards[YAKU_TYPE.DRY_THREE_BRIGHT] = captured_cards.filter(func(card: Card):
			return card.type == Card.CardType.BRIGHT
		)

	# dry/rainy 4 bright
	if bright_cards.size() == 4:
		if has_rain_man:
			score_details.total_score += 7
			score_details.yaku_achieved.append(YAKU_TYPE.RAINY_FOUR_BRIGHT)
		else:
			score_details.total_score += 8
			score_details.yaku_achieved.append(YAKU_TYPE.DRY_FOUR_BRIGHT)
		score_details.yaku_cards[score_details.yaku_achieved[-1]] = captured_cards.filter(func(card: Card):
			return card.type == Card.CardType.BRIGHT
		)

	# 5 bright
	if bright_cards.size() == 5:
		score_details.total_score += 10
		score_details.yaku_achieved.append(YAKU_TYPE.FIVE_BRIGHT)
		score_details.yaku_cards[YAKU_TYPE.FIVE_BRIGHT] = captured_cards.filter(func(card: Card):
			return card.type == Card.CardType.BRIGHT
		)

	return score_details