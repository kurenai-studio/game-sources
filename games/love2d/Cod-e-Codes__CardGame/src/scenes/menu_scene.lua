--[[
Menu Scene - Main Menu Interface

Simple main menu scene demonstrating UI layout, button interactions,
and scene transitions. Serves as the entry point for the game.

Features:
- Responsive button layout
- Smooth transitions between scenes
- Settings menu integration
- Visual effects and animations
--]]

local Layout = require('lib.layout')
local AnimationManager = require('lib.animation')

local MenuScene = {}
MenuScene.__index = MenuScene

function MenuScene:new()
    local instance = {
        -- Scene state
        is_active = false,
        animation_manager = nil,
        
        -- UI elements
        ui_container = nil,
        title_text = "Card Game",
        buttons = {},
        
        -- Visual effects
        background_particles = {},
        title_scale = 1.0,
        
        -- Configuration
        button_width = 200,
        button_height = 50,
        button_spacing = 20
    }
    
    setmetatable(instance, MenuScene)
    return instance
end

function MenuScene:enter()
    self.is_active = true
    
    -- Initialize animation manager
    self.animation_manager = AnimationManager.AnimationManager:new()
    
    -- Create UI
    self:createUI()
    
    -- Skip animations for now to debug positioning
    -- self:playEntranceAnimations()
    
    -- Set up input handlers
    if Game and Game.input then
        Game.input:addEventListener("mouse_pressed", function(event) self:onMousePressed(event) end)
        Game.input:addEventListener("mouse_moved", function(event) self:onMouseMoved(event) end)
    end
    
    -- Play menu music
    if Game and Game.audio then
        Game.audio:playMusic("menu_theme", {loop = true, volume = 0.5})
    end
    
    print("Entered menu scene")
end

function MenuScene:exit()
    self.is_active = false
    
    -- Clean up animations
    if self.animation_manager then
        self.animation_manager:stopAll()
    end
    
    print("Exited menu scene")
end

function MenuScene:onPause()
    print("Menu scene paused")
    -- Keep the scene active for rendering but don't process input
end

function MenuScene:onResume()
    print("Menu scene resumed")
    self.is_active = true
    
    -- Re-register input handlers
    if Game and Game.input then
        Game.input:addEventListener("mouse_pressed", function(event) self:onMousePressed(event) end)
        Game.input:addEventListener("mouse_moved", function(event) self:onMouseMoved(event) end)
    end
end

function MenuScene:createUI()
    -- Get actual screen dimensions
    local screen_width, screen_height = love.graphics.getDimensions()
    
    print("Creating UI with screen dimensions: " .. screen_width .. "x" .. screen_height)
    
    -- Create menu buttons (simplified - store positions directly)
    self.buttons = {
        {
            text = "Start Game",
            action = function() self:startGame() end,
            x = (screen_width - self.button_width) / 2,
            y = screen_height / 2 - 60,
            width = self.button_width,
            height = self.button_height,
            hovered = false,
            scale = 1.0
        },
        {
            text = "Deck Builder", 
            action = function() self:openDeckBuilder() end,
            x = (screen_width - self.button_width) / 2,
            y = screen_height / 2,
            width = self.button_width,
            height = self.button_height,
            hovered = false,
            scale = 1.0
        },
        {
            text = "Settings",
            action = function() self:openSettings() end,
            x = (screen_width - self.button_width) / 2,
            y = screen_height / 2 + 60,
            width = self.button_width,
            height = self.button_height,
            hovered = false,
            scale = 1.0
        },
        {
            text = "Exit",
            action = function() self:exitGame() end,
            x = (screen_width - self.button_width) / 2,
            y = screen_height / 2 + 120,
            width = self.button_width,
            height = self.button_height,
            hovered = false,
            scale = 1.0
        }
    }
    
    -- Debug print button positions
    for i, button in ipairs(self.buttons) do
        print("Button " .. button.text .. " at: " .. button.x .. ", " .. button.y .. " size: " .. button.width .. "x" .. button.height)
    end
