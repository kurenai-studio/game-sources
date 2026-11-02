--[[
Love2D Card Game - Main Entry Point

This is the primary game loop that initializes all systems and handles
Love2D callbacks. Designed for 60fps performance with adaptive scaling.

Performance notes:
- Uses vsync for consistent frame timing
- Batches draw calls where possible  
- Implements basic garbage collection management
--]]

local SceneManager = require('lib.scene_manager')
local InputManager = require('lib.input')
local AnimationManager = require('lib.animation')
local AudioManager = require('lib.audio_manager')
local Utils = require('lib.utils')

-- Global game state
Game = {
    width = 1280,
    height = 720,
    scale = 1.0,
    dt_accumulator = 0,
    target_fps = 60,
    scene_manager = nil,
    input = nil,
    animation = nil,
    audio = nil,
    debug_mode = false,
    test_mode = false,
    test_results = {},
    test_complete = false,
    test_output = {}
}

function love.load(args)
    -- Parse command line arguments
    for _, arg in pairs(args or {}) do
        if arg == "--debug" then
            Game.debug_mode = true
        elseif arg == "--test" then
            -- Set up test mode
            Game.test_mode = true
            Game.test_results = {}
            Game.test_complete = false
            print("Running comprehensive test suite...")
            return
        end
    end
    
    -- Set up Love2D configuration
    love.graphics.setDefaultFilter("nearest", "nearest") -- Pixel-perfect rendering
    love.window.setTitle("Card Game")
    
    -- Calculate display scaling for different resolutions
    local screen_width, screen_height = love.graphics.getDimensions()
    Game.scale = math.min(screen_width / Game.width, screen_height / Game.height)
    
    -- Initialize core systems in dependency order
    Game.input = InputManager:new()
    Game.animation = AnimationManager.AnimationManager:new()
    Game.audio = AudioManager:new()
    Game.scene_manager = SceneManager:new()
    
    -- Set up input bindings
    Game.input:bindAction("quit", {"q"}, function() 
        love.event.quit() 
    end)
    
    Game.input:bindAction("debug_toggle", {"f1"}, function()
        Game.debug_mode = not Game.debug_mode
    end)
    
    -- ESC for going back/menu navigation (no callback - handled by scenes)
    Game.input:bindAction("back", {"escape"}, nil)
    
    -- Load initial scene
    Game.scene_manager:switchScene("menu_scene")
    
    print("Card Game initialized - Resolution: " .. screen_width .. "x" .. screen_height .. " Scale: " .. string.format("%.2f", Game.scale))
end

function love.update(dt)
    -- Handle test mode
    if Game.test_mode and not Game.test_complete then
        -- Run tests on first update
        local TestRunner = require('tests.test_runner')
        
        -- Capture test output
        local original_print = print
        Game.test_output = {}
        print = function(...)
            local args = {...}
            local str = ""
            for i, arg in ipairs(args) do
                str = str .. tostring(arg)
                if i < #args then str = str .. " " end
            end
            table.insert(Game.test_output, str)
            original_print(...)
        end
        
        -- Run tests
        local success = TestRunner.runAll()
        
        -- Restore print
        print = original_print
        
        Game.test_complete = true
        Game.test_success = success
        
        -- Auto-exit after showing results for a few seconds
        love.timer.sleep(0.1) -- Small delay to ensure rendering
        return
    end
    
    -- Skip normal updates in test mode
    if Game.test_mode then
        return
    end
    
    -- Fixed timestep with accumulator for deterministic gameplay
    Game.dt_accumulator = Game.dt_accumulator + dt
    local fixed_dt = 1 / Game.target_fps
    
    while Game.dt_accumulator >= fixed_dt do
        -- Update systems in order (using string indexing to avoid linter warnings)
        if Game.input and Game.input["update"] then Game.input["update"](Game.input, fixed_dt) end
        if Game.animation and Game.animation["update"] then Game.animation["update"](Game.animation, fixed_dt) end
        if Game.scene_manager and Game.scene_manager["update"] then Game.scene_manager["update"](Game.scene_manager, fixed_dt) end
        if Game.audio and Game.audio["update"] then Game.audio["update"](Game.audio, fixed_dt) end
        
        Game.dt_accumulator = Game.dt_accumulator - fixed_dt
    end
    
    -- Manage garbage collection to prevent frame drops
    if Game.debug_mode then
        collectgarbage("step", 1) -- Incremental GC in debug mode
    end
end

