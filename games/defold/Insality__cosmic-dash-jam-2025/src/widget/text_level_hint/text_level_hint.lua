local lang = require("lang.lang")
local tweener = require("tweener.tweener")

---@class widget.text_level_hint: druid.widget
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.rich_text = self.druid:new_rich_text("text", "")
	self.rich_text:set_split_to_characters(true)

	self:set_text("")
end


---@param text_id string
function M:set_text(text_id)
	self:animate_text(text_id, nil)
end


---@private
function M:animate_text(text_id, on_node_appear)
	self._last_text_id = text_id

	if self._last_tweener then
		tweener.cancel(self._last_tweener)
	end

	self.rich_text:set_text(lang.txp(text_id))

	local rich_text_words = self.rich_text:get_words()

	for index = 1, #rich_text_words do
		local word = rich_text_words[index]
		gui.set_alpha(word.node, 0)
	end

	local last_index = 0
	self._last_tweener = tweener.tween(gui.EASING_OUTINSINE, 0, #rich_text_words, 1.2, function(value)
		local index = math.floor(value)
		if index > last_index then
			for i = last_index + 1, index do
				local word = rich_text_words[i]
				gui.animate(word.node, "color.w", 1, gui.EASING_OUTSINE, 0.3, 0)
				gui.set_scale(word.node, word.scale * 1.1)
				gui.animate(word.node, "scale", word.scale, gui.EASING_OUTSINE, 0.3, 0)

				gui.animate(word.node, "position.y", word.position.y - 4, gui.EASING_OUTSINE, 0.3, 0, function()
					gui.animate(word.node, "position.y", word.position.y, gui.EASING_OUTSINE, 0.4, 0)
				end, gui.PLAYBACK_ONCE_FORWARD)

				if on_node_appear then
					on_node_appear(word.node, word.node)
				end
			end

			last_index = index
		end
	end)
end


function M:clear_text()
	if self._last_tweener then
		tweener.cancel(self._last_tweener)
	end

	local rich_text_words = self.rich_text:get_words()

	local last_index = 0
	self._last_tweener = tweener.tween(gui.EASING_OUTINSINE, 0, #rich_text_words, 0.4, function(value)
		local index = math.floor(value)
		if index > last_index then
			for i = last_index + 1, index do
				local word = rich_text_words[i]
				gui.animate(word.node, "color.w", 0, gui.EASING_OUTSINE, 0.2, 0)
			end

			last_index = index
		end
	end)
end


function M:on_language_change()
	self:animate_text(self._last_text_id, nil)
end


return M
