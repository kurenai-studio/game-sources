-- states/play.lua: el estado de juego activo.
-- Mueve la paleta, integra las bolas por sub-pasos resolviendo colisiones,
-- actualiza power-ups y decide el fin de vida, de nivel y de partida.
local Config = require("src.config")
local Game = require("src.game")
local Scene = require("src.scene")
local Collision = require("src.collision")
local Ball = require("src.ball")
local PowerUp = require("src.powerup")

-- Definiciones de power-up. El efecto es una FUNCIÓN: el PowerUp no sabe
-- qué hace, solo la ejecuta al tocar la paleta.
local PowerDefs = {
    {
        label = "M", color = { 0.40, 0.80, 1.00, 1 },
        apply = function(g)                      -- multibola
            local base = g.balls[1]
            if not base then return end
            for i = 1, 2 do
                local b = Ball.new(base.x, base.y)
                b.stuck = false
                b.vx = base.vx + (i == 1 and -120 or 120)
                b.vy = -math.abs(base.vy)
                table.insert(g.balls, b)
            end
        end,
    },
    {
        label = "W", color = { 0.60, 1.00, 0.60, 1 },
        apply = function(g)                      -- paleta ancha (con tween)
            g.paddle.targetWidth = g.paddle.baseWidth * 1.5
        end,
    },
    {
        label = "+", color = { 1.00, 0.80, 0.40, 1 },
        apply = function(g)                      -- vida extra
            g.lives = g.lives + 1
        end,
    },
}

local function dropPower(brick)
    if love.math.random() >= Config.powerupChance then return end
    local def = PowerDefs[love.math.random(#PowerDefs)]
    local pu = PowerUp.new(
        brick.x + brick.w / 2 - Config.powerupW / 2,
        brick.y,
        def.apply, def.color, def.label
    )
    table.insert(Game.powerups, pu)
end

-- Mueve una bola en sub-pasos y resuelve las colisiones en cada uno,
-- para que a alta velocidad no atraviese ladrillos (tunneling).
local function moveAndCollide(ball, dt)
    local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
    local steps = math.max(1, math.ceil(speed * dt / Config.ballRadius))
    local sdt = dt / steps

    for _ = 1, steps do
        ball:moveStep(sdt)

        -- Bordes
        if ball.x < 0 then
            ball.x = 0
            ball.vx = math.abs(ball.vx)
            Game.playSound("bounce")
        elseif ball.x + ball.w > Config.width then
            ball.x = Config.width - ball.w
            ball.vx = -math.abs(ball.vx)
            Game.playSound("bounce")
        end
        if ball.y < 0 then
            ball.y = 0
            ball.vy = math.abs(ball.vy)
            Game.playSound("bounce")
        end

        -- Paleta: rebote por punto de impacto
        if ball.vy > 0 and Collision.aabb(ball, Game.paddle) then
            Collision.bounceOnPaddle(ball, Game.paddle)
            Game.playSound("bounce")
        end

        -- Ladrillos: el ladrillo responde por sí mismo (polimorfismo)
        for _, brick in ipairs(Game.level.bricks) do
            if not brick._dead and Collision.aabb(ball, brick) then
                local pts = brick:onHit()
                Game.score = Game.score + pts
                Game.playSound("brick")
                local cx = brick.x + brick.w / 2
                local cy = brick.y + brick.h / 2
                if brick._dead then
                    Game.fx:burst(cx, cy, brick.color, 14)
                    Game.fx:shakeIt(6)
                    dropPower(brick)
                else
                    Game.fx:burst(cx, cy, brick.color, 5)
                    Game.fx:shakeIt(2)
                end
                Collision.resolveBallBrick(ball, brick)
                break
            end
        end
    end
end

local function updatePowerups(dt)
    for i = #Game.powerups, 1, -1 do
        local p = Game.powerups[i]
        p:update(dt)
        if Collision.aabb(p, Game.paddle) then
            p.efecto(Game)
            Game.playSound("power")
            Game.fx:burst(p.x + p.w / 2, p.y + p.h / 2, p.color, 10)
            table.remove(Game.powerups, i)
        elseif p._dead then
            table.remove(Game.powerups, i)
        end
    end
end

return {
    enter = function()
        Game.ui:setMessage("")
    end,

    update = function(dt)
        Game.paddle:update(dt, Game.input)
        Game:updateStuckBalls()

        -- Bola(s): mover y eliminar las que caen
        for i = #Game.balls, 1, -1 do
            local b = Game.balls[i]
            moveAndCollide(b, dt)
            if b.y - b.h > Config.height then
                table.remove(Game.balls, i)
            end
        end

        -- Sin bolas: se pierde una vida
        if #Game.balls == 0 then
            Game.lives = Game.lives - 1
            Game.playSound("lose")
            Game.fx:shakeIt(16)
            if Game.lives <= 0 then
                Game.sm:switch("gameover")
            else
                Game:serveBall()
                Game.sm:switch("serve")
            end
            return
        end

        updatePowerups(dt)
        Game.level:update(dt)
        Game.fx:update(dt)

        -- Nivel completo: avanzar o ganar
        if Game.level:isComplete() then
            Game.levelNum = Game.levelNum + 1
            if Game.levelNum > #Game.layouts then
                Game.sm:switch("victory")
            else
                Game:loadLevel(Game.levelNum)
                Game:serveBall()
                Game.sm:switch("serve")
            end
            return
        end

        Game.ui:setHud(Game.score, Game.lives, Game.levelNum)
    end,

    draw = function()
        Scene.drawWorld()
    end,

    keypressed = function(key)
        if key == "p" or key == "escape" then
            Game.sm:switch("pause")
        end
    end,
}
