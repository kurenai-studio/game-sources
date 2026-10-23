local event = require("event.event")
local color = require("druid.color")
local fill_dots = require("widget.fill_dots.fill_dots")
local tweener = require("tweener.tweener")
local utf8 = require("druid.system.utf8")

---@class widget.level_header: druid.widget
local M = {}


function M:init()
	self.on_level_prev = event.create()
	self.on_level_next = event.create()

	self.text = self.druid:new_lang_text("text")
	self.fill_dots = self.druid:new_widget(fill_dots, "fill_dots")
	self.fill_dots:set_dots(5)
	self.button_level_prev = self.druid:new_button("button_level_prev", self.on_button_level_prev)
	self.button_level_next = self.druid:new_button("button_level_next", self.on_button_level_next)
end


function M:set_text(text)
	self._last_text_id = text
	self.text:translate(text)
	self:animate_text()
end


function M:on_button_level_prev()
	if not self._is_prev_available then
		return
	end

	self.on_level_prev:trigger()
end


function M:on_button_level_next()
	if not self._is_next_available then
		return
	end

	self.on_level_next:trigger()
end


function M:set_enabled_change_buttons(is_prev_available, is_next_available)
	self._is_prev_available = is_prev_available
	self._is_next_available = is_next_available

	gui.set_alpha(self.button_level_prev.node, self._is_prev_available and 1 or 0.4)
	gui.set_alpha(self.button_level_next.node, self._is_next_available and 1 or 0.4)
end


function M:animate_text()
	local full_text = self.text.text:get_text()
	local full_text_length = utf8.len(full_text)

	if self._tween then
		tweener.cancel(self._tween)
	end

	self._tween = tweener.tween(gui.EASING_OUTINSINE, 0, 1, 2.5, function(progress, is_final_call)
		local displayed_text = ""

		for i = 1, full_text_length do
			local char_progress = (progress * full_text_length) - (i - 1)

			if char_progress <= 0 then
				-- Character hasn't started appearing yet
				break
			elseif char_progress < 0.5 then
				-- First half of character animation - show "?"
				displayed_text = displayed_text .. "?"
			else
				-- Second half of character animation - show actual character
				displayed_text = displayed_text .. utf8.sub(full_text, i, i)
			end
		end

		self.text:set_to(displayed_text)

		if is_final_call then
			self.text:set_to(full_text)
		end
	end)
end


function M:on_language_change()
	self.text:translate(self._last_text_id)
	self:animate_text()
end


function M:set_level_status(current_level, level_count)
	self.fill_dots:set_level_status(current_level, level_count)
end


---@param color_id color
function M:set_color(color_id)
	color.set_color(self.text.node, color_id)
	color.set_color(self:get_node("icon_level_next"), color_id)
	color.set_color(self:get_node("icon_level_prev"), color_id)
	self.fill_dots:set_color(color_id)
end


return M
