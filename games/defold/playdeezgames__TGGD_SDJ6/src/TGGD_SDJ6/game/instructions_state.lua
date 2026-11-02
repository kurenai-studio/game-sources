local display_buffer = require("display_buffer.display_buffer")
local states = require("game.states")
local commands = require("game.commands")
local data = require("game.data")

local M = {}

function M.update(dt)
	display_buffer.clear(97)
	display_buffer.write_line("INSTRUCTIONS:", 2)
	display_buffer.write_line("IN THIS GAME, YOU WILL ENCOUNTERWHAT APPEAR TO BE PEOPLE.", 1)
	display_buffer.write_line("SOME ARE HUMAN, OTHERS ARE      LIZZID PEOPLE.", 1)
	display_buffer.write_line("YOU MUST CHOOSE TO DENOUNCE THEMAS A LIZZID PERSON, OR ACCEPT   THEM AS HUMAN.", 1)
	display_buffer.write_line("IF YER RIGHT, YOU LIVE ON.", 1)
	display_buffer.write_line("IF YER WRONG, YOU DIE.", 1)
	display_buffer.write_line(" ", 1)
	display_buffer.write("0)", 2)
	display_buffer.write_line("DONE", 1)
	return states.INSTRUCTIONS
end

function M.handle_command(command)
	if command == commands.ZERO then
		return states.TITLE
	end
	return states.INSTRUCTIONS
end

return M