extends RefCounted
const WEIGHTS := [0.35,0.27,0.20,0.13,0.05]
const FACTORY := [80,85,88,90,92]

func targets() -> Dictionary:
	var ordered := {}
	var pairs := {}
	for first in range(5):
		for second in range(5):
			if first != second:
				ordered["%d-%d" % [first+1,second+1]] = WEIGHTS[first] * WEIGHTS[second] / (1.0 - WEIGHTS[first])
	for first in range(5):
		for second in range(first+1,5):
			var key := "%d-%d" % [first+1,second+1]
			pairs[key] = ordered[key] + ordered["%d-%d" % [second+1,first+1]]
	return {"first":WEIGHTS.duplicate(),"ordered":ordered,"pairs":pairs,"basis":"Plackett-Luce reference targets, not measured movement outcomes"}

func board(rtp_percent: int = 90, permutation: Array = [0,1,2,3,4]) -> Dictionary:
	assert(rtp_percent >= 70 and rtp_percent <= 200)
	assert(permutation.size() == 5)
	for horse in range(5):
		assert(permutation.count(horse) == 1)
	var reference := targets()
	var payouts := {}
	var probabilities := {}
	var effective := {}
	var first_targets := [0.0,0.0,0.0,0.0,0.0]
	for first in range(5):
		first_targets[permutation[first]] = WEIGHTS[first]
		for second in range(first+1,5):
			var labels := [permutation[first]+1,permutation[second]+1]
			labels.sort()
			var key := "%d-%d" % labels
			var probability: float = reference.pairs["%d-%d" % [first+1,second+1]]
			probabilities[key] = probability
			payouts[key] = clampi(roundi(float(rtp_percent)/100.0/probability),2,200)
			effective[key] = probability * payouts[key]
	return {"schema":1,"payouts":payouts,"pair_targets":probabilities,"first_targets":first_targets,"effective_target_rtp":effective,"requested_rtp":rtp_percent,"permutation":permutation.duplicate(),"calibrated":false,"payout_semantics":"total return including original stake"}

func encoded_version(rtp_percent: int, custom: bool) -> String:
	return "V2.%d%03d54" % [2 if custom else 1, rtp_percent]
