--[[
Input Manager - Unified Input Handling System

Handles mouse, keyboard, and touch input with gesture recognition,
action binding, and drag-and-drop operations. Provides consistent
interface across different input methods.

Key features:
- Action-based input binding (map multiple keys to single action)
- Mouse and touch gesture recognition (drag, pinch, long-press)
- Drag-and-drop system with constraints
- Input state caching for smooth gameplay
- Cross-platform touch/mouse compatibility

Usage:
  input:bindAction("play_card", {"space", "return"}, function() playCard() end)
  input:startDrag(card_object, {snap_targets = drop_zones})
--]]

local InputManager = {}
InputManager.__index = InputManager

-- Input event types
local INPUT_EVENTS = {
    ACTION_PRESSED = "action_pressed",
    ACTION_RELEASED = "action_released", 
    MOUSE_PRESSED = "mouse_pressed",
    MOUSE_RELEASED = "mouse_released",
    MOUSE_MOVED = "mouse_moved",
    DRAG_START = "drag_start",
    DRAG_UPDATE = "drag_update",
    DRAG_END = "drag_end",
    GESTURE_START = "gesture_start",
    GESTURE_UPDATE = "gesture_update",
    GESTURE_END = "gesture_end"
}

function InputManager:new()
    local instance = {
        -- Action bindings
        actions = {},              -- action_name -> {keys = {}, callback = function}
        
        -- Input state
        keys_down = {},           -- key -> true/false
        mouse_down = {},          -- button -> true/false
        mouse_x = 0,              -- Current mouse position
        mouse_y = 0,
        prev_mouse_x = 0,         -- Previous mouse position 
        prev_mouse_y = 0,
        
        -- Touch state
        touches = {},             -- touch_id -> {x, y, start_time, prev_x, prev_y}
        touch_enabled = love.touch.getTouches ~= nil,
        
        -- Drag and drop
        drag_object = nil,        -- Currently dragged object
        drag_start_x = 0,         -- Drag start position
        drag_start_y = 0,
        drag_offset_x = 0,        -- Offset from object center
        drag_offset_y = 0,
        drag_constraints = {},    -- Drag constraints and snap targets
        is_dragging = false,
        
        -- Gesture recognition
        gestures = {},            -- Active gestures
        gesture_threshold = 10,   -- Minimum movement for gesture start
        long_press_time = 0.5,    -- Long press duration
        double_tap_time = 0.3,    -- Double tap window
        last_tap_time = 0,
        last_tap_x = 0,
        last_tap_y = 0,
        
        -- Event system
        event_listeners = {},     -- event_type -> {callback, ...}
        
        -- Configuration
        mouse_sensitivity = 1.0,
        dead_zone = 0.1          -- For analog inputs
    }
    
    setmetatable(instance, InputManager)
    
    -- Initialize default bindings
    instance:_setupDefaultBindings()
    
    return instance
end

function InputManager:_setupDefaultBindings()
    -- Common game actions with default key bindings
    self:bindAction("confirm", {"space", "return"}, nil)
    self:bindAction("cancel", {"escape", "backspace"}, nil)
    self:bindAction("pause", {"p"}, nil)
end

function InputManager:bindAction(action_name, keys, callback)
    if type(keys) == "string" then
        keys = {keys}
    end
    
    self.actions[action_name] = {
        keys = keys,
        callback = callback,
        is_pressed = false,
        was_pressed = false -- For edge detection
    }
end

function InputManager:unbindAction(action_name)
    self.actions[action_name] = nil
end

function InputManager:isActionPressed(action_name)
    local action = self.actions[action_name]
    if not action then return false end
    
    for _, key in ipairs(action.keys) do
        if self.keys_down[key] then
            return true
        end
    end
    return false
end

function InputManager:isActionJustPressed(action_name)
    local action = self.actions[action_name]
    if not action then return false end
    
    return action.is_pressed and not action.was_pressed
end

function InputManager:isActionJustReleased(action_name)
    local action = self.actions[action_name]
    if not action then return false end
    
    return not action.is_pressed and action.was_pressed
end

