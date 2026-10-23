--[[
Layout System - Responsive UI Containers

Provides flexible, resolution-independent UI layout with anchoring,
automatic scaling, and flex-box style positioning.

Key features:
- Anchor-based positioning (top-left, center, bottom-right, etc.)
- Automatic scaling based on screen resolution
- Nested container hierarchy
- Constraint-based sizing (min/max width/height)

Usage:
  local container = Container:new(0, 0, 400, 300)
  container:setAnchor("center", "center")
  container:addChild(button, {anchor = "top-left", padding = {10, 10}})
--]]

local Layout = {}

-- Container class for UI elements
local Container = {}
Container.__index = Container

-- Anchor types for positioning
local ANCHORS = {
    ["top-left"] = {0, 0},
    ["top-center"] = {0.5, 0},
    ["top-right"] = {1, 0},
    ["center-left"] = {0, 0.5},
    ["center"] = {0.5, 0.5},
    ["center-right"] = {1, 0.5},
    ["bottom-left"] = {0, 1},
    ["bottom-center"] = {0.5, 1},
    ["bottom-right"] = {1, 1}
}

function Container:new(x, y, width, height, options)
    options = options or {}
    
    local instance = {
        -- Position and size
        x = x or 0,
        y = y or 0,
        width = width or 100,
        height = height or 100,
        
        -- Anchor settings
        anchor_x = 0, -- 0-1 anchor point within parent
        anchor_y = 0,
        anchor_offset_x = 0, -- Pixel offset from anchor
        anchor_offset_y = 0,
        
        -- Hierarchy
        parent = nil,
        children = {},
        
        -- Layout properties
        padding = options.padding or {0, 0, 0, 0}, -- top, right, bottom, left
        margin = options.margin or {0, 0, 0, 0},
        visible = options.visible ~= false,
        
        -- Constraints
        min_width = options.min_width or 0,
        min_height = options.min_height or 0,
        max_width = options.max_width or math.huge,
        max_height = options.max_height or math.huge,
        
        -- Layout behavior
        auto_resize = options.auto_resize or false,
        maintain_aspect = options.maintain_aspect or false,
        aspect_ratio = nil,
        
        -- Styling
        background_color = options.background_color,
        border_color = options.border_color,
        border_width = options.border_width or 0,
        
        -- Internal state
        cached_bounds = nil,
        needs_layout = true
    }
    
    setmetatable(instance, Container)
    
    -- Calculate aspect ratio if maintaining aspect
    if instance.maintain_aspect then
        instance.aspect_ratio = width / height
    end
    
    return instance
end

function Container:setAnchor(anchor_type, offset_x, offset_y)
    if type(anchor_type) == "string" then
        local anchor_point = ANCHORS[anchor_type]
        if not anchor_point then
            error("Invalid anchor type: " .. anchor_type)
        end
        self.anchor_x = anchor_point[1]
        self.anchor_y = anchor_point[2]
    else
        -- Assume numeric anchor values (0-1)
        self.anchor_x = anchor_type or 0
        self.anchor_y = offset_x or 0
        offset_x = offset_y
        offset_y = nil
    end
    
    self.anchor_offset_x = offset_x or 0
    self.anchor_offset_y = offset_y or 0
    self:invalidateLayout()
end

function Container:addChild(child, options)
    options = options or {}
    
    child.parent = self
    table.insert(self.children, child)
    
    -- Apply child positioning options
    if options.anchor then
        child:setAnchor(options.anchor, options.offset_x, options.offset_y)
    end
    
    if options.padding then
        child.padding = options.padding
    end
    
    if options.margin then
        child.margin = options.margin
    end
    
    self:invalidateLayout()
end

function Container:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            c.parent = nil
            table.remove(self.children, i)
            self:invalidateLayout()
            return true
        end
    end
    return false
end

function Container:setSize(width, height)
    local old_width, old_height = self.width, self.height
    
    -- Apply constraints
    self.width = math.max(self.min_width, math.min(width, self.max_width))
    self.height = math.max(self.min_height, math.min(height, self.max_height))
    
    -- Maintain aspect ratio if required
    if self.maintain_aspect and self.aspect_ratio then
        if math.abs(width - old_width) > math.abs(height - old_height) then
            -- Width changed more, adjust height
            self.height = self.width / self.aspect_ratio
        else
            -- Height changed more, adjust width
            self.width = self.height * self.aspect_ratio
        end
        
        -- Reapply constraints after aspect adjustment
        self.width = math.max(self.min_width, math.min(self.width, self.max_width))
        self.height = math.max(self.min_height, math.min(self.height, self.max_height))
    end
    
    if self.width ~= old_width or self.height ~= old_height then
        self:invalidateLayout()
    end
end

function Container:setPosition(x, y)
    if self.x ~= x or self.y ~= y then
        self.x, self.y = x, y
        self:invalidateLayout()
    end
end

