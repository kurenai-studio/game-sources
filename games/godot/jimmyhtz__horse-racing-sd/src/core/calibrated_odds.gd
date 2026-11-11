extends RefCounted
const Stream = preload("res://core/crypto_stream.gd")
const Entropy = preload("res://core/race_entropy.gd")
const Deck = preload("res://core/card_deck.gd")
const PAIRS := [[0,1],[0,2],[0,3],[0,4],[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
static var _catalog: Dictionary = {}

static func _load_catalog() -> void:
	if _catalog.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/payback_v1.json"))
		assert(parsed is Dictionary and parsed.schema == 1)
		_catalog=parsed

static func internal_catalog() -> Dictionary:
	_load_catalog()
	return _catalog.duplicate(true)

static func valid_permutation(value: Variant) -> bool:
	if not value is Array or value.size()!=5:
		return false
	for h in range(5):
		if not value[h] is int or value.count(h)!=1:
			return false
	return true

func board(percent: int=90, permutation: Array=[0,1,2,3,4]) -> Dictionary:
	assert(percent>=70 and percent<=200 and valid_permutation(permutation))
	_load_catalog()
	var card: Dictionary=_catalog.cards[str(percent)]
	var payouts := {}
	for i in range(10):
		var labels := [permutation[PAIRS[i][0]]+1,permutation[PAIRS[i][1]]+1]
		labels.sort()
		payouts["%d-%d" % labels]=int(card.payoffs[i])
	return {"schema":2,"model_version":"positive-step-mixture-v1","payouts":payouts,
		"requested_rtp":percent,"permutation":permutation.duplicate(),"calibrated":true,
		"payout_semantics":"total return including original stake"}

func fresh_board(percent: int=90, mode: String="SD", history: Dictionary={}, previous: Dictionary={}) -> Dictionary:
	var master: String=Entropy.new().new_seed()
	if master.is_empty(): return {}
	return Deck.new().next_board(percent,mode,previous,Stream.new(master,"card-rotation-v1"),history)

static func catalog_for_board(value: Dictionary) -> Dictionary:
	var result:=internal_catalog()
	if value.get("schema")==3:
		var fitted: Dictionary=Deck.new().calibration(value)
		assert(not fitted.is_empty())
		result.cards[str(value.requested_rtp)]=fitted
	return result

func valid_board(value: Variant,percent: int) -> bool:
	if value is Dictionary and value.get("schema")==3: return Deck.new().valid_board(value,percent)
	if not value is Dictionary or percent<70 or percent>200 or value.get("schema")!=2:
		return false
	if not valid_permutation(value.get("permutation")):
		return false
	return value==board(percent,value.permutation)
