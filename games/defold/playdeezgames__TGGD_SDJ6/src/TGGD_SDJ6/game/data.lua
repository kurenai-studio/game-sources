local states = require("game.states")

local M = {}

local data = {}


function M.new_game()
	data = {}
	M.set_score(0)
	M.clear_messages()
	M.add_message("YER ALIVE!")
end

function M.set_score(value)
	data.score = value
end

function M.get_score()
	return data.score
end

function M.clear_messages()
	data.messages={}
end

function M.add_message(message)
	table.insert(data.messages, message)
end

function M.get_messages()
	return data.messages
end

function M.set_lizzid(flag)
	data.lizzid = flag
end

function M.get_lizzid()
	return data.lizzid
end


function M.generate()
	M.set_lizzid(math.random(1,2)==1)
	M.add_message("YOU ENCOUNTER WHAT SEEMS TO BE APERSON!")
	return states.CHOOSE
end

function M.continue_game()
	M.clear_messages()
	M.add_message("YOU CONTINUE ONWARD!")
	return M.generate()
end

function M.accept()
	M.clear_messages()
	M.add_message("YOU ACCEPT THEM AS HUMAN.")
	if M.get_lizzid() then
		M.add_message("YOU COULD NOT HAVE BEEN MORE    WRONG!")
		M.add_message("MOMENTS LATER, YOU ARE TORN LIMBFROM LIMB BY LIZZID PEOPLE AND  YER FLESH IS CONSUMED RAW!")
		return states.DEAD
	else
		M.set_score(M.get_score()+1)
		M.add_message("AND THEY WERE, WHEW!")
		M.add_message("YER STILL ALIVE!")
		return states.IN_PLAY
	end
end

function M.denounce()
	M.clear_messages()
	M.add_message("YOU DENOUNCE THEM AS A LIZZID   PERSON.")
	if M.get_lizzid() then
		M.set_score(M.get_score()+1)
		M.add_message("AND THEY WERE, WHEW!")
		M.add_message("YER STILL ALIVE!")
		return states.IN_PLAY
	else
		M.add_message("YOU COULD NOT HAVE BEEN MORE    WRONG!")
		M.add_message("MOMENTS LATER, YOU ARE TORN LIMBFROM LIMB BY HUMANS FOR YER     FALSE ACCUSATION!")
		return states.DEAD
	end
end

return M
