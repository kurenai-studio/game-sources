extends "res://core/effort_race_engine.gd"
# Test-only candidate. A 256-bit master is retained as hex, never converted to a JSON number.
var master_seed: String
static func fresh_seed(mouse_activity_digest: String = "") -> String:
	var entropy := Crypto.new().generate_random_bytes(32)
	assert(entropy.size() == 32)
	var supplemental := "%d:%s:%d:%s" % [Time.get_ticks_usec(),str(Time.get_unix_time_from_system()),OS.get_process_id(),mouse_activity_digest]
	return ("DerbySeed:v1:"+entropy.hex_encode()+":"+supplemental).sha256_text()
func _init(master: String, configuration: Dictionary = {}) -> void:
	assert(master.length() == 64 and master.is_valid_hex_number(false))
	master_seed = master.to_lower()
	super(0,configuration)
	var stream = preload("res://tools/audit_crypto_stream.gd")
	_scheduler = stream.new(master_seed,"scheduler")
	for horse in range(5):
		_streams[horse] = stream.new(master_seed,"horse:%d" % horse)
		_effort[horse] = 0.45+0.4*_streams[horse].unit()
func _seal() -> void:
	super()
	_result.seed = master_seed
	_result.model_version = "audit-only-sha256-counter-streams"
