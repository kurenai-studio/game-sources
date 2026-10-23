--[[
Settings Scene - Game Configuration and Options

A simple settings screen for adjusting game preferences like audio volume,
graphics options, and controls.
--]]

local Layout = require('lib.layout')
local AnimationManager = require('lib.animation')

local SettingsScene = {}
SettingsScene.__index = SettingsScene

function SettingsScene:new()
    local instance = {
        -- Scene state
        is_active = false,
        animation_manager = nil,
        
        -- UI Layout
        ui_container = nil,
        title_container = nil,
        options_container = nil,
        back_button = nil,
        
        -- Settings values
        master_volume = 0.8,
        sfx_volume = 0.7,
        music_volume = 0.6,
        fullscreen = true,
        vsync = true,
        
        -- UI state
        hovered_option = nil
    }
    
    setmetatable(instance, SettingsScene)
    return instance
end

function SettingsScene:enter()
    self.is_active = true
    
    -- Initialize systems
    self.animation_manager = AnimationManager.AnimationManager:new()
    
    -- Create UI
    self:createUI()
    
    -- Set up input handlers
    if Game and Game.input then
        Game.input:addEventListener("mouse_pressed", function(event) self:onMousePressed(event) end)
        Game.input:addEventListener("mouse_moved", function(event) self:onMouseMoved(event) end)
    end
    
    print("Entered settings scene")
end

function SettingsScene:exit()
    self.is_active = false
    
    if self.animation_manager then
        self.animation_manager:stopAll()
    end
    
    print("Exited settings scene")
end

function SettingsScene:createUI()
    local screen_width, screen_height = love.graphics.getDimensions()
    
    -- Use direct positioning instead of Layout.Container for better control
    self.title_area = {
        x = screen_width / 2 - 200,
        y = 100,
        width = 400,
        height = 80
    }
    
    self.options_area = {
        x = screen_width / 2 - 250,
        y = screen_height / 2 - 200,
        width = 500,
        height = 400
    }
    
    -- Back button
    self.back_button = {
        x = screen_width / 2 - 60,
        y = screen_height - 100,
        width = 120,
        height = 40,
        text = "Back to Menu"
    }
end

function SettingsScene:onMousePressed(event)
    if not self.is_active then return end
    
    print("Settings mouse pressed at: " .. event.x .. ", " .. event.y)
    
    -- Check back button
    if self:isPointInButton(event.x, event.y, self.back_button) then
        print("Back button clicked!")
        self:goBack()
        return
    end
    
    -- Check settings options
    local options_x, options_y, options_w, options_h = self.options_area.x, self.options_area.y, self.options_area.width, self.options_area.height
    
    if event.x >= options_x and event.x < options_x + options_w and
       event.y >= options_y and event.y < options_y + options_h then
        
        -- Simple option clicking (in a real implementation, these would be proper UI controls)
        local relative_y = event.y - options_y
        local option_height = 50
        local option_index = math.floor(relative_y / option_height) + 1
        
        if option_index == 1 then
            -- Toggle fullscreen
            self.fullscreen = not self.fullscreen
            love.window.setFullscreen(self.fullscreen)
            print("Fullscreen: " .. (self.fullscreen and "ON" or "OFF"))
        elseif option_index == 2 then
            -- Toggle vsync
            self.vsync = not self.vsync
            love.window.setVSync(self.vsync and 1 or 0)
            print("VSync: " .. (self.vsync and "ON" or "OFF"))
        elseif option_index == 3 then
            -- Cycle master volume
            self.master_volume = (self.master_volume + 0.2) % 1.2
            if self.master_volume > 1.0 then self.master_volume = 0.0 end
            print("Master Volume: " .. math.floor(self.master_volume * 100) .. "%")
        elseif option_index == 4 then
            -- Cycle SFX volume
            self.sfx_volume = (self.sfx_volume + 0.2) % 1.2
            if self.sfx_volume > 1.0 then self.sfx_volume = 0.0 end
            print("SFX Volume: " .. math.floor(self.sfx_volume * 100) .. "%")
        elseif option_index == 5 then
            -- Cycle music volume
            self.music_volume = (self.music_volume + 0.2) % 1.2
            if self.music_volume > 1.0 then self.music_volume = 0.0 end
            print("Music Volume: " .. math.floor(self.music_volume * 100) .. "%")
        end
        
        -- Play click sound
        if Game and Game.audio then
            Game.audio:playSound("button_click")
        end
    end
end

