local drawer = {}

function drawer.register_draw_action(game_state, draw_action)
	drawer[game_state] = draw_action
end

function drawer.draw(game_state)
	drawer[game_state]()
end

return drawer