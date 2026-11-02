local HUDQuotes = {}
HUDQuotes.__index = HUDQuotes

function HUDQuotes.new()
    return setmetatable({
        level = nil,
        timer = 0,
        quote_timer = 0,
        next_quote_delay = 0,
        active_text = nil,
        last_quote_index = nil,
        frame_timer = 0,
        frame = 1,
        frame_count = 1,
        speaking = false,
    }, HUDQuotes)
end

function HUDQuotes:reset(level, localization, frame_count)
    self.level = level or {}
    self.localization = localization
    self.timer = 0
    self.quote_timer = 0
    self.frame_timer = 0
    self.frame = 1
    self.frame_count = math.max(1, frame_count or 1)
    self.speaking = false
    self.active_text = nil
    self.next_quote_delay = love.math.random(8, 12)
end

local function choose_quote(level, localization, last_quote_index)
    local quotes = level and level.hud_quotes or nil
    if not quotes or #quotes == 0 then
        return nil, last_quote_index
    end

    if #quotes == 1 then
        return localization:get(quotes[1]), 1
    end

    local index = love.math.random(1, #quotes)
    if index == last_quote_index then
        index = (index % #quotes) + 1
    end
    return localization:get(quotes[index]), index
end

function HUDQuotes:update(dt)
    self.timer = self.timer + dt

    if self.active_text then
        self.quote_timer = self.quote_timer - dt
        self.speaking = self.quote_timer > 2
        if self.speaking then
            self.frame_timer = self.frame_timer + dt
            if self.frame_timer >= 0.18 then
                self.frame_timer = self.frame_timer - 0.18
                self.frame = self.frame % self.frame_count + 1
            end
        else
            self.frame = 1
        end

        if self.quote_timer <= 0 then
            self.active_text = nil
            self.speaking = false
            self.frame = 1
            self.next_quote_delay = love.math.random(18, 30)
            self.timer = 0
        end
        return
    end

    if self.timer >= self.next_quote_delay then
        local text, quote_index = choose_quote(self.level, self.localization, self.last_quote_index)
        if text then
            self.active_text = text
            self.last_quote_index = quote_index
            self.quote_timer = 4
            self.speaking = true
            self.frame = 1
            self.frame_timer = 0
        else
            self.next_quote_delay = love.math.random(18, 30)
            self.timer = 0
        end
    end
end

function HUDQuotes:get_frame()
    return self.frame
end

function HUDQuotes:get_text()
    return self.active_text
end

function HUDQuotes:is_speaking()
    return self.speaking
end

return HUDQuotes
