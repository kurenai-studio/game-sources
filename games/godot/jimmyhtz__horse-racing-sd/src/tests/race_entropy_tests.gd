extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(description)
func _init() -> void:
	if not FileAccess.file_exists("res://core/race_entropy.gd"):
		check(false,"Accepted-start entropy adapter is missing")
		quit(1)
		return
	var source=load("res://core/race_entropy.gd").new()
	var seeds := {}
	for i in range(1000):
		var seed_value: String=source.new_seed()
		check(seed_value.length()==64 and seed_value.is_valid_hex_number(false),"Full-width replay-safe seed")
		check(not seeds.has(seed_value),"Fresh-start sample has no duplicate master")
		seeds[seed_value]=true
	var bytes:=PackedByteArray()
	bytes.resize(32)
	var first: String=source.mix(bytes,1000000,"100.0",123,"a")
	check(first!=source.mix(bytes,1000001,"100.0",123,"a"),"One microsecond changes derived seed")
	check(first!=source.mix(bytes,1000000,"100.0",123,"b"),"Activity digest supplements entropy")
	check(first==source.mix(bytes,1000000,"100.0",123,"a"),"Mixing is reproducible for controlled tests")
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://test-results/payback-v2/catalog.json"))
	var engine=load("res://tools/payback_v2/race_candidate.gd")
	var prefixes := {}
	for i in range(32):
		var race=engine.new(source.new_seed(),catalog,90,false)
		var moves: Array=[]
		for event_index in range(100):
			race.advance_event()
			moves.append([race.last_event().selected,race.snapshot().positions])
		var digest:=JSON.stringify(moves).sha256_text()
		check(not prefixes.has(digest),"Fresh start produces a different actual movement prefix in the sample")
		prefixes[digest]=true
	print("RACE ENTROPY: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
