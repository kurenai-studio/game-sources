--[[
Card Renderer - Visual Card System

Handles rendering of individual cards with animations, states, and effects.
Supports batch rendering for performance, sprite atlas usage, and smooth
state transitions (idle, hover, selected, dragging).

Key features:
- Efficient batch rendering with automatic texture switching
- State-based animations (hover effects, selection highlights, flipping)
- Sprite atlas support for optimized memory usage
- Customizable card layouts and visual themes
- Glow effects, shadows, and particle systems

Usage:
  renderer:drawCard(card_data, x, y, {state = "hover", scale = 1.2})
  renderer:playFlipAnimation(card, duration, callback)
--]]

local CardRenderer = {}
CardRenderer.__index = CardRenderer

local Animation = require('lib.animation')

-- Card visual states
local CARD_STATES = {
    IDLE = "idle",
    HOVER = "hover", 
    SELECTED = "selected",
    DRAGGING = "dragging",
    DISABLED = "disabled",
    FLIPPING = "flipping"
}

-- Card dimensions (standard playing card ratio ~1.4)
local CARD_WIDTH = 90
local CARD_HEIGHT = 126
local CORNER_RADIUS = 8

function CardRenderer:new(options)
    options = options or {}
    
    local instance = {
        -- Rendering settings
        card_width = options.card_width or CARD_WIDTH,
        card_height = options.card_height or CARD_HEIGHT,
        corner_radius = options.corner_radius or CORNER_RADIUS,
        
        -- Texture atlas
        atlas_image = nil,
        atlas_quads = {},          -- card_id -> love.graphics.newQuad()
        card_back_quad = nil,      -- Default card back texture
        
        -- Batch rendering
        batch_enabled = true,
        current_batch = nil,
        batch_cards = {},          -- Cards queued for batch rendering
        max_batch_size = 1000,
        
        -- Animation system
        animation_manager = Animation.AnimationManager:new(),
        active_animations = {},    -- card_id -> animation_data
        
        -- Visual effects
        glow_shader = nil,
        shadow_enabled = true,
        shadow_offset_x = 2,
        shadow_offset_y = 4,
        shadow_color = {0, 0, 0, 0.3},
        
        -- State colors and effects
        state_colors = {
            [CARD_STATES.IDLE] = {1, 1, 1, 1},
            [CARD_STATES.HOVER] = {1.1, 1.1, 1.1, 1},
            [CARD_STATES.SELECTED] = {1.2, 1.2, 0.8, 1},
            [CARD_STATES.DRAGGING] = {0.9, 0.9, 0.9, 0.8},
            [CARD_STATES.DISABLED] = {0.5, 0.5, 0.5, 0.7}
        },
        
        state_scales = {
            [CARD_STATES.IDLE] = 1.0,
            [CARD_STATES.HOVER] = 1.05,
            [CARD_STATES.SELECTED] = 1.1,
            [CARD_STATES.DRAGGING] = 1.0,
            [CARD_STATES.DISABLED] = 0.95
        },
        
        -- Fonts for card text
        title_font = nil,
        description_font = nil,
        cost_font = nil,
        
        -- Default colors
        background_color = {0.9, 0.9, 0.95, 1},
        border_color = {0.2, 0.2, 0.3, 1},
        text_color = {0.1, 0.1, 0.2, 1}
    }
    
    setmetatable(instance, CardRenderer)
    instance:_initializeRenderer()
    
    return instance
end

function CardRenderer:_initializeRenderer()
    -- Initialize fonts
    self.title_font = love.graphics.newFont(12)
    self.description_font = love.graphics.newFont(9) 
    self.cost_font = love.graphics.newFont(14)
    
    -- Create simple glow shader
    local glow_shader_code = [[
        uniform float glow_strength;
        uniform vec3 glow_color;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(texture, texture_coords);
            if (pixel.a > 0.1) {
                float glow = glow_strength;
                pixel.rgb = mix(pixel.rgb, glow_color, glow);
            }
            return pixel * color;
        }
    ]]
    
    local success, shader = pcall(love.graphics.newShader, glow_shader_code)
    if success then
        self.glow_shader = shader
        self.glow_shader:send("glow_strength", 0.0)
        self.glow_shader:send("glow_color", {1.0, 1.0, 0.8})
    end
