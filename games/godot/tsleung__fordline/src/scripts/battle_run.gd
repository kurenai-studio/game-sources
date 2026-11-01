class_name BattleRun
extends RefCounted
## One battle being fought: the battle, the seats that command it, the log
## of every order given by hand, and a trace of how it went. This is the
## only loop that advances a battle, and the screen, the suite and the
## studies all use it, so what is measured is what is played.
##
## The battle is deterministic: the same scenario, seed and log fight the
## same battle again, with the AI seats deciding afresh. That makes a
## replay a log, and a "what if" a log with one order taken out.

## A commander over some of a side's regiments. With no commander, the seat
## is a person's, whose orders come through give(). A seat for the whole
## side commands every regiment of it that no other seat has claimed;
## otherwise it commands only its `ids` (a division on its own command).
class Seat:
	var team := 0
	var commander: Commander
	var whole_side := true
	var ids: Array[int] = []
	## Log this seat's orders as if given by hand: a recorded AI player,
	## whose battle can then be replayed with an order taken out.
	var logged := false
	## Seconds between decisions, and the time left until the next.
	var every := AI.THINK_EVERY
	var wait := 0.0

	func _init(on_team: int, by: Commander, think_every := AI.THINK_EVERY, for_whole_side := true) -> void:
		team = on_team
		commander = by
		every = think_every
		whole_side = for_whole_side


var battle: Battle
var seats: Array[Seat] = []
## Steps taken since the battle began.
var tick := 0
## Each order given by hand or by a logged seat, in turn: {"tick", "seat",
## "orders", "deploy", "turn"}. "turn" is true for a seat's orders, which
## were given at its turn in the step; false for orders given by hand
## between steps, which come before every seat's turn.
var log: Array[Dictionary] = []
var trace := Telemetry.Trace.new()
var _events: Array[Dictionary] = []


func _init(b: Battle) -> void:
	battle = b
	trace.start(b)


func add_seat(seat: Seat) -> int:
	seats.append(seat)
	return seats.size() - 1


## Orders from the seat `index` by hand: logged with the step they belong to,
## then carried out.
func give(index: int, orders: Array, at_turn := false) -> void:
	if orders.is_empty():
		return
	log.append({"tick": tick, "seat": index, "orders": orders.duplicate(true), "deploy": battle.phase == "deploy", "turn": at_turn})
	battle.apply_orders(orders)


func begin() -> void:
	battle.begin()


## One step: each AI seat whose turn it is decides, then the battle moves.
func advance() -> void:
	if battle.phase != "battle":
		return
	for i in seats.size():
		var seat := seats[i]
		if seat.commander == null:
			continue
		seat.wait -= Battle.STEP
		if seat.wait > 0.0:
			continue
		seat.wait = seat.every
		var orders := _claimed(i, seat.commander.decide(battle, seat.team))
		trace.note_orders(seat.team, orders.size())
		if seat.logged:
			give(i, orders, true)
		else:
			battle.apply_orders(orders)
	battle.step(Battle.STEP)
	tick += 1
	var events := battle.take_events()
	trace.note_events(events)
	_events.append_array(events)
	if tick % Telemetry.Trace.SAMPLE_TICKS == 0 or battle.phase == "over":
		trace.sample(battle)


## Advance until the battle ends or `seconds` of it have passed.
func run_for(seconds: float) -> void:
	var until := tick + int(ceil(seconds / Battle.STEP))
	while battle.phase == "battle" and tick < until:
		advance()


## The battle's events since the last call, for whoever shows them.
func take_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


## Hand `ids` to the seat `index` (a division on its own command), taking
## them from any other seat's list.
func claim(index: int, ids: Array[int]) -> void:
	for i in seats.size():
		if i != index:
			release(i, ids)
	for id in ids:
		if not id in seats[index].ids:
			seats[index].ids.append(id)


func release(index: int, ids: Array) -> void:
	seats[index].ids.assign(seats[index].ids.filter(func(id): return not id in ids))


## The orders a seat may give: to its own regiments, or, for the whole side,
## to the side's regiments that no other seat claims. Orders for no regiment
## (the Rally horn) belong to the seat for the whole side.
func _claimed(index: int, orders: Array) -> Array:
	var seat := seats[index]
	if not seat.whole_side:
		return orders.filter(func(o): return o.get("id", -1) in seat.ids)
	var others: Array[int] = []
	for i in seats.size():
		if i != index and seats[i].team == seat.team and not seats[i].whole_side:
			others.append_array(seats[i].ids)
	if others.is_empty():
		return orders
	return orders.filter(func(o): return not o.get("id", -1) in others)


## Fight the battle again from the start with `given` (a log) and the
## other seats deciding for themselves: the replay of a played battle, or a
## "what if" when the log has been changed. `make` builds the battle as it
## was before its first order; `make_seats` returns the seats as they were.
## A seat whose orders are in the log as its turns gives them at its turn;
## orders given by hand go in before any seat's turn, as they did.
static func replay(make: Callable, make_seats: Callable, given: Array, seconds: float) -> BattleRun:
	var run := BattleRun.new(make.call())
	var seats_now: Array = make_seats.call()
	for i in seats_now.size():
		var seat: Seat = seats_now[i]
		var turns := given.filter(func(e): return e.turn and e.seat == i)
		if not turns.is_empty():
			seat = Seat.new(seat.team, Replayed.new(run, turns), Battle.STEP, seat.whole_side)
			seat.ids = seats_now[i].ids
		run.add_seat(seat)
	var by_hand := given.filter(func(e): return not e.turn)
	var next := 0
	while next < by_hand.size() and by_hand[next].deploy:
		run.give(by_hand[next].seat, by_hand[next].orders)
		next += 1
	run.begin()
	var until := int(ceil(seconds / Battle.STEP))
	while run.battle.phase == "battle" and run.tick < until:
		while next < by_hand.size() and by_hand[next].tick <= run.tick:
			run.give(by_hand[next].seat, by_hand[next].orders)
			next += 1
		run.advance()
	return run


## A seat's logged turns, given back step by step. It holds its run weakly:
## the run holds it through its seat.
class Replayed extends Commander:
	var _run: WeakRef
	var _turns: Array
	var _next := 0

	func _init(of_run: BattleRun, turns: Array) -> void:
		_run = weakref(of_run)
		_turns = turns

	func decide(_b: Battle, _team: int) -> Array:
		var tick: int = _run.get_ref().tick
		var out: Array = []
		while _next < _turns.size() and _turns[_next].tick <= tick:
			out.append_array(_turns[_next].orders)
			_next += 1
		return out
