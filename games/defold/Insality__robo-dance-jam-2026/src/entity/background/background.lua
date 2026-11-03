local color = require("druid.color")
local tweener = require("tweener.tweener")
local panthera = require("panthera.panthera")
local animation = require("entity.background.background_panthera")


---@class widget.background: druid.widget
local M = {}

local COLOR_IDLE = color.get_color("#4f63c0")
local COLOR_BATTLE = color.get_color("#5f8bdb")

function M:init()
	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	self.animation_fx = panthera.clone_state(self.animation)
	self.node_background = self:get_node("background")
	panthera.play(self.animation, "default", panthera.OPTIONS_LOOP)
end


---@param is_battle boolean
function M:set_battle_state(is_battle)
	tweener.tween(gui.EASING_OUTSINE, 0, 1, 0.6, function(value)
		if is_battle then
			local lerp = color.lerp(value, COLOR_IDLE, COLOR_BATTLE)
			color.set_color(self.node_background, lerp)
		else
			local lerp = color.lerp(value, COLOR_BATTLE, COLOR_IDLE)
			color.set_color(self.node_background, lerp)
		end
	end)
end


---@param bar_beat_counter integer
function M:on_beat(bar_beat_counter)
	panthera.play(self.animation_fx, "on_beat")
end


return M
