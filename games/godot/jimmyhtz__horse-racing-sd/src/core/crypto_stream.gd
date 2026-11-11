extends RefCounted
# Deterministic cryptographic stream. Each block uses the entire master seed.
const RANGE := 4294967296
var _prefix: String
var _counter := 0
var _block := PackedByteArray()
var _offset := 32
func _init(master: String, domain: String) -> void:
	_prefix = "DerbyAudit:v3:%s:%s:" % [master,domain]
func raw() -> int:
	if _offset == 32:
		_block = (_prefix+str(_counter)).sha256_buffer()
		_counter += 1
		_offset = 0
	var value := int(_block.decode_u32(_offset))
	_offset += 4
	return value
func unit() -> float:
	return float(raw())/float(RANGE)
func index(count: int) -> int:
	assert(count > 0 and count < RANGE)
	var limit := RANGE-(RANGE%count)
	var draw := raw()
	while draw >= limit: draw = raw()
	return draw%count
func permutation(count: int) -> Array:
	var values := range(count)
	for i in range(count-1,0,-1):
		var j := index(i+1)
		var previous: int = values[i]
		values[i] = values[j]
		values[j] = previous
	return values
