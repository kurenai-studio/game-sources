class_name Meet
extends RefCounted
## One event's competition: who's in it, whose turn it is, every attempt's
## mark and the standings. Races are one race for everyone at once; the jumps
## and the dive are rounds of attempts, best (or, for the dive, total) counts;
## the high jump is a rising bar with three tries at each height.
##
## Entrants: [{name, nation, cpu, skill, look, player}] where player is 0 or 1
## for a person and -1 for the computer.

var id := "sprint"
var info: Dictionary = {}
var kind := "race"
var level := "junior"
var entrants: Array = []
var attempts := 3
var marks: Array = []            ## per entrant: [mark, ...] (-1 = foul)
var times := {}                  ## races: entrant -> time
var seed := 1
var round_i := 0
var turn_i := 0

# the high jump
var bar := 1.5
var step := 0.1
var tries: Array = []            ## tries at the current bar
var cleared: Array = []          ## has cleared the current bar
var out: Array = []              ## three misses at one height: done
var high_best: Array = []        ## highest bar cleared
var high_log: Array = []         ## per entrant: "1.50 O  1.60 XO ..."
var misses: Array = []           ## the high jump's countback: misses in all
var misses_at_best: Array = []   ## and misses at the best height cleared


func setup(p_id: String, p_entrants: Array, p_level: String, p_seed := 1) -> void:
	id = p_id
	info = Catalog.event(id)
	kind = String(info.get("kind", "race"))
	level = p_level
	entrants = p_entrants
	seed = p_seed
	attempts = int(info.get("attempts", 3))
	marks = []
	for e in entrants:
		marks.append([])
		tries.append(0)
		cleared.append(false)
		out.append(false)
		high_best.append(0.0)
		high_log.append("")
		misses.append(0)
		misses_at_best.append(0)
	bar = float(info.get("start", 1.5)) + float(info.get("pro_start", 0.3)) * (1.0 if level == "pro" else 0.0) \
		- float(info.get("easy_drop", 0.0)) * (1.0 if level == "easy" else 0.0)
	step = float(info.get("step", 0.1))


func humans() -> Array:
	var out_: Array = []
	for i in entrants.size():
		if int(entrants[i].get("player", -1)) >= 0:
			out_.append(i)
	return out_


func entrant_of(player: int) -> int:
	for i in entrants.size():
		if int(entrants[i].get("player", -1)) == player:
			return i
	return -1


## Whose go it is now (-1: the event is over).
func next_turn() -> int:
	match kind:
		"race":
			return -1 if not times.is_empty() else 0
		"high":
			return _next_high()
	while round_i < attempts:
		if turn_i < entrants.size():
			return turn_i
		turn_i = 0
		round_i += 1
	return -1


func _next_high() -> int:
	for guard in 40:
		for i in entrants.size():
			if not out[i] and not cleared[i] and tries[i] < 3:
				return i
		# everyone still in has cleared this bar (or there's no one left): raise it
		var left := 0
		for i in entrants.size():
			if not out[i]:
				left += 1
		if left == 0 or bar > float(info.get("start", 1.5)) + 2.5:
			return -1
		bar = snappedf(bar + step, 0.01)
		for i in entrants.size():
			tries[i] = 0
			cleared[i] = false
	return -1


## The mark of an attempt by entrant i: a distance, a score, or for the high
## jump 1 (cleared) or 0 (knocked).
func record(i: int, value: float) -> void:
	if kind == "high":
		tries[i] += 1
		if tries[i] == 1:
			high_log[i] = String(high_log[i]) + ("  " if high_log[i] != "" else "") + "%.2f " % bar
		if value > 0.5:
			cleared[i] = true
			high_best[i] = maxf(high_best[i], bar)
			misses_at_best[i] = tries[i] - 1
			high_log[i] += "O"
		else:
			misses[i] += 1
			high_log[i] += "X"
			if tries[i] >= 3:
				out[i] = true
		return
	marks[i].append(value)
	if kind != "race":
		turn_i += 1


func record_race(p_times: Dictionary) -> void:
	times = p_times.duplicate()
	for i in entrants.size():
		marks[i] = [float(times.get(i, 99.0))]


