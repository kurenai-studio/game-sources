State = require('states.state')
Ship = require('objects.ship')
Utils = require('utils')

local PlayState = State:new()

PlayState.y1 = 300
PlayState.y2 = 300

PlayState.p1_up = 'w'
PlayState.p1_down ='s'
PlayState.p1_fire = 'd'
PlayState.p2_up = 'up'
PlayState.p2_down = 'down'
PlayState.p2_fire = 'left'

PlayState.bound = 60
_, wh = love.window.getMode()
PlayState.ubound = wh-PlayState.bound

function PlayState:load(level)
    self.ship1 = Ship:new({x=50, y=self.y1, s=2, tint={0, 0.5, 1},
                           y0=self.bound, y1=self.ubound})
    self.ship2 = Ship:new({x=750, y=self.y2, s=-2, tint={1, 0.5, 0},
                           y0=self.bound, y1=self.ubound})

    self.bullets = {}

    self.level = require('levels.' .. level) or require('levels.level')
end

function PlayState:update(dt)
    local dy1 = Utils.axis(love.keyboard.isDown(self.p1_down),
                           love.keyboard.isDown(self.p1_up))
    local dy2 = Utils.axis(love.keyboard.isDown(self.p2_down),
                           love.keyboard.isDown(self.p2_up))

    self.ship1:steer(dy1)
    self.ship2:steer(dy2)

    if (love.keyboard.isDown(self.p1_fire)) then
        bb = self.ship1:fire()
        table.insert(self.bullets, bb)
    end
    if (love.keyboard.isDown(self.p2_fire)) then
        bb = self.ship2:fire()
        table.insert(self.bullets, bb)
    end

    self.ship1:update(dt)
    self.ship2:update(dt)

    for i, bb in ipairs(self.bullets) do
        bb:update(dt)
    end

end

function PlayState:draw()
    self.ship1:draw()
    self.ship2:draw()

    for i, bb in ipairs(self.bullets) do
        bb:draw()
    end
end

return PlayState