extends GutTest
## Test boards: the validator, boards_of, level_on_board, simulate_all and BoardProgress.
## The shared fixtures (including boards/) are run by test_contract_fixtures.gd.


func _codes(level: Variant) -> Array[String]:
	return ContractSupport.pairs(LevelValidator.validate_level(level)["issues"])


func test_a_level_with_extra_boards_is_valid() -> void:
	assert_eq(_codes(MultiSupport.level(5)), [])
	assert_eq(_codes(MultiSupport.level(1)), [])


func test_extra_boards_must_be_one_to_five() -> void:
	var level := MultiSupport.level()
	level["extraBoards"] = []
	assert_eq(_codes(level), ["extraBoards|LENGTH_OUT_OF_RANGE"])
	level["extraBoards"] = (
		MultiSupport.level(5)["extraBoards"] + MultiSupport.level(1)["extraBoards"]
	)
	assert_eq(_codes(level), ["extraBoards|LENGTH_OUT_OF_RANGE"])
	level["extraBoards"] = "x"
	assert_eq(_codes(level), ["extraBoards|INVALID_TYPE"])
	level["extraBoards"] = [3]
	assert_eq(_codes(level), ["extraBoards[0]|INVALID_TYPE"])


func test_issues_in_an_extra_board_carry_the_path_prefix() -> void:
	var level := MultiSupport.level()
	level["extraBoards"][1]["goal"]["position"] = [9, 1]
	level["extraBoards"][0]["board"]["walls"] = [[1, 1], [1, 1]]
	level["extraBoards"][1]["bonus"] = 1
	assert_eq(
		_codes(level),
		[
			"extraBoards[0].board.walls[1]|DUPLICATE_WALL",
			"extraBoards[1].bonus|UNKNOWN_FIELD",
			"extraBoards[1].goal.position|OUTSIDE_BOARD",
		]
	)


func test_a_level_without_extra_boards_has_one_board() -> void:
	var level := MultiSupport.level()
	level.erase("extraBoards")
	assert_eq(BoardSet.boards_of(level).size(), 1)
	var all := LevelSimulator.simulate_all(level, MultiSupport.general())
	assert_eq(all["results"].size(), 1)
	assert_eq(all["status"], "SUCCEEDED")
	assert_eq(all["steps"], LevelSimulator.simulate(level, MultiSupport.general())["steps"])


func test_level_on_board_swaps_the_board_and_drops_the_extras() -> void:
	var level := MultiSupport.level()
	var second := BoardSet.level_on_board(level, 1)
	assert_false(second.has("extraBoards"))
	assert_eq(int(second["board"]["width"]), 8)
	assert_eq(int(second["goal"]["position"][0]), 7)
	assert_eq(int(level["board"]["width"]), 5, "the level itself is unchanged")
	assert_true(level.has("extraBoards"))


func test_simulate_all_solves_every_board_with_one_general_program() -> void:
	var all := LevelSimulator.simulate_all(MultiSupport.level(), MultiSupport.general())
	assert_eq(all["status"], "SUCCEEDED")
	assert_null(all["firstFailure"])
	assert_eq(all["steps"], 4 + 7 + 2, "the sum over the three boards")


func test_simulate_all_runs_every_board_and_names_the_first_failure() -> void:
	var all := LevelSimulator.simulate_all(MultiSupport.level(), MultiSupport.overfit())
	assert_eq(all["status"], "FAILED")
	assert_eq(all["firstFailure"], 1)
	assert_eq(all["results"].size(), 3, "all boards run, not only up to the first failure")
	assert_eq(all["results"][0]["status"], "SUCCEEDED")
	assert_eq(all["results"][1]["reason"], "PROGRAM_ENDED")
	assert_eq(all["results"][2]["reason"], "GOAL_REACHED", "a later board may pass again")


func test_board_progress_marks_belong_to_the_program() -> void:
	var progress := BoardProgress.new(MultiSupport.level())
	assert_true(progress.is_multi())
	assert_eq(progress.count(), 3)
	progress.mark_solved(0, MultiSupport.general())
	assert_true(progress.is_solved(0))
	progress.sync(MultiSupport.general())
	assert_true(progress.is_solved(0), "the same program keeps its marks")
	progress.sync(MultiSupport.overfit())
	assert_false(progress.is_solved(0), "a different program clears them")


func test_board_progress_picks_the_next_unsolved_board_and_finishes() -> void:
	var progress := BoardProgress.new(MultiSupport.level())
	var program := MultiSupport.general()
	progress.mark_solved(0, program)
	assert_eq(progress.next_unsolved(), 1)
	progress.select(1)
	progress.mark_solved(1, program)
	assert_eq(progress.next_unsolved(), 2)
	progress.select(2)
	progress.mark_solved(2, program)
	assert_true(progress.all_solved())
	assert_eq(progress.next_unsolved(), -1)
	progress.select(0)
	progress.sync([])
	progress.mark_solved(2, program)
	assert_eq(progress.next_unsolved(), 1, "wraps round to an earlier unsolved board")


func test_board_progress_prefix_and_steps() -> void:
	var progress := BoardProgress.new(MultiSupport.level())
	progress.select(1)
	assert_eq(progress.prefix(), "BOARD 2: ")
	assert_eq(progress.total_steps(MultiSupport.general()), 13)
	var single := MultiSupport.level()
	single.erase("extraBoards")
	var one := BoardProgress.new(single)
	assert_false(one.is_multi())
	assert_eq(one.prefix(), "")
	assert_eq(one.board_level(), single)


func test_the_campaign_keeps_extra_boards_and_supports_multi_board() -> void:
	assert_true(Campaign.SUPPORTED_MECHANICS.has("multi_board"))
	var level := MultiSupport.level()
	var campaign := Campaign.from_data(
		{
			"worlds":
			[
				{
					"id": "w",
					"title": "W",
					"summary": "",
					"chapters": [{"id": "c", "title": "C", "levels": ["mb"]}]
				}
			]
		},
		func(_id: String) -> Variant: return level
	)
	assert_eq(campaign.errors, [])
	assert_eq(campaign.entries.size(), 1)
	assert_eq(campaign.entries[0]["level"]["extraBoards"].size(), 2)
