--[[
Razey's Bizzare Adventure

Nick Teves, Hanwei Li, Daniel Tweedy

Turn based top down strategy game where player controls units and fights enemy units. Game follows alchemist Razey, a young man made old by drinking bad potions. Razey travels the world with a motely group of friends and sell swords to find ingrediants for the ultimate potion.
]]--
require("protoMap")
require("cursor")
require("player")
require("ui")
require("enemy")
CURSOR_MOVE = 1
UNITS_MOVE = 2
AI_TURN = 3

gameState = CURSOR_MOVE -- game state defaults to moving cursor around

function love.load()
    love.window.setTitle("Razey's Bizarre Adventure")
end

function love.draw()
    map.draw()
    cursor.draw()
	ui.drawTileInfo(map.getTile(cursor.y, cursor.x))
    ui.drawControls()
	if(player.selectedUnit ~= nil) then
		ui.drawUnitInfo(player.selectedUnit)
		player.drawRange()
	elseif(map.getUnit(cursor.y, cursor.x) ~= nil) then
		ui.drawUnitInfo(map.getUnit(cursor.y, cursor.x))
	end
	if(enemy.selectedUnit~= nil) then
		enemy.drawRange()
	end
end

function love.update(dt)
    if(gameState == AI_TURN) then
		enemy.ai()
    end

    --map.update(dt)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if gameState ~= AI_TURN then
        if key == "up" then
            cursor.move(0, -1)
        elseif key == "down" then
            cursor.move(0,1)
        elseif key == "left" then
            cursor.move(-1,0)
        elseif key == "right" then
            cursor.move(1, 0)
        elseif key == "return" or key == "kpenter" or key == "space" then
            tileSelect()
        elseif key == "c" then
            gameState = CURSOR_MOVE
            player.selectedUnit = nil
        -- End turn
        elseif key == "e" then
			player.selectedUnit = nil
            gameState = AI_TURN
			
        end
    end
end

function tileSelect()
    if(map.getUnit(cursor.y,cursor.x) ~= nil and gameState == CURSOR_MOVE) then
        gameState = UNITS_MOVE
        player.selectUnit(cursor.y, cursor.x)
    elseif gameState == UNITS_MOVE then
      if (map.getUnit(cursor.y,cursor.x) ~= nil) then
        if (map.getUnit(cursor.y, cursor.x).player == true) then
            player.selectUnit(cursor.y, cursor.x)
        else 
        player.attackUnit(cursor.y, cursor.x)
          end
      else 
        player.moveUnit(cursor.y, cursor.x)
        end
    end
end
