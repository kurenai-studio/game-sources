--- Event holds a list of callbacks that can all be invoked at once.
-- classmod: Event

Object = require "classic"
local Event = Object:extend()


function Event:new()
	self._callbacks = {}
end


--- Subscribe to the event.
-- function: func  Callback function.
-- ?Object: obj    Object to call the function on.
function Event:add(func, obj)
	table.insert(self._callbacks, {obj = obj, func = func})
end


--- Invoke all callbacks with the desired arguments.
function Event:invoke(...)
	for i, callback in pairs(self._callbacks) do
		if callback.obj then
			callback.func(callback.obj, ...)
		else
			callback.func(...)
		end
	end
end


return Event
