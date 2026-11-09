extends Translation
## The game's English and Japanese (the source text is Chinese). Registered with
## the TranslationServer, so every Label, Button and tooltip is translated as it
## is shown, and draw code calls tr(). A string is looked up whole first; failing
## that, it is matched against the source's sentence templates (the strings with
## %s %d %.1f in them) and whatever was filled in — a skill name, a player — is
## translated in turn; failing that, it is cut at its separators and the pieces
## translated. Player names become English or Japanese names (see SUR, GIVEN).

const Data := preload("res://scripts/i18n_data.gd")

## Player names, made local: the game builds names from a surname and a given
## name out of two lists (People.SURNAMES, People.GIVEN), so each piece has an
## English and a Japanese stand-in — the same Chinese name always comes out as
## the same English or Japanese one; the hand-made players have their own.
const SUR := {
	"王": ["Walker", "大野"], "李": ["Lee", "森"], "张": ["Chandler", "長田"], "刘": ["Lewis", "柳田"],
	"陈": ["Chapman", "中村"], "杨": ["Young", "山本"], "赵": ["Shaw", "佐藤"], "黄": ["Hughes", "黄瀬"],
	"周": ["Jones", "周防"], "吴": ["Woods", "小林"], "徐": ["Fisher", "徳田"], "孙": ["Sullivan", "鈴木"],
	"马": ["Marsh", "馬場"], "朱": ["Turner", "赤松"], "胡": ["Hudson", "久保"], "郭": ["Gordon", "加藤"],
	"何": ["Harper", "河野"], "林": ["Lynch", "林"], "罗": ["Rowe", "村上"], "高": ["Gale", "高橋"],
	"梁": ["Lane", "橋本"], "宋": ["Simmons", "宗像"], "郑": ["Jensen", "田中"], "谢": ["Shepherd", "斎藤"],
	"韩": ["Hanson", "松本"], "唐": ["Thompson", "唐沢"], "冯": ["Fleming", "藤井"], "于": ["Yates", "上田"],
	"董": ["Dawson", "堂本"], "萧": ["Sharp", "清水"],
}
const GIVEN := {
	"子轩": ["Zack", "翔太"], "浩然": ["Harry", "浩"], "一鸣": ["Ethan", "一真"], "宇航": ["Neil", "航"],
	"思远": ["Simon", "遥斗"], "嘉豪": ["Jake", "健太"], "泽宇": ["Zane", "拓海"], "博文": ["Ben", "博"],
	"天佑": ["Toby", "佑真"], "俊杰": ["Jack", "俊"], "明哲": ["Matt", "明"], "晨阳": ["Sonny", "陽太"],
	"星辰": ["Leo", "昴"], "皓轩": ["Henry", "光"], "景行": ["Jonah", "景"], "子墨": ["Max", "颯太"],
	"亦凡": ["Evan", "亮"], "沐阳": ["Miles", "陽翔"], "承恩": ["Owen", "誠"], "启航": ["Kai", "航平"],
}
const NAMES := {
	"林远航": ["Ryan Lynch", "林 航"], "周子墨": ["Max Jones", "周防 颯太"], "许嘉禾": ["Jasper Hale", "堀 嘉和"],
	"陈小满": ["Sam Chapman", "中村 満"], "叶星河": ["Leo Rivers", "葉山 星河"], "唐秋白": ["Archie Thompson", "唐沢 秋"],
	"宋知远": ["Noah Simmons", "宗像 知"], "沈一帆": ["Ethan Sinclair", "篠原 一帆"], "白一鸣": ["Ian White", "白石 一真"],
	"罗海生": ["Harvey Rowe", "村上 海生"], "苏木": ["Sam Sutton", "須藤 樹"], "郑小舟": ["Toby Jensen", "田中 舟"],
	"钱老三": ["Trey Penny", "金田 三郎"], "韩铁柱": ["Tyler Hanson", "松本 鉄平"], "顾承泽": ["Chase Graham", "古賀 澄"],
	"魏青松": ["Quinn Wells", "渡辺 青"],
}

var table: Dictionary          # source -> translation
var templates: Array = []      # [RegEx, fragment, output template, kinds]
var cache := {}
var done := {}                 # StringName in -> StringName out, as the engine asks
var one_s := RegEx.create_from_string("\\b1 (point|game|heart|stage|ball|round|match|card|time|slot)s\\b")
var lang := 0                 # 0 English, 1 Japanese (the index into the name tables)


