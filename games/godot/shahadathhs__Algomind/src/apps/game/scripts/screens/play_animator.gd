class_name PlayAnimator
extends RefCounted
## Shows one simulation event: the automaton and tape slide, a blocked move nudges. Displays what
## the simulation decided and never changes it.

const NUDGE_SECONDS := 0.08


## Animates `entry`. Returns false when the run was stopped meanwhile (`id` no longer current).
static func show_step(p: PlayScreen, id: int, entry: Dictionary) -> bool:
	p._tape_view.running = true
	p._tape_view.failed_index = -1
	PlayTape.set_head(p, entry)
	p._board.facing = entry["direction"]
	var cell: Array = entry["position"]
	var target := Vector2(int(cell[0]), int(cell[1]))
	var blocked := str(entry["event"]).begins_with("BLOCKED")
	if blocked:
		p.app.sfx("blocked")
		p.app.haptic(40)
	else:
		p.app.sfx("step")
	var seconds: float = p.app.progress.settings.step_seconds()
	var slide := 0.0 if p.app.progress.settings.reduce_motion() else seconds
	if slide > 0.0:
		var tween := p.create_tween().set_parallel(true)
		if UiLook.depth:
			tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(p._board, "guard_time", float(entry["index"]) + 1.0, slide)
		tween.tween_property(
			p._tape_view, "scroll", p._tape_view.head_scroll(p._tape_view.current), slide
		)
		# A slide or a carry goes through every cell of the step's path in turn.
		var cells: Array = entry.get("path", [])
		var chain := p.create_tween()
		if UiLook.depth:
			chain.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if entry["event"] == "TELEPORTED":
			# Walk to the teleporter (through any ice before it), then appear on its other end.
			var walk := cells.size() - 1
			for i in walk:
				var cell_on_way: Array = cells[i]
				var on_way := Vector2(int(cell_on_way[0]), int(cell_on_way[1]))
				chain.tween_property(p._board, "automaton", on_way, slide / 2.0 / float(walk))
			chain.tween_callback(func() -> void: p._board.automaton = target)
			chain.tween_interval(slide / 2.0)
		elif cells.size() > 1:
			for cell_on_path: Array in cells:
				var at := Vector2(int(cell_on_path[0]), int(cell_on_path[1]))
				chain.tween_property(p._board, "automaton", at, slide / float(cells.size()))
		else:
			chain.tween_property(p._board, "automaton", target, slide)
		await chain.finished
	else:
		p._board.automaton = target
		p._board.guard_time = float(entry["index"]) + 1.0
		p._tape_view.scroll = p._tape_view.head_scroll(p._tape_view.current)
	if id != p._run_id:
		return false
	if blocked and slide > 0.0:
		await _nudge(p, entry["direction"])
	elif slide == 0.0:
		# Reduce motion: a short beat so each step is still readable.
		await p.get_tree().create_timer(seconds).timeout
	return id == p._run_id


static func _nudge(p: PlayScreen, direction: String) -> void:
	var delta: Array = ContractLimits.DIRECTION_DELTAS[direction]
	var push := Vector2(float(delta[0]), float(delta[1])) * 0.15
	var tween := p.create_tween()
	tween.tween_property(p._board, "nudge", push, NUDGE_SECONDS)
	tween.tween_property(p._board, "nudge", Vector2.ZERO, NUDGE_SECONDS)
	await tween.finished


## Plays steps one after another until the run stops, is paused, or is cancelled.
static func play_until_stopped(p: PlayScreen) -> void:
	var id := p._run_id
	while p._session.state == PlaySession.State.RUNNING and id == p._run_id:
		await play_one_step(p)


static func play_one_step(p: PlayScreen) -> void:
	var id := p._run_id
	p._busy = true
	var entry := p._session.advance()
	if entry.is_empty() or await show_step(p, id, entry):
		after_step(p)
	if id == p._run_id:
		p._busy = false


static func after_step(p: PlayScreen) -> void:
	if p._session.state == PlaySession.State.SUCCEEDED:
		p.app.sfx("success")
		p.app.haptic(60)
		# On a level with test boards the level is won only when every board is solved.
		if not PlayBoards.after_success(p) and p.persist:
			PlayCompletion.save(p)
	elif p._session.state == PlaySession.State.FAILED:
		p.app.sfx("fail")
	p._refresh()