end

function CardRenderer:loadAtlas(image_path, atlas_data)
    self.atlas_image = love.graphics.newImage(image_path)
    self.atlas_image:setFilter("nearest", "nearest") -- Pixel-perfect scaling
    
    -- Create quads for each card texture
    for card_id, quad_data in pairs(atlas_data.cards or {}) do
        self.atlas_quads[card_id] = love.graphics.newQuad(
            quad_data.x, quad_data.y, quad_data.w, quad_data.h,
            self.atlas_image:getDimensions()
        )
    end
    
    -- Load card back texture
    if atlas_data.card_back then
        local back = atlas_data.card_back
        self.card_back_quad = love.graphics.newQuad(
            back.x, back.y, back.w, back.h,
            self.atlas_image:getDimensions()
        )
    end
    
    -- Create sprite batch for efficient rendering
    if self.batch_enabled and self.atlas_image then
        self.current_batch = love.graphics.newSpriteBatch(self.atlas_image, self.max_batch_size)
    end
end

function CardRenderer:setBatchMode(enabled)
    self.batch_enabled = enabled
    
    if enabled and self.atlas_image and not self.current_batch then
        self.current_batch = love.graphics.newSpriteBatch(self.atlas_image, self.max_batch_size)
    elseif not enabled then
        self.current_batch = nil
    end
end

function CardRenderer:drawCard(card_data, x, y, options)
    options = options or {}
    
    local state = options.state or CARD_STATES.IDLE
    local scale = options.scale or self.state_scales[state] or 1.0
    local alpha = options.alpha or 1.0
    local rotation = options.rotation or 0
    local flip_progress = options.flip_progress or 0
    
    -- Calculate actual card dimensions
    local card_w = self.card_width * scale
    local card_h = self.card_height * scale
    
    -- Apply flip effect (horizontal scale based on progress)
    local flip_scale_x = scale
    if flip_progress > 0 then
        flip_scale_x = scale * (1.0 - 2 * math.abs(flip_progress - 0.5))
    end
    
    love.graphics.push()
    love.graphics.translate(x + card_w/2, y + card_h/2)
    love.graphics.rotate(rotation)
    love.graphics.scale(flip_scale_x, scale)
    
    -- Draw shadow
    if self.shadow_enabled and state ~= CARD_STATES.DRAGGING then
        love.graphics.setColor(self.shadow_color)
        self:_drawCardShape(-card_w/2 + self.shadow_offset_x, 
                           -card_h/2 + self.shadow_offset_y, 
                           card_w, card_h)
    end
    
    -- Set card color based on state
    local color = self.state_colors[state] or {1, 1, 1, 1}
    love.graphics.setColor(color[1], color[2], color[3], color[4] * alpha)
    
    -- Apply glow effect for selected/hover states
    if self.glow_shader and (state == CARD_STATES.SELECTED or state == CARD_STATES.HOVER) then
        love.graphics.setShader(self.glow_shader)
        local glow_strength = (state == CARD_STATES.SELECTED) and 0.3 or 0.1
        self.glow_shader:send("glow_strength", glow_strength)
    end
    
    -- Draw card content
    if flip_progress < 0.5 then
        -- Front side
        self:_drawCardFront(card_data, -card_w/2, -card_h/2, card_w, card_h)
    else
        -- Back side
        self:_drawCardBack(-card_w/2, -card_h/2, card_w, card_h)
    end
    
    -- Reset shader
    if self.glow_shader then
        love.graphics.setShader()
    end
    
    love.graphics.pop()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function CardRenderer:_drawCardShape(x, y, width, height)
    if self.corner_radius > 0 then
        -- Draw rounded rectangle (simple approximation)
        local r = math.min(self.corner_radius, width/4, height/4)
        
        -- Center rectangle
        love.graphics.rectangle("fill", x + r, y, width - 2*r, height)
        love.graphics.rectangle("fill", x, y + r, width, height - 2*r)
        
        -- Corners
        love.graphics.circle("fill", x + r, y + r, r)
        love.graphics.circle("fill", x + width - r, y + r, r)
        love.graphics.circle("fill", x + r, y + height - r, r)
        love.graphics.circle("fill", x + width - r, y + height - r, r)
    else
        love.graphics.rectangle("fill", x, y, width, height)
    end
