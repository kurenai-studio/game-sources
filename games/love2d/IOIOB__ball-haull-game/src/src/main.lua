require "libraries/graphics"
require "libraries/math"
require "libraries/sound"

function love.load()
    --Require all files in the game folder
    requireGameFiles("gameLogic")

    --Set up all the graphics variables
    SCALE = 5 --Bigger = less resolution
    SCREEN_WIDTH = 128
    SCREEN_HEIGHT = 128
    SPRITE_SIZE = 16
    PALETTES = makePalettes("palette.png")
    CURRENT_PALETTE = 1
    USE_SHADER = true
    SHADER_PARAMS = {
        {"intensity", 1},
        {"screenWidth", SCREEN_WIDTH},
        {"screenHeight", SCREEN_HEIGHT},
        {"brightness", 1.1},
    }
    GRAYSCALE = makePalette("grayScale.png")
    FONT = "font.png"

    --Set up the sound variables
    SOUND_VOLUME = 0.1
    MUSIC_VOLUME = 0.05
    SOUNDS = getSounds("sounds", "static", SOUND_VOLUME)
    MUSIC = getSounds("music", "stream", MUSIC_VOLUME)

    --Initialize the input variables
    BUTTONS = {
        {'w', 'up'},
        {'a', 'left'},
        {'s', 'down'},
        {'d', 'right'},
        {'o', 'x'},
        {'p', 'c'}
    }
    buttonsDownTable = {}
    buttonsPressedTable = {}

    --Initialize the font from an image
    local glyphs = " abcdefghijklmnopqrstuvwxyz1234567890.,!?\"'#:|—-"
    local spacing = 1
    FONT = love.graphics.newImageFont(FONT, glyphs, spacing)
	love.graphics.setFont(FONT)

    --Initialize graphics variables
    initGraphics(SCALE, SCREEN_WIDTH, SCREEN_HEIGHT)

    --Make the sprites
    SPRITE_SHEET = love.graphics.newImage("sprites.png")
    QUADS = initSprites(SPRITE_SHEET, SPRITE_SIZE)

    --game load function
    load()

end


function love.update(dt)
    update(dt)
    buttonsPressedTable = {false}
end


function love.draw()
    startDrawing()

    draw()

    endDrawing()
end


function love.keypressed(key, scancode)
    for i, keys in ipairs(BUTTONS) do
        for j, key in ipairs(keys) do
            if scancode == key then
                buttonsDownTable[i] = true
                buttonsPressedTable[i] = true
            end
        end
    end
    if scancode == "f11" then
        toggleFullscreen()
    end
end

function love.keyreleased(key, scancode)
    for i, keys in ipairs(BUTTONS) do
        for j, key in ipairs(keys) do
            if scancode == key then
                buttonsDownTable[i] = false
            end
        end
    end
end


function buttonDown(n)
    return buttonsDownTable[n]
end

function buttonPressed(n)
    return buttonsPressedTable[n]
end


function requireGameFiles(gameFolder)
    local folderFiles = love.filesystem.getDirectoryItems(gameFolder)
    for i, v in ipairs(folderFiles) do
        if string.sub(v, #v-3) == ".lua" then
            require(gameFolder.."/"..string.sub(v, 1, #v-4))
        else
            local info = love.filesystem.getInfo(gameFolder.."/"..v)
            if info.type == "directory" then
                requireGameFiles(gameFolder.."/"..v)
            end
        end
    end
end


function quit()
    love.event.quit()
end
