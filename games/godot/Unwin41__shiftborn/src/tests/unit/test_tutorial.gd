extends TestCase
## The guided first run: steps advance only on their own event.


func test_starts_at_move_and_needs_real_distance() -> void:
	var steps := TutorialSteps.new()
	assert_eq(steps.current, TutorialSteps.Step.MOVE)
	assert_false(steps.add_movement(TutorialSteps.MOVE_DISTANCE * 0.5), "half the distance is not enough")
	assert_true(steps.add_movement(TutorialSteps.MOVE_DISTANCE * 0.6), "enough distance should advance")
	assert_eq(steps.current, TutorialSteps.Step.SHIFT)


func test_events_only_advance_their_own_step() -> void:
	var steps := TutorialSteps.new()
	steps.add_movement(TutorialSteps.MOVE_DISTANCE)
	assert_false(steps.notify(&"perfect"), "perfect should not skip the shift step")
	assert_true(steps.notify(&"shifted"))
	assert_eq(steps.current, TutorialSteps.Step.RESIST)
	assert_false(steps.notify(&"shifted"), "shift does not finish the resist step")
	assert_true(steps.notify(&"resist_kill"))
	assert_eq(steps.current, TutorialSteps.Step.PERFECT)
	assert_true(steps.notify(&"perfect"))
	assert_true(steps.is_done(), "tutorial should be done after the perfect shift")


func test_movement_is_ignored_after_the_move_step() -> void:
	var steps := TutorialSteps.new()
	steps.add_movement(TutorialSteps.MOVE_DISTANCE)
	assert_false(steps.add_movement(TutorialSteps.MOVE_DISTANCE), "moving again should not advance")
	assert_eq(steps.current, TutorialSteps.Step.SHIFT)


func test_every_step_has_a_prompt_and_progress() -> void:
	for step in [TutorialSteps.Step.MOVE, TutorialSteps.Step.SHIFT, TutorialSteps.Step.RESIST, TutorialSteps.Step.PERFECT]:
		assert_true(TutorialSteps.prompt(step) != "", "step %d has no prompt" % step)
	assert_eq(TutorialSteps.progress_text(TutorialSteps.Step.SHIFT), "2/4")


func test_settings_remember_the_finished_tutorial() -> void:
	var path := "user://test_tutorial_settings.cfg"
	var saved := GameSettings.new()
	assert_false(saved.tutorial_done, "fresh settings should show the tutorial")
	saved.tutorial_done = true
	saved.save_to(path)
	var loaded := GameSettings.new()
	loaded.load_from(path)
	assert_true(loaded.tutorial_done, "tutorial_done should load back")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_pause_menu_skip_button_only_during_the_tutorial() -> void:
	var menu := PauseMenu.new()
	menu.open()
	assert_false(menu.is_skip_tutorial_shown(), "no skip button outside the tutorial")
	menu.set_tutorial_active(true)
	assert_true(menu.is_skip_tutorial_shown(), "skip button during the tutorial")
	menu.free()
