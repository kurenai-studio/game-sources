Object = require('objects.object')
Bullet = require('objects.bullet')
Utils = require('utils')

local Ship = Object:new()

Ship.sprite = love.graphics.newImage('assets/sprites/ship.png')
Ship.sprite:setFilter('nearest', 'nearest', 0)
Ship.px = Ship.sprite:getWidth()/2
Ship.py = Ship.sprite:getHeight()/2

function Ship:load(arg)

    for k, v in pairs(arg) do
        print(k, v)
    end

    self.x = arg.x or 0
    self.y = arg.y or 0
    self.sx = arg.sx or arg.s or 1
    self.sy = arg.sy or arg.s or 1
    self.rot = arg.rot or 0
    self.tint = arg.tint or {255, 255, 255}
    self.speed = arg.speed or 200
    self.rate = arg.rate or 0.5

    self.dir = 0
    self.bounds = {arg.y0 or 0, arg.y1 or 100}
    self.reload = 0
end

function Ship:steer(dy)
    self.dir = dy
end

function Ship:update(dt)
    self.y = Utils.clip(self.y + self.dir*self.speed*dt,
                        self.bounds[1], self.bounds[2])
    self.reload = Utils.clip(self.reload-dt, 0, self.rate)
end

function Ship:fire()

    if self.reload > 0 then
        return nil
    end

    local bb = Bullet:new({tint=self.tint, x=self.x, y=self.y,
                               vx=self.sx, vy=0})
    self.reload = self.rate

    return bb
end

function Ship:draw()
    love.graphics.setColor(self.tint)
    love.graphics.draw(self.sprite, self.x, self.y, self.rot, 
                       self.sx, self.sy, self.px, self.py)
    love.graphics.setColor({255, 255, 255})
end

return Ship