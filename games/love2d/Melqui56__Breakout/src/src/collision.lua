-- Collision: detección AABB y resolución de la respuesta.
-- Es un módulo sin estado: solo recibe entidades y devuelve el resultado.
local M = {}

-- ¿Se solapan dos rectángulos? Las entidades exponen x, y, w, h.
function M.aabb(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w
       and a.y < b.y + b.h and b.y < a.y + a.h
end

-- Bola contra un ladrillo: rebota por el eje de MENOR solapamiento
-- y empuja la bola fuera para que no quede pegada.
function M.resolveBallBrick(ball, brick)
    local ax2, bx2 = ball.x + ball.w, brick.x + brick.w
    local ay2, by2 = ball.y + ball.h, brick.y + brick.h
    local ox = math.min(ax2, bx2) - math.max(ball.x, brick.x)   -- solape en X
    local oy = math.min(ay2, by2) - math.max(ball.y, brick.y)   -- solape en Y

    if ox < oy then                 -- menor solape en X: chocó de lado
        ball.vx = -ball.vx
        ball.x = ball.x + (ball.x < brick.x and -ox or ox)
    else                            -- menor solape en Y: chocó arriba/abajo
        ball.vy = -ball.vy
        ball.y = ball.y + (ball.y < brick.y and -oy or oy)
    end
end

-- Bola contra la paleta: reubica la bola encima y decide el ángulo
-- según el punto de impacto (t va de -1 en el borde izquierdo a +1 en el derecho).
function M.bounceOnPaddle(ball, paddle)
    ball.y = paddle.y - ball.h
    ball.vy = -math.abs(ball.vy)

    local centroBola = ball.x + ball.w / 2
    local centroPaleta = paddle.x + paddle.w / 2
    local t = (centroBola - centroPaleta) / (paddle.w / 2)
    t = math.max(-1, math.min(1, t))
    ball.vx = t * ball.maxVx
end

return M
