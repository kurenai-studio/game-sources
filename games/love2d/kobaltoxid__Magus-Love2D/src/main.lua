-- TODO Make game cool.
local map = require 'map'

-- Load various things in love and the game itself.
function love.load()

    love.window.setMode(1280, 720, {
        resizable = true,
        vsync = true,
        minwidth = 400,
        minheight = 300
    })
    love.graphics.setBackgroundColor(0, 0, 0)
    local font = love.graphics.newFont()
    love.graphics.setFont(font, 144)
    -- music = love.audio.newSource('assets/sounds/Dungeon-Cave_loop.ogg', 'stream')
    music = love.audio.newSource('assets/sounds/cave/cave.mp3', 'stream')
    music:setVolume(1)
    music:setLooping(true)
    music:play()

end

function love.update(dt)
    if map:getAliveStatus() == true and map:getWinStatus() == false then
        map:update(dt)
    end
end

function love.draw()
    if map:getAliveStatus() == true and map:getWinStatus() == false then
        love.graphics.print('Lives:', love.graphics.getWidth() - 580, love.graphics.getHeight() - 50)
        love.graphics.print(map:getLives(), love.graphics.getWidth() - 540, love.graphics.getHeight() - 50)
        love.graphics.print('Keys:', love.graphics.getWidth() - 520, love.graphics.getHeight() - 50)
        love.graphics.print(map:getKeys(), love.graphics.getWidth() - 480, love.graphics.getHeight() - 50)
        love.graphics.print('AD: ~30 DPS', love.graphics.getWidth() - 450, love.graphics.getHeight() - 50)
        love.graphics.print('Health:', love.graphics.getWidth() - 350, love.graphics.getHeight() - 50)
        love.graphics.print(map:drawHealth(), love.graphics.getWidth() - 280, love.graphics.getHeight() - 50)

        -- Scale world.
        local scale = 3
        local screen_width = love.graphics.getWidth() / scale
        local screen_height = love.graphics.getHeight() / scale

        -- Translate world so that player is always centred
        local player = map.layers["Sprites"].sprites.player
        local tx = math.floor(player.xPos - (screen_width - 120) / 2)
        local ty = math.floor(player.yPos - (screen_height - 50) / 2)

        -- As basic as fog of war can get. Thank god I wasted 10 hours on more unoptimal solutions.
        map:resize(screen_width - 120, screen_height - 50)
        map:draw(-tx, -ty, scale, scale)

        -- Reset colour.
        love.graphics.setColor(255, 255, 255, 255)
    elseif map:getAliveStatus() == false then
        if love.keyboard.isDown('r') then
            love.event.quit('restart')
        elseif love.keyboard.isDown('q') then
            love.event.quit()
        end
        local myFont = love.graphics.newFont(45)
        love.graphics.setFont(myFont)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setBackgroundColor(0, 0, 0)
        love.graphics.printf('AND HE LIVED HAPPILY NEVER AFTER', 0, love.graphics.getHeight() / 3,
            love.graphics.getWidth(), 'center')
        love.graphics.printf('press "r" to try again, if you dare', 0, love.graphics.getHeight() / 2,
            love.graphics.getWidth(), 'center')
        love.graphics.printf('press "q" to quit and cry about it', 0, love.graphics.getHeight() / 1.5,
            love.graphics.getWidth(), 'center')
    elseif map:getWinStatus() == true then
        if love.keyboard.isDown('r') then
            love.event.quit('restart')
        elseif love.keyboard.isDown('q') then
            love.event.quit()
        end
        local myFont = love.graphics.newFont(45)
        love.graphics.setFont(myFont)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setBackgroundColor(0, 0, 0)
        love.graphics.printf('AND HE LIVED HAPPILY MAYBE AFTER', 0, love.graphics.getHeight() / 3,
            love.graphics.getWidth(), 'center')
        love.graphics.printf('press "r" to try again, if you\'d like to', 0, love.graphics.getHeight() / 2,
            love.graphics.getWidth(), 'center')
        love.graphics.printf('press "q" to quit and enjoy your life', 0, love.graphics.getHeight() / 1.5,
            love.graphics.getWidth(), 'center')
    end
    -- Collision map.
    -- map:bump_draw(world)
    -- drawDebug()

end
