local chat = {}

local api = require "player2.api"
local history = require "player2.history"
local prompt = require "player2.prompt"
local custom_tools = require "player2.tools"
local completions = require "player2.completions"

local get_tools = custom_tools.get_table

local config = {}
local retries = 2
local print_reply = true
local print_info = false

local function chat_post(message, tools, callback, retry)
	local messages = prompt.get({all = true, retry = retry})
	local new_messages = completions.create_messages(message)
	for k, v in pairs(new_messages) do
		table.insert(messages, v)
	end
	local tool_list = get_tools(tools)
	local max_tokens = config.max_tokens
	local temperature = config.temperature
	completions.post(messages, tool_list, max_tokens, temperature, function(content, tool_calls, info, error)
		if content or tool_calls then
			for _, v in pairs(new_messages) do
				if v.role ~= api.ROLE_SYSTEM then
					history.add(v.role, v.content)
				end
			end
			if content then
				history.add(info.role, content)
				history.fit()
				if print_reply then
					print(content)
				end
				if print_info then
					print("  (t="..string.format("%.2f", info.duration).."s prompt="..info.prompt_tokens.." completion="..info.completion_tokens..")")
				end
				if callback then
					callback(content, tool_calls, info)
				end
			end
		else
			if not retry then
				retry = 0
			end
			if retries and retry < retries then
				retry = retry + 1
				print("Empty response from agent. Retry "..retry.."/"..retries)
				chat_post(message, tools, callback, retry)
			else
				print("Empty response from agent. Stopped.")
				if callback then
					callback(nil, nil, info)
				end
			end
		end
	end)
end

---Post messages to the assistant and receive a reply.
---The previous history will be added as context to the chat.
---To post only a user message, use a string as message.
---For posting with other roles, use a table with the roles as key and message as value.
---Or post a list of tables, each with a 'role' and 'content' value.
---@param message (string|table) The message your are posting.
---@param tools (table|nil) A list of tools that the assistant can use.
---@param callback (function|nil) Function to call and send response to.
function chat.post(message, tools, callback)
	chat_post(message, tools, callback)
end

function chat.set_config(key, value)
	config[key] = value
end

return chat