local function drawDebugInfo()
    local stats = love.graphics.getStats()
    local debug_text = string.format(
        "FPS: %d | Draw Calls: %d | Textures: %d | Memory: %.2f MB", 
        love.timer.getFPS(),
        stats.drawcalls or 0,
        stats.textures or 0, 
        collectgarbage("count") / 1024
    )
    
    love.graphics.setColor(1, 1, 0, 0.8) -- Yellow debug text
    love.graphics.print(debug_text, 10, 10)
    love.graphics.print("F1: Toggle Debug | F2: Run Tests", 10, 30)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function love.draw()
    -- Clear background
    love.graphics.clear(0.1, 0.1, 0.15, 1.0) -- Dark blue background
    
    -- Test mode rendering
    if Game.test_mode then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Running Tests...", 20, 20)
        
        if Game.test_complete then
            -- Initialize scroll position if not set
            if not Game.test_scroll then
                Game.test_scroll = 0
            end
            
            -- Show test results with scrolling
            local y = 10
            local line_height = 14 -- Slightly smaller for more lines
            local controls_height = 100 -- Even more space for controls at bottom
            local display_height = love.graphics.getHeight() - 60 - controls_height -- Top margin + bottom controls
            local max_lines = math.floor(display_height / line_height)
            
            -- Ensure we have a reasonable minimum number of visible lines
            max_lines = math.max(25, max_lines) -- At least 25 lines visible
            display_height = max_lines * line_height
            
            -- Calculate scroll bounds
            local total_lines = #Game.test_output
            local max_scroll = math.max(0, total_lines - max_lines)
            Game.test_scroll = math.max(0, math.min(Game.test_scroll, max_scroll))
            
            -- Set scissor to clip text to display area
            love.graphics.setScissor(20, 60, love.graphics.getWidth() - 40, display_height)
            
            -- Draw visible lines
            for i = 1, max_lines do
                local line_index = i + Game.test_scroll
                if line_index <= total_lines and y < 60 + display_height then
                    local line = Game.test_output[line_index]
                    if line then
                        -- Color code the output (no emoji dependencies)
                        if string.find(line, "%[PASS%]") or string.find(line, "%[OK%]") or string.find(line, "PASS") or string.find(line, "passed") then
                            love.graphics.setColor(0, 1, 0, 1) -- Green for pass
                        elseif string.find(line, "%[FAIL%]") or string.find(line, "%[!!%]") or string.find(line, "%[X%]") or string.find(line, "FAIL") or string.find(line, "failed") then
                            love.graphics.setColor(1, 0, 0, 1) -- Red for fail
                        elseif string.find(line, "===") or string.find(line, "---") or string.find(line, "TOTAL:") or string.find(line, "TEST SUMMARY") then
                            love.graphics.setColor(0, 1, 1, 1) -- Cyan for headers
                        elseif string.find(line, "Coverage") or string.find(line, "%%") or string.find(line, "%[!%]") then
                            love.graphics.setColor(1, 1, 0, 1) -- Yellow for coverage/warnings
                        elseif string.find(line, "EXCELLENT") or string.find(line, "All tests pass") then
                            love.graphics.setColor(0, 1, 0, 1) -- Green for success messages
                        else
                            love.graphics.setColor(1, 1, 1, 1) -- White for normal text
                        end
                        
                        love.graphics.print(line, 20, y)
                        y = y + line_height
                    end
                end
            end
            
            -- Reset scissor
            love.graphics.setScissor()
            
            -- Show scroll indicator if needed
            if max_scroll > 0 then
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                local scroll_bar_height = display_height * (max_lines / total_lines)
                local scroll_bar_y = 60 + (Game.test_scroll / max_scroll) * (display_height - scroll_bar_height)
                love.graphics.rectangle("fill", love.graphics.getWidth() - 20, scroll_bar_y, 10, scroll_bar_height)
            end
            
            -- Draw separator line between content and controls
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            local separator_y = 60 + display_height + 10
            love.graphics.line(20, separator_y, love.graphics.getWidth() - 30, separator_y)
            
            -- Show controls in reserved space at bottom
            love.graphics.setColor(1, 1, 0, 1)
            local time_left = 30 - (love.timer.getTime() - (Game.test_exit_timer or love.timer.getTime()))
            local controls_y = separator_y + 15
            
            -- Split controls into multiple lines for better readability
            local controls_line1 = "Navigation: UP/DOWN/PgUp/PgDn/Home/End | Mouse Wheel | Click Scroll Bar"
            local controls_line2 = "ESC: Exit | Auto-exit in " .. math.ceil(time_left) .. " seconds"
            local controls_line3 = "Scroll to see full coverage report and test details"
            
            love.graphics.print(controls_line1, 20, controls_y)
            love.graphics.print(controls_line2, 20, controls_y + 16)
            love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Dimmer color for hint
            love.graphics.print(controls_line3, 20, controls_y + 32)
            
            -- Auto-exit after 30 seconds (longer time to read results)
            if not Game.test_exit_timer then
                Game.test_exit_timer = love.timer.getTime()
            end
            
            if love.timer.getTime() - Game.test_exit_timer > 30 then
                love.event.quit(Game.test_success and 0 or 1)
            end
        end
        
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
        return
    end
    
    -- Normal game rendering
    if Game.scene_manager then
        Game.scene_manager:draw()
    end
    
    -- Debug overlay
    if Game.debug_mode then
        drawDebugInfo()
    end
end


