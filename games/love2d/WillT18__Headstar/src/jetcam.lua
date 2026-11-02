--local g3d = require("g3d")
-- TODO remove dependency on CFrame
local Vector3 = require("galaxy").vector3
local CFrame = require("galaxy").cframe

local origin = CFrame.new()
local up = Vector3.new(0, 1, 0)
local xz = Vector3.new(1, 0, 1)
local keyNames = {
	-- rotate pitch, roll, yaw
	s = 1, w = -1, a = 1, d = -1, q = 1, e = -1,
	-- translate forward, side, vertical
	down = 1, up = -1, right = 1, left = -1, space = 1, lshift = -1,
	-- level, reset
	f = 1, r = 1
}

local jetcam = {
	cframe = origin,
	translateSpeed = 10,
	pitchSpeed = math.pi / 2,
	yawSpeed = math.pi / 2,
	rollSpeed = math.pi / 2
}

local function fromV3(v)
	return {v.z, v.x, v.y}
end

function jetcam.move(cf)
	jetcam.cframe = cf
	g3d.camera.position = fromV3(jetcam.cframe.p)
	g3d.camera.target = fromV3(jetcam.cframe.p + jetcam.cframe.lookVector)
	g3d.camera.up = fromV3(jetcam.cframe.upVector)
	g3d.camera.updateViewMatrix()
end

function jetcam.inputs()
	local keys = {}
	for key, value in pairs(keyNames) do
		keys[key] = love.keyboard.isDown(key) and value or 0
	end
	return keys
end

function jetcam.update(dt)
	local keys = jetcam.inputs()
	local pitch = keys.s + keys.w
	local roll = keys.d + keys.a
	local yaw = keys.q + keys.e
	local forward = keys.down + keys.up
	local side = keys.right + keys.left
	local vertical = keys.space + keys.lshift
	if (keys.r == 1) then
		jetcam.move(origin)
	elseif (keys.f == 1) then
		if (jetcam.cframe.lookVector:FuzzyEq(up)) then
			jetcam.move(origin)
		else
			local norm = (jetcam.cframe.lookVector * xz).unit
			jetcam.move(CFrame.lookAlong(jetcam.cframe.p, norm))
		end
	else
		local cframe = jetcam.cframe
		local move = false
		if (pitch ~= 0 or roll ~= 0 or yaw ~= 0) then
			move = true
			cframe = jetcam.cframe * CFrame.fromEulerAnglesYXZ(pitch * jetcam.pitchSpeed * dt, yaw * jetcam.yawSpeed * dt, roll * jetcam.rollSpeed * dt)
		end
		if (forward ~= 0 or side ~= 0 or vertical ~= 0) then
			move = true
			cframe = cframe * CFrame.new(side * jetcam.translateSpeed * dt, vertical * jetcam.translateSpeed * dt, forward * jetcam.translateSpeed * dt)
		end
		if (move) then
			jetcam.move(cframe)
		end
	end
end

return jetcam
