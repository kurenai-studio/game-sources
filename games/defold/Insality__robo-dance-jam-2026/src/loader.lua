local log = require("log.log")
local lang = require("lang.lang")
local audio = require("audio.audio")
local druid = require("druid.druid")
local saver = require("saver.saver")
local event = require("event.event")
local levels = require("game.levels")
local events = require("event.events")
local decore = require("decore.decore")
local detiled = require("detiled.detiled")
local panthera = require("panthera.panthera")

local sounds = require("game.sounds")


local M = {}

function M.init()
	M.init_random()
	M.init_logger()
	M.init_druid()
	M.init_window_listener()
	M.init_event()
	M.init_saver()
	M.init_audio()
	M.init_lang()
	M.init_defos()
	M.init_detiled()
end


function M.init_random()
	math.randomseed(socket.gettime())
	math.random()
	math.random()
	math.random()
end


function M.init_defos()
	if not defos then
		return
	end

	local is_debug = sys.get_engine_info().is_debug
	local system_name = sys.get_sys_info().system_name
	local is_desktop = system_name == "Windows" or system_name == "Darwin" or system_name == "Linux"

	if is_debug and is_desktop then
		timer.delay(1, true, function()
			local x, y, w, h = defos.get_window_size()
			saver.set_value("window.last_state", { x, y, w, h })
		end)

		-- Restore window size and position
		local displays = defos.get_displays()
		local current_id = defos.get_current_display_id()
		local bounds = displays[current_id].bounds
		local prev_settings = saver.get_value("window.last_state")
		if prev_settings then
			---@cast prev_settings number[]
			local x, y, w, h = unpack(prev_settings)

			-- Limit size to fit in bounds, keep minimum size
			w = vmath.clamp(w, 300, bounds.width)
			h = vmath.clamp(h, 200, bounds.height)

			-- Move inside bounds if outside
			x = math.max(bounds.x, math.min(x, bounds.x + bounds.width - w))
			y = math.max(bounds.y, math.min(y, bounds.y + bounds.height - h))
			defos.set_window_size(x, y, w, h)
		else
			-- If current window size bigger than display size, set it to display size
			local x, y, w, h = defos.get_window_size()

			-- Limit size to fit in bounds
			w = math.min(w, bounds.width)
			h = math.min(h, bounds.height)
			-- Move inside bounds if outside
			x = math.max(bounds.x, math.min(x, bounds.x + bounds.width - w))
			y = math.max(bounds.y, math.min(y, bounds.y + bounds.height - h))

			defos.set_window_size(x, y, w, h)
		end
	end
end


function M.init_logger()
	lang.set_logger(log.get_logger("lang"))
	event.set_logger(log.get_logger("event"))
	saver.set_logger(log.get_logger("saver", "INFO"))
	audio.set_logger(log.get_logger("audio"))
	decore.set_logger(log.get_logger("decore", "DEBUG"))
	detiled.set_logger(log.get_logger("detiled"))
	panthera.set_logger(log.get_logger("panthera"))
end


function M.init_druid()
	druid.set_text_function(lang.txp)
end


function M.init_window_listener()
	window.set_listener(function(_, window_event)
		druid.on_window_callback(window_event)
		events.trigger("decore.window_event", window_event)
	end)
end


function M.init_event()
	event.set_mode("xpcall")
end


function M.init_saver()
	---@class saver.game_state
	---@field lang lang.state
	---@field audio audio.state
	---@field levels game.levels.state

	saver.before_save_callback = function()
		events.trigger("saver.before_save")
	end

	saver.init()
	saver.bind_save_state("lang", lang.state)
	saver.bind_save_state("audio", audio.get_state())
	saver.bind_save_state("levels", levels.state)
end


function M.init_audio()
	audio.init(sounds)
end


function M.init_lang()
	lang.init({
		{ id = "en", path = "/assets/locales/en.json" },
		{ id = "ru", path = "/assets/locales/ru.json" },
		{ id = "lt", path = "/assets/locales/lt.json" },
		{ id = "es", path = "/assets/locales/es.json" },
		{ id = "fr", path = "/assets/locales/fr.json" },
		{ id = "pl", path = "/assets/locales/pl.json" },
	})
end


function M.init_detiled()
	detiled.load_tileset("/tiled/tilesets/tileset.json")
end


return M