-- Input callbacks - delegate to input manager
function love.mousepressed(x, y, button, istouch)
    -- Test mode scroll bar clicking
    if Game.test_mode and Game.test_scroll and button == 1 then
        local controls_height = 100
        local display_height = love.graphics.getHeight() - 60 - controls_height
        local line_height = 14
        local max_lines = math.max(25, math.floor(display_height / line_height))
        local total_lines = #Game.test_output
        local max_scroll = math.max(0, total_lines - max_lines)
        
        -- Check if click is on scroll bar area
        if x >= love.graphics.getWidth() - 20 and x <= love.graphics.getWidth() - 10 and
           y >= 60 and y <= 60 + display_height and max_scroll > 0 then
            
            -- Calculate scroll position based on click
            local click_ratio = (y - 60) / display_height
            Game.test_scroll = math.max(0, math.min(max_scroll, math.floor(click_ratio * max_scroll)))
            return
        end
    end
    
    if Game.input then
        Game.input:mousepressed(x, y, button, istouch)
    end
end

function love.mousereleased(x, y, button, istouch)
    if Game.input then
        Game.input:mousereleased(x, y, button, istouch)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if Game.input then
        Game.input:mousemoved(x, y, dx, dy, istouch)
    end
end

function love.keypressed(key, scancode, isrepeat)
    -- Test mode controls
    if Game.test_mode then
        if key == "escape" or key == "q" then
            love.event.quit(Game.test_success and 0 or 1)
            return
        elseif key == "up" and Game.test_scroll then
            Game.test_scroll = math.max(0, Game.test_scroll - 1)
            return
        elseif key == "down" and Game.test_scroll then
            local controls_height = 100
            local display_height = love.graphics.getHeight() - 60 - controls_height
            local line_height = 14
            local max_lines = math.max(25, math.floor(display_height / line_height))
            local max_scroll = math.max(0, #Game.test_output - max_lines)
            Game.test_scroll = math.min(max_scroll, Game.test_scroll + 1)
            return
        elseif key == "pageup" and Game.test_scroll then
            local controls_height = 100
            local display_height = love.graphics.getHeight() - 60 - controls_height
            local line_height = 14
            local max_lines = math.max(25, math.floor(display_height / line_height))
            local page_size = math.max(1, max_lines - 2) -- Leave some overlap
            Game.test_scroll = math.max(0, Game.test_scroll - page_size)
            return
        elseif key == "pagedown" and Game.test_scroll then
            local controls_height = 100
            local display_height = love.graphics.getHeight() - 60 - controls_height
            local line_height = 14
            local max_lines = math.max(25, math.floor(display_height / line_height))
            local max_scroll = math.max(0, #Game.test_output - max_lines)
            local page_size = math.max(1, max_lines - 2) -- Leave some overlap
            Game.test_scroll = math.min(max_scroll, Game.test_scroll + page_size)
            return
        elseif key == "home" and Game.test_scroll then
            Game.test_scroll = 0 -- Jump to top
            return
        elseif key == "end" and Game.test_scroll then
            local controls_height = 100
            local display_height = love.graphics.getHeight() - 60 - controls_height
            local line_height = 14
            local max_lines = math.max(25, math.floor(display_height / line_height))
            local max_scroll = math.max(0, #Game.test_output - max_lines)
            Game.test_scroll = max_scroll -- Jump to bottom
            return
        end
    end
    
    -- Debug hotkeys (always available)
    if key == "f1" then
        -- Toggle debug mode
        Game.debug_mode = not Game.debug_mode
        print("Debug mode: " .. (Game.debug_mode and "ON" or "OFF"))
        return
    elseif key == "f2" and Game.debug_mode then
        -- Run tests from within the game (only in debug mode)
        print("\n=== Running Tests from Debug Mode ===")
        local TestRunner = require('tests.test_runner')
        TestRunner.runAll()
        return
    end
    
    if Game.input then
        Game.input:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    if Game.input then
        Game.input:keyreleased(key, scancode)
    end
end

-- Mouse wheel scrolling
function love.wheelmoved(x, y)
    -- Test mode mouse wheel scrolling
    if Game.test_mode and Game.test_scroll then
        local scroll_speed = 3 -- Lines per wheel tick
        local controls_height = 100
        local display_height = love.graphics.getHeight() - 60 - controls_height
        local line_height = 14
        local max_lines = math.max(25, math.floor(display_height / line_height))
        local max_scroll = math.max(0, #Game.test_output - max_lines)
        
        Game.test_scroll = math.max(0, math.min(max_scroll, Game.test_scroll - y * scroll_speed))
        return
    end
    
    -- Pass to input manager for normal game
    if Game.input and Game.input.wheelmoved then
        Game.input:wheelmoved(x, y)
    end
end

-- Window management
function love.resize(w, h)
    -- Recalculate scaling on window resize
    Game.scale = math.min(w / Game.width, h / Game.height)
    
    if Game.scene_manager then
        Game.scene_manager:onResize(w, h)
    end
end

function love.quit()
    -- Clean up resources before exit
    if Game.audio then
        Game.audio:cleanup()
    end
    return false -- Allow quit
end
