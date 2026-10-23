extends TestCase
## Cutscenes: lines are written out, held, and move on by themselves, or wait for Enter if the
## settings say so; Enter always hurries a line along, and Escape always skips the whole scene.

const LINES: Array[String] = ["One line.", "And another, a little longer."]


func _run(scene: Cutscene, seconds: float) -> void:
	for step in ceili(seconds * 60.0):
		scene.step(1.0 / 60.0, false, false)


func test_a_line_is_written_out_letter_by_letter() -> void:
	var scene := Cutscene.new(LINES)
	_run(scene, 0.1)
	check(scene.written().length() > 0 and scene.written().length() < LINES[0].length(), "a tenth of a second in, it shows '%s'" % scene.written())
	_run(scene, 1.0)
	check(scene.written() == LINES[0], "the line was never written in full")


func test_lines_move_on_by_themselves() -> void:
	var scene := Cutscene.new(LINES)
	_run(scene, scene.length() + 0.1)
	check(scene.done() and not scene.skipped, "left alone, the scene never finished")


func test_lines_can_wait_for_enter() -> void:
	var scene := Cutscene.new(LINES, true)
	_run(scene, scene.length() * 3.0)
	check(scene.line == 0 and scene.written() == LINES[0], "a waiting line moved on by itself")
	scene.step(0.0, true, false)
	check(scene.line == 1, "Enter didn't move a finished line on")


func test_enter_finishes_a_line_then_moves_on() -> void:
	var scene := Cutscene.new(LINES)
	scene.step(0.05, true, false)
	check(scene.line == 0 and scene.written() == LINES[0], "Enter on a half-written line didn't finish it")
	scene.step(0.0, true, false)
	check(scene.line == 1, "Enter on a finished line didn't move on")


func test_escape_skips_the_whole_scene() -> void:
	var scene := Cutscene.new(LINES)
	scene.step(0.0, false, true)
	check(scene.done() and scene.skipped and scene.written().is_empty(), "Escape didn't skip the scene")


func test_a_scene_with_no_lines_is_done_at_once() -> void:
	check(Cutscene.new().done(), "an empty scene had something left to tell")
