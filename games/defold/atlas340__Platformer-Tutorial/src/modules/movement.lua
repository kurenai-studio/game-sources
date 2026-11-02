-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

local Movement = {}


function Movement.walk(direction)
	local position = go.get_position() --get actual position of the current game object
	position.x = position.x + 5 * direction
	sprite.set_hflip("#sprite", direction < 0)
	go.set_position(position)-- set the new position of the current game object
end

return Movement