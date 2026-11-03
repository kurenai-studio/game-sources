local prompt = {}

local history = require "player2.history"
local character = require "player2.character"
local state = require "player2.state"

local base_prompt = ""
local max_words = 30

local function add_sentence(a, b)
	if a then
		if #a > 0 then
			a = a.." "
		end
	else
		a = ""
	end
	if b then
		return a..b
	else
		return a
	end
end

function prompt.get(options)
	if options.all then
		options.base = true
		options.character = true
		options.max_words = true
		options.history = true
		options.state = true
	end
	if options.retry then
		if options.retry >= 1 then
			options.max_words = false
		end
		if options.retry >= 2 then
			history.clear()
		end
	end
	local system_prompt = ""
	if options.base then
		system_prompt = add_sentence(system_prompt, base_prompt)
	end
	if options.character then
		system_prompt = add_sentence(system_prompt, character.get_prompt())
	end
	if options.max_words then
		local words = tonumber(options.max_words) or tonumber(max_words)
		if words then
			system_prompt = add_sentence(system_prompt, "The number of words in your response must be at maximum "..words.." words.")
		end
	end
	if options.history then
		local summary = history.get_summary()
		if summary then
			system_prompt = add_sentence(system_prompt, summary)
		end
	end
	local messages = {
		{role = "system", content = system_prompt}
	}
	if options.history then
		local unsummarized = history.get_unsummarized()
		if unsummarized then
			for k, v in pairs(unsummarized) do
				table.insert(messages, v)
			end
		end
	end
	if options.state then
		local state_descriptions = state.get_descriptions()
		if state_descriptions then
			table.insert(messages, {role = "system", content = state_descriptions})
		end
	end
	return messages
end

function prompt.set_base_prompt(s)
	base_prompt = s
end

return prompt