end

function CardRenderer:_drawCardFront(card_data, x, y, width, height)
    -- Background
    love.graphics.setColor(self.background_color)
    self:_drawCardShape(x, y, width, height)
    
    -- Border
    love.graphics.setColor(self.border_color)
    love.graphics.setLineWidth(2)
    if self.corner_radius > 0 then
        -- Simplified rounded border
        love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, self.corner_radius)
    else
        love.graphics.rectangle("line", x, y, width, height)
    end
    
    -- Card artwork (from atlas if available)
    if self.atlas_image and self.atlas_quads[card_data.id] then
        love.graphics.setColor(1, 1, 1, 1)
        local artwork_height = height * 0.5
        love.graphics.draw(self.atlas_image, self.atlas_quads[card_data.id],
                          x + width/2, y + artwork_height/2,
                          0, width/self.card_width, artwork_height/self.card_height,
                          width/(2*self.card_width), artwork_height/(2*self.card_height))
    else
        -- Placeholder artwork
        love.graphics.setColor(0.7, 0.7, 0.8, 1)
        love.graphics.rectangle("fill", x + 5, y + 5, width - 10, height * 0.5)
    end
    
    -- Card cost (top-left corner)
    if card_data.cost then
        love.graphics.setFont(self.cost_font)
        love.graphics.setColor(0.9, 0.9, 0.2, 1) -- Gold for mana cost
        love.graphics.circle("fill", x + 15, y + 15, 12)
        love.graphics.setColor(0.1, 0.1, 0.2, 1)
        love.graphics.printf(tostring(card_data.cost), x + 6, y + 8, 18, "center")
    end
    
    -- Card title - simple and clean
    love.graphics.setColor(0.1, 0.1, 0.2, 1) -- Dark text
    love.graphics.setFont(self.title_font)
    local title = card_data.name or "Card"
    love.graphics.printf(title, x + 2, y + height * 0.55, width - 4, "center")
    
    -- Simple stats at bottom - just text, no fancy graphics
    local bottom_text = ""
    
    -- Add attack/health if creature
    if card_data.attack and card_data.health then
        bottom_text = card_data.attack .. "/" .. card_data.health
    elseif card_data.attack then
        bottom_text = "ATK " .. card_data.attack
    elseif card_data.health then
        bottom_text = "HP " .. card_data.health
    end
    
    -- Add ability if exists
    if card_data.abilities and #card_data.abilities > 0 then
        local ability = card_data.abilities[1]
        local ability_text = ""
        
        if ability == "direct_damage" then ability_text = "Deal 3 dmg"
        elseif ability == "heal" then ability_text = "Heal 5"
        elseif ability == "area_damage" then ability_text = "Area dmg"
        elseif ability == "burn" then ability_text = "Burn"
        elseif ability == "regenerate" then ability_text = "Regen"
        elseif ability == "mana_boost" then ability_text = "+1 mana"
        else ability_text = ability
        end
        
        if bottom_text ~= "" then
            bottom_text = bottom_text .. " | " .. ability_text
        else
            bottom_text = ability_text
        end
    end
    
    -- Draw bottom text
    if bottom_text ~= "" then
        love.graphics.setFont(self.description_font)
        love.graphics.setColor(0.2, 0.2, 0.3, 1)
        love.graphics.printf(bottom_text, x + 2, y + height - 25, width - 4, "center")
    end
end

