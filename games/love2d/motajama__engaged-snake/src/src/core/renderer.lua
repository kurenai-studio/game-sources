local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(logical_width, logical_height, internal_scale)
    local base_width = logical_width * internal_scale
    local base_height = logical_height * internal_scale
    local canvas = love.graphics.newCanvas(base_width, base_height)
    canvas:setFilter("nearest", "nearest")

    local self = setmetatable({
        logical_width = logical_width,
        logical_height = logical_height,
        internal_scale = internal_scale,
        base_width = base_width,
        base_height = base_height,
        canvas = canvas,
        scale = 1,
        offset_x = 0,
        offset_y = 0,
        screen_width = base_width,
        screen_height = base_height,
    }, Renderer)

    self:sync_dimensions(true)
    return self
end

function Renderer:compute_layout(width, height)
    width = math.max(1, width or self.screen_width or self.base_width)
    height = math.max(1, height or self.screen_height or self.base_height)

    local scale_x = width / self.base_width
    local scale_y = height / self.base_height
    local scale = math.min(scale_x, scale_y)

    if scale <= 0 then
        scale = 1
    end

    return {
        screen_width = width,
        screen_height = height,
        scale = scale,
        offset_x = math.floor((width - self.base_width * scale) * 0.5),
        offset_y = math.floor((height - self.base_height * scale) * 0.5),
    }
end

function Renderer:resize(width, height)
    local layout = self:compute_layout(width, height)
    self.screen_width = layout.screen_width
    self.screen_height = layout.screen_height
    self.scale = layout.scale
    self.offset_x = layout.offset_x
    self.offset_y = layout.offset_y
end

function Renderer:sync_dimensions(force)
    local width, height = love.graphics.getDimensions()
    if force or width ~= self.screen_width or height ~= self.screen_height then
        self:resize(width, height)
        return true
    end
    return false
end

function Renderer:to_virtual(x, y)
    self:sync_dimensions()
    local render_x = (x - self.offset_x) / self.scale
    local render_y = (y - self.offset_y) / self.scale
    return render_x / self.internal_scale, render_y / self.internal_scale
end

function Renderer:toVirtual(x, y)
    return self:to_virtual(x, y)
end

function Renderer:screen_to_game(x, y)
    return self:to_virtual(x, y)
end

function Renderer:to_screen(x, y)
    self:sync_dimensions()
    return
        self.offset_x + x * self.internal_scale * self.scale,
        self.offset_y + y * self.internal_scale * self.scale
end

function Renderer:toScreen(x, y)
    return self:to_screen(x, y)
end

function Renderer:is_inside_virtual(x, y)
    local virtual_x, virtual_y = self:to_virtual(x, y)
    return
        virtual_x >= 0 and virtual_x <= self.logical_width and
        virtual_y >= 0 and virtual_y <= self.logical_height
end

function Renderer:isInsideVirtual(x, y)
    return self:is_inside_virtual(x, y)
end

function Renderer:draw_scene(draw_fn, post_fn)
    self:sync_dimensions()

    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0.04, 0.05, 0.08, 1)
    love.graphics.push()
    love.graphics.scale(self.internal_scale, self.internal_scale)
    draw_fn()
    love.graphics.pop()
    love.graphics.setCanvas()

    love.graphics.clear(0, 0, 0, 1)
    love.graphics.push()
    love.graphics.translate(self.offset_x, self.offset_y)

    if post_fn then
        post_fn(self.canvas)
    else
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.canvas, 0, 0, 0, self.scale, self.scale)
    end

    love.graphics.pop()
end

return Renderer
