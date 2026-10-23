-- states/pause.lua: congela la partida. No define update(), así nada avanza.
local Config = require("src.config")
local Game = require("src.game")
local Scene = require("src.scene")

return {
    enter = function()
        Game.ui:setMessage("PAUSA  ·  P para continuar")
    end,

    draw = function()
        Scene.drawWorld()
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", 0, 0, Config.width, Config.height)
        love.graphics.setColor(Config.colorText)
        love.graphics.printf("PAUSA", 0, Config.height / 2 - 40, Config.width, "center")
        love.graphics.printf("P para continuar  ·  Esc al menú", 0, Config.height / 2 + 10, Config.width, "center")
        love.graphics.setColor(1, 1, 1)
    end,

    keypressed = function(key)
        if key == "p" then
            Game.ui:setMessage("")
            Game.sm:switch("play")
        elseif key == "escape" then
            Game.ui:setMessage("")
            Game.sm:switch("title")
        end
    end,
}
