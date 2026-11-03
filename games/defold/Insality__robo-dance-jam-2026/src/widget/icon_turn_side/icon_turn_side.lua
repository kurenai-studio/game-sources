local event = require("event.event")
local color = require("druid.color")
local panthera = require("panthera.panthera")
local animation = require("widget.icon_turn_side.icon_turn_side_panthera")

---@class widget.icon_turn_side: druid.widget
local M = {}


local SIDE_ANGLE = {
	["up"] = 180,
	["left"] = 90,
	["down"] = 0,
	["right"] = 270,
}


function M:init()
	self.on_click = event.create()

	self.root = self:get_node("root")
	self.icon_turn = self:get_node("icon_turn")

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	self.animation_cancel = panthera.clone_state(self.animation)
	self.animation_appear = panthera.clone_state(self.animation)

	self.panel = self:get_node("panel")
	self.panel_side = self:get_node("panel_side")
	self.button = self.druid:new_button(self.root, self.on_icon_click)

	self.button.hover.on_mouse_hover:subscribe(self._on_mouse_hover, self)
end


---@param ability game.ability|nil
---@param side "up" | "down" | "left" | "right" | "none" | nil
function M:set_ability(ability, side)
	if self.ability == ability and self.side == side then
		return
	end

	self.ability = ability
	self.side = side

	if ability then
		self:set_color(ability.color)
		self:set_icon(ability.icon)

		--gui.set_enabled(self.panel, true)
		gui.set_alpha(self.panel, 1)
		--gui.set_enabled(self:get_node("empty"), false)
		gui.set_alpha(self:get_node("empty"), 0)
		panthera.play(self.animation_appear, "appear")
	else
		--gui.set_enabled(self.panel, false)
		gui.set_alpha(self.panel, 0)
		--gui.set_enabled(self:get_node("empty"), true)
		gui.set_alpha(self:get_node("empty"), 1)
	end

	self:set_side(side)
end


function M:clear_ability()
	self.ability = nil
	self.side = nil
	if gui.get_alpha(self.panel) > 0 then
		--gui.set_enabled(self.panel, false)
		gui.set_alpha(self.panel, 0)

		--gui.set_enabled(self:get_node("empty"), true)
		gui.set_alpha(self:get_node("empty"), 1)
	end
end


---@param index integer
function M:set_index(index)
	self.index = index
end


function M:set_color(color_id)
	color.set_color(self:get_node("panel_side"), color_id)
end


function M:set_icon(icon)
	gui.play_flipbook(self.icon_turn, icon)
end


function M:set_side(side)
	local side_angle = SIDE_ANGLE[side]
	if side_angle then
		gui.set(self.panel_side, "euler.z", SIDE_ANGLE[side])
		gui.set_enabled(self.panel_side, true)
	else
		gui.set_enabled(self.panel_side, false)
	end
end


---@return "up" | "down" | "left" | "right" | "none" | nil
function M:get_side()
	return self.side
end


---@return game.ability|nil
function M:get_ability()
	return self.ability
end


---@return integer
function M:get_index()
	return self.index
end


function M:on_icon_click()
	self.on_click:trigger(self)
	self:_on_mouse_hover(nil, false)
end


function M:_on_mouse_hover(_, is_hover)
	self._is_hover = is_hover
	if is_hover then
		if not self._is_turn_execution_running then
			panthera.play(self.animation_cancel, "remove_on", panthera.OPTIONS_SKIP_INIT)
		end
	else
		panthera.play(self.animation_cancel, "remove_off", panthera.OPTIONS_SKIP_INIT)
	end
end


function M:set_turn_execution_running(is_running)
	self._is_turn_execution_running = is_running
	if self._is_hover and is_running then
		self:_on_mouse_hover(nil, false)
	end
end


function M:on_music_beat(bar_beat_counter)
	if bar_beat_counter == self.index then
		panthera.play(self.animation, "empty")
	end
end


return M