function InputManager:addEventListener(event_type, callback)
    if not self.event_listeners[event_type] then
        self.event_listeners[event_type] = {}
    end
    table.insert(self.event_listeners[event_type], callback)
end

function InputManager:removeEventListener(event_type, callback)
    local listeners = self.event_listeners[event_type]
    if not listeners then return end
    
    for i, listener in ipairs(listeners) do
        if listener == callback then
            table.remove(listeners, i)
            break
        end
    end
end

function InputManager:_fireEvent(event_type, event_data)
    local listeners = self.event_listeners[event_type]
    if not listeners then return end
    
    for _, callback in ipairs(listeners) do
        callback(event_data)
    end
end

function InputManager:getMousePos()
    return self.mouse_x, self.mouse_y
end

function InputManager:getMouseDelta()
    return self.mouse_x - self.prev_mouse_x, self.mouse_y - self.prev_mouse_y
end

function InputManager:isMouseDown(button)
    button = button or 1
    return self.mouse_down[button] or false
end

function InputManager:startDrag(object, constraints)
    if self.is_dragging then return false end
    
    self.drag_object = object
    self.drag_start_x = self.mouse_x
    self.drag_start_y = self.mouse_y
    self.is_dragging = true
    self.drag_constraints = constraints or {}
    
    -- Calculate offset from object center
    if object.x and object.y then
        self.drag_offset_x = object.x - self.mouse_x
        self.drag_offset_y = object.y - self.mouse_y
    else
        self.drag_offset_x = 0
        self.drag_offset_y = 0
    end
    
    self:_fireEvent(INPUT_EVENTS.DRAG_START, {
        object = object,
        start_x = self.drag_start_x,
        start_y = self.drag_start_y
    })
    
    return true
end

function InputManager:updateDrag()
    if not self.is_dragging or not self.drag_object then return end
    
    local new_x = self.mouse_x + self.drag_offset_x
    local new_y = self.mouse_y + self.drag_offset_y
    
    -- Apply constraints
    if self.drag_constraints.bounds then
        local bounds = self.drag_constraints.bounds
        new_x = math.max(bounds.x, math.min(new_x, bounds.x + bounds.width))
        new_y = math.max(bounds.y, math.min(new_y, bounds.y + bounds.height))
    end
    
    -- Don't automatically update object position - let the scene handle it
    -- This prevents conflicts with manual position updates in drag handlers
    -- if self.drag_object.x and self.drag_object.y then
    --     self.drag_object.x = new_x
    --     self.drag_object.y = new_y
    -- end
    
    -- Check for snap targets
    local snap_target = nil
    if self.drag_constraints.snap_targets then
        for _, target in ipairs(self.drag_constraints.snap_targets) do
            if self:_isInSnapRange(new_x, new_y, target) then
                snap_target = target
                break
            end
        end
    end
    
    self:_fireEvent(INPUT_EVENTS.DRAG_UPDATE, {
        object = self.drag_object,
        x = new_x,
        y = new_y,
        snap_target = snap_target
    })
end

function InputManager:endDrag()
    if not self.is_dragging then return end
    
    local final_x = self.mouse_x + self.drag_offset_x
    local final_y = self.mouse_y + self.drag_offset_y
    
    -- Check for drop targets
    local drop_target = nil
    if self.drag_constraints.snap_targets then
        for _, target in ipairs(self.drag_constraints.snap_targets) do
            if self:_isInSnapRange(final_x, final_y, target) then
                drop_target = target
                
                -- Snap to target position
                if target.snap_x and target.snap_y then
                    if self.drag_object.x and self.drag_object.y then
                        self.drag_object.x = target.snap_x
                        self.drag_object.y = target.snap_y
                    end
                end
                break
            end
        end
    end
    
    self:_fireEvent(INPUT_EVENTS.DRAG_END, {
        object = self.drag_object,
        x = final_x,
        y = final_y,
        drop_target = drop_target,
        was_dropped = drop_target ~= nil
    })
    
    -- Reset drag state
    self.drag_object = nil
    self.is_dragging = false
    self.drag_constraints = {}
end

function InputManager:_isInSnapRange(x, y, snap_target)
    if not snap_target.x or not snap_target.y then return false end
    
    local range = snap_target.range or 50
    local dx = x - snap_target.x
    local dy = y - snap_target.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    return distance <= range
