extends RefCounted
## Separate salted PIN credentials. Local protection, not an operating-system security boundary.
const ITERATIONS := 10000
var credentials := {}
var _failures := {"operator":0,"rtp":0}
var _blocked_until := {"operator":0,"rtp":0}

func setup(operator_pin: String, rtp_pin: String) -> bool:
	if not credentials.is_empty() or not valid_pin(operator_pin) or not valid_pin(rtp_pin):
		return false
	for entry in [["operator",operator_pin],["rtp",rtp_pin]]:
		set_pin(entry[0],entry[1])
	return true

func valid_pin(pin: String) -> bool:
	return pin.length() == 4 and numeric(pin)

func numeric(pin: String) -> bool:
	if pin.is_empty():
		return false
	for character in pin:
		if character < "0" or character > "9":
			return false
	return true

func valid_domain(domain: String) -> bool:
	return domain in ["operator","rtp","start"] or domain in ["player_0","player_1","player_2","player_3","player_4","player_5","player_6","player_7"]

func set_pin(domain: String, pin: String) -> bool:
	if not valid_domain(domain) or not valid_pin(pin):
		return false
	var salt := Crypto.new().generate_random_bytes(16)
	credentials[domain] = {"salt":salt.hex_encode(),"hash":derive(pin,salt).hex_encode(),"iterations":ITERATIONS,"digits":4}
	_failures[domain] = 0
	_blocked_until.erase(domain)
	return true

func valid_credentials(candidate: Dictionary) -> bool:
	for domain in candidate:
		if not domain is String or not valid_domain(domain) or not candidate[domain] is Dictionary:
			return false
		var credential: Dictionary = candidate[domain]
		if not credential.get("salt") is String or not credential.get("hash") is String:
			return false
		if credential.salt.length() != 32 or not credential.salt.is_valid_hex_number() or credential.hash.length() != 64 or not credential.hash.is_valid_hex_number() or credential.get("iterations") != ITERATIONS:
			return false
		if credential.has("digits") and credential.digits != 4:
			return false
	return true

func verify(domain: String, pin: String) -> bool:
	if not credentials.has(domain) or Time.get_ticks_msec() < _blocked_until.get(domain,0):
		return false
	var credential: Dictionary = credentials[domain]
	var valid_length := valid_pin(pin) if credential.has("digits") else (pin.length() >= 6 and pin.length() <= 16 and numeric(pin))
	if not valid_length:
		return false
	var actual := derive(pin,credential.salt.hex_decode())
	var expected: PackedByteArray = credential.hash.hex_decode()
	var mismatch := 0
	for i in range(actual.size()):
		mismatch |= actual[i] ^ expected[i]
	if mismatch != 0:
		_failures[domain] = _failures.get(domain,0) + 1
		if _failures[domain] >= 5:
			_blocked_until[domain] = Time.get_ticks_msec() + 1000
		return false
	_failures[domain] = 0
	return true

func derive(pin: String, salt: PackedByteArray) -> PackedByteArray:
	# PBKDF2-HMAC-SHA256, one 32-byte block.
	var crypto := Crypto.new()
	var block_input := salt.duplicate()
	block_input.append_array(PackedByteArray([0,0,0,1]))
	var key := pin.to_utf8_buffer()
	var previous := crypto.hmac_digest(HashingContext.HASH_SHA256,key,block_input)
	var output := previous.duplicate()
	for iteration in range(1,ITERATIONS):
		previous = crypto.hmac_digest(HashingContext.HASH_SHA256,key,previous)
		for i in range(32):
			output[i] ^= previous[i]
	return output
