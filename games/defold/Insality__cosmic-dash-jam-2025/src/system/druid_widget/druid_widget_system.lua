local decore = require("decore.decore")
local druid = require("druid.druid")

---@class entity
---@field druid_widget component.druid_widget|nil

---@class entity.druid_widget: entity
---@field druid_widget component.druid_widget|nil

---@class component.druid_widget
---@field widget_id string?
---@field widget_class druid.widget
---@field widget druid.widget?
---@field command_on_add any[]
decore.register_component("druid_widget", {
	widget_class = nil, -- Path to the Druid widget class
	widget_id = "gui_compoment_id",
	widget = nil,
	command_on_add = nil,
})


---@class system.druid_widget: system
---@field entities entity.druid_widget[]
local M = {}


function M.create_system()
	return decore.system(M, "druid_widget", { "game_object", "druid_widget" })
end


---@param entity entity.druid_widget
function M:onAdd(entity)
	local widget_class = entity.druid_widget.widget_class
	local gui_url = msg.url(nil, entity.game_object.root, entity.druid_widget.widget_id)
	entity.druid_widget.widget = druid.get_widget(widget_class, gui_url, entity)
end


return M
