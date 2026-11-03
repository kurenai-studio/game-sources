local audio = require("audio.audio")
local lang = require("lang.lang")
local event = require("event.event")
local color = require("druid.color")
local panthera = require("panthera.panthera")

local side_selector = require("widget.side_selector.side_selector")
local icon_turn_action = require("widget.icon_turn_action.icon_turn_action")

local animation = require("widget.turn_action_card.turn_action_card_panthera")

---@class widget.turn_action_card: druid.widget
---@field ability game.ability
---@field index integer
local M = {}


function M:init()
	self.on_drag = event.create()
	self.on_drag_end = event.create()

	self.root = self:get_node("root")
	self.group_description = self:get_node("group_description")

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())

	self.description = self.druid:new_rich_text("text_description")
	self.text_hint = self.druid:new_lang_text("text_hint", "ui_ability_hint")
	self.icon_turn_action = self.druid:new_widget(icon_turn_action, "icon_turn_action")
	self.side_selector = self.druid:new_widget(side_selector, "side_selector")
	self.fx_hint = self:get_node("fx_hint")

	self.drag = self.druid:new_drag(self.root, self._on_drag)
	self.drag.on_touch_start:subscribe(self._on_drag_start)
	self.drag.on_touch_end:subscribe(self._on_drag_end)
	--self.drag.on_drag_start:subscribe(self._on_drag_start)
	self.drag.on_drag_end:subscribe(self._on_drag_end)
	self.drag.hover.on_mouse_hover:subscribe(self._on_drag_hover, self)

	self.index = 1

	gui.set_enabled(self.text_hint.node, false)
	gui.set_enabled(self.side_selector.root, false)
	self.start_position = gui.get_position(self.icon_turn_action.root)
end


function M:onRemove()
	panthera.stop(self.animation)
	self.index = nil
end


function M:on_language_change()
	self.description:set_text(lang.txt(self.ability.description))
end


---@param ability game.ability
function M:set_ability(ability)
	self.ability = ability
	self.description:set_text(lang.txt(ability.description))
	self.icon_turn_action:set_icon(ability.icon)
	self.icon_turn_action:set_color(ability.color)
	self.side_selector:set_color(ability.color, ability.color_back)

	color.set_color(self.fx_hint, ability.color)
end


function M:_on_drag_hover(_, is_hover)
	if is_hover then
		gui.animate(self.group_description, "scale", vmath.vector3(1.1), gui.EASING_OUTSINE, 0.15)
	else
		gui.animate(self.group_description, "scale", vmath.vector3(1), gui.EASING_OUTSINE, 0.15)
	end
end


function M:_on_drag_start()
	gui.set_enabled(self.description.root, false)
	gui.set_enabled(self.text_hint.node, true)

	self.side_selector:set_enabled(true, function()
		self.icon_turn_action:set_top_layer(true)
	end)

	gui.animate(self.icon_turn_action.root, gui.PROP_SCALE, vmath.vector3(0.9), gui.EASING_OUTBACK, 0.2)

	audio.play("fx_action_select")
end


function M:on_music_beat(bar_beat_counter)
	if bar_beat_counter == self.index then
		panthera.play(self.animation, "on_beat", panthera.OPTIONS_SKIP_INIT)
	end
end


function M:_on_drag(dx, dy, x, y, touch)
	local side = self.side_selector:set_angle(math.deg(math.atan2(y, x)))
	self.on_drag:trigger(self.ability, side)
end


function M:_on_drag_end()
	local is_active = gui.is_enabled(self.description.root)

	gui.set_enabled(self.description.root, true)
	gui.set_enabled(self.text_hint.node, false)

	self.side_selector:set_enabled(false, function()
		self.icon_turn_action:set_top_layer(false)
	end)

	--gui.animate(self.icon_turn_action.root, "position", self.start_position, gui.EASING_OUTBACK, 0.3)
	if is_active then
		self.on_drag_end:trigger(self.ability)
		audio.play("fx_action_selected")
	end
	gui.animate(self.icon_turn_action.root, gui.PROP_SCALE, vmath.vector3(1), gui.EASING_OUTBACK, 0.2)
end


function M:set_index(index)
	self.index = index

	self.icon_turn_action.button_input_hint:set_enabled(index == 1)
end


return M
