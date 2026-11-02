local Json = require("src.util.json")
local TableUtil = require("src.util.table")

local Save = {}
Save.__index = Save

function Save.new()
    return setmetatable({
        files = {
            settings = "settings.json",
            highscores = "highscores.json",
        },
    }, Save)
end

function Save:read_json(filename, fallback)
    if not love.filesystem.getInfo(filename) then
        return TableUtil.deep_copy(fallback)
    end

    local data = love.filesystem.read(filename)
    if not data or data == "" then
        return TableUtil.deep_copy(fallback)
    end

    local ok, decoded = pcall(Json.decode, data)
    if not ok then
        return TableUtil.deep_copy(fallback)
    end

    return decoded
end

function Save:write_json(filename, value)
    return love.filesystem.write(filename, Json.encode(value))
end

function Save:load_settings(defaults)
    return self:read_json(self.files.settings, defaults)
end

function Save:save_settings(settings)
    return self:write_json(self.files.settings, settings)
end

function Save:load_highscores()
    return self:read_json(self.files.highscores, { entries = {} })
end

function Save:save_highscores(highscores)
    return self:write_json(self.files.highscores, highscores)
end

function Save:add_highscore(highscores, entry)
    highscores.entries = highscores.entries or {}
    highscores.entries[#highscores.entries + 1] = entry
    table.sort(highscores.entries, function(a, b)
        return (a.score or 0) > (b.score or 0)
    end)

    while #highscores.entries > 10 do
        table.remove(highscores.entries)
    end

    self:save_highscores(highscores)
end

return Save
