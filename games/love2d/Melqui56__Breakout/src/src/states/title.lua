-- states/title.lua: pantalla de inicio. Espera Enter para empezar.
local Config = require("src.config")
local Game = require("src.game")

return {
    enter = function()
        Game.ui:setMessage("")
    end,

    draw = function()
        love.graphics.setColor(Config.colorText)
        love.graphics.printf("BREAKOUT", 0, 180, Config.width, "center")
        love.graphics.printf("Enter / Espacio para jugar", 0, 260, Config.width, "center")
        love.graphics.printf("Flechas o A/D para mover la paleta", 0, 300, Config.width, "center")
        love.graphics.printf("Enter lanza la bola  ·  P pausa", 0, 324, Config.width, "center")
        love.graphics.setColor(1, 1, 1)
    end,

    keypressed = function(key)
        if key == "return" or key == "space" then
            Game.newGame()
            Game.sm:switch("serve")
        end
    end,
}
