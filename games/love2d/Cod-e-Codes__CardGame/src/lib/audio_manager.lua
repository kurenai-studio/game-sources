--[[
Audio Manager - Sound System

Manages sound effects, music, and spatial audio for the card game.
Handles audio loading, playback, volume control, and memory management.

Key features:
- Background music with seamless looping
- Sound effect pool for performance
- Volume control and muting
- Spatial audio positioning
- Audio compression and streaming

Usage:
  audio:playSound("card_flip", {volume = 0.8, pitch = 1.2})
  audio:playMusic("background_ambient", {loop = true})
--]]

local AudioManager = {}
AudioManager.__index = AudioManager

function AudioManager:new(options)
    options = options or {}
    
    local instance = {
        -- Audio sources storage
        sounds = {},              -- Loaded sound effects
        music_sources = {},       -- Loaded music tracks
        current_music = nil,      -- Currently playing music
        
        -- Volume controls
        master_volume = options.master_volume or 0.7,
        sound_volume = options.sound_volume or 0.8,
        music_volume = options.music_volume or 0.6,
        
        -- Playback settings
        max_simultaneous_sounds = options.max_sounds or 16,
        sound_instances = {},     -- Currently playing sound instances
        
        -- Audio file paths
        sound_path = options.sound_path or "assets/sounds/",
        music_path = options.music_path or "assets/sounds/music/",
        
        -- Audio configuration
        supported_formats = {".ogg", ".wav", ".mp3"},
        enable_3d_audio = options.enable_3d_audio or false,
        listener_x = 0,
        listener_y = 0,
        
        -- Performance settings
        preload_sounds = options.preload_sounds or true,
        stream_music = options.stream_music or true,
        
        -- State
        is_muted = false,
        is_initialized = false
    }
    
    setmetatable(instance, AudioManager)
    instance:initialize()
    
    return instance
end

function AudioManager:initialize()
    if self.is_initialized then return end
    
    -- Set up Love2D audio settings
    love.audio.setVolume(self.master_volume)
    
    -- Preload common sound effects if enabled
    if self.preload_sounds then
        self:preloadCommonSounds()
    end
    
    self.is_initialized = true
    print("Audio Manager initialized")
end

function AudioManager:preloadCommonSounds()
    local common_sounds = {
        "card_flip",
        "card_place", 
        "card_hover",
        "button_click",
        "error_sound",
        "success_sound",
        "shuffle_cards",
        "draw_card"
    }
    
    for _, sound_name in ipairs(common_sounds) do
        self:loadSound(sound_name)
    end
end

function AudioManager:loadSound(sound_name, options)
    if self.sounds[sound_name] then
        return self.sounds[sound_name] -- Already loaded
    end
    
    options = options or {}
    local file_path = nil
    
    -- Try different audio formats
    for _, format in ipairs(self.supported_formats) do
        local test_path = self.sound_path .. sound_name .. format
        if love.filesystem.getInfo(test_path) then
            file_path = test_path
            break
        end
    end
    
    if not file_path then
        print("Warning: Sound file not found: " .. sound_name)
        return nil
    end
    
    local sound_source
    local success, source = pcall(love.audio.newSource, file_path, "static")
    
    if success then
        sound_source = source
        -- Configure source properties
        source:setVolume(options.volume or 1.0)
        source:setLooping(options.loop or false)
        
        self.sounds[sound_name] = {
            source = source,
            volume = options.volume or 1.0,
            instances = {} -- Track playing instances
        }
        
        print("Loaded sound: " .. sound_name)
    else
        print("Error loading sound " .. sound_name .. ": " .. tostring(source))
    end
    
    return sound_source
end

function AudioManager:loadMusic(music_name, options)
    if self.music_sources[music_name] then
        return self.music_sources[music_name] -- Already loaded
    end
    
    options = options or {}
    local file_path = nil
    
    -- Try different audio formats
    for _, format in ipairs(self.supported_formats) do
        local test_path = self.music_path .. music_name .. format
        if love.filesystem.getInfo(test_path) then
            file_path = test_path
            break
        end
    end
    
    if not file_path then
        print("Warning: Music file not found: " .. music_name)
        return nil
    end
    
    local music_source
    local stream_type = self.stream_music and "stream" or "static"
    local success, source = pcall(love.audio.newSource, file_path, stream_type)
    
    if success then
        music_source = source
        source:setVolume(options.volume or self.music_volume)
        source:setLooping(options.loop ~= false) -- Default to looping
        
        self.music_sources[music_name] = source
        print("Loaded music: " .. music_name)
    else
        print("Error loading music " .. music_name .. ": " .. tostring(source))
    end
    
    return music_source
end

