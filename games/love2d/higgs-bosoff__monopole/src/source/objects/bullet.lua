Object = require('objects.object')
Utils = require('utils')

local Bullet = Object:new()

function Bullet:load(arg)
    self.radius = arg.radius or 5
    self.mass = arg.mass or 1
    self.q = arg.q or 1
    self.tint = arg.tint or {255, 255, 255}
    self.x = arg.x or 0
    self.y = arg.y or 0
    self.v = {x=arg.vx*100 or 0, y=arg.vy or 0}

    self.totF = {x=0, y=0}
end

function Bullet:addForceFromCharge(q, x, y)
    -- Module of distance?
    local dx = (x-self.x)
    local dy = (y-self.y)

    r2 = dx*dx+dy*dy
    r = math.sqrt(r2)

    F = -self.q*q/r2

    self.totF.x = self.totF.x+F*dx/r
    self.totF.y = self.totF.y+F*dy/r

end

function Bullet:update(dt)

    self.v.x = self.v.x + self.totF.x/self.mass*dt
    self.v.y = self.v.y + self.totF.y/self.mass*dt

    self.totF = {x=0, y=0}

    self.x = self.x + self.v.x*dt
    self.y = self.y + self.v.y*dt

end

function Bullet:draw()
    love.graphics.setColor(self.tint)
    love.graphics.circle('fill', self.x, self.y, self.radius, 30)
    love.graphics.setColor({255, 255, 255})
end

return Bullet