-- Scene: dibuja el mundo del juego (nivel, power-ups, bolas, paleta, FX, HUD).
-- Se comparte entre los estados que necesitan mostrar la partida
-- (serve, play y pause) para no duplicar el render.
local Game = require("src.game")

local Scene = {}

function Scene.drawWorld()
    Game.level:draw()
    for _, p in ipairs(Game.powerups) do p:draw() end
    for _, b in ipairs(Game.balls) do b:draw() end
    Game.paddle:draw()
    Game.fx:draw()
    Game.ui:draw()
end

return Scene
