local display_buffer = require("display_buffer.display_buffer")
local states = require("game.states")
local commands = require("game.commands")
local data = require("game.data")

local M = {}

function M.update(dt)
	display_buffer.clear(97)
	display_buffer.write_line("LIZZID PEEPLE OF SPLORR!!", 2)
	display_buffer.write_line("A PRODUCTION OF THEGRUMPYGAMEDEV", 1)
	display_buffer.write_line("FOR SOLODEVELOPMENT JAM #6", 1)
	display_buffer.write_line("DECEMBER 2024", 1)
	display_buffer.write_line(" ", 1)
	display_buffer.write("1)", 2)
	display_buffer.write_line("NEW GAME", 1)
	display_buffer.write("2)", 2)
	display_buffer.write_line("INSTRUCTIONS", 1)
	return states.TITLE
end

function M.handle_command(command)
	if command == commands.ONE then
		data.new_game()
		return states.IN_PLAY
	elseif command == commands.TWO then
		return states.INSTRUCTIONS
	end
	return states.TITLE
end

return M


--The McDLT (McDonald's Lettuce and Tomato) was served with mayonnaise, mustard, ketchup, pickles, sliced onions, lettuce, American cheese, and two tomato slices. It was served in a polystyrene container with two compartments in which one side contained the half with one bun and the hamburger, and the other compartment contained the bun with the cheese and other cold ingredients. It was advertised as a design to keep the hot side hot and the cold side cold.