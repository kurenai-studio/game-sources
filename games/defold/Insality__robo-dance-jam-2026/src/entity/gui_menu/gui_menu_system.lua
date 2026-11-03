local event = require("event.event")
local decore = require("decore.decore")

local music_command = require("system.music.music_command")


---@class entity
---@field gui_menu component.gui_menu|nil

---@class entity.gui_menu: entity
---@field gui_menu component.gui_menu

---@class component.gui_menu
---@field on_play event
---@field on_level_select event
---@field on_menu event
decore.register_component("gui_menu", {
	on_menu = event.create(),
	on_play = event.create(),
	on_level_select = event.create(),
})

---@class system.gui_menu: system
---@field entities entity.gui_menu[]
local M = {}


---@return system.gui_menu
function M.create()
	return decore.system(M, "gui_menu", { "gui_menu" })
end


function M:onAdd(entity)
	self.widget = entity.druid_widget.widget --[[@as widget.gui_menu]]
	music_command.on_beat:subscribe(self.widget.on_beat, self.widget)
end


function M:onRemove()
	music_command.on_beat:unsubscribe(self.widget.on_beat, self.widget)
end


return M
