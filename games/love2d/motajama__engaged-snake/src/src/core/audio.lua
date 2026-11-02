local Audio = {}
Audio.__index = Audio

local function build_tone(frequency, duration, volume, waveform)
    local sample_rate = 22050
    local samples = math.max(1, math.floor(sample_rate * duration))
    local sound_data = love.sound.newSoundData(samples, sample_rate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sample_rate
        local sample
        if waveform == "square" then
            sample = math.sin(2 * math.pi * frequency * t) >= 0 and 1 or -1
        else
            sample = math.sin(2 * math.pi * frequency * t)
        end
        local envelope = 1 - (i / samples)
        sound_data:setSample(i, sample * volume * envelope)
    end

    local source = love.audio.newSource(sound_data, "static")
    source:setVolume(0.35)
    return source
end

function Audio.new(settings)
    return setmetatable({
        settings = settings,
        music_tracks = {},
        current_music = nil,
        current_music_id = nil,
        generated_sfx = {
            pickup_good = build_tone(880, 0.08, 0.5, "square"),
            pickup_bad = build_tone(220, 0.12, 0.6, "square"),
            stats_tick = build_tone(680, 0.035, 0.45, "square"),
            stats_done = build_tone(1040, 0.10, 0.45, "sine"),
            menu_move = build_tone(500, 0.05, 0.35, "square"),
            menu_confirm = build_tone(760, 0.08, 0.4, "square"),
        },
    }, Audio)
end

function Audio:load(dataset)
    self.music_tracks = {}
    local music = dataset and dataset.music or {}
    local extensions = { "ogg", "mp3", "wav", "flac" }

    for _, track_id in pairs(music) do
        if type(track_id) == "string" and not self.music_tracks[track_id] then
            for _, extension in ipairs(extensions) do
                local path = "datasets/base/music/" .. track_id .. "." .. extension
                if love.filesystem.getInfo(path) then
                    local ok, source = pcall(love.audio.newSource, path, "stream")
                    if ok and source then
                        source:setLooping(true)
                        source:setVolume(0.45)
                        self.music_tracks[track_id] = source
                    end
                    break
                end
            end
        end
    end

    for _, level in ipairs(dataset and dataset.levels or {}) do
        local track_id = level.music
        if type(track_id) == "string" and not self.music_tracks[track_id] then
            for _, extension in ipairs(extensions) do
                local path = "datasets/base/music/" .. track_id .. "." .. extension
                if love.filesystem.getInfo(path) then
                    local ok, source = pcall(love.audio.newSource, path, "stream")
                    if ok and source then
                        source:setLooping(true)
                        source:setVolume(0.45)
                        self.music_tracks[track_id] = source
                    end
                    break
                end
            end
        end
    end
end

function Audio:play_music(track_id)
    if not self.settings.values.music_enabled then
        self:stop_music(true)
        self.current_music_id = track_id
        return
    end

    local source = self.music_tracks[track_id]
    if not source then
        return false
    end

    if self.current_music_id == track_id and self.current_music and self.current_music:isPlaying() then
        return true
    end

    self:stop_music(true)
    self.current_music_id = track_id

    pcall(source.seek, source, 0)
    pcall(source.play, source)
    self.current_music = source
    return true
end

function Audio:stop_music(keep_track_id)
    if self.current_music then
        self.current_music:stop()
    end
    self.current_music = nil
    if not keep_track_id then
        self.current_music_id = nil
    end
end

function Audio:apply_music_setting()
    if not self.settings.values.music_enabled then
        self:stop_music(true)
    elseif self.current_music_id then
        local track_id = self.current_music_id
        self.current_music_id = nil
        self:play_music(track_id)
    end
end

function Audio:play_sfx(_sfx_id)
    if not self.settings.values.sfx_enabled then
        return
    end

    local source = self.generated_sfx[_sfx_id]
    if source then
        local clone = source:clone()
        clone:play()
    end
end

return Audio