end

function InputManager:_detectGestures()
    local touch_count = 0
    for _ in pairs(self.touches) do touch_count = touch_count + 1 end
    
    if touch_count == 0 then
        -- End any active gestures
        for gesture_id, gesture in pairs(self.gestures) do
            self:_fireEvent(INPUT_EVENTS.GESTURE_END, gesture)
            self.gestures[gesture_id] = nil
        end
        return
    end
    
    -- Single finger gestures
    if touch_count == 1 then
        local touch_id, touch = next(self.touches)
        local current_time = love.timer.getTime()
        
        -- Long press detection
        if touch and current_time - touch.start_time > self.long_press_time and not self.gestures.long_press then
            self.gestures.long_press = {
                type = "long_press",
                x = touch.x,
                y = touch.y,
                duration = current_time - touch.start_time
            }
            self:_fireEvent(INPUT_EVENTS.GESTURE_START, self.gestures.long_press)
        end
        
        -- Drag gesture
        if not touch then return end
        local dx = touch.x - touch.start_x
        local dy = touch.y - touch.start_y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > self.gesture_threshold and not self.gestures.drag then
            self.gestures.drag = {
                type = "drag",
                start_x = touch.start_x,
                start_y = touch.start_y,
                x = touch.x,
                y = touch.y,
                delta_x = dx,
                delta_y = dy,
                distance = distance
            }
            self:_fireEvent(INPUT_EVENTS.GESTURE_START, self.gestures.drag)
        elseif self.gestures.drag and touch then
            self.gestures.drag.x = touch.x
            self.gestures.drag.y = touch.y
            self.gestures.drag.delta_x = dx
            self.gestures.drag.delta_y = dy
            self.gestures.drag.distance = distance
            self:_fireEvent(INPUT_EVENTS.GESTURE_UPDATE, self.gestures.drag)
        end
    end
    
    -- Two finger gestures (pinch)
    if touch_count == 2 then
        local touches = {}
        for _, touch in pairs(self.touches) do
            table.insert(touches, touch)
        end
        
        local dx = touches[1].x - touches[2].x
        local dy = touches[1].y - touches[2].y
        local current_distance = math.sqrt(dx * dx + dy * dy)
        
        if not self.gestures.pinch then
            -- Start pinch gesture
            self.gestures.pinch = {
                type = "pinch",
                start_distance = current_distance,
                current_distance = current_distance,
                center_x = (touches[1].x + touches[2].x) / 2,
                center_y = (touches[1].y + touches[2].y) / 2,
                scale = 1.0
            }
            self:_fireEvent(INPUT_EVENTS.GESTURE_START, self.gestures.pinch)
        else
            -- Update pinch gesture
            self.gestures.pinch.current_distance = current_distance
            self.gestures.pinch.scale = current_distance / self.gestures.pinch.start_distance
            self.gestures.pinch.center_x = (touches[1].x + touches[2].x) / 2
            self.gestures.pinch.center_y = (touches[1].y + touches[2].y) / 2
            self:_fireEvent(INPUT_EVENTS.GESTURE_UPDATE, self.gestures.pinch)
        end
    end
end