## An entrant's mark: best distance, best time, highest bar, or dive total.
func best(i: int) -> float:
	match kind:
		"race":
			return float(times.get(i, 99.0))
		"high":
			return high_best[i]
		"dive":
			var tot := 0.0
			for m in marks[i]:
				tot += maxf(0.0, float(m))
			return tot
	var low := String(info.get("better", "high")) == "low"
	var b := -1.0
	for m in marks[i]:
		var v := float(m)
		if v <= 0.0:
			continue
		if b < 0.0 or (v < b if low else v > b):
			b = v
	if low and b < 0.0:
		return 99.0                # no time at all: last
	return b


func standings() -> Array:
	var idx: Array = range(entrants.size())
	var low := String(info.get("better", "high")) == "low"
	idx.sort_custom(func(a, b):
		var ma := best(a)
		var mb := best(b)
		if ma != mb:
			return ma < mb if low else ma > mb
		if kind == "high":
			# the countback: fewer misses at the height, then fewer in all
			if misses_at_best[a] != misses_at_best[b]:
				return misses_at_best[a] < misses_at_best[b]
			return misses[a] < misses[b]
		return a < b)
	return idx


func place(i: int) -> int:
	return standings().find(i) + 1


func qualified(i: int) -> bool:
	var q := float(info.get("qualify", {}).get(level, 0.0))
	var m := best(i)
	if kind == "race":
		return times.has(i) and m <= q
	if String(info.get("better", "high")) == "low":
		return m > 0.0 and m <= q
	return m >= q


## Play a computer athlete's attempt without drawing it, to the same rules.
func sim(i: int, beat: Beat, salt := 0) -> float:
	var e: Dictionary = entrants[i]
	var who := {"name": e.get("name", "?"), "cpu": true, "skill": e.get("skill", 0.8)}
	var s := seed * 1000 + i * 37 + round_i * 7 + salt
	var dt := 1.0 / 60.0
	var t := 0.0
	match kind:
		"throw":
			var th := Throw.new()
			th.setup(beat, who, level, 0.0, s)
			while not th.finished() and t < 40.0:
				t += dt
				th.update(t, dt)
			return th.result()
		"jump":
			var j := Jump.new()
			j.setup(id, beat, who, level, 0.0, s)
			while not j.finished() and t < 40.0:
				t += dt
				j.update(t, dt)
			return j.result()
		"high":
			var h := High.new()
			h.setup(beat, who, level, bar, 0.0, s + tries[i] * 3, id)
			while not h.finished() and t < 30.0:
				t += dt
				h.update(t, dt)
			return 1.0 if h.cleared else 0.0
		"bob":
			var bo := Bob.new()
			bo.setup(beat, who, level, 0.0, seed, s)
			while not bo.finished() and t < 60.0:
				t += dt
				bo.update(t, dt)
			return bo.result()
		"skijump":
			var sj := SkiJump.new()
			sj.setup(beat, who, level, 0.0, s)
			while not sj.finished() and t < 60.0:
				t += dt
				sj.update(t, dt)
			return sj.points
		"skate":
			var sk := Skate.new()
			sk.setup(beat, who, level, 0.0, seed, s)
			while not sk.finished() and t < 90.0:
				t += dt
				sk.update(t, dt)
			return sk.score
		"battle":
			var bt := Battle.new()
			bt.setup(beat, who, level, 0.0, seed, s)
			while not bt.finished() and t < 90.0:
				t += dt
				bt.update(t, dt)
			return bt.score
		"tramp":
			var tr := Tramp.new()
			tr.setup(beat, who, level, 0.0, s)
			while not tr.finished() and t < 60.0:
				t += dt
				tr.update(t, dt)
			return tr.score
		"dive":
			var d := Dive.new()
			d.setup(beat, who, level, 0.0, s)
			while not d.finished() and t < 40.0:
				t += dt
				d.update(t, dt)
			return d.score
	return 0.0


## A race with only computer athletes in it, start to finish, unseen.
static func sim_race(id_: String, beat: Beat, entrants_: Array, level_: String, seed_ := 1) -> Dictionary:
	var r := Race.new()
	var ent: Array = []
	for e in entrants_:
		ent.append({"name": e.get("name", "?"), "cpu": true, "skill": e.get("skill", 0.8), "boost": e.get("boost", 0.0)})
	r.setup(id_, beat, ent, level_, 0.0, seed_)
	var t := 0.0
	while not r.finished():
		t += 1.0 / 60.0
		r.update(t, 1.0 / 60.0)
	return r.times
