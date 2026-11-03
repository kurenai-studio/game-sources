sprites = {}
local music = require("music")
require ("map.map")
local character_model = require ("character.model")
local character_control = require("character.control")
local mapreader = require("map.mapreader")

local utils = require('utils')
local render = require('render')

game_state = "title"

local map_store = mapreader.MapStore:read_maps("ASSETS/maps/map1.json")
game_map1 = map_store.maps.game_map1
game_map2 = map_store.maps.game_map2

character_model.main_character = character_model.PlayerCharacter:new(
    "player", 
    1098, 
    character_model.CharacterStats:new(100),
    2,
    2
)

character_model.farmer = character_model.Character:new(
    "farmer", 
    1085, 
    character_model.CharacterStats:new(100),
    9,
    6
)

character_model.wizard = character_model.Character:new(
    "wizard", 
    1084, 
    character_model.CharacterStats:new(100),
    10,
    2
)

character_model.swordsman = character_model.Character:new(
    "Swordsman", 
    1097, 
    character_model.CharacterStats:new(120, 70),
    7,
    4
)

function love.load()
    utils.setup_random()
    love.keyboard.setKeyRepeat( true )
    for i = 0, 131 do
        local filename = string.format("ASSETS/tinytown/Tiles/tile_%04d.png", i)
        sprites[i] = love.graphics.newImage(filename)
    end
    for i = 0, 131 do
        local filename = string.format("ASSETS/tinydungeon/Tiles/tile_%04d.png", i)
        sprites[i + 1000] = love.graphics.newImage(filename)
    end

    love.window.setTitle("Spawner of Everilynn Map Upd 2.1 PA1.8.5version.05")
    love.window.setMode(800, 600, {resizable=true, vsync=0, minwidth=400, minheight=300})

    local iconimg_data = love.image.newImageData("icon.png")
    iconimg = love.graphics.newImage("icon.png")
    love.window.setIcon(iconimg_data)
    love.graphics.setBackgroundColor(0.8, 0.71, 0.55)
end

local function deal_environmental_damage()
    for i, the_character in pairs(character_model.Character.all_characters) do
        local pos = the_character:pos()
        local tile = game_map1.mapdata[pos.y][pos.x]
        if game_state == 'ingame' then
            if tile.u[1] == SPIKE then
            the_character.stats:deal_damage(math.random(1, 4))
            end
        end
    end
end

local function handle_status_updates()
    local the_character = character_model.main_character

    
end

local TimedUpdate = {}

TimedUpdate.__index = TimedUpdate

function TimedUpdate:new(interval, func)
    local new_object = {
        interval = interval,
        time_total = 0,
        func = func
    }

    setmetatable(new_object, {__index = TimedUpdate})
    new_object.__index = TimedUpdate
    return new_object
end

function TimedUpdate:update(step_in_time)
    self.time_total = self.time_total + step_in_time
    if self.time_total >= self.interval then
      self.time_total = self.time_total - self.interval
      self.func()
   end
end

function recover_health()
    local new_health = character_model.main_character.stats.current_health + 1
    if new_health <= character_model.main_character.stats.max_health then
        character_model.main_character.stats.current_health = new_health
    end
end


function move_swordsman_wrapper()
    character_control.move_swordsman(game_map1)
end

local updaters = {
    TimedUpdate:new(1, move_swordsman_wrapper),
    TimedUpdate:new(1, deal_environmental_damage),
    TimedUpdate:new(60, recover_health)
}

local background_music = music.BackgroundMusicManager:new()

local time_total = 0
function love.update(step_in_time)
    for index, updater in ipairs(updaters) do
        updater:update(step_in_time)
    end
    handle_status_updates()

    background_music:update(game_state, character_model.main_character:get_player_status())
end


function love.draw()
    local ingame_renderer = render.IngameRenderer:new()
    if game_state == 'ingame' then
        ingame_renderer:draw()
    elseif game_state == 'title' then
        render.draw_title()
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end

    if game_state == 'ingame' then
        character_control.move_main_character(game_map1, key)
    elseif game_state == 'title' then
        if key == "escape" then
            love.event.quit()
        elseif key == "return" then
            game_state = 'ingame'
        end
    end
end

