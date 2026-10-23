-- Game: estado compartido del mundo.
-- Los estados leen y escriben aquí; la máquina de estados (StateMachine)
-- vive en main.lua, que es quien cablea los estados.
local Config = require("src.config")
local Ball = require("src.ball")
local Paddle = require("src.paddle")
local Level = require("src.level")
local UI = require("src.ui")
local Effects = require("src.effects")
local Layouts = require("src.levels")

local Game = {
    score = 0,
    lives = 3,
    levelNum = 1,
    input = { left = false, right = false },

    paddle = nil,
    balls = {},
    level = nil,
    ui = nil,
    fx = nil,
    powerups = {},
    sm = nil,             -- lo asigna main.lua

    sounds = {},
    layouts = Layouts,
}

-- Carga de recursos (se llama una sola vez desde love.load).
function Game.init()
    Game.fx = Effects.new()
    Game.paddle = Paddle.new(0, Config.paddleY, Config.paddleWidth, Config.paddleSpeed)
    Game.level = Level.new()
    Game.ui = UI.new()
    for _, name in ipairs({ "bounce", "brick", "lose", "power" }) do
        local ok, src = pcall(love.audio.newSource, "assets/" .. name .. ".wav", "static")
        Game.sounds[name] = ok and src or nil
    end
end

function Game.playSound(name)
    local s = Game.sounds[name]
    if s then
        s:stop()
        s:play()
    end
end

-- Empieza una partida nueva desde cero.
function Game.newGame()
    Game.score = 0
    Game.lives = 3
    Game.levelNum = 1
    Game.powerups = {}
    Game.paddle:reset()
    Game:loadLevel(Game.levelNum)
    Game:serveBall()
end

function Game:loadLevel(n)
    Game.level:load(Game.layouts[n])
end

-- Deja una bola pegada a la paleta, lista para lanzar.
function Game:serveBall()
    Game.balls = { Ball.new(0, 0) }
    local b = Game.balls[1]
    b.stuck = true
    Game:updateStuckBalls()
end

-- Reubica las bolas pegadas sobre la paleta (serve y play).
function Game:updateStuckBalls()
    for _, b in ipairs(Game.balls) do
        if b.stuck then
            b.x = Game.paddle.x + Game.paddle.w / 2 - b.w / 2
            b.y = Game.paddle.y - b.h
        end
    end
end

return Game
