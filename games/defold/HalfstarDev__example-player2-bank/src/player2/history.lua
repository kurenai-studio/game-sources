local history = {}

local api = require "player2.api"
local completions = require "player2.completions"

local ceil = math.ceil

local character_limit = 10000
local save_log = false
local print_info = false
local log_folder = "player2_log"
local summary_prompt = "Please summarize the following conversation in natural language, prioritizing important facts, and things the user asked you to remember, but use not more than %i chars: %s"

local full_log = {}
local log = {}
local summary
local summarized = 0
local file_name

local function save_to_file()
	if not save_log then return end
	local text = ""
	for k, v in pairs(full_log) do
		if v.role and v.content and v.role ~= "system" then
			text = text..v.role..":\n"..v.content.."\n\n"
		end
	end
	if not file_name then
		file_name = os.date("%Y%m%d_%H%M%S")..".txt"
	end
	local path = sys.get_save_file(log_folder, file_name)
	local file = io.open(path, "w")
	if file then
		file:write(text)
		file:close()
	end
end

local function get_messages(from, to)
	if not from or from < 1 then
		from = 1
	end
	if not to or to > #log then
		to = #log
	end
	local messages = {}
	if from <= summarized then
		table.insert(messages, summary)
	end
	if to > summarized then
		local start
		if from <= summarized then
			start = summarized + 1
		else
			start = from
		end
		for i = start, to do
			table.insert(messages, log[i])
		end
	end
	return messages
end

local function to_text(tab)
	local s = '"""\n'
	for k, v in pairs(tab) do
		if v.content and #v.content > 0 and v.content ~= "..." then
			s = s..' ('..v.role..' said: '..v.content..')'
		else
			s = s..' ('..v.role..' stayed quiet.)'
		end
	end
	s = s..'"""'
	return s
end

local function summarize(from, to)
	local messages = get_messages(from, to)
	local encoded = to_text(messages)
	local question = string.format(summary_prompt, ceil(character_limit/3), encoded)
	messages = {{role = api.ROLE_SYSTEM, content = question}}
	completions.post(messages, nil, nil, nil, function(content, tool_calls, info)
		if content and to > summarized then
			summary = {role = api.ROLE_SYSTEM, content = content}
			summarized = to
			if print_info then
				print(#content, "Summary:", summary.content)
			end
		end
	end)
end

local function fit_to_limit()
	local messages = get_messages()
	local counter = {}
	local count = 0
	for i, v in ipairs(messages) do
		count = count + string.len(v.content or "")
		counter[i] = count
	end
	if count > character_limit then
		for i, v in ipairs(counter) do
			if v > character_limit * 2 / 3 then
				summarize(1, i + summarized)
				return
			end
		end
	end
	if print_info then
		print("History limit: "..(count/character_limit*100).."%.")
	end
end

function history.add(role, content)
	table.insert(log, {role = role, content = content})
	table.insert(full_log, {role = role, content = content})
	save_to_file()
end

function history.get_messages()
	return get_messages()
end

function history.get_summary()
	if summary then
		return summary.content
	end
end

function history.get_unsummarized()
	return get_messages(summarized + 1)
end

function history.fit()
	fit_to_limit()
end

function history.clear()
	log = {}
end

function history.roll_back(by)
	for i = 1, by do
		if #log > 0 then
			log[#log] = nil
		end
	end
end

function history.set_limit(chars)
	character_limit = chars
end

return history