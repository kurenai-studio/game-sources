local display_buffer = require("display_buffer.display_buffer")
local states = require("game.states")
local commands = require("game.commands")
local data = require("game.data")

local M = {}

function M.update(dt)
	display_buffer.clear(97)
	for _, message in ipairs(data.get_messages()) do
		display_buffer.write_line(message, 1)
	end
	display_buffer.write_line("SCORE: "..data.get_score(), 1)
	display_buffer.write_line(" ", 1)
	display_buffer.write("1)", 2)
	display_buffer.write_line("CONTINUE", 1)
	display_buffer.write("0)", 2)
	display_buffer.write_line("QUIT", 1)
	return states.IN_PLAY
end

function M.handle_command(command)
	if command == commands.ZERO then
		return states.CONFIRM_QUIT
	elseif command == commands.ONE then
		return data.continue_game()
	end
	return states.IN_PLAY
end

return M