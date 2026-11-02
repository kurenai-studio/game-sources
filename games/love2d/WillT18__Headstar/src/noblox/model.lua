
local noblox = noblox
local module = {}

local mt = {
	__index = function(self, key)
		return module[key] or self.data[key] or self.proxy[key]
	end,
	__newindex = function(self, key, value)
		if (key == "cframe") then
			module.SetCFrame(self, value)
		elseif (key == "size") then
			module.SetSize(self, value)
		elseif (key == "color") then
			module.SetColor(self, value)
		elseif (key == "transparency") then
			self.data.transparency = value
		end
	end
}

function module.fromV3(vector)
	return vector.z, vector.x, vector.y
end

function module.toV3(x, y, z)
	return noblox.vector3.new(y, z, x)
end

function module.new(verts, texture, cframe, size, color, alpha)
	local self = {
		proxy = noblox.g3d.newModel(verts, texture),
		data = {
			verts = verts,
			texture = texture,
			cframe = noblox.cframe.new(),
			size = noblox.vector3.new(1, 1, 1),
			color = noblox.vector3.new(1, 1, 1),
			transparency = alpha or 0
		}
	}
	setmetatable(self, mt)
	module.SetCFrame(self, cframe)
	module.SetSize(self, size)
	module.SetColor(self, color)
	return self
end

function module:Clone()
	return module.new(self.data.verts, self.data.texture, self.data.cframe, self.data.size, self.data.color, self.data.transparency)
end

function module:SetCFrame(cframe)
	self.data.cframe = cframe or noblox.cframe.new()
	self.proxy:lookAtFrom(
		{module.fromV3(self.data.cframe.p)},
		{module.fromV3(self.data.cframe.p + self.data.cframe.lookVector)},
		{module.fromV3(self.data.cframe.upVector)}
	)
end

function module:SetSize(scale)
	self.data.size = noblox.vector3.new(1, 1, 1) * (scale or 1)
	self.proxy:setScale(module.fromV3(self.data.size))
	module.SetCFrame(self, self.data.cframe)
end

function module:SetColor(color)
	self.data.color = noblox.vector3.new(1, 1, 1) * (color or 1)
end

-- Draw the model on the screen. If ignoreRGBA is true then draw it quickly using whatever the current graphics color settings are.
function module:Draw(ignoreRGBA)
	if (ignoreRGBA) then
		self.proxy:draw()
	else
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(
			self.data.color.x,
			self.data.color.y,
			self.data.color.z,
			1 - self.data.transparency
		)
		self.proxy:draw()
		love.graphics.setColor(r, g, b, a)
	end
end

-- set the position and orientation of the camera as a CFrame. The camera will look along the negative Z vector just like in roblox.
function module.setCameraCFrame(cframe)
	noblox.g3d.camera.position = {module.fromV3(cframe.p)}
	noblox.g3d.camera.target = {module.fromV3(cframe.p + cframe.lookVector)}
	noblox.g3d.camera.up = {module.fromV3(cframe.upVector)}
	noblox.g3d.camera.updateViewMatrix()
end

-- get the g3d camera's position and orientation since it's not a wrapped model
function module.getCameraCFrame()
	return noblox.cframe.lookAt(
		module.toV3(unpack(noblox.g3d.camera.position)),
		module.toV3(unpack(noblox.g3d.camera.target)),
		module.toV3(unpack(noblox.g3d.camera.up))
	)
end

-- shortcut for creating an orientation from degree angles
function module.fromOrientation(x, y, z)
	return noblox.cframe.fromEulerAnglesYXZ(math.rad(x), math.rad(y), math.rad(z))
end
-- because Lua 5.1 doesn't have math.sign
function module.sign(n)
	if (n < 0) then
		return -1
	elseif (n > 0) then
		return 1
	else
		return 0
	end
end

return module