function AudioManager:playSound(sound_name, options)
    if self.is_muted then return nil end
    
    options = options or {}
    local sound_data = self.sounds[sound_name]
    
    if not sound_data then
        sound_data = self:loadSound(sound_name, options)
        if not sound_data then return nil end
        sound_data = self.sounds[sound_name]
    end
    
    -- Limit simultaneous sound instances
    if #self.sound_instances >= self.max_simultaneous_sounds then
        -- Remove oldest sound
        local oldest = table.remove(self.sound_instances, 1)
        if oldest and oldest:isPlaying() then
            oldest:stop()
        end
    end
    
    -- Clone the source for concurrent playback
    local instance = sound_data.source:clone()
    
    -- Apply options
    local volume = (options.volume or 1.0) * sound_data.volume * self.sound_volume
    instance:setVolume(volume)
    
    if options.pitch then
        instance:setPitch(options.pitch)
    end
    
    -- 3D positioning
    if self.enable_3d_audio and (options.x or options.y) then
        local x = options.x or 0
        local y = options.y or 0
        local z = options.z or 0
        instance:setPosition(x, y, z)
    end
    
    -- Play sound
    love.audio.play(instance)
    table.insert(self.sound_instances, instance)
    
    return instance
end

function AudioManager:playMusic(music_name, options)
    options = options or {}
    
    -- Stop current music if playing
    if self.current_music then
        self.current_music:stop()
    end
    
    local music_source = self.music_sources[music_name]
    if not music_source then
        music_source = self:loadMusic(music_name, options)
        if not music_source then return nil end
    end
    
    -- Configure music source
    local volume = (options.volume or 1.0) * self.music_volume
    if not self.is_muted then
        music_source:setVolume(volume)
    else
        music_source:setVolume(0)
    end
    
    music_source:setLooping(options.loop ~= false)
    
    -- Fade in effect
    if options.fade_in then
        music_source:setVolume(0)
        love.audio.play(music_source)
        
        -- Simple fade in (should use animation system in production)
        local fade_duration = options.fade_in
        local target_volume = volume
        -- Note: In a real implementation, this would use the animation system
        -- for now, just set volume immediately
        music_source:setVolume(target_volume)
    else
        love.audio.play(music_source)
    end
    
    self.current_music = music_source
    return music_source
end

function AudioManager:stopMusic(options)
    if not self.current_music then return end
    
    options = options or {}
    
    if options.fade_out then
        -- Simple fade out (should use animation system)
        self.current_music:setVolume(0)
        -- In production, animate volume to 0 then stop
    end
    
    self.current_music:stop()
    self.current_music = nil
end

function AudioManager:pauseMusic()
    if self.current_music and self.current_music:isPlaying() then
        self.current_music:pause()
    end
end

function AudioManager:resumeMusic()
    if self.current_music then
        love.audio.play(self.current_music)
    end
end

function AudioManager:setMasterVolume(volume)
    self.master_volume = math.max(0, math.min(1, volume))
    love.audio.setVolume(self.master_volume)
end

function AudioManager:setSoundVolume(volume)
    self.sound_volume = math.max(0, math.min(1, volume))
end

function AudioManager:setMusicVolume(volume)
    self.music_volume = math.max(0, math.min(1, volume))
    if self.current_music then
        self.current_music:setVolume(self.music_volume)
    end
end

function AudioManager:mute()
    self.is_muted = true
    love.audio.setVolume(0)
end

function AudioManager:unmute()
    self.is_muted = false
    love.audio.setVolume(self.master_volume)
end

function AudioManager:toggleMute()
    if self.is_muted then
        self:unmute()
    else
        self:mute()
    end
end

function AudioManager:setListenerPosition(x, y, z)
    if not self.enable_3d_audio then return end
    
    self.listener_x = x or 0
    self.listener_y = y or 0
    z = z or 0
    
    love.audio.setPosition(x, y, z)
end

function AudioManager:stopAllSounds()
    -- Stop all sound instances
    for _, instance in ipairs(self.sound_instances) do
        if instance:isPlaying() then
            instance:stop()
        end
    end
    self.sound_instances = {}
end

function AudioManager:update(dt)
    -- Clean up finished sound instances
    for i = #self.sound_instances, 1, -1 do
        local instance = self.sound_instances[i]
        if not instance:isPlaying() then
            table.remove(self.sound_instances, i)
        end
    end
    
    -- Update any audio-related animations (volume fades, etc.)
    -- This would integrate with the animation system in a full implementation
end

function AudioManager:cleanup()
    self:stopAllSounds()
    self:stopMusic()
    
    -- Release audio sources
    for _, sound_data in pairs(self.sounds) do
        if sound_data.source then
            sound_data.source:release()
        end
    end
    
    for _, music_source in pairs(self.music_sources) do
        music_source:release()
    end
    
    self.sounds = {}
    self.music_sources = {}
    self.sound_instances = {}
    
    print("Audio Manager cleaned up")
end

-- Convenience functions for common card game sounds
function AudioManager:cardFlip(options)
    return self:playSound("card_flip", options)
end

function AudioManager:cardPlace(options)
    return self:playSound("card_place", options)
end

function AudioManager:cardHover(options)
    return self:playSound("card_hover", options)
end

function AudioManager:buttonClick(options)
    return self:playSound("button_click", options)
end

function AudioManager:shuffleCards(options)
    return self:playSound("shuffle_cards", options)
end

function AudioManager:drawCard(options)
    return self:playSound("draw_card", options)
end

function AudioManager:errorSound(options)
    return self:playSound("error_sound", options)
end

function AudioManager:successSound(options)
    return self:playSound("success_sound", options)
end

return AudioManager
