local level_button = require("widget.level_button.level_button")

---@class widget.gui_level_select: druid.widget
local M = {}


---@param entity entity.gui_level_select
function M:init(entity)
	self.entity = entity
	self.root = self:get_node("root")
	self.button_menu = self.druid:new_button("button_menu", entity.gui_level_select.on_menu)
	self.druid:new_lang_text("text_back", "ui_back")

	self.button_back = self.druid:new_button("button_back", entity.gui_level_select.on_back)
	self.button_back:set_key_trigger("key_esc")

	self.layout = self.druid:new_layout("levels", "horizontal_wrap")
	self._levels = {}

	gui.set_enabled(self:get_node("level_button/root"), false)
end


---@param levels table<number, { level: number, level_id: string, state: "completed" | "current" | "blocked" }>
function M:set_levels(levels)
	self.layout:clear_layout()
	for i = 1, #self._levels do
		gui.delete_node(self._levels[i].root)
		self.druid:remove(self._levels[i])
	end
	self._levels = {}

	for i = 1, #levels do
		local level = levels[i]
		local level_button = self.druid:new_widget(level_button, "level_button", "root")
		level_button:set_text(level.level, level.level_id)
		level_button:set_state(level.state)
		level_button.on_click:subscribe(self.entity.gui_level_select.on_level_click)

		gui.set_enabled(level_button.root, true)
		table.insert(self._levels, level_button)
		self.layout:add(level_button.root)
	end
end


return M
