local StateMachine = require("src.core.state_machine")
local Renderer = require("src.core.renderer")
local Input = require("src.core.input")
local Assets = require("src.core.assets")
local Audio = require("src.core.audio")
local Save = require("src.core.save")
local Localization = require("src.core.localization")
local Settings = require("src.core.settings")
local CRT = require("src.systems.crt")
local Constants = require("src.core.constants")
local OnlineScores = require("src.core.online_scores")

local Game = {}
Game.__index = Game

function Game.new()
    local renderer = Renderer.new(
        Constants.logical_width,
        Constants.logical_height,
        Constants.internal_scale
    )
    local save = Save.new()
    local settings = Settings.new(save)

    local self = setmetatable({
        renderer = renderer,
        input = Input.new(renderer),
        save = save,
        settings = settings,
        localization = Localization.new(),
        assets = Assets.new(renderer),
        online_scores = OnlineScores.new(),
        audio = nil,
        crt = nil,
        dataset = nil,
        highscores = { entries = {} },
        state_factories = {},
        session = {},
        suppress_mouse_until = 0,
    }, Game)

    self.audio = Audio.new(settings)
    self.crt = CRT.new(renderer)
    self.state_machine = StateMachine.new(self)
    self:register_states()
    return self
end

function Game:register_states()
    self.state_factories.boot = require("src.states.boot")
    self.state_factories.intro = require("src.states.intro")
    self.state_factories.menu = require("src.states.menu")
    self.state_factories.difficulty_select = require("src.states.difficulty_select")
    self.state_factories.settings_menu = require("src.states.settings_menu")
    self.state_factories.highscore = require("src.states.highscore")
    self.state_factories.story = require("src.states.story")
    self.state_factories.play = require("src.states.play")
    self.state_factories.level_stats = require("src.states.level_stats")
    self.state_factories.game_over = require("src.states.game_over")
    self.state_factories.victory = require("src.states.victory")
    self.state_factories.score_entry = require("src.states.score_entry")
end

function Game:load()
    self.input:begin_frame()
    self.state_machine:change("boot")
end

function Game:start_new_run()
    local difficulty = self:get_difficulty_profile(self.settings.values.difficulty)
    self.session = {
        level_index = 1,
        score = 0,
        lives = difficulty.lives or self.settings:get_starting_lives(),
        level_stats = {},
    }
end

function Game:get_difficulty_profile(difficulty_id)
    local difficulty_data = self.dataset and self.dataset.difficulty or {}
    local fallback = difficulty_data.normal or {
        label_key = "difficulty.normal",
        lives = 3,
        initial_speed = 6,
        speed_increment = 0.25,
        good_food_multiplier = 1.0,
        bad_food_multiplier = 1.0,
        face_index = 2,
    }

    local profile = difficulty_data[difficulty_id] or fallback
    if not profile.label_key then
        profile.label_key = fallback.label_key
    end
    return profile
end

function Game:get_sfx_id(key, fallback)
    local sfx = self.dataset and self.dataset.sfx or nil
    if sfx and sfx[key] then
        return sfx[key]
    end
    return fallback
end

function Game:get_music_id(key, fallback)
    local music = self.dataset and self.dataset.music or nil
    if music and music[key] then
        return music[key]
    end
    return fallback
end

function Game:is_mobile_device()
    if love.system and love.system.getOS then
        local os_name = love.system.getOS()
        return os_name == "Android" or os_name == "iOS"
    end
    return false
end

function Game:is_web_device()
    if love.system and love.system.getOS then
        return love.system.getOS() == "Web"
    end
    return false
end

function Game:is_compact_screen()
    local width = self.renderer.screen_width or 0
    local height = self.renderer.screen_height or 0
    return math.min(width, height) > 0 and math.min(width, height) <= 900
end

function Game:should_show_touch_controls()
    local mode = self.settings.values.touch_controls
    if mode == "on" then
        return true
    end
    if mode == "off" then
        return false
    end
    return self:is_mobile_device()
end

function Game:update(dt)
    self.renderer:sync_dimensions()
    self.crt:update(dt)
    self.state_machine:update(dt)
    self.input:begin_frame()
end

function Game:draw()
    self.renderer:sync_dimensions()
    local post = nil
    if self.settings.values.video_mode == "mono_crt" then
        post = function(canvas)
            self.crt:draw(canvas)
        end
    end

    self.renderer:draw_scene(function()
        self.state_machine:draw()
    end, post)
end

function Game:resize(width, height)
    self.renderer:resize(width, height)
end

function Game:keypressed(key, _scancode, isrepeat)
    if not isrepeat then
        self.input:keypressed(key)
    end
end

function Game:keyreleased(key)
    self.input:keyreleased(key)
end

function Game:textinput(text)
    self.input:textinput(text)
end

function Game:mousepressed(x, y, _button, istouch)
    local now = love.timer and love.timer.getTime and love.timer.getTime() or 0
    if istouch or now < self.suppress_mouse_until then
        return
    end
    self.input:pointerpressed(x, y)
end

function Game:touchpressed(_id, x, y)
    local now = love.timer and love.timer.getTime and love.timer.getTime() or 0
    self.suppress_mouse_until = now + 0.35
    local width, height = love.graphics.getDimensions()
    self.input:pointerpressed(x * width, y * height)
end

return Game
