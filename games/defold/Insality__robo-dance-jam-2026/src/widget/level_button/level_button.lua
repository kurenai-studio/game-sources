local color = require("druid.color")
local event = require("event.event")

---@class widget.level_button: druid.widget
local M = {}


local STATES = {
	["completed"] = {
		image = "level_completed",
		text_color = "#D0F9B5"
	},
	["current"] = {
		image = "level_current",
		text_color = "#595B30",
	},
	["blocked"] = {
		image = "level_blocked",
		text_color = "#51575F",
	},
}

function M:init()
	self.on_click = event.create()

	self.root = self:get_node("root")
	self.level_back = self:get_node("level_back")
	self.text = self.druid:new_text("text")

	self.button = self.druid:new_button("root", self._on_click)
end


---@param state "completed" | "current" | "blocked"
function M:set_state(state)
	self.state = state
	gui.play_flipbook(self.level_back, STATES[state].image)
	color.set_color(self.text.node, STATES[state].text_color)
end


---@param level number
---@param level_id string
function M:set_text(level, level_id)
	self.level = level
	self.level_id = level_id

	self.text:set_text(tostring(level))
end


---@private
function M:_on_click()
	self.on_click:trigger(self.level_id)
end


return M
