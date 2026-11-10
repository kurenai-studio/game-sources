-- Snakes and Ladders - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_sin = math.sin

local helpText = {
    "Snakes and Ladders - Food Adventure!",
    "",
    "How to Play:",
    "• Two players take turns rolling the dice",
    "• Move your token the number of spaces shown on the dice",
    "• If you land on a ladder, climb up to the higher square",
    "• If you land on a snake, slide down to the lower square",
    "• First player to reach square 100 wins!",
    "",
    "Controls:",
    "• SPACE - Roll dice",
    "• R - Restart game",
    "• ESC - Return to menu",
    "",
    "Food Theme:",
    "• Ladders are delicious treats that help you climb",
    "• Snakes are spoiled foods that make you slide down",
    "",
    "Click anywhere to close"
}

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.title = {
        text = "SNAKES & LADDERS",
        subtitle = "Food Adventure",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.3,
        minScale = 0.95,
        maxScale = 1.05,
        rotation = 0,
        rotationSpeed = 0.2
    }
    instance.showHelp = false

    instance:createMenuButtons()

    return instance
end

function Menu:setFonts(fonts)
    self.smallFont = fonts.small
    self.mediumFont = fonts.medium
    self.largeFont = fonts.large
    self.sectionFont = fonts.section
end

function Menu:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:updateButtonPositions()
end

function Menu:createMenuButtons()
    self.menuButtons = {
        {
            text = "Start Game",
            action = "start",
            width = 220,
            height = 50,
            x = 0,
            y = 0
        },
        {
            text = "How to Play",
            action = "help",
            width = 220,
            height = 50,
            x = 0,
            y = 0
        },
        {
            text = "Quit",
            action = "quit",
            width = 220,
            height = 50,
            x = 0,
            y = 0
        }
    }

    self:updateButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = self.screenHeight / 2 + 20
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 70
    end
end

function Menu:update(dt, screenWidth, screenHeight)
    if screenWidth ~= self.screenWidth or screenHeight ~= self.screenHeight then
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self:updateButtonPositions()
    end

    -- Update title animation
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end

    self.title.rotation = self.title.rotation + self.title.rotationSpeed * dt
end

function Menu:draw(screenWidth, screenHeight, state)
    -- Draw animated title
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.setFont(self.largeFont)

    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 4)
    love.graphics.rotate(math_sin(self.title.rotation) * 0.05)
    love.graphics.scale(self.title.scale, self.title.scale)
    love.graphics.printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")
    love.graphics.pop()

    -- Draw subtitle
    love.graphics.setColor(0.8, 0.3, 0.1)
    love.graphics.setFont(self.mediumFont)
    love.graphics.printf(self.title.subtitle, 0, screenHeight / 4 + 50, screenWidth, "center")

    if state == "menu" then
        if self.showHelp then
            self:drawHelpOverlay(screenWidth, screenHeight)
        else
            self:drawMenuButtons()
        end
    end

    -- Draw copyright
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("© 2025 Jericho Crosby – Snakes & Ladders", 10, screenHeight - 25, screenWidth - 20, "right")
end

function Menu:drawHelpOverlay(screenWidth, screenHeight)
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Help box
    local boxWidth = 700
    local boxHeight = 500
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = (screenHeight - boxHeight) / 2

    -- Box background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10)

    -- Box border
    love.graphics.setColor(1, 0.6, 0.2)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.largeFont)
    love.graphics.printf("How to Play", boxX, boxY + 20, boxWidth, "center")

    -- Help text
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(self.smallFont)

    local lineHeight = 22
    for i, line in ipairs(helpText) do
        local y = boxY + 80 + (i - 1) * lineHeight
        love.graphics.printf(line, boxX + 30, y, boxWidth - 60, "left")
    end

    love.graphics.setLineWidth(1)
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button)
    end
end

function Menu:drawButton(button)
    -- Button background with food-themed colors
    love.graphics.setColor(1, 0.7, 0.3, 0.9)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(1, 0.9, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(0.3, 0.2, 0.1)
    love.graphics.setFont(self.smallFont)
    local textWidth = self.smallFont:getWidth(button.text)
    local textHeight = self.smallFont:getHeight()
    love.graphics.print(button.text, button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = self.menuButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    -- If help is showing, any click closes it
    if state == "menu" and self.showHelp then
        self.showHelp = false
        return "help_close"
    end

    return nil
end

return Menu
