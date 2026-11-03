class_name LevelStats
extends RefCounted

var score: int
var kerno_dropped: int
var total_merges: int
var hp_left: int
var merges_per_tier: Dictionary

func _init():
    reset()

func reset():
    score = 0
    kerno_dropped = 0
    total_merges = 0
    hp_left = 0
    merges_per_tier = {}

func add_score(amount: int):
    score += amount

func add_kerno_dropped():
    kerno_dropped += 1

func add_merge(tier: int):
    total_merges += 1
    if not merges_per_tier.has(tier):
        merges_per_tier[tier] = 0
    merges_per_tier[tier] += 1

func set_hp_left(amount: int):
    hp_left = amount

func to_dict() -> Dictionary:
    return {
        "score": score,
        "kerno_dropped": kerno_dropped,
        "total_merges": total_merges,
        "hp_left": hp_left,
        "merges_per_tier": merges_per_tier
    }

func to_rich_text() -> String:
    var out = "Score: " + str(score) + "\n"
    out += "Kernoj Dropped: " + str(kerno_dropped) + "\n"
    out += "Merges: " + str(total_merges) + "\n"
    out += "HP Left: " + str(hp_left) + "\n"
    out += "Merges Per Tier: " + str(merges_per_tier) + "\n"
    return out
