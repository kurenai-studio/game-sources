local render = {}

local character_model = require('character.model')
local maps = require("map.map")

COLOR_GOLD = {1.0, 0.84, 0, 1}
COLOR_HEALTH = {0.4,0.1,0.2,1}

render.IngameRenderer = {}

render.IngameRenderer.__index = render.IngameRenderer

function render.IngameRenderer:new()
    new_object = {
    }
    setmetatable(new_object, self)
    new_object.__index = render.IngameRenderer
    return new_object
end


function render.IngameRenderer:draw_stats(stats, x, y)
    local health = stats.current_health
    local max_health = stats.max_health
    local health_str = string.format( "PlayerHealth: %d/%d", health, max_health )

    love.graphics.setColor(COLOR_HEALTH)
    love.graphics.print(health_str, x, y)

    love.graphics.setColor({1,1,1,1})
end



function render.IngameRenderer:draw_inventory(inventory, x, y)
    local coins = inventory.coins
    local coins_str = string.format( "Coins: %d", coins)

    love.graphics.setColor(COLOR_GOLD)
    love.graphics.print(coins_str, x, y)

    love.graphics.setColor({1,1,1,1})
end

function render.IngameRenderer:draw_death()
    love.graphics.setColor(COLOR_HEALTH)

    local death_font = love.graphics.newFont(30)
    local respawn_text = love.graphics.newText(death_font, "Press R to Respawn")
    love.graphics.draw(respawn_text, 20, 200)

    love.graphics.setColor({1,1,1,1})
end

function render.IngameRenderer:draw()
    local col_number, row_number, row, x_c, y_c
    maps.draw_map(game_map1, sprites, 0, 20)

    
    character_model.draw_characters(sprites, 0, 20)
    maps.draw_map_overlay(game_map1, sprites, 0, 20)
    local max_x = love.graphics.getWidth()

    local gamefps_str = string.format("FPS: %0.2f f/sec", love.timer.getFPS())
    
    love.graphics.setColor(COLOR_GOLD)
    love.graphics.print(gamefps_str, 0, 0)

    love.graphics.setColor({1,1,1,1})
    
    self:draw_stats(character_model.main_character.stats, max_x - 250, 30 )
    self:draw_inventory(character_model.main_character.inventory, max_x - 250, 100)

    if character_model.main_character.stats.death_status ~= nil then
        self:draw_death()
    end

    
end

function render.draw_title()
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local icon_width = iconimg:getPixelWidth()
    local icon_height = iconimg:getPixelHeight()
    --  |------------------------- window_width ---------------|
    --  |                  |.icon_width*0.5. |               |
    --  |                  <-------                            |
    --  |                         ^ window_width / 2           |
    local icon_x_offest_from_middle = icon_width / 2 / 2
    local icon_y_offest_from_middle = icon_height / 2 / 2

    local text = "The Spawner of Everilynn"
    local font       = love.graphics.getFont()
	local textWidth  = font:getWidth(text)
	local textHeight  = font:getHeight()
    local text_x_offset_from_middle = textWidth / 2
    local text_y_offset_from_middle = icon_y_offest_from_middle + 50

    love.graphics.draw(
        iconimg, 
        window_width/2 - icon_x_offest_from_middle, 
        window_height/2 - icon_y_offest_from_middle, 
        0, 
        0.5, 
        0.5)
    love.graphics.print(
        text, 
        window_width/2 - text_x_offset_from_middle, 
        window_height/2 + text_y_offset_from_middle + 1.5*textHeight
    )
end

return render
