local character = {}

local characters = {
	default = {},
}
local current_character = "default"

function character.get_prompt()
	local prompt = ""
	local sep = ""
	if characters[current_character] then
		for k, v in pairs(characters[current_character]) do
			if v then
				prompt = prompt..sep..k
				sep = " "
			end
		end
	end
	if #prompt > 0 then
		return prompt
	end
end

function character.add_info(info)
	if not characters[current_character] then
		characters[current_character] = {}
	end
	characters[current_character][info] = true
end

function character.remove_info(info)
	if not characters[current_character] then
		characters[current_character] = {}
	end
	characters[current_character][info] = nil
end

function character.clear()
	characters[current_character] = {}
end

return character