end

function MenuScene:playEntranceAnimations()
    -- Animate title
    self.title_scale = 0.5
    local title_grow = AnimationManager.Tween:new(self, 0.8, {title_scale = 1.0}, AnimationManager.Easing.outBack)
    self.animation_manager:play(title_grow)
    
    -- Animate buttons with staggered entrance
    for i, button in ipairs(self.buttons) do
        if button.container then
            -- Start buttons off-screen
            ---@diagnostic disable-next-line: inject-field
            button.container.x = -self.button_width
            
            local delay = i * 0.1
            local slide_in = AnimationManager.Tween:new(button.container, 0.5, 
                {x = (love.graphics.getWidth() - self.button_width) / 2}, 
                AnimationManager.Easing.outBack, delay)
            
            self.animation_manager:play(slide_in)
        end
    end
end

function MenuScene:onMousePressed(event)
    if not self.is_active then 
        print("Menu scene not active")
        return 
    end
    
    print("Mouse pressed in menu: " .. event.x .. ", " .. event.y)
    
    -- Check button clicks with simple bounds checking
    for _, button in ipairs(self.buttons) do
        local contains = event.x >= button.x and event.x <= button.x + button.width and
                        event.y >= button.y and event.y <= button.y + button.height
        print("Button " .. button.text .. " contains point: " .. tostring(contains))
        if contains then
            self:clickButton(button)
            break
        end
    end
end

function MenuScene:onMouseMoved(event)
    if not self.is_active then return end
    
    -- Update button hover states with simple bounds checking
    for _, button in ipairs(self.buttons) do
        local is_hovering = event.x >= button.x and event.x <= button.x + button.width and
                           event.y >= button.y and event.y <= button.y + button.height
        
        if is_hovering ~= button.hovered then
            button.hovered = is_hovering
            
            if is_hovering then
                -- Scale button up slightly on hover
                button.scale = 1.05
                
                -- Play hover sound
                if Game.audio then
                    Game.audio:playSound("card_hover", {volume = 0.3, pitch = 1.2})
                end
            else
                -- Reset scale when not hovering
                button.scale = 1.0
            end
        end
    end
end

function MenuScene:clickButton(button)
    print("Button clicked: " .. button.text)
    
    -- Play click sound
    if Game.audio then
        Game.audio:playSound("button_click", {volume = 0.6})
    end
    
    -- Simple click animation - scale down briefly then execute
    button.scale = 0.95
    
    -- Execute the button's action immediately
    button.action()
    
    -- Reset scale 
    button.scale = button.hovered and 1.05 or 1.0
end

function MenuScene:startGame()
    print("Starting game...")
    
    -- Transition to game scene
    if Game and Game.scene_manager then
        print("Attempting to switch to game_scene")
        Game.scene_manager:switchScene("game_scene", {
            type = "fade",
            duration = 0.5
        })
    else
        print("ERROR: Game or scene_manager not available")
    end
end

function MenuScene:openDeckBuilder()
    print("Opening deck builder...")
    
    -- Transition to deck builder
    if Game and Game.scene_manager then
        Game.scene_manager:switchScene("deck_builder", {
            type = "slide", 
            duration = 0.4
        })
    end
end

function MenuScene:openSettings()
    print("Opening settings...")
    
    -- Push settings as overlay
    if Game and Game.scene_manager then
        Game.scene_manager:pushScene("settings_scene", {
            type = "fade",
            duration = 0.3
        })
    end
end

function MenuScene:exitGame()
    print("Exiting game...")
    love.event.quit()
end

function MenuScene:update(dt)
    if not self.is_active then return end
    
    -- Update animations
    if self.animation_manager then
        self.animation_manager:update(dt)
    end
    
    -- Update UI containers
    if self.ui_container then
        self.ui_container:update(dt)
    end
    
    -- Handle input
    if Game and Game.input then
        if Game.input:isActionJustPressed("quit") then
            self:exitGame()
        end
    end
