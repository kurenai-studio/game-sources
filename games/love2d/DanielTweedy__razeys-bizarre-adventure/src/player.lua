require("protoMap")
require("unit")

player = {}
player.units = {}
player.selectedUnit = nil
local TILE_SIZE = 32 -- 32x32 tiles
function player.new(o) 
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function player.selectUnit(y, x) 
    if map.getUnit(y, x) == nil or map.getUnit(y, x).player==false then
      --insert menu functionality here.
    else
        player.selectedUnit = map.getUnit(y, x)
		sound = love.audio.newSource(SE_PATH .. "true.wav", "static")
		sound:play()		
    end
end
  
function player.moveUnit(y, x) 
    if player.selectedUnit ~= nil then
		if player.selectedUnit.stamina == 0 then
			player.selectedUnit = nil
			sound = love.audio.newSource(SE_PATH .. "return.wav", "static")
			sound:play()
		else
			x = x-player.selectedUnit.x
			y = y-player.selectedUnit.y
			map.moveUnit(y, x, player.selectedUnit)
		end
    end
end

function player.attackUnit(y, x)
    local attacker = player.selectedUnit
    local defender = map.getUnit(y,x)
    
    if defender ~= nil and attacker ~= nil then
        local attackTile = map.getTile(attacker.y,attacker.x)
        local defendTile = map.getTile(y,x)
        local dx = x - attacker.x
        local dy = y - attacker.y
        local dist = math.abs(dx) + math.abs(dy)
    
        if unit.inRange(attacker, dist) and unit.canFight(attacker) then
            fight(attacker, defender, attackTile, defendTile)
        end
        -- Counter attack
        if unit.canFight(defender) and unit.inRange(defender, dist) then
            fight(defender, attacker, defendTile, attackTile)
        end
    end
end

function fight(attacker, defender, attackTile, defendTile)
    attacker.stamina = attacker.stamina-1
    local attackerHit = math.random(100) < unit.hitChance(defender.avoid,defendTile.avoidBonus)

    if attackerHit then
        local dmg = attacker.strength - defender.defense - defendTile.defenseBonus
        if (dmg > 0) then
            defender.health = defender.health - dmg
        end
    end
end

function player.drawRange()
	for y=0, player.selectedUnit.stamina+player.selectedUnit.maxRange do
		for x=0, player.selectedUnit.stamina-y+player.selectedUnit.maxRange do
            if (player.selectedUnit.x+x < 11 and player.selectedUnit.y+y < 11) then
              
              if (x > player.selectedUnit.stamina-y-player.selectedUnit.minRange+1) then
                love.graphics.setColor(255, 50, 50, 50)
                love.graphics.rectangle("fill",(player.selectedUnit.x+x)*TILE_SIZE,(player.selectedUnit.y+y)*TILE_SIZE,TILE_SIZE,TILE_SIZE)
                love.graphics.setColor(255, 255, 255)
              else
              love.graphics.rectangle("line",(player.selectedUnit.x+x)*TILE_SIZE,(player.selectedUnit.y+y)*TILE_SIZE,TILE_SIZE,TILE_SIZE)
              end
			
          end if (player.selectedUnit.x+x < 11 and player.selectedUnit.y-y >= 1) then
            
            if (x > player.selectedUnit.stamina-y-player.selectedUnit.minRange+1) then
                love.graphics.setColor(255, 50, 50, 50)
                love.graphics.rectangle("fill",(player.selectedUnit.x+x)*TILE_SIZE,(player.selectedUnit.y-y)*TILE_SIZE,TILE_SIZE,TILE_SIZE)
                love.graphics.setColor(255, 255, 255)
              else
              love.graphics.rectangle("line",(player.selectedUnit.x+x)*TILE_SIZE,(player.selectedUnit.y-y)*TILE_SIZE,TILE_SIZE,TILE_SIZE)
              end
      
          end if (player.selectedUnit.x-x >= 1 and player.selectedUnit.y+y < 11) then
            
            if (x > player.selectedUnit.stamina-y-player.selectedUnit.minRange+1) then
                love.graphics.setColor(255, 50, 50, 50)
                love.graphics.rectangle("fill",(player.selectedUnit.x-x)*TILE_SIZE,(player.selectedUnit.y+y)*TILE_SIZE,TILE_SIZE,TILE_SIZE)
                love.graphics.setColor(255, 255, 255)
              else 
              love.graphics.rectangle("line",(player.selectedUnit.x-x)*TILE_SIZE,(player.selectedUnit.y+y)*TILE_SIZE,TILE_SIZE,TILE_SIZE)
              end
      
          end if (player.selectedUnit.x-x >= 1 and player.selectedUnit.y-y >= 1) then
            
            if(x > player.selectedUnit.stamina-y-player.selectedUnit.minRange+1) then
                love.graphics.setColor(255, 50, 50, 50)
                love.graphics.rectangle("fill",(player.selectedUnit.x-x)*TILE_SIZE,(player.selectedUnit.y-y)*TILE_SIZE,TILE_SIZE,TILE_SIZE)
                love.graphics.setColor(255, 255, 255)
              else
              love.graphics.rectangle("line",(player.selectedUnit.x-x)*TILE_SIZE,(player.selectedUnit.y-y)*TILE_SIZE,TILE_SIZE,TILE_SIZE)
              end
      
          end
		end
	end
end
