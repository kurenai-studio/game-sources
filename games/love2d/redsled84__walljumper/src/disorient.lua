local disorient = {}

local theta = 0
function disorient.disorient(dx, dy, speed)
	local dt = love.timer.getDelta()
	theta = theta + speed * dt
	love.graphics.shear(dx * math.cos(theta), dy * math.sin(theta))
end

function disorient.getTheta()
	return theta
end

return disorient