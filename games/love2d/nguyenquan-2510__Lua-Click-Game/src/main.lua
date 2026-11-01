-- Randomness
math.randomseed(os.time())

local love = require 'love'

-- Point System
local point = {
    point = 0,
    color = {1, 1, 1},
    drawPoint = function (self)
        love.graphics.setColor(self.color)
        love.graphics.printf(self.point, 0, 20, love.graphics.getWidth(), "center")
        love.graphics.setColor(0, 0, 0)
    end,
}

-- Character To Click
local clicker = {
    x = love.graphics.getWidth() / 2,
    y = love.graphics.getHeight() / 2,
    r = 30,
    color = {math.random(0, 255) / 255, math.random(1, 255) / 255, math.random(0, 255) / 255},
    draw = function (self)
        love.graphics.circle("fill",self.x, self.y, self.r)
    end,
    checkClick = function (self, mx, my, button)
        if button ~= 1 then return end

        local dx = mx - self.x
        local dy = my - self.y

        if dx^2 + dy^2 <= self.r^2 then
            point.point = point.point + 1
            self.color = {math.random(1, 255) / 255, math.random(0, 255) / 255, math.random(0, 255) / 255}
            
            self.x = math.random(self.r, love.graphics.getWidth() - self.r)
            self.y = math.random(self.r, love.graphics.getHeight() - self.r)
        end
    end
}

function love.load()
    FPS = 0
    local icon = love.image.newImageData("cursor.png")

    love.window.setTitle("Click game - Lua x LOVE2D")
    love.window.setIcon(icon)
end

function love.update(dt)

    FPS = love.timer.getFPS()
end

function love.mousepressed(x, y, button, istouch, presses)
    clicker:checkClick(x, y, button)
end

function love.draw()
    -- Display game FPS (quite unnecessary)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("FPS: "..FPS, 10, love.graphics.getHeight() - 30)

    -- Draw point
    point:drawPoint()

    -- Draw the clicker
    love.graphics.setColor(clicker.color)
    clicker:draw()

    --Reset
    love.graphics.setColor(1, 1, 1)

end
