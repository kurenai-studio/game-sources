extends RefCounted
# Call only when an authorized Start Race action is accepted. No predictable fallback.
# Coordinates supplement OS randomness; only their running digest is retained.
var _activity_digest := ""
func observe_pointer(position: Vector2) -> void:
	_activity_digest=("%s:%s:%s:%d" % [_activity_digest,str(position.x),str(position.y),Time.get_ticks_usec()]).sha256_text()
func new_seed() -> String:
	var entropy := Crypto.new().generate_random_bytes(32)
	if entropy.size()!=32:
		push_error("Operating-system random source unavailable; race must not start")
		return ""
	return mix(entropy,Time.get_ticks_usec(),str(Time.get_unix_time_from_system()),OS.get_process_id(),_activity_digest)
func mix(entropy: PackedByteArray, ticks: int, wall_time: String, process_id: int, activity: String) -> String:
	assert(entropy.size()==32)
	return ("DerbySeed:v2:%s:%d:%s:%d:%s" % [entropy.hex_encode(),ticks,wall_time,process_id,activity]).sha256_text()
