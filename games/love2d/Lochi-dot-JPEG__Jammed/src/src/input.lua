Inputs = {}
Inputs.down = { "down", "s" }
Inputs.up = { "up", "w" }
Inputs.left = { "left", "a" }
Inputs.right = { "right", "d" }
Inputs.continue = { "return" }

function input_pressed(inputs)
	for i = 1, #inputs do
		if love.keyboard.isDown(inputs[i]) then
			return true
		end
	end
	return false
end
