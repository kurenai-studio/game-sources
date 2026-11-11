extends "res://core/effort_race_engine.gd"
# Isolated diagnostic candidate. Neither playable scene loads this script.
# Only domain-separate the random stream seeds; movement and 10x timing are inherited.
static func domain_seed(seed_value: int, domain: String) -> int:
	var bytes := ("DerbyAudit:v1:%d:%s" % [seed_value,domain]).sha256_buffer()
	return int(bytes.decode_u32(0))

func _init(seed_value: int, configuration: Dictionary = {}) -> void:
	super(seed_value,configuration)
	_scheduler = RandomStream.new(domain_seed(seed_value,"scheduler"))
	for horse in range(5):
		_streams[horse] = RandomStream.new(domain_seed(seed_value,"horse:%d" % horse))
		_effort[horse] = 0.45+0.4*_streams[horse].unit()
