-- states/serve.lua: la bola espera sobre la paleta hasta que el jugador lanza.
local Game = require("src.game")
local Scene = require("src.scene")

return {
    enter = function()
        Game:updateStuckBalls()
        Game.ui:setMessage("Enter para lanzar")
        Game.ui:setHud(Game.score, Game.lives, Game.levelNum)
    end,

    update = function(dt)
        Game.paddle:update(dt, Game.input)
        Game:updateStuckBalls()
        Game.fx:update(dt)
    end,

    draw = function()
        Scene.drawWorld()
    end,

    keypressed = function(key)
        if key == "return" or key == "space" then
            for _, b in ipairs(Game.balls) do
                if b.stuck then b:launch() end
            end
            Game.ui:setMessage("")
            Game.sm:switch("play")
        end
    end,
}
