class_name ComboController
extends Node

## Timed-abilities test - tracks combo state: a run of tree/boulder breaks
## that started with a big enough single swing (>=3 trees via axe, or
## >=1 boulder via hammer), and keeps extending on every subsequent
## tree/boulder break while active. The saw can extend an already-active
## combo too (see report_saw_tree_cut()) - a much smaller amount per tree,
## reported live as it cuts rather than in one batch like axe/hammer, and
## it can never start a combo on its own. Snow barriers never interact
## with any of this - heat only, see hammer_ability.gd's
## _break_snow_barrier().
##
## The combo timer's cap shrinks as combo_count grows (see _window()),
## which is what makes big combos progressively harder to sustain even
## though every single break still adds some time back - see
## _extend_combo(). When the timer runs out, or the player gets hurt
## (on_hurt()), the combo "completes" and pays out bonus heat based on
## how big it got. First-pass numbers below, flagged for balance tuning
## after playtesting. See Notes/TEST-TIMED-ABILITIES.md.

const _START_TREES := 3
const _START_BOULDERS := 1

const _WINDOW_BASE := 4.0
const _WINDOW_SHRINK_PER_ITEM := 0.15

## Single floor - no mastery gate. The incentive to max out both abilities
## is already built in: more stacks means faster cooldowns and a bigger
## swing area (catches more per hit), which is what actually lets a player
## keep pace with the shrinking window as combo_count climbs. Eased up from
## an earlier two-tier version that was still too tight even at max stacks.
## First-pass number, flagged for balance tuning - see
## Notes/TEST-TIMED-ABILITIES.md.
const _WINDOW_MIN := 1.75

const _EXTEND_PER_BOULDER := 1.5
const _EXTEND_PER_TREE := 0.4

## Saw cuts trees passively over its whole flight instead of in one
## deliberate swing, so each individual cut is worth much less than an
## axe's - it chains an existing combo along, it doesn't carry it.
const _EXTEND_PER_SAW_TREE := 0.15

## Bonus payout scaled down a bit from the first pass so a big combo
## doesn't outclass just grabbing coffee - it should still feel great, but
## coffee stays the more reliable way to survive.
const _BONUS_PER_ITEM := 0.3
const _BONUS_CAP := 6.0

var combo_active: bool = false
var combo_count: int = 0
var time_remaining: float = 0.0

## Highest combo reached this run - for the leaderboard, once that's wired up.
var highest_combo_this_run: int = 0

func _process(delta: float) -> void:
	if not combo_active:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		_complete_combo()

## Called by axe_ability.gd once a swing's full hit window closes, with how
## many trees it cut in total (0 if none).
func report_tree_swing(trees_cut: int) -> void:
	if trees_cut <= 0:
		return
	if not combo_active:
		if trees_cut >= _START_TREES:
			_start_combo(trees_cut)
		return
	_extend_combo(trees_cut, trees_cut * _EXTEND_PER_TREE)

## Called by hammer_ability.gd once a swing's full hit window closes, with
## how many boulders it smashed in total (0 if none).
func report_boulder_swing(boulders_smashed: int) -> void:
	if boulders_smashed <= 0:
		return
	if not combo_active:
		if boulders_smashed >= _START_BOULDERS:
			_start_combo(boulders_smashed)
		return
	_extend_combo(boulders_smashed, boulders_smashed * _EXTEND_PER_BOULDER)

## Called by saw_blade.gd once per tree it cuts, live as it happens (not
## batched at the end of the blade's flight like axe/hammer report their
## swings) - the blade could be out for several seconds, well longer than
## the combo window, so waiting until it despawns to report would usually
## be too late to matter. Does nothing if there's no combo active yet -
## the saw can extend a combo, never start one.
func report_saw_tree_cut() -> void:
	if not combo_active:
		return
	_extend_combo(1, _EXTEND_PER_SAW_TREE)

## Called from vulnerable.gd when the player gets hit - combo still pays
## out whatever it earned, it just ends instead of continuing.
func on_hurt() -> void:
	if combo_active:
		_complete_combo()

func _start_combo(count: int) -> void:
	combo_active = true
	combo_count = count
	time_remaining = _window(combo_count)
	highest_combo_this_run = max(highest_combo_this_run, combo_count)
	EventBus.combo_changed.emit(combo_active, combo_count, time_remaining)

func _extend_combo(added_count: int, extend_seconds: float) -> void:
	combo_count += added_count
	var cap := _window(combo_count)
	time_remaining = min(cap, time_remaining + extend_seconds)
	highest_combo_this_run = max(highest_combo_this_run, combo_count)
	EventBus.combo_changed.emit(combo_active, combo_count, time_remaining)

func _complete_combo() -> void:
	var bonus: float = min(_BONUS_CAP, combo_count * _BONUS_PER_ITEM)
	var player := get_parent()
	if player and "control" in player and player.control:
		player.control.add_freeze_time(bonus)
	combo_active = false
	combo_count = 0
	time_remaining = 0.0
	EventBus.combo_changed.emit(combo_active, combo_count, time_remaining)

## HUD helper - the bonus heat that would pay out if the combo ended right
## now, so the HeatBonus label can show a live "what you'd get" preview
## while it's still building. Same formula _complete_combo() actually pays.
func get_pending_bonus() -> float:
	return min(_BONUS_CAP, combo_count * _BONUS_PER_ITEM)

func _window(count: int) -> float:
	return max(_WINDOW_MIN, _WINDOW_BASE - count * _WINDOW_SHRINK_PER_ITEM)
