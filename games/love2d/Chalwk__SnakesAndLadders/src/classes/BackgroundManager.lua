-- Snakes and Ladders - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.foodParticles = {}
    instance.time = 0
    instance:initFoodParticles()
    return instance
end

function BackgroundManager:initFoodParticles()
    self.foodParticles = {}
    for i = 1, 30 do
        table_insert(self.foodParticles, {
            x = math_random() * 1200,
            y = math_random() * 800,
            size = math_random(3, 10),
            speed = math_random(20, 60),
            angle = math_random() * math_pi * 2,
            type = math_random(1, 6), -- Different food types
            life = math_random(10, 20),
            maxLife = math_random(10, 20),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = math_random(-2, 2),
            color = {
                math_random(0.7, 1.0),
                math_random(0.7, 1.0),
                math_random(0.7, 1.0)
            }
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    -- Update food particles
    for i = #self.foodParticles, 1, -1 do
        local particle = self.foodParticles[i]
        particle.life = particle.life - dt

        if particle.life <= 0 then
            table.remove(self.foodParticles, i)
        else
            particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
            particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt
            particle.rotation = particle.rotation + particle.rotationSpeed * dt

            -- Wrap around screen
            if particle.x < -50 then particle.x = 1250 end
            if particle.x > 1250 then particle.x = -50 end
            if particle.y < -50 then particle.y = 850 end
            if particle.y > 850 then particle.y = -50 end
        end
    end

    -- Add new particles to maintain count
    while #self.foodParticles < 30 do
        table_insert(self.foodParticles, {
            x = math_random() * 1200,
            y = -50,
            size = math_random(3, 10),
            speed = math_random(20, 60),
            angle = math_random(0.2, 0.8) * math_pi,
            type = math_random(1, 6),
            life = math_random(10, 20),
            maxLife = math_random(10, 20),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = math_random(-2, 2),
            color = {
                math_random(0.7, 1.0),
                math_random(0.7, 1.0),
                math_random(0.7, 1.0)
            }
        })
    end
end

function BackgroundManager:draw(screenWidth, screenHeight, gameState)
    -- Food-themed gradient background
    for y = 0, screenHeight, 3 do
        local progress = y / screenHeight
        local pulse = (math_sin(self.time * 0.5 + progress * 3) + 1) * 0.03

        local r = 0.9 + progress * 0.1 + pulse
        local g = 0.8 + progress * 0.15 + pulse * 0.5
        local b = 0.7 + progress * 0.1 + pulse

        love.graphics.setColor(r, g, b, 0.6)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Floating food particles
    for _, particle in ipairs(self.foodParticles) do
        local lifeProgress = particle.life / particle.maxLife
        local alpha = lifeProgress * 0.7
        local scale = 0.8 + 0.4 * math_sin(self.time * 2 + particle.rotation)

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)
        love.graphics.scale(scale, scale)

        -- Draw different food types
        if particle.type == 1 then -- Apple
            love.graphics.setColor(1, 0.2, 0.2, alpha)
            love.graphics.circle("fill", 0, 0, particle.size)
            love.graphics.setColor(0.3, 0.7, 0.3, alpha)
            love.graphics.rectangle("fill", -2, -particle.size-3, 4, 6)
        elseif particle.type == 2 then -- Orange
            love.graphics.setColor(1, 0.5, 0, alpha)
            love.graphics.circle("fill", 0, 0, particle.size)
        elseif particle.type == 3 then -- Candy
            love.graphics.setColor(1, 0.8, 0.9, alpha)
            love.graphics.rectangle("fill", -particle.size/2, -particle.size/2, particle.size, particle.size, 3)
        elseif particle.type == 4 then -- Cookie
            love.graphics.setColor(0.8, 0.6, 0.4, alpha)
            love.graphics.circle("fill", 0, 0, particle.size)
            love.graphics.setColor(0.6, 0.4, 0.2, alpha)
            for i = 1, 4 do
                local angle = (i-1) * math_pi/2
                love.graphics.circle("fill", math_cos(angle)*particle.size*0.5, math_sin(angle)*particle.size*0.5, 2)
            end
        elseif particle.type == 5 then -- Grapes
            love.graphics.setColor(0.5, 0.2, 0.7, alpha)
            for i = 1, 3 do
                love.graphics.circle("fill", (i-2)*3, 0, particle.size*0.8)
            end
        else -- Lemon
            love.graphics.setColor(1, 1, 0.3, alpha)
            love.graphics.circle("fill", 0, 0, particle.size)
        end

        love.graphics.pop()
    end
end

return BackgroundManager