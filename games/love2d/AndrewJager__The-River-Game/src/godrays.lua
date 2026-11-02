local rayHandler= {}

local function createRay(raysNum, startAX, startAY, startBX, startBY, endX, endY)
rays = {}
	rays["amount"] = raysNum
	rays["color"] = {0.819, 0.819, 0.819, 0.1}
	rays["colorB"] = {0.819, 0.819, 0.819, 0.1}
	rays["spreadX"] = 50
	rays["spreadY"] = 0
	rays["startAX"] = startAX
	rays["startAY"] = startAY
	rays["startBX"] = startBX
	rays["startBY"] = startBY
	rays["endX"] = endX
	rays["endY"] = endY
	rays["blendSpeed"] = 1
	for i = 1, raysNum do
		ray = {}
		ray["startX"] = love.math.random(startAX, startBX)
		ray["startY"] = love.math.random(startAY, startBY)
		ray["endX"] = endX + love.math.random(-rays.spreadX, rays.spreadX)
		ray["endY"] = endY + love.math.random(-rays.spreadY, rays.spreadY)
		ray["blendX"] = love.math.random(0,1)
		ray["blendY"] = love.math.random(0,1)
		r,g,b,a = unpack(rays.color)
		r2,g2,b2,a2 = unpack(rays.colorB)
		ray["color"] = {love.math.random(r, r2),love.math.random(g, g2),love.math.random(b, b2), love.math.random(a, a2)}
		rays[i] = ray 
	end
    return rays
end
rayHandler.createRay = createRay

local function reCreateRay(rays)
	for i = 1, rays.amount do
		rays[i].startX = love.math.random(rays.startAX, rays.startBX)
		rays[i].startY = love.math.random(rays.startAY, rays.startBY)
		rays[i].endX = rays.endX + love.math.random(-rays.spreadX, rays.spreadX)
		rays[i].endY = rays.endY + love.math.random(-rays.spreadY, rays.spreadY)
		rays["blendX"] = love.math.random(0,1)
		rays["blendY"] = love.math.random(0,1)
		r,g,b,a = unpack(rays.color)
		r2,g2,b2,a2 = unpack(rays.colorB)
		rays[i].color = {love.math.random(inOrder(r, r2)),love.math.random(inOrder(g, g2)),love.math.random(inOrder(b, b2)), love.math.random(inOrder(a, a2))}
	end
end
rayHandler.reCreateRay = reCreateRay

local function updateRay(rays, dt)
	speed = (dt * rays.blendSpeed) * 5
	for i = 1, rays.amount do
		if rays[i].blendX == 1 then --Increase X
			if rays[i].endX >= rays.endX + rays.spreadX then -- at max
				rays[i].blendX = 0
			else
				rays[i].endX = rays[i].endX + speed
			end
		else-- Decrease X
			if rays[i].endX <= rays.endX - rays.spreadX then -- at max
				rays[i].blendX = 1
			else
				rays[i].endX = rays[i].endX - speed
			end
		end

		if rays[i].blendY == 1 then --Increase Y
			if rays[i].endY >= rays.endY + rays.spreadY then -- at max
				rays[i].blendY = 0
			else
				rays[i].endY = rays[i].endY + speed
			end
		else -- Decrease Y
			if rays[i].endY <= rays.endY - rays.spreadY then -- at max
				rays[i].blendY = 1
			else
				rays[i].endY = rays[i].endY - speed
			end
		end
	end
end
rayHandler.updateRay = updateRay

local function drawRay(rays)
	r, g, b, a = love.graphics.getColor()
	for i = 1, rays.amount do
		love.graphics.setColor(unpack(rays[i].color))
		love.graphics.line(rays[i].startX, rays[i].startY, rays[i].endX, rays[i].endY)
	end 
	
	love.graphics.setColor(r, g, b, a)
end 
rayHandler.drawRay = drawRay

function inOrder(a, b)
	if a > b then 
		temp = a
		a = b
		b = temp
	end
	return a, b
end

return rayHandler