func _init(loc: String) -> void:
	locale = loc
	table = Data.EN.duplicate() if loc == "en" else Data.JA.duplicate()
	lang = 0 if loc == "en" else 1
	# a piece cut out of a longer line has lost its padding: know it bare too
	for src in table.keys():
		var bare: String = src.strip_edges()
		if bare != src and bare != "" and not table.has(bare):
			table[bare] = str(table[src]).strip_edges()
	var spec := RegEx.create_from_string("%[-+0-9.]*[sdf]")
	for src in table:
		if not "%" in src:
			continue
		var parts: Array = []      # literal pieces between the specs
		var kinds: Array = []
		var at := 0
		var pattern := "(?s)^"   # a filled-in piece may run over several lines
		for m in spec.search_all(src):
			var lit: String = src.substr(at, m.get_start() - at)
			parts.append(lit)
			pattern += _escape(lit)
			var k: String = m.get_string()
			kinds.append(k.right(1))
			pattern += "(.*?)" if k.ends_with("s") else ("([+-]?\\d+)" if k.ends_with("d") else "([+-]?\\d+(?:\\.\\d+)?)")
			at = m.get_end()
		var tail: String = src.substr(at)
		parts.append(tail)
		pattern += _escape(tail) + "$"
		var frag := ""             # the piece to look for: the longest, Chinese if any is
		for p in parts:
			var better: bool = p.length() > frag.length() if _has_cjk(p) == _has_cjk(frag) else _has_cjk(p)
			if better:
				frag = p
		var core: String = frag.strip_edges()
		if core == "" or (core.length() < 2 and not _has_cjk(core)):
			continue                   # nothing distinctive to look for
		var out: String = spec.sub(str(table[src]).replace("%%", "\u0001"), "%s", true).replace("\u0001", "%%")
		# the same, matching only the start of a line (something appended after)
		var open_end: RegEx = null
		if not (tail == "" and kinds.size() > 0 and kinds[-1] == "s"):
			open_end = RegEx.create_from_string(pattern.trim_suffix("$").replace("%%", "%"))
		var lit_len := 0
		for p in parts:
			lit_len += p.strip_edges().length()
		templates.append([RegEx.create_from_string(pattern.replace("%%", "%")), frag.replace("%%", "%"), out, kinds, open_end, lit_len])
	templates.sort_custom(func(a, b): return a[5] > b[5])   # the most specific first


static func _escape(s: String) -> String:
	var out := ""
	for ch in s:
		out += ("\\" + ch) if ch in ".^$*+?()[]{}|\\/" else ch
	return out


static func _has_cjk(s: String) -> bool:
	for ch in s:
		var c := ch.unicode_at(0)
		if c >= 0x3400 and c <= 0x9fff:
			return true
	return false


func _get_message(src_message: StringName, _context: StringName) -> StringName:
	var hit = done.get(src_message)
	if hit != null:            # the HUD asks for the same few strings every frame
		return hit
	var s := String(src_message)
	if not _has_cjk(s):
		done[src_message] = &""   # nothing to translate: the engine keeps it as it is
		return &""
	var out := translate(s)
	if lang == 0:   # the templates are written for many: "1 points left" -> "1 point left"
		out = one_s.sub(out, "1 $1", true)
	if OS.has_environment("I18N_MISS") and (_has_cjk(out) if lang == 0 else out == s):
		print("[i18n-miss] ", s.c_escape())
	if done.size() > 4000:
		done.clear()
	done[src_message] = StringName(out)
	return done[src_message]


## The whole of `s` in this language (as far as the tables go).
func translate(s: String, depth := 0) -> String:
	if cache.has(s):
		return cache[s]
	var out := _translate(s, depth)
	if cache.size() > 8000:
		cache.clear()
	cache[s] = out
	return out


