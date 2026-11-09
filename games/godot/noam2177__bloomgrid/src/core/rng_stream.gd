class_name RngStream
extends RefCounted
## xorshift 32-bit. אותו סיד → אותה סדרת חלקים. נוח לטסטים.

var s: int = 0xA341316C


func _init(seed: int = 1) -> void:
	s = seed & 0xFFFFFFFF
	if s == 0:
		s = 0xA341316C


func next_u32() -> int:
	var x := s
	x ^= (x << 13) & 0xFFFFFFFF
	x ^= x >> 17
	x ^= (x << 5) & 0xFFFFFFFF
	s = x & 0xFFFFFFFF
	return s


func randrange(n: int) -> int:
	# modulo רגיל. לטסטים זה מספיק; לא קריפטוגרפיה.
	return next_u32() % n