function SettingsScene:onMouseMoved(event)
    if not self.is_active then return end
    
    -- Update hovered option
    local options_x, options_y, options_w, options_h = self.options_area.x, self.options_area.y, self.options_area.width, self.options_area.height
    
    if event.x >= options_x and event.x < options_x + options_w and
       event.y >= options_y and event.y < options_y + options_h then
        
        local relative_y = event.y - options_y
        local option_height = 50
        local new_hovered = math.floor(relative_y / option_height) + 1
        
        if new_hovered ~= self.hovered_option then
            self.hovered_option = new_hovered
            
            -- Play hover sound
            if Game and Game.audio then
                Game.audio:playSound("card_hover")
            end
        end
    else
        self.hovered_option = nil
    end
end

function SettingsScene:isPointInButton(x, y, button)
    return x >= button.x and x < button.x + button.width and
           y >= button.y and y < button.y + button.height
end

function SettingsScene:goBack()
    if Game and Game.scene_manager then
        -- Use popScene with transition effects
        Game.scene_manager:popScene({
            type = "fade",
            duration = 0.3
        })
    end
end

function SettingsScene:update(dt)
    if not self.is_active then return end
    
    -- Update animation system
    if self.animation_manager then
        self.animation_manager:update(dt)
    end
    
    -- Handle escape key to go back
    if Game and Game.input then
        if Game.input:isActionJustPressed("back") then
            self:goBack()
        end
    end
end

function SettingsScene:draw()
    if not self.is_active then return end
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    
    -- Draw title background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    love.graphics.rectangle("fill", self.title_area.x, self.title_area.y, self.title_area.width, self.title_area.height)
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.rectangle("line", self.title_area.x, self.title_area.y, self.title_area.width, self.title_area.height)
    
    -- Draw options background
    love.graphics.setColor(0.15, 0.15, 0.25, 0.9)
    love.graphics.rectangle("fill", self.options_area.x, self.options_area.y, self.options_area.width, self.options_area.height)
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.rectangle("line", self.options_area.x, self.options_area.y, self.options_area.width, self.options_area.height)
    
    -- Draw title
    self:drawTitle()
    
    -- Draw options
    self:drawOptions()
    
    -- Draw back button
    self:drawBackButton()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function SettingsScene:drawTitle()
    local title_x, title_y, title_w, title_h = self.title_area.x, self.title_area.y, self.title_area.width, self.title_area.height
    
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 1, 0.8, 1)
    
    local title_text = "Settings"
    local text_width = love.graphics.getFont():getWidth(title_text)
    love.graphics.print(title_text, title_x + (title_w - text_width) / 2, title_y + 25)
end

function SettingsScene:drawOptions()
    local options_x, options_y, options_w, options_h = self.options_area.x, self.options_area.y, self.options_area.width, self.options_area.height
    
    love.graphics.setFont(love.graphics.newFont(16))
    
    local options = {
        {"Fullscreen", self.fullscreen and "ON" or "OFF"},
        {"VSync", self.vsync and "ON" or "OFF"},
        {"Master Volume", math.floor(self.master_volume * 100) .. "%"},
        {"SFX Volume", math.floor(self.sfx_volume * 100) .. "%"},
        {"Music Volume", math.floor(self.music_volume * 100) .. "%"}
    }
    
    for i, option in ipairs(options) do
        local y = options_y + 20 + (i - 1) * 50
        
        -- Highlight hovered option
        if i == self.hovered_option then
            love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
            love.graphics.rectangle("fill", options_x + 10, y - 5, options_w - 20, 40)
        end
        
        -- Option name
        love.graphics.setColor(0.9, 0.9, 1, 1)
        love.graphics.print(option[1], options_x + 30, y + 10)
        
        -- Option value
        love.graphics.setColor(1, 1, 0.8, 1)
        local value_width = love.graphics.getFont():getWidth(option[2])
        love.graphics.print(option[2], options_x + options_w - value_width - 30, y + 10)
    end
end

function SettingsScene:drawBackButton()
    local btn = self.back_button
    
    -- Button background
    love.graphics.setColor(0.3, 0.5, 0.3, 0.9)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
    
    -- Button border
    love.graphics.setColor(0.5, 0.7, 0.5, 1)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    local text_width = love.graphics.getFont():getWidth(btn.text)
    local text_height = love.graphics.getFont():getHeight()
    love.graphics.print(btn.text, 
        btn.x + (btn.width - text_width) / 2,
        btn.y + (btn.height - text_height) / 2)
end

return SettingsScene
