extends RefCounted
## Replaceable developer content. This generator never uses the race RNG.
const CATEGORIES := ["start","leader","change","order","second","second_change","challenge","early","middle","late","close","result","small","jackpot","none","lead_move","place_move","chase","place_chase","recent_order","recent_places"]
const PLACEHOLDERS := {"lead_move":["mover", "rival"],"place_move":["mover", "rival"],"chase":["leader", "second"],"place_chase":["second", "third"],"recent_order":["leader", "second"],"recent_places":["second", "third"],"leader":["leader"],"change":["leader"],"order":["leader","second"],"second":["second"],"second_change":["second"],"challenge":["second","third"],"result":["first","second","pair"]}
var recent: Array=[]
var rng:=RandomNumberGenerator.new()
var lines: Array=[]
var error: String=""
func _init() -> void:
	rng.randomize()
	var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://data/announcer_phrases.json"))
	error=validate_catalog(parsed)
	if error.is_empty(): lines=parsed.lines
	else: push_error("Announcer catalog rejected: "+error)

func validate_catalog(data: Variant) -> String:
	if not data is Dictionary or data.get("schema")!=1 or not data.get("lines") is Array: return "Unsupported catalog"
	var ids: Dictionary={}
	var covered: Dictionary={}
	var tokens:=RegEx.new()
	tokens.compile("\\{([^{}]*)\\}")
	for line in data.lines:
		if not line is Dictionary or not line.get("id") is String or line.id.is_empty() or ids.has(line.id): return "Invalid or duplicate line ID"
		ids[line.id]=true
		if not line.get("category") in CATEGORIES or not line.get("text") is String: return "Unknown category or text"
		if line.text.strip_edges().is_empty() or line.text.length()>280 or "\n" in line.text: return "Line must contain 1 to 280 characters on one line"
		if not line.get("traits") is Dictionary: return "Missing traits"
		for key in ["humor","sarcasm","energy","detail"]:
			var value=line.traits.get(key)
			if not (value is float or value is int) or not is_finite(float(value)) or value<0 or value>1: return "Trait outside 0 to 1"
		var allowed: Array=PLACEHOLDERS.get(line.category,[])
		var plain: String=line.text
		for token in tokens.search_all(line.text):
			if not token.get_string(1) in allowed: return "Placeholder not valid in this category"
			plain=plain.replace(token.get_string(),"")
		if "{" in plain or "}" in plain: return "Malformed placeholder"
		for token in allowed:
			if not ("{"+token+"}") in line.text: return "Required context placeholder missing"
		# Every category needs a neutral fallback when humor and sarcasm are zero.
		if line.traits.humor==0 and line.traits.sarcasm==0: covered[line.category]=true
	for category in CATEGORIES:
		if not covered.has(category): return "Missing neutral category: "+category
	return ""

func choose(category: String, replacements: Dictionary={}) -> Dictionary:
	return choose_traits(category,replacements,{"humor":0.3,"sarcasm":0.1,"energy":0.6,"detail":0.5})

func choose_traits(category: String, replacements: Dictionary, quirks: Dictionary, max_words: int=0) -> Dictionary:
	var pool: Array=[]
	for source in lines:
		if source.category!=category: continue
		if source.traits.humor>0 and float(quirks.get("humor",0.3))<=0: continue
		if source.traits.sarcasm>0 and float(quirks.get("sarcasm",0.1))<=0: continue
		var line: Dictionary=source.duplicate(true)
		line.weight=1.0
		for key in ["humor","sarcasm","energy","detail"]:
			line[key]=source.traits[key]
			line.weight*=0.15+1.0-absf(float(quirks.get(key,0.5))-float(line[key]))
		pool.append(line)
	if pool.is_empty(): return {"id":"unavailable","text":"","category":category}
	if max_words>0:
		var short: Array=pool.filter(func(line): return line.text.split(" ",false).size()<=max_words)
		if not short.is_empty(): pool=short
	var candidates: Array=pool.filter(func(line): return not line.id in recent)
	if candidates.is_empty(): candidates=pool
	var total := 0.0
	for line in candidates: total+=line.weight
	var pick := rng.randf()*total
	var chosen: Dictionary=candidates.back().duplicate()
	for line in candidates:
		pick-=line.weight
		if pick<=0:
			chosen=line.duplicate()
			break
	recent.append(chosen.id)
	if recent.size()>48: recent.pop_front()
	for key in replacements: chosen.text=chosen.text.replace("{"+str(key)+"}",str(replacements[key]))
	return chosen
