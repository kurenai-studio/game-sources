local AnimatedCounter = {}
AnimatedCounter.__index = AnimatedCounter

function AnimatedCounter.new(target, rate, formatter)
    return setmetatable({
        target = target or 0,
        value = 0,
        rate = rate or 1,
        formatter = formatter,
        finished = false,
    }, AnimatedCounter)
end

function AnimatedCounter:update(dt)
    if self.finished then
        return false, true
    end

    local previous = self.value
    self.value = math.min(self.target, self.value + self.rate * dt)
    if self.value >= self.target then
        self.value = self.target
        self.finished = true
    end

    return self.value ~= previous, self.finished
end

function AnimatedCounter:get_display_value()
    local value = math.floor(self.value + 0.5)
    if self.formatter then
        return self.formatter(value, self.target)
    end
    return tostring(value)
end

return AnimatedCounter
