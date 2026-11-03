local completions = {}

local api = require "player2.api"
local ai_tools = require "player2.tools"

local get_tools = ai_tools.get_table
local call_tool = ai_tools.call

local default_role = api.ROLE_USER

local config = {}

local function create_message(role, content)
	return {role = role or default_role, content = content or ""}
end

local function trim_response(s)
	s = string.match(s, "^\n*([^\n].*)") or s
	s = string.match(s, "(.*[^\n])\n*$") or s
	return s
end

function completions.set_tools(list)
	config.tools = list
end

function completions.set_max_tokens(n)
	config.max_tokens = n
end

function completions.set_temperature(n)
	config.temperature = n
end

function completions.create_messages(messages)
	if messages then
		if type(messages) == "string" then
			return {create_message(nil, messages)}
		elseif type(messages) == "table" then
			local list = {}
			for k, v in pairs({api.ROLE_SYSTEM, api.ROLE_DEVELOPER}) do
				if messages[v] then
					table.insert(list, create_message(v, messages[v]))
				end
			end
			for i, v in ipairs(messages) do
				if v.role and v.content then
					table.insert(list, v)
				else
					for role, content in pairs(v) do
						table.insert(list, create_message(role, content))
					end
				end
			end
			for k, v in pairs({api.ROLE_ASSISTANT, api.ROLE_TOOL, api.ROLE_USER}) do
				if messages[v] then
					table.insert(list, create_message(v, messages[v]))
				end
			end
			return list
		end
	else
		return {create_message()}
	end
end

---Post messages to the assistant and receive a reply.
---To post only a user message, use a string as message.
---For posting with other roles, use a table with the roles as key and message as value.
---Or post a list of tables, each with a 'role' and 'content' value.
---@param messages (string|table) The messages your are posting.
---@param tools (table|nil) A list of tools that the assistant can use.
---@param max_tokens (number|nil) The maximum number of tokens the assistant can use.
---@param temperature (number|nil) [0-2] Higher value will result in more random response.
---@param callback (function|nil) Function to call and send response to.
function completions.post(messages, tools, max_tokens, temperature, callback)
	tools = tools or config.tools
	max_tokens = max_tokens or config.max_tokens
	temperature = temperature or config.temperature or 1
	messages = completions.create_messages(messages)
	local data = {
		messages = messages,
		tools = get_tools(tools),
		max_tokens = max_tokens,
		temperature =  temperature,
		tool_choice = "auto",
		stream = false,
	}
	local info = {
		time_start = socket.gettime(),
		max_tokens = max_tokens,
		temperature = temperature,
	}
	api.chat_post_completions(data, function(response, error)
		if not response then
			if callback then
				callback(nil, nil, info, error)
			end
			return
		end
		local choices = response.choices
		if not choices or not choices[1] or not choices[1].message then
			return
		end
		local choice = choices[1]
		local message = choice.message
		local content = message.content
		if content then
			content = trim_response(content)
			if #content == 0 then 
				content = nil
			end
		end
		if response.usage then
			for k, v in pairs(response.usage) do
				info[k] = v
			end
		end
		info.time_finish = socket.gettime()
		info.duration = info.time_finish - info.time_start
		info.model = response.model
		info.id = response.id
		info.object = response.object
		info.finish_reason = choice.finish_reason
		info.role = message.role
		info.chars = 0
		info.words = 0
		if content then
			info.chars = #content
			_, info.words = content:gsub("%S+","")
		end
		local tool_calls = message.tool_calls
		if tool_calls then
			for k, v in pairs(tool_calls) do
				local f = v["function"]
				if f.arguments then
					local args = json.decode(f.arguments)
					local tool_reply = call_tool(f.name, args, content)
				end
				if ai_tools.is_response_blocked(f.name) then
					content = nil
				end
			end
		end
		if callback then
			callback(content, tool_calls, info)
		end
	end)
end

return completions