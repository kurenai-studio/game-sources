
local noblox = require("noblox")
Vector3 = noblox.vector3
CFrame = noblox.cframe
Model = noblox.model
g3d = noblox.g3d

local galaxyModule = require("galaxy1")

local n = 3000
local galaxy
local tetraScale = 1--0.5
local sy
local t = 0
local lastDt

love.load = function()
	galaxy = galaxyModule(n, os.time())
	print(#galaxy.all)
	local regions = {}
	for _, star in ipairs(galaxy.all) do
		--star.part = Model.new("assets/tetrahedron.obj", nil, CFrame.new(star.position))
		--star.part.color = Vector3.new(1, 0, 1)
		star.part = g3d.newModel("assets/tetrahedron.obj", nil, {Model.fromV3(star.position)})
		regions[star.region] = regions[star.region] and regions[star.region] + 1 or 1
	end
	for a, b in pairs(regions) do
		print(galaxy[a].name, b)
	end
	sky = Model.new("assets/sphere.obj", "assets/nebula3.png", nil, 900)
end

-- correct the camera view if the window size changes
love.resize = function()
	g3d.camera.aspectRatio = love.graphics.getWidth() / love.graphics.getHeight()
	g3d.camera.updateProjectionMatrix()
	g3d.camera.updateViewMatrix()
end

love.update = function(dt)
	g3d.camera.firstPersonMovement(dt)
	sky.cframe = CFrame.new(Model.getCameraCFrame().p)
	lastDt = dt
end

love.draw = function()
	sky:Draw()
	local d
	local windowSize = math.min(love.graphics.getDimensions()) / 2
	local windowDistance = windowSize / math.tan(g3d.camera.fov / 2)
	local camp = Model.getCameraCFrame().p
	for _, star in ipairs(galaxy.all) do
		d = g3d.vectors.magnitude(g3d.vectors.subtract(
			star.part.translation[1],
			star.part.translation[2],
			star.part.translation[3],
			g3d.camera.position[1],
			g3d.camera.position[2],
			g3d.camera.position[3]
		))
		star.part:setScale(d * tetraScale / windowDistance)
		if (star.rtimer == nil or star.rtimer <= 0) then
			star.part:setRotation(math.random() * 2 * math.pi, math.random() * 2 * math.pi, math.random() * 2 * math.pi)
			star.rtimer = math.random(1, math.ceil(1 / lastDt) * 2)
		else
			star.rtimer = star.rtimer - 1
		end
		star.part:draw()
	end
	love.graphics.print(
		string.format(
[[%.3f fps
%.3f, %.3f, %.3f
%.3f from origin]],
			1/ lastDt,
			camp.x, camp.y, camp.z,
			camp.magnitude
		)
	)
	love.graphics.print(
[[wasd: move
space: up
lshift: down
esc: close]],
		love.graphics.getWidth() - 100
	)
end

love.mousemoved = function(x, y, dx, dy)
	g3d.camera.firstPersonLook(dx,dy)
end

love.keypressed = function(key)
	if (key == "escape") then
		love.event.quit()
	elseif (key == "x") then
		t = 1
	elseif (key == "y") then
		t = 2
	elseif (key == "z") then
		t = 3
	elseif (key == "e") then
		t = 0
	elseif (key == "r") then
		t = -1
	end
end

