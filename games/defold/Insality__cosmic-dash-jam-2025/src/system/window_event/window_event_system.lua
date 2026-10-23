local events = require("event.events")
local decore = require("decore.decore")

---window.WINDOW_EVENT_FOCUS_GAINED | window.WINDOW_EVENT_FOCUS_LOST | window.WINDOW_EVENT_RESIZED
---@class system.window_event.event

---System that listens to window events and triggers events on the event bus
---@class system.window_event: system
local M = {}

local SAVE_FILE = sys.get_save_file(sys.get_config_string("project.title"), "window_state")

---@return system.window_event
function M.create_system()
	return decore.system(M, "window_event")
end


function M:onAddToWorld()
	self:restore_window_size()
	events.subscribe("decore.window_event", self.on_window_event, self)
end


function M:onRemoveFromWorld()
	events.unsubscribe("decore.window_event", self.on_window_event, self)
end


function M:on_window_event(event)
	self.world.event_bus:trigger("window_event", event)
end


function M:restore_window_size()
	local is_debug = sys.get_engine_info().is_debug
	local system_name = sys.get_sys_info().system_name
	local is_desktop = system_name == "Windows" or system_name == "Darwin" or system_name == "Linux"

	if not (defos and is_debug and is_desktop) then
		return
	end

	timer.delay(1, true, function()
		local x, y, w, h = defos.get_window_size()
		sys.save(SAVE_FILE, { x, y, w, h })
	end)

	-- Restore window size and position
	local prev_settings = sys.load(SAVE_FILE) or nil
	if prev_settings and #prev_settings > 0 then
		---@cast prev_settings number[]
		local x, y, w, h = unpack(prev_settings)
		-- Limit size to 300x200
		x = vmath.clamp(x or 0, 0, 4000)
		y = vmath.clamp(y or 0, 0, 4000)
		w = vmath.clamp(w or 300, 300, 4000)
		h = vmath.clamp(h or 200, 200, 4000)
		defos.set_window_size(x, y, w, h)
	end
end


return M
