local tools = {}

local state = require "player2.state"

local list = {}

local function create_tool(name, description, properties, required)
	return {
		type = "function",
		["function"] = {
			name = name,
			description = description,
			parameters = {
				type = "object",
				properties = properties or {},
				required = required,
			},
		},
	}
end

function tools.get(name)
	local tool = list[name]
	if tool then
		return create_tool(name, tool.description, tool.properties, tool.required)
	end
end

local function is_tool_active(name)
	local tool = list[name]
	if not tool then
		return false
	end
	if tool.condition then
		if type(tool.condition) == "function" then
			return tool.condition(name)
		elseif type(tool.condition) == "string" then
			return state.get(tool.condition)
		end
	else
		return true
	end
end

local function get_active_names()
	local tool_names = {}
	for name, _ in pairs(list) do
		if is_tool_active(name) then
			table.insert(tool_names, name)
		end
	end
	return tool_names
end

function tools.get_all()
	local all = {}
	for _, name in pairs(get_active_names()) do
		table.insert(all, tools.get(name))
	end
	if #all > 0 then
		return all
	end
end

function tools.get_table(t)
	if not t then
		return
	elseif type(t) == "string" then
		if t == "all" then
			return tools.get_all()
		else
			return {tools.get(t)}
		end
	elseif type(t) == "table" then
		if type(t[1]) == "string" then
			local tool_list = {}
			for k, v in pairs(t) do
				table.insert(tool_list, tools.get(v))
			end
			return tool_list
		elseif type(t[1]) == "table" then
			return t
		end
	end
end

function tools.add(name, description, properties, required, block, condition, func)
	if required and #required == 0 then
		required = nil
	end
	list[name] = {description = description, properties = properties, required = required, block = block, condition = condition, func = func}
end

function tools.call(name, properties, reply)
	local tool = list[name]
	if tool and tool.func then
		return tool.func(properties, reply)
	end
end

function tools.is_response_blocked(name)
	local tool = list[name]
	return tool and tool.block
end

return tools