local Input = {}
Input.__index = Input

local confirm_keys = {
    ["return"] = true,
    ["space"] = true,
}

local back_keys = {
    escape = true,
}

local direction_keys = {
    up = "up",
    w = "up",
    down = "down",
    s = "down",
    left = "left",
    a = "left",
    right = "right",
    d = "right",
}

function Input.new(renderer)
    return setmetatable({
        renderer = renderer,
        pressed = {},
        released = {},
        tapped_points = {},
        text_inputs = {},
        any_press = false,
        last_direction = nil,
    }, Input)
end

function Input:begin_frame()
    self.pressed = {}
    self.released = {}
    self.tapped_points = {}
    self.text_inputs = {}
    self.any_press = false
    self.last_direction = nil
end

function Input:keypressed(key)
    self.pressed[key] = true
    self.any_press = true
    if direction_keys[key] then
        self.last_direction = direction_keys[key]
    end
end

function Input:keyreleased(key)
    self.released[key] = true
end

function Input:textinput(text)
    self.text_inputs[#self.text_inputs + 1] = text
    self.any_press = true
end

function Input:pointerpressed(x, y)
    if not self.renderer:is_inside_virtual(x, y) then
        return
    end

    local gx, gy = self.renderer:to_virtual(x, y)
    self.tapped_points[#self.tapped_points + 1] = { x = gx, y = gy }
    self.any_press = true
end

function Input:was_pressed(key)
    return self.pressed[key] == true
end

function Input:confirm_pressed()
    for key in pairs(confirm_keys) do
        if self.pressed[key] then
            return true
        end
    end
    return false
end

function Input:back_pressed()
    for key in pairs(back_keys) do
        if self.pressed[key] then
            return true
        end
    end
    return false
end

function Input:get_direction_pressed()
    return self.last_direction
end

function Input:any_pressed()
    return self.any_press
end

function Input:get_taps()
    return self.tapped_points
end

function Input:get_text_inputs()
    return self.text_inputs
end

return Input
