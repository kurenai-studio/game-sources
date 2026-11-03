local state = {}

local variables = {}
local descriptions = {}

function state.get(key)
	return variables[key]
end

function state.set(key, value, description)
	variables[key] = value
	if description ~= nil then
		descriptions[key] = description
	end
end

function state.clear()
	variables = {}
end

function state.get_descriptions()
	local full_description = ""
	local sep = ""
	for k, v in pairs(variables) do
		local formated
		local description = descriptions[k]
		if description then
			if type(description) == "string" then
				formated = string.format(description, v)
			elseif type(description) == "function" then
				formated = description(v, k)
			end
		end
		if formated then
			full_description = full_description..sep..formated
			sep = " "
		end
	end
	return full_description
end

return state