local color = require("druid.color")
local tweener = require("tweener.tweener")

---@class widget.health_bar: druid.widget
local M = {}


local COLOR_EXIST = color.get_color("#FF5765")
local COLOR_MISSING = color.get_color("#492B2D")

function M:init()
	self.hearts = {
		self:get_node("heart_1"),
		self:get_node("heart_2"),
		self:get_node("heart_3"),
	}
	self._state = {
		true,
		true,
		true,
	}
end


---@param entity entity?
function M:set_entity(entity)
	self.entity = entity
	if not entity then
		return
	end
end


function M:update_hearts(bar_beat_counter)
	-- Only at attack beats, it's 2 and 4
	if bar_beat_counter == 1 or bar_beat_counter == 3 then
		return
	end

	if not self.entity then
		return
	end

	local health = self.entity.field_actor.field_entity.health or self.entity.field_actor.health
	for index = 1, #self.hearts do
		local is_heart_should_exists = index <= health
		local is_heart_exists = self._state[index]
		if is_heart_should_exists ~= is_heart_exists then
			self._state[index] = is_heart_should_exists

			gui.set_scale(self.hearts[index], vmath.vector3(1.2, 1.2, 1))
			gui.animate(self.hearts[index], "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTSINE, 0.6)

			tweener.tween(gui.EASING_OUTSINE, 0, 1, 0.6, function(value)
				if is_heart_should_exists then
					local v = color.lerp(value, COLOR_MISSING, COLOR_EXIST)
					color.set_color(self.hearts[index], v)
				else
					local v = color.lerp(value, COLOR_EXIST, COLOR_MISSING)
					color.set_color(self.hearts[index], v)
				end
			end)
		end
	end
end


return M
