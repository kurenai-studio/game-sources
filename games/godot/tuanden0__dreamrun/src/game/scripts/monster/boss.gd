## The monster penned into an arena, as the mini-boss (2 hits) and as the final boss (3 hits). It cannot be fought, only
## trapped: a trap that stuns it is a hit, and `hits_to_win` hits bring it down. Cycle: patrol toward the player, rear
## up (telegraph), charge at the player's side of the arena, crash and recover at the edge. Each hit starts the next
## phase, which is faster and chains more charges (straight back across the arena) with less time to recover:
##   phase 1  one charge, a long recovery
##   phase 2  1.4x speed, two charges in a row
##   phase 3  1.8x speed, three in a row and half the recovery, so a trap has to be fired before it arrives
## A boss with hits_to_win = 2 never reaches phase 3.
## Origin and facing as in Monster; it never leaves [arena_left, arena_right]. Players are safe beyond the edges.
class_name Boss
extends Monster

signal state_changed(state: StringName)
signal defeated

enum State { PATROL, WINDUP, CHARGE, RECOVER, DEAD }

@export var arena_left := -300.0
@export var arena_right := 300.0
@export var hits_to_win := 2
## A trap may ask for a longer stun than this; the boss shakes it off after this many seconds.
@export var max_stun := 6.0
@export_group("Timing")
@export var patrol_speed := 100.0
@export var charge_speed := 380.0
@export var patrol_time := 2.0
@export var windup_time := 0.9
@export var recover_time := 1.2
@export_group("Phases")
## One entry per phase. Speeds are multiplied by `speedups` and times divided by them; `recover_scales` shortens the
## recovery on top of that; `charges_per_attack` is how many charges follow each other before it patrols again.
@export var speedups: Array[float] = [1.0, 1.4, 1.8]
@export var charges_per_attack: Array[int] = [1, 2, 3]
@export var recover_scales: Array[float] = [1.0, 1.0, 0.5]

var hits := 0

var _state := State.PATROL
var _timer := 0.0
var _returning := false  # on a charge that follows another in the same attack
var _chain_left := 0  # charges still to come in this attack
var _saved_hits := 0
var _saved_dead := false
var _collapse: Tween


func _ready() -> void:
	super()
	started.connect(func() -> void: _enter(State.PATROL))
	stunned.connect(_on_stunned)


func state_name() -> StringName:
	return StringName(State.keys()[_state].to_lower())


func phase() -> int:
	return 1 + _phase_index()


func _phase_index() -> int:
	return mini(hits, speedups.size() - 1)


func stun(seconds: float) -> void:
	super(minf(seconds, max_stun))


func save_checkpoint() -> void:
	_saved_x = position.x
	_saved_active = active
	_saved_hits = hits
	_saved_dead = _state == State.DEAD


func reset_to_checkpoint() -> void:
	if _collapse != null:
		_collapse.kill()
	_stun_left = 0.0
	_rearing = false
	_limp = _saved_dead
	_returning = false
	_chain_left = 0
	hits = _saved_hits
	position.x = _saved_x
	active = _saved_active and not _saved_dead
	visible = _saved_active or _saved_dead
	scale.y = 0.45 if _saved_dead else 1.0
	_state = State.DEAD if _saved_dead else State.PATROL
	_timer = 0.0
	_reset_tail()


func _advance(delta: float) -> void:
	_timer += delta
	var phase_index := _phase_index()
	var speedup := speedups[phase_index]
	match _state:
		State.PATROL:
			var toward := signf(_player_x() - position.x)
			if toward != 0.0:
				_face(int(toward))
			position.x = clampf(position.x + direction * patrol_speed * speedup * delta, arena_left, arena_right)
			if _timer >= patrol_time / speedup:
				_chain_left = charges_per_attack[phase_index] - 1
				_enter(State.WINDUP)
		State.WINDUP:
			if _timer >= windup_time / speedup:
				if not _returning:  # a charge that follows another goes the way it is already facing
					var toward := signf(_player_x() - position.x)
					if toward != 0.0:
						_face(int(toward))
				_enter(State.CHARGE)
		State.CHARGE:
			position.x += direction * charge_speed * speedup * delta
			var edge := arena_right if direction > 0 else arena_left
			if (direction > 0 and position.x >= edge) or (direction < 0 and position.x <= edge):
				position.x = edge
				_enter(State.RECOVER)
		State.RECOVER:
			if _timer >= recover_time * recover_scales[phase_index] / speedup:
				if _chain_left > 0:
					_chain_left -= 1
					_returning = true
					_face(-direction)
					_enter(State.WINDUP)
				else:
					_returning = false
					_enter(State.PATROL)
	_kill_touching()


func _enter(next: State) -> void:
	_state = next
	_timer = 0.0
	_rearing = next == State.WINDUP
	state_changed.emit(state_name())


func _face(dir: int) -> void:
	direction = dir
	scale.x = dir


func _player_x() -> float:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	return player.global_position.x if player != null else position.x


func _on_stunned() -> void:
	if _state == State.DEAD:
		return
	hits += 1
	_returning = false
	_chain_left = 0
	if hits >= hits_to_win:
		_die()
		return
	_enter(State.PATROL)  # after the stun it starts over, faster
	state_changed.emit(&"stunned")


func _die() -> void:
	_state = State.DEAD
	active = false
	_rearing = false
	_limp = true
	if _collapse != null:
		_collapse.kill()
	_collapse = create_tween()
	_collapse.tween_property(self, "scale:y", 0.45, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	state_changed.emit(&"dead")
	defeated.emit()
