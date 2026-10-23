local staticAsteroids = {
	{219,  380, 0},
	{211,  500, 140},
	{282,  861, 0},
	{288,  837, 0},
	{120,  265, 10},
	{71,   805, 0},
	{260,  313, 0},
	{183,  490, 0},
	{199,  500, 0},
	{203,  400, 70},
	{310,  160, 100},
	{330,  346, 0},
	{240,  410, 30},
	{237,  325, 0},
	{60,   250, 30},
	{192,  510, 90},
	{5,    545, 0},
	{90,   200, 60},
	{49,   435, 0},
	{290,  826, 0},
	{},
	{},
	{46,   496, 0},
	{190,  440, 200},
	{78,   888, 0},
}

local logo = {}

local INDEX = false

function logo.gen()
	love.math.setRandomSeed(2)

	ship:set(1)
	ship.angle = math.rad(220)

	ship.active = true
	laser.active = true
	laser:update(1)
	laser.heat = 100

	for i, as in pairs(staticAsteroids) do
		if #as > 0 then
			local asteroid = Asteroid(asteroids)
			table.insert(asteroids.asteroids, asteroid)
			asteroid.position.x = ship.position.x + math.cos(math.rad(as[1])) * as[2]
			asteroid.position.y = ship.position.y + math.sin(math.rad(as[1])) * as[2]
			asteroid.angle = math.rad(as[3])
			asteroid:updatePositions()
			asteroid.body:setPosition(asteroid.position.x, asteroid.position.y)
			asteroid.body:setLinearVelocity(0, 0)
			if INDEX then
				asteroid.index = i
			end
		end
	end

	asteroids.pauseState = true
end

function logo.draw()
	love.graphics.print(
		LOCALIZATIONS[1].gameName,
		350,
		love.graphics.getHeight() / 2 + 80,
		0, 2
	)
end

return logo