function InputManager:update(dt)
    -- Store previous mouse position
    self.prev_mouse_x = self.mouse_x
    self.prev_mouse_y = self.mouse_y
    self.mouse_x = love.mouse.getX() / (Game and Game.scale or 1)
    self.mouse_y = love.mouse.getY() / (Game and Game.scale or 1)
    
    -- Update action states for edge detection
    for action_name, action in pairs(self.actions) do
        action.was_pressed = action.is_pressed
        action.is_pressed = self:isActionPressed(action_name)
        
        -- Fire action events
        if action.is_pressed and not action.was_pressed then
            if action.callback then
                action.callback()
            end
            self:_fireEvent(INPUT_EVENTS.ACTION_PRESSED, {action = action_name})
        elseif not action.is_pressed and action.was_pressed then
            self:_fireEvent(INPUT_EVENTS.ACTION_RELEASED, {action = action_name})
        end
    end
    
    -- Update drag operation
    if self.is_dragging then
        self:updateDrag()
    end
    
    -- Update touch positions and detect gestures
    if self.touch_enabled then
        local active_touches = love.touch.getTouches()
        
        -- Remove ended touches
        for touch_id in pairs(self.touches) do
            local found = false
            for _, active_id in ipairs(active_touches) do
                if active_id == touch_id then
                    found = true
                    break
                end
            end
            if not found then
                self.touches[touch_id] = nil
            end
        end
        
        -- Update active touches
        for _, touch_id in ipairs(active_touches) do
            local x, y = love.touch.getPosition(touch_id)
            x = x / (Game and Game.scale or 1)
            y = y / (Game and Game.scale or 1)
            
            if self.touches[touch_id] then
                self.touches[touch_id].prev_x = self.touches[touch_id].x
                self.touches[touch_id].prev_y = self.touches[touch_id].y
                self.touches[touch_id].x = x
                self.touches[touch_id].y = y
            end
        end
        
        self:_detectGestures()
    end
end

-- Love2D callback handlers
function InputManager:mousepressed(x, y, button, istouch)
    if istouch then return end -- Handle touch separately
    
    self.mouse_down[button] = true
    
    self:_fireEvent(INPUT_EVENTS.MOUSE_PRESSED, {
        x = x, y = y, button = button, istouch = istouch
    })
end

function InputManager:mousereleased(x, y, button, istouch)
    if istouch then return end
    
    self.mouse_down[button] = false
    
    -- End drag if releasing primary button
    if button == 1 and self.is_dragging then
        self:endDrag()
    end
    
    self:_fireEvent(INPUT_EVENTS.MOUSE_RELEASED, {
        x = x, y = y, button = button, istouch = istouch
    })
end

function InputManager:mousemoved(x, y, dx, dy, istouch)
    if istouch then return end
    
    self.mouse_x = x
    self.mouse_y = y
    
    self:_fireEvent(INPUT_EVENTS.MOUSE_MOVED, {
        x = x, y = y, dx = dx, dy = dy, istouch = istouch
    })
end

function InputManager:keypressed(key, scancode, isrepeat)
    if isrepeat then return end -- Ignore key repeats
    
    self.keys_down[key] = true
    
    -- Check for double-tap equivalent on spacebar/enter
    local current_time = love.timer.getTime()
    if (key == "space" or key == "return") and 
       (current_time - self.last_tap_time) < self.double_tap_time then
        self:_fireEvent("double_tap", {key = key, time = current_time})
    end
    self.last_tap_time = current_time
end

function InputManager:keyreleased(key, scancode)
    self.keys_down[key] = false
end

-- Touch event handlers (if supported)
function InputManager:touchpressed(id, x, y, dx, dy, pressure)
    if not self.touch_enabled then return end
    
    x = x / (Game and Game.scale or 1)
    y = y / (Game and Game.scale or 1)
    
    self.touches[id] = {
        x = x, y = y,
        start_x = x, start_y = y,
        prev_x = x, prev_y = y,
        start_time = love.timer.getTime(),
        pressure = pressure or 1.0
    }
    
    -- Treat touch like mouse press for compatibility
    self:mousepressed(x, y, 1, true)
end

function InputManager:touchreleased(id, x, y, dx, dy, pressure)
    if not self.touch_enabled then return end
    
    x = x / (Game and Game.scale or 1)
    y = y / (Game and Game.scale or 1)
    
    if self.touches[id] then
        self.touches[id] = nil
    end
    
    -- Treat touch like mouse release for compatibility
    self:mousereleased(x, y, 1, true)
end

function InputManager:touchmoved(id, x, y, dx, dy, pressure)
    if not self.touch_enabled then return end
    
    x = x / (Game and Game.scale or 1)
    y = y / (Game and Game.scale or 1)
    
    if self.touches[id] then
        self.touches[id].prev_x = self.touches[id].x
        self.touches[id].prev_y = self.touches[id].y
        self.touches[id].x = x
        self.touches[id].y = y
        self.touches[id].pressure = pressure or 1.0
    end
    
    -- Treat touch like mouse move for compatibility
    self:mousemoved(x, y, dx, dy, true)
end

return InputManager
