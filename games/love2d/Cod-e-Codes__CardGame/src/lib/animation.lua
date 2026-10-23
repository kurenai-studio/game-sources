--[[
Animation System - Non-blocking Tween Engine

Provides smooth interpolation between values with easing functions,
animation chaining, parallel execution, and completion callbacks.

Key features:
- Multiple easing functions (cubic, elastic, bounce, etc.)
- Non-blocking execution (doesn't halt game loop)
- Animation sequences and parallel groups
- Property-based tweening of any numeric value
- Automatic cleanup of completed animations

Usage:
  local tween = Tween:new(card, 0.5, {x = 100, y = 200}, Easing.outCubic)
  AnimationManager:play(tween, function() print("Animation complete!") end)
--]]

local Animation = {}

-- Easing functions for smooth animation curves
local Easing = {}

-- Linear easing (no acceleration)
function Easing.linear(t)
    return t
end

-- Cubic easing functions
function Easing.inCubic(t)
    return t * t * t
end

function Easing.outCubic(t)
    local t1 = t - 1
    return t1 * t1 * t1 + 1
end

function Easing.inOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local t1 = 2 * t - 2
        return 1 + t1 * t1 * t1 / 2
    end
end

-- Elastic easing for bouncy effects
function Easing.outElastic(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 then return 0 end
    if t == 1 then return 1 end
        return (2 ^ (-10 * t)) * math.sin((t * 10 - 0.75) * c4) + 1
end

function Easing.inElastic(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return -(2 ^ (10 * t - 10)) * math.sin((t * 10 - 10.75) * c4)
end

-- Bounce easing for impact effects
function Easing.outBounce(t)
    local n1 = 7.5625
    local d1 = 2.75
    
    if t < 1 / d1 then
        return n1 * t * t
    elseif t < 2 / d1 then
        t = t - 1.5 / d1
        return n1 * t * t + 0.75
    elseif t < 2.5 / d1 then
        t = t - 2.25 / d1
        return n1 * t * t + 0.9375
    else
        t = t - 2.625 / d1
        return n1 * t * t + 0.984375
    end
end

function Easing.inBounce(t)
    return 1 - Easing.outBounce(1 - t)
end

-- Back easing (overshoot effect)
function Easing.outBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
end

function Easing.inBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return c3 * t * t * t - c1 * t * t
end

Animation.Easing = Easing

-- Tween class for individual property animations
local Tween = {}
Tween.__index = Tween

function Tween:new(target, duration, properties, easing_func, delay)
    local instance = {
        target = target,                    -- Object to animate
        duration = duration or 1.0,         -- Animation duration in seconds
        properties = properties or {},      -- Properties to animate {x = 100, y = 200}
        easing_func = easing_func or Easing.linear,
        delay = delay or 0,                -- Delay before starting animation
        
        -- Internal state
        elapsed_time = 0,
        delay_elapsed = 0,
        is_complete = false,
        is_playing = false,
        start_values = {},                 -- Starting property values
        
        -- Chaining
        next_tween = nil,                  -- Next tween in sequence
        parallel_tweens = {},              -- Tweens to run simultaneously
        
        -- Callbacks
        on_start = nil,
        on_update = nil,
        on_complete = nil
    }
    
    setmetatable(instance, Tween)
    return instance
end

function Tween:start()
    if self.is_playing then return end
    
    self.is_playing = true
    self.elapsed_time = 0
    self.delay_elapsed = 0
    self.is_complete = false
    
    -- Store starting values for interpolation
    self.start_values = {}
    for property, target_value in pairs(self.properties) do
        if type(self.target[property]) == "number" then
            self.start_values[property] = self.target[property]
        else
            print("Warning: Cannot animate non-numeric property '" .. property .. "'")
        end
    end
    
    -- Start parallel tweens
    for _, parallel_tween in ipairs(self.parallel_tweens) do
        parallel_tween:start()
    end
    
    if self.on_start then
        self.on_start(self)
    end
end

function Tween:update(dt)
    if not self.is_playing or self.is_complete then return end
    
    -- Handle delay
    if self.delay > 0 and self.delay_elapsed < self.delay then
        self.delay_elapsed = self.delay_elapsed + dt
        return
    end
    
    self.elapsed_time = self.elapsed_time + dt
    local progress = math.min(self.elapsed_time / self.duration, 1.0)
    local eased_progress = self.easing_func(progress)
    
    -- Update animated properties
    for property, target_value in pairs(self.properties) do
        if self.start_values[property] then
            local start_value = self.start_values[property]
            local current_value = start_value + (target_value - start_value) * eased_progress
            self.target[property] = current_value
        end
    end
    
    -- Update parallel tweens
    for i = #self.parallel_tweens, 1, -1 do
        local parallel_tween = self.parallel_tweens[i]
        parallel_tween:update(dt)
        if parallel_tween.is_complete then
            table.remove(self.parallel_tweens, i)
        end
    end
    
    if self.on_update then
        self.on_update(self, progress)
    end
    
    -- Check for completion
    if progress >= 1.0 then
        self:complete()
    end
end

function Tween:complete()
    if self.is_complete then return end
    
    self.is_complete = true
    self.is_playing = false
    
    -- Ensure final values are set exactly
    for property, target_value in pairs(self.properties) do
        if self.start_values[property] then
            self.target[property] = target_value
        end
    end
    
    if self.on_complete then
        self.on_complete(self)
    end
    
    -- Start next tween in sequence
    if self.next_tween then
        self.next_tween:start()
    end
end

function Tween:stop()
    self.is_playing = false
    self.is_complete = true
    
    -- Stop parallel tweens
    for _, parallel_tween in ipairs(self.parallel_tweens) do
        parallel_tween:stop()
    end
end

function Tween:chain(next_tween)
    self.next_tween = next_tween
    return next_tween -- Allow method chaining
end

function Tween:parallel(other_tween)
    table.insert(self.parallel_tweens, other_tween)
    return self
end

function Tween:setCallbacks(on_start, on_update, on_complete)
    self.on_start = on_start
    self.on_update = on_update
    self.on_complete = on_complete
    return self
end

Animation.Tween = Tween

-- Animation Manager for handling multiple animations
local AnimationManager = {}
AnimationManager.__index = AnimationManager

function AnimationManager:new()
    local instance = {
        active_tweens = {},        -- Currently running animations
        completed_tweens = {},     -- Completed animations to be cleaned up
        paused = false,
        time_scale = 1.0          -- Global time scaling for slow-motion effects
    }
    
    setmetatable(instance, AnimationManager)
    return instance
end

function AnimationManager:play(tween, completion_callback)
    if completion_callback then
        -- Wrap existing callback or set new one
        local original_callback = tween.on_complete
        tween.on_complete = function(t)
            if original_callback then original_callback(t) end
            completion_callback(t)
        end
    end
    
    table.insert(self.active_tweens, tween)
    tween:start()
    
    return tween
end

function AnimationManager:stop(tween)
    tween:stop()
    
    -- Remove from active list
    for i, active_tween in ipairs(self.active_tweens) do
        if active_tween == tween then
            table.remove(self.active_tweens, i)
            break
        end
    end
end

function AnimationManager:stopAll()
    for _, tween in ipairs(self.active_tweens) do
        tween:stop()
    end
    self.active_tweens = {}
end

function AnimationManager:pause()
    self.paused = true
end

function AnimationManager:resume()
    self.paused = false
end

function AnimationManager:setTimeScale(scale)
    self.time_scale = math.max(0, scale)
end

function AnimationManager:update(dt)
    if self.paused then return end
    
    local scaled_dt = dt * self.time_scale
    
    -- Update all active tweens
    for i = #self.active_tweens, 1, -1 do
        local tween = self.active_tweens[i]
        tween:update(scaled_dt)
        
        -- Remove completed tweens
        if tween.is_complete then
            table.remove(self.active_tweens, i)
        end
    end
end

function AnimationManager:getActiveCount()
    return #self.active_tweens
end

function AnimationManager:isAnimating(target)
    for _, tween in ipairs(self.active_tweens) do
        if tween.target == target then
            return true
        end
    end
    return false
end

Animation.AnimationManager = AnimationManager

-- Utility functions for common animation patterns
function Animation.fadeIn(target, duration, callback)
    target.alpha = 0
    local tween = Tween:new(target, duration or 0.3, {alpha = 1}, Easing.outCubic)
    if callback then tween.on_complete = callback end
    return tween
end

function Animation.fadeOut(target, duration, callback)
    local tween = Tween:new(target, duration or 0.3, {alpha = 0}, Easing.inCubic)
    if callback then tween.on_complete = callback end
    return tween
end

function Animation.slideIn(target, from_x, to_x, duration, callback)
    target.x = from_x
    local tween = Tween:new(target, duration or 0.4, {x = to_x}, Easing.outBack)
    if callback then tween.on_complete = callback end
    return tween
end

function Animation.bounce(target, scale_amount, duration, callback)
    local original_scale = target.scale or 1
    local scale_up = Tween:new(target, (duration or 0.3) / 2, 
        {scale = original_scale + scale_amount}, Easing.outCubic)
    local scale_down = Tween:new(target, (duration or 0.3) / 2, 
        {scale = original_scale}, Easing.inCubic)
    
    scale_up:chain(scale_down)
    if callback then scale_down.on_complete = callback end
    
    return scale_up
end

function Animation.shake(target, intensity, duration, callback)
    local original_x, original_y = target.x, target.y
    local shake_count = math.floor((duration or 0.5) * 20) -- 20 shakes per second
    local shake_duration = duration / shake_count
    
    local first_tween = nil
    local current_tween = nil
    
    for i = 1, shake_count do
        local offset_x = (math.random() - 0.5) * 2 * intensity
        local offset_y = (math.random() - 0.5) * 2 * intensity
        
        local tween = Tween:new(target, shake_duration, 
            {x = original_x + offset_x, y = original_y + offset_y}, Easing.linear)
        
        if not first_tween then
            first_tween = tween
            current_tween = tween
        else
            if current_tween and current_tween.chain then
                current_tween:chain(tween)
            end
            current_tween = tween
        end
    end
    
    -- Return to original position
    local final_tween = Tween:new(target, shake_duration, 
        {x = original_x, y = original_y}, Easing.outCubic)
    current_tween:chain(final_tween)
    
    if callback then final_tween.on_complete = callback end
    
    return first_tween
end

return Animation
