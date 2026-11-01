local M = {}

M.alt = false

function M.action(action_id, action)
	return action.pressed and (action_id == hash("action") or ((action_id == hash("enter") and not M.alt)))
end

function M.back(action_id, action)
	return (action_id == hash("attack") or action_id == hash("exit")) and action.pressed
end

function M.close(action_id, action)
	return (action_id == hash("action") or action_id == hash("exit")) and action.pressed
end


return M
