local lang = require("lang.lang")
local world = require("game.world")
local decore = require("decore.decore")

local memory_panel = require("widget.memory_panel.memory_panel")
local fps_panel = require("widget.fps_panel.fps_panel")
local properties_panel = require("widget.properties_panel.properties_panel")

local saver_debug_page = require("widget.debug_page_saver.debug_page_saver")
local lang_debug_page = require("widget.debug_page_lang.debug_page_lang")
local decore_debug_page = require("widget.debug_page_decore.debug_page_decore")

---@class widget.debug_panel: druid.widget
local M = {}

function M:init()
	gui.set_render_order(15)

	self.root = self:get_node("root")

	self.memory_panel = self.druid:new_widget(memory_panel, "memory_panel")
	self.fpp_panel = self.druid:new_widget(fps_panel, "fps_panel")

	self.properties_panel = self.druid:new_widget(properties_panel, "properties_panel")
	self.properties_panel:set_header("Debug Panel")
	self.properties_panel:set_hidden(true)

	self.properties_panel:add_button(function(button)
		button:set_text_property("Saver")
		button:set_text_button("Open")
		button.button.on_click:subscribe(function()
			saver_debug_page.render_properties_panel(self.druid, self.properties_panel)
		end)
	end)

	self.properties_panel:add_button(function(button)
		button:set_text_property("Lang")
		button:set_text_button("Open")
		button.button.on_click:subscribe(function()
			lang_debug_page.render_properties_panel(lang, self.druid, self.properties_panel)
		end)
	end)

	self.properties_panel:add_button(function(button)
		button:set_text_property("Decore")
		button:set_text_button("Open")
		button.button.on_click:subscribe(function()
			decore_debug_page.render_properties_panel(world, self.druid, self.properties_panel)
		end)
	end)

	self.properties_panel:add_button(function(button)
		local profiler_mode = nil
		button:set_text_property("Profiler")
		button:set_text_button("Toggle")
		button.button.on_click:subscribe(function()
			if not profiler_mode then
				profiler_mode = profiler.VIEW_MODE_MINIMIZED
				profiler.enable_ui(true)
				profiler.set_ui_view_mode(profiler_mode)
			elseif profiler_mode == profiler.VIEW_MODE_MINIMIZED then
				profiler_mode = profiler.VIEW_MODE_FULL
				profiler.enable_ui(true)
				profiler.set_ui_view_mode(profiler_mode)
			else
				profiler.enable_ui(false)
				profiler_mode = nil
			end
		end)
	end)
end


function M:update()
	local is_hidden = self.properties_panel:is_hidden()
	if self._is_hidden == is_hidden then
		return
	end

	self._is_hidden = is_hidden
	gui.set_enabled(self.memory_panel.root, not is_hidden)
	gui.set_enabled(self.fpp_panel.root, not is_hidden)
end


return M
