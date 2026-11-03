local inputfield = {}
inputfield.__index = inputfield

local TEXT = hash("text")
local ENTER = hash("key_enter")
local BACKSPACE = hash("key_backspace")
local LCTRL = hash("key_lctrl")
local RCTRL = hash("key_rctrl")

local fields = {
	default = {}
}
local inputs = {}
local previous_inputs = {}

function inputfield.new(id, callback)
	local field = {}
	field.url = msg.url()
	field.id = id
	field.callback = callback
	field.text = ""
	fields[id] = field
	setmetatable(fields, inputfield)
	return field
end

local function post(field, message_id, message)
	if field.url then
		msg.post(field.url, message_id, message)
	end
end

function inputfield.set_text(field, s)
	field.text = s or ""
	if field.max_chars and #field.text > field.max_chars then
		field.text = string.sub(field.text, 1, field.max_chars)
	end
	if field.force_caps then
		field.text = string.upper(field.text)
	end
	if field.url == msg.url() then
		gui.set_text(gui.get_node(field.id), field.text)
	else
		post(field, "inputfield.set_text")
	end
end

function inputfield.add_text(field, s)
	if tostring(s) and #tostring(s) > 0 then
		inputfield.set_text(field, field.text .. s)
	end
end

local function delete_character(field)
	if #field.text > 0 then
		inputfield.set_text(field, string.sub(field.text, 1, -2))
	end
end

local function delete_word(field)
	local s = string.match(field.text, "(.*%s+)%S+%s*$")
	inputfield.set_text(field, s)
end

function inputfield.clear(field)
	inputfield.set_text(field, nil)
end

function inputfield.update()
	previous_inputs = inputs
	inputs = {}
end

function inputfield.on_input(field, action_id, action)
	if action_id then
		inputs[action_id] = true
	end
	if action_id == TEXT then
		inputfield.add_text(field, action.text)
	elseif action.repeated and action_id == BACKSPACE then
		if inputs[LCTRL] or inputs[RCTRL] or previous_inputs[LCTRL] or previous_inputs[RCTRL] then
			delete_word(field)
		else
			delete_character(field)
		end
	elseif action.pressed and action_id == ENTER then
		post(field, "inputfield.enter", {text = field.text})
		inputfield.clear(field)
	end
end

function inputfield.on_message(field, message_id, message)
	if message_id == hash("inputfield.set_text") then
		inputfield.set_text(field, field.text)
	elseif message_id == hash("inputfield.enter") then
		if field.callback then
			field.callback(message.text)
		end
	end
end

return inputfield