-- states/victory.lua: pantalla de victoria al superar todos los niveles.
local Config = require("src.config")
local Game = require("src.game")
local Scene = require("src.scene")

return {
    enter = function()
        Game.ui:setMessage("")
    end,

    draw = function()
        Scene.drawWorld()
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", 0, 0, Config.width, Config.height)
        love.graphics.setColor(Config.colorText)
        love.graphics.printf("¡VICTORIA!", 0, Config.height / 2 - 50, Config.width, "center")
        love.graphics.printf("Completaste los " .. #Game.layouts .. " niveles", 0, Config.height / 2, Config.width, "center")
        love.graphics.printf("Puntaje final: " .. Game.score, 0, Config.height / 2 + 28, Config.width, "center")
        love.graphics.printf("R / Enter para volver al inicio", 0, Config.height / 2 + 60, Config.width, "center")
        love.graphics.setColor(1, 1, 1)
    end,

    keypressed = function(key)
        if key == "r" or key == "return" then
            Game.sm:switch("title")
        end
    end,
}