func _translate(s: String, depth: int) -> String:
	var nm0 := _name(s)
	if nm0 != "":
		return nm0
	if table.has(s):
		return table[s]
	if not _has_cjk(s) or depth > 6:
		return s
	var stripped := s.strip_edges()
	if stripped != s and stripped != "":
		var lead := s.substr(0, s.find(stripped))
		return lead + translate(stripped, depth + 1) + s.substr(s.find(stripped) + stripped.length())
	if s.begins_with("· "):   # a bullet point
		return "· " + translate(s.substr(2), depth + 1)
	for t in templates:
		if not s.contains(t[1]):
			continue
		var m: RegExMatch = t[0].search(s)
		if m == null:
			continue
		var args := []
		for i in t[3].size():
			var v: String = m.get_string(i + 1)
			args.append(translate(v, depth + 1) if t[3][i] == "s" else v)
		return t[2] % args
	# lines that are no template together: each on its own
	if "\n" in s:
		var lines := s.split("\n")
		var res := PackedStringArray()
		for l in lines:
			res.append(translate(l, depth + 1))
		return "\n".join(res)
	var nm := _name(s)
	if nm != "":
		return nm
	# a known line with more appended: the line, then the rest
	for t in templates:
		if t[4] == null or not s.contains(t[1]):
			continue
		var m: RegExMatch = t[4].search(s)
		if m == null or m.get_end() >= s.length():
			continue
		var args := []
		for i in t[3].size():
			var v: String = m.get_string(i + 1)
			args.append(translate(v, depth + 1) if t[3][i] == "s" else v)
		return (t[2] % args) + translate(s.substr(m.get_end()), depth + 1)
	# a title in 「」: "龙马「六边形战士」" -> Ryoma "Hexagon Warrior"
	var lq := s.find("「")
	var rq := s.find("」", lq)
	if lq >= 0 and rq > lq:
		var inner_q := translate(s.substr(lq + 1, rq - lq - 1), depth + 1)
		var quoted := (" \"%s\"" % inner_q) if lang == 0 else ("「%s」" % inner_q)
		return translate(s.substr(0, lq), depth + 1) + quoted + translate(s.substr(rq + 1), depth + 1)
	# a tag in 【】: what's inside, in brackets of the language
	var lb := s.find("【")
	var rb := s.find("】", lb)
	if lb >= 0 and rb > lb:
		var inner := translate(s.substr(lb + 1, rb - lb - 1), depth + 1)
		var tag := ("[%s]" % inner) if lang == 0 else ("【%s】" % inner)
		return translate(s.substr(0, lb), depth + 1) + tag + translate(s.substr(rb + 1), depth + 1)
	# a long known sentence with something run on after it (before cutting at
	# separators, which would break the sentence up)
	if s.length() <= 80:
		for k in range(s.length() - 1, 3, -1):
			var head := s.substr(0, k)
			if table.has(head):
				return _join(str(table[head]), translate(s.substr(k), depth + 1))
	# cut at the separators and translate the pieces
	for sep in [" —— ", "   ", "  ", " · ", " vs ", "、", "：", " ", "·"]:
		if sep in s:
			var bits := s.split(sep)
			var res := PackedStringArray()
			var changed := false
			for b in bits:
				var tb := translate(b, depth + 1) if b != "" else b
				changed = changed or tb != b
				res.append(tb)
			if changed:
				var joint: String = sep
				if sep == "、":
					joint = ", " if lang == 0 else "、"
				elif sep == "：":
					joint = ": " if lang == 0 else "："
				return joint.join(res)
	# two strings run together in the code: the longest known start, then the rest
	if s.length() <= 80:
		for k in range(s.length() - 1, 1, -1):
			var head := s.substr(0, k)
			if table.has(head):
				return _join(str(table[head]), translate(s.substr(k), depth + 1))
	return s


## Two translated pieces that were one string: in English a word break, and the
## second word in lower case ("Backhand" + "Power loop" -> "Backhand power loop").
func _join(a: String, b: String) -> String:
	if lang != 0 or a == "" or b == "":
		return a + b
	var a_end := a.unicode_at(a.length() - 1)
	var b_start := b.unicode_at(0)
	var letter := func(c: int) -> bool: return (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
	if letter.call(a_end) and letter.call(b_start):
		return a + " " + b.substr(0, 1).to_lower() + b.substr(1)
	if letter.call(a_end) and b.begins_with("("):
		return a + " " + b
	return a + b


## A player's name made local: "林远航" -> "Ryan Lynch" / "林 航".
func _name(s: String) -> String:
	if NAMES.has(s):
		return NAMES[s][lang]
	if s.length() == 3 and SUR.has(s[0]) and GIVEN.has(s.substr(1)):
		var g: String = GIVEN[s.substr(1)][lang]
		var f: String = SUR[s[0]][lang]
		return "%s %s" % [g, f] if lang == 0 else "%s %s" % [f, g]
	return ""
