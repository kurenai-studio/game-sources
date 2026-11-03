local level = require "main.level"

local game = {}

function game.win()
	msg.post("/win#win", "show")
	msg.post("/chat#chat", "hide")
end

function game.start_next_level()
	if level.is_final() then
		msg.post("/title", "show")
	else
		level.next()
		msg.post("/bank/notes#notes", "show", {notes = level.get() - 1})
		if level.get() == 1 then
			msg.post("/chat#chat", "intro")
		end
	end
end

function game.is_final()
	return level.is_final()
end

return game