function CardRenderer:_drawCardBack(x, y, width, height)
    -- Background
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    self:_drawCardShape(x, y, width, height)
    
    -- Border
    love.graphics.setColor(0.6, 0.6, 0.8, 1)
    love.graphics.setLineWidth(2)
    if self.corner_radius > 0 then
        love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, self.corner_radius)
    else
        love.graphics.rectangle("line", x, y, width, height)
    end
    
    -- Card back pattern (simple geometric design)
    love.graphics.setColor(0.5, 0.5, 0.7, 1)
    local center_x, center_y = x + width/2, y + height/2
    
    -- Draw decorative pattern
    for i = 1, 3 do
        local radius = (width/4) - (i * 5)
        love.graphics.circle("line", center_x, center_y, radius)
    end
    
    -- Central emblem
    love.graphics.setColor(0.7, 0.7, 0.9, 1)
    love.graphics.circle("fill", center_x, center_y, 8)
end

function CardRenderer:playFlipAnimation(card_data, duration, callback)
    duration = duration or 0.6
    
    local flip_object = {flip_progress = 0}
    local flip_tween = Animation.Tween:new(flip_object, duration, {flip_progress = 1}, 
                                          Animation.Easing.inOutCubic)
    
    -- Store animation data
    self.active_animations[card_data.id] = {
        type = "flip",
        tween = flip_tween,
        target_object = flip_object,
        card_data = card_data
    }
    
    if callback then
        flip_tween.on_complete = function()
            self.active_animations[card_data.id] = nil
            callback()
        end
    else
        flip_tween.on_complete = function()
            self.active_animations[card_data.id] = nil
        end
    end
    
    self.animation_manager:play(flip_tween)
    
    return flip_tween
end

function CardRenderer:playHoverAnimation(card_data, is_hovering)
    -- Cancel existing hover animation for this card
    local existing_anim = self.active_animations[card_data.id .. "_hover"]
    if existing_anim then
        self.animation_manager:stop(existing_anim.tween)
    end
    
    local hover_object = {hover_scale = card_data.hover_scale or 1.0}
    local target_scale = is_hovering and self.state_scales[CARD_STATES.HOVER] or 1.0
    local duration = is_hovering and 0.15 or 0.1
    
    local hover_tween = Animation.Tween:new(hover_object, duration, 
        {hover_scale = target_scale}, Animation.Easing.outCubic)
    
    self.active_animations[card_data.id .. "_hover"] = {
        type = "hover",
        tween = hover_tween,
        target_object = hover_object,
        card_data = card_data
    }
    
    hover_tween.on_complete = function()
        self.active_animations[card_data.id .. "_hover"] = nil
    end
    
    -- Update card's hover scale property
    hover_tween.on_update = function()
        card_data.hover_scale = hover_object.hover_scale
    end
    
    card_data.hover_scale = hover_object.hover_scale
    self.animation_manager:play(hover_tween)
end

function CardRenderer:getCardAnimation(card_data)
    local flip_anim = self.active_animations[card_data.id]
    if flip_anim and flip_anim.type == "flip" then
        return flip_anim.target_object.flip_progress
    end
    return 0
end

function CardRenderer:isCardAnimating(card_data)
    return self.active_animations[card_data.id] ~= nil
end

function CardRenderer:stopAllAnimations()
    for card_id, anim_data in pairs(self.active_animations) do
        self.animation_manager:stop(anim_data.tween)
        self.active_animations[card_id] = nil
    end
end

function CardRenderer:update(dt)
    self.animation_manager:update(dt)
end

function CardRenderer:getCardDimensions()
    return self.card_width, self.card_height
end

function CardRenderer:setCardDimensions(width, height)
    self.card_width = width
    self.card_height = height
end

-- Static helper functions
CardRenderer.STATES = CARD_STATES

function CardRenderer.getDefaultCard()
    return {
        id = "default",
        name = "Sample Card",
        description = "A basic card for testing purposes.",
        cost = 3,
        attack = 2,
        health = 3
    }
end

return CardRenderer