function Container:resize(width, height)
    -- Alias for setSize for compatibility
    self:setSize(width, height)
end

function Container:invalidateLayout()
    self.cached_bounds = nil
    self.needs_layout = true
    
    -- Invalidate all children
    for _, child in ipairs(self.children) do
        child:invalidateLayout()
    end
end

function Container:getScreenBounds()
    if self.cached_bounds and not self.needs_layout then
        return self.cached_bounds.x, self.cached_bounds.y, 
               self.cached_bounds.width, self.cached_bounds.height
    end
    
    local screen_x, screen_y = self.x, self.y
    
    -- Apply parent anchor positioning
    if self.parent then
        local parent_x, parent_y, parent_w, parent_h = self.parent:getScreenBounds()
        
        -- Calculate anchor position within parent
        local anchor_x = parent_x + (parent_w * self.anchor_x)
        local anchor_y = parent_y + (parent_h * self.anchor_y)
        
        -- Apply container position relative to anchor
        screen_x = anchor_x + self.anchor_offset_x + self.x
        screen_y = anchor_y + self.anchor_offset_y + self.y
        
        -- Apply parent padding
        local padding = self.parent.padding
        local pt, pr, pb, pl = padding[1] or 0, padding[2] or 0, padding[3] or 0, padding[4] or 0
        screen_x = screen_x + pl
        screen_y = screen_y + pt
    else
        -- Root container - apply global screen scaling
        local screen_width = love.graphics.getWidth() / (Game and Game.scale or 1)
        local screen_height = love.graphics.getHeight() / (Game and Game.scale or 1)
        
        local anchor_x = screen_width * self.anchor_x
        local anchor_y = screen_height * self.anchor_y
        
        screen_x = anchor_x + self.anchor_offset_x + self.x
        screen_y = anchor_y + self.anchor_offset_y + self.y
    end
    
    -- Cache calculated bounds
    self.cached_bounds = {
        x = screen_x,
        y = screen_y,
        width = self.width,
        height = self.height
    }
    
    self.needs_layout = false
    
    return screen_x, screen_y, self.width, self.height
end

function Container:contains(x, y)
    local bx, by, bw, bh = self:getScreenBounds()
    return x >= bx and x < bx + bw and y >= by and y < by + bh
end

function Container:getChildAt(x, y)
    -- Check children in reverse order (top-most first)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child.visible and child:contains(x, y) then
            return child
        end
    end
    return nil
end

function Container:update(dt)
    -- Update all children
    for _, child in ipairs(self.children) do
        if child.update then
            child:update(dt)
        end
    end
end

function Container:draw()
    if not self.visible then return end
    
    local x, y, w, h = self:getScreenBounds()
    
    -- Draw background
    if self.background_color then
        love.graphics.setColor(self.background_color)
        love.graphics.rectangle("fill", x, y, w, h)
    end
    
    -- Draw border
    if self.border_color and self.border_width > 0 then
        love.graphics.setColor(self.border_color)
        love.graphics.setLineWidth(self.border_width)
        love.graphics.rectangle("line", x, y, w, h)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw children
    for _, child in ipairs(self.children) do
        if child.draw then
            child:draw()
        end
    end
end

function Container:onResize(screen_width, screen_height)
    -- Invalidate layout on screen resize
    self:invalidateLayout()
    
    -- Notify all children
    for _, child in ipairs(self.children) do
        if child.onResize then
            child:onResize(screen_width, screen_height)
        end
    end
end

-- Layout utility functions
Layout.Container = Container

function Layout.createGrid(rows, cols, width, height, spacing)
    spacing = spacing or 0
    local containers = {}
    
    local cell_width = (width - (cols - 1) * spacing) / cols
    local cell_height = (height - (rows - 1) * spacing) / rows
    
    for row = 1, rows do
        containers[row] = {}
        for col = 1, cols do
            local x = (col - 1) * (cell_width + spacing)
            local y = (row - 1) * (cell_height + spacing)
            
            containers[row][col] = Container:new(x, y, cell_width, cell_height)
        end
    end
    
    return containers
end

function Layout.distributeHorizontally(parent, children, spacing)
    spacing = spacing or 0
    local total_spacing = (#children - 1) * spacing
    local available_width = parent.width - total_spacing
    local child_width = available_width / #children
    
    for i, child in ipairs(children) do
        local x = (i - 1) * (child_width + spacing)
        child:setPosition(x, child.y)
        child:setSize(child_width, child.height)
        parent:addChild(child)
    end
end

function Layout.distributeVertically(parent, children, spacing)
    spacing = spacing or 0
    local total_spacing = (#children - 1) * spacing
    local available_height = parent.height - total_spacing
    local child_height = available_height / #children
    
    for i, child in ipairs(children) do
        local y = (i - 1) * (child_height + spacing)
        child:setPosition(child.x, y)
        child:setSize(child.width, child_height)
        parent:addChild(child)
    end
end

return Layout
