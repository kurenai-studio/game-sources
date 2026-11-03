local friends = {}

local api = require "player2.api"

local selected_characters = api.selected_characters

local characters

function friends.get(callback)
	selected_characters(function(response, error)
		if response then
			characters = response.characters
			if callback then
				callback(characters)
			end
		end
	end)
	return characters
end

return friends