end

function MenuScene:draw()
    if not self.is_active then return end
    
    -- Draw background gradient
    self:drawBackground()
    
    -- Draw title
    self:drawTitle()
    
    -- Draw buttons directly
    self:drawButtons()
    
    -- Draw version info
    self:drawVersionInfo()
end

function MenuScene:drawBackground()
    -- Simple gradient background
    local screen_width, screen_height = love.graphics.getDimensions()
    local gradient_colors = {
        {0.1, 0.1, 0.2, 1},  -- Top
        {0.05, 0.05, 0.15, 1} -- Bottom
    }
    
    for y = 0, screen_height, 4 do
        local t = y / screen_height
        local r = gradient_colors[1][1] + (gradient_colors[2][1] - gradient_colors[1][1]) * t
        local g = gradient_colors[1][2] + (gradient_colors[2][2] - gradient_colors[1][2]) * t
        local b = gradient_colors[1][3] + (gradient_colors[2][3] - gradient_colors[1][3]) * t
        
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", 0, y, screen_width, 4)
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function MenuScene:drawTitle()
    -- Title text
    local title_font = love.graphics.newFont(48)
    love.graphics.setFont(title_font)
    
    local screen_width = love.graphics.getWidth()
    local title_width = title_font:getWidth(self.title_text)
    local title_x = (screen_width - title_width * self.title_scale) / 2
    local title_y = 100
    
    -- Title shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.push()
    love.graphics.translate(title_x + 3, title_y + 3)
    love.graphics.scale(self.title_scale)
    love.graphics.print(self.title_text)
    love.graphics.pop()
    
    -- Title text
    love.graphics.setColor(0.9, 0.9, 1, 1)
    love.graphics.push()
    love.graphics.translate(title_x, title_y)
    love.graphics.scale(self.title_scale)
    love.graphics.print(self.title_text)
    love.graphics.pop()
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function MenuScene:drawButtons()
    local button_font = love.graphics.newFont(18)
    love.graphics.setFont(button_font)
    
    for _, button in ipairs(self.buttons) do
        local x, y, w, h = button.x, button.y, button.width, button.height
        
        -- Apply button scaling
        love.graphics.push()
        love.graphics.translate(x + w/2, y + h/2)
        love.graphics.scale(button.scale)
        love.graphics.translate(-w/2, -h/2)
        
        -- Draw button background
        if button.hovered then
            love.graphics.setColor(0.3, 0.4, 0.5, 0.9)
        else
            love.graphics.setColor(0.2, 0.3, 0.4, 0.8)
        end
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        -- Draw button border
        love.graphics.setColor(0.4, 0.5, 0.6, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 0, 0, w, h)
        
        -- Button text color
        if button.hovered then
            love.graphics.setColor(1, 1, 0.8, 1) -- Slight yellow tint when hovered
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 1)
        end
        
        -- Center text in button
        local text_width = button_font:getWidth(button.text)
        local text_x = (w - text_width) / 2
        local text_y = (h - button_font:getHeight()) / 2
        
        love.graphics.print(button.text, text_x, text_y)
        
        love.graphics.pop()
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function MenuScene:drawVersionInfo()
    local version_font = love.graphics.newFont(12)
    love.graphics.setFont(version_font)
    love.graphics.setColor(0.6, 0.6, 0.7, 1)
    
    local version_text = "Card Game v1.0 - Built with Love2D"
    local text_width = version_font:getWidth(version_text)
    local screen_width, screen_height = love.graphics.getDimensions()
    love.graphics.print(version_text, screen_width - text_width - 10, screen_height - 25)
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function MenuScene:onResize(width, height)
    if self.ui_container then
        self.ui_container:onResize(width, height)
        self:createUI() -- Recreate UI layout
    end
end

return MenuScene
