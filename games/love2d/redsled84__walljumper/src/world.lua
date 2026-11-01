local bump = require 'bump'
local world = {}

function world.load()
	world.bump = bump.newWorld()
end

return world