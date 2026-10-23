-- StrongBrick: ladrillo resistente que aguanta dos golpes.
-- POLIMORFISMO: misma firma que Brick:onHit(), comportamiento distinto.
-- No redefine draw(): lo hereda de Brick por la cadena de metatablas.
local Brick = require("src.brick")
local Config = require("src.config")

local StrongBrick = setmetatable({}, { __index = Brick })
StrongBrick.__index = StrongBrick

function StrongBrick.new(x, y, w, h)
    local self = Brick.new(x, y, w, h, 2)   -- 1) constructor del padre
    self.color = Config.colorStrong
    self.points = 20
    return setmetatable(self, StrongBrick)   -- 2) re-etiqueta como StrongBrick
end

-- Misma firma, otra conducta: solo muere al segundo golpe.
function StrongBrick:onHit()
    self._hp = self._hp - 1
    self._flash = 0.12
    if self._hp <= 0 then
        self._dead = true
        return self.points
    end
    return 5
end

return StrongBrick
