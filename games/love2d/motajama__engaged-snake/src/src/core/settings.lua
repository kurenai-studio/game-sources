local TableUtil = require("src.util.table")

local Settings = {}
Settings.__index = Settings

local legacy_difficulty_map = {
    hard = "death",
    normal = "normal",
    easy = "easy",
}

Settings.defaults = {
    music_enabled = true,
    sfx_enabled = true,
    difficulty = "normal",
    video_mode = "color",
    language = "en",
    control_layout = "right_handed",
    touch_controls = "auto",
    player_name = "PLY",
}

Settings.options = {
    difficulty = { "baby", "easy", "normal", "death" },
    video_mode = { "color", "mono_crt" },
    language = { "cs", "en" },
    control_layout = { "right_handed", "left_handed", "split" },
    touch_controls = { "auto", "on", "off" },
}

function Settings.new(save)
    return setmetatable({
        save = save,
        values = TableUtil.deep_copy(Settings.defaults),
    }, Settings)
end

function Settings:load()
    local loaded = self.save:load_settings(Settings.defaults)
    if legacy_difficulty_map[loaded.difficulty] then
        loaded.difficulty = legacy_difficulty_map[loaded.difficulty]
    end
    self.values = TableUtil.merge(Settings.defaults, loaded)
end

function Settings:save_now()
    self.save:save_settings(self.values)
end

function Settings:toggle(key)
    self.values[key] = not self.values[key]
    self:save_now()
end

function Settings:cycle(key, direction)
    local options = Settings.options[key]
    local current = self.values[key]
    local index = 1

    for i, value in ipairs(options) do
        if value == current then
            index = i
            break
        end
    end

    index = index + direction
    if index < 1 then
        index = #options
    elseif index > #options then
        index = 1
    end

    self.values[key] = options[index]
    self:save_now()
end

function Settings:get_starting_lives()
    local map = {
        baby = 5,
        easy = 4,
        normal = 3,
        death = 1,
    }
    return map[self.values.difficulty] or 3
end

return Settings
