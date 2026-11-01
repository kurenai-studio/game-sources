class_name BattleAction

func apply(_state: BattleState, _setup: BattleSetup) -> ActionResult:
	var result := ActionResult.new()
	result.state = _state.duplicate()
	return result
