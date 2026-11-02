local Typewriter = {}
Typewriter.__index = Typewriter

function Typewriter.new(text, speed)
    return setmetatable({
        text = text or "",
        speed = speed or 40,
        timer = 0,
        visible = 0,
    }, Typewriter)
end

function Typewriter:update(dt)
    if self.visible >= #self.text then
        return
    end

    self.timer = self.timer + dt * self.speed
    local count = math.floor(self.timer)
    if count > self.visible then
        self.visible = math.min(#self.text, count)
    end
end

function Typewriter:get_text()
    return self.text:sub(1, self.visible)
end

function Typewriter:is_done()
    return self.visible >= #self.text
end

function Typewriter:finish()
    self.visible = #self.text
end

return Typewriter
