local character_model = require("character.model")
local music = {}


music.BackgroundMusicManager = {
    death_sound = {
        love.audio.newSource("ASSETS/audio/music/game_over1.mp3", "static"),
        love.audio.newSource("ASSETS/audio/music/game_over2.mp3", "static"),
        love.audio.newSource("ASSETS/audio/music/game_over3.mp3", "static")
    },
    menu_music = {
        love.audio.newSource("ASSETS/audio/music/menu_music.ogg", "stream"),
        love.audio.newSource("ASSETS/audio/music/menu_music2.mp3", "stream")
    },
    game_music = { 
        love.audio.newSource("ASSETS/Audio/music/overworld_track_1.ogg", "stream"),
        love.audio.newSource("ASSETS/Audio/music/overworld_track_2.ogg", "stream")
    }
}

music.BackgroundMusicManager.__index = music.BackgroundMusicManager

function music.BackgroundMusicManager:new()
    new_object = {
        current_music = nil,
        last_state = nil
    }
    setmetatable(new_object, self)
    new_object.__index = music.BackgroundMusicManager
    return new_object
end



function music.BackgroundMusicManager:update(game_state, player_state)
    local next_music
    next_music = nil

    local rich_state = string.format('%s/%s', game_state, player_state)

    -- TODO: death_status not checked, enrich game_status so we see change.
    if rich_state == self.last_state then
        if self.current_music == nil then
            return
        end

        if self.current_music:isPlaying() then
            return
        end
    end
    self.last_state = rich_state

    if self.current_music ~= nil then
        love.audio.stop(self.current_music)
        self.current_music = nil
    end

    if game_state == 'title' then
        local music_choice = math.random( #self.menu_music )
        next_music = self.menu_music[music_choice]
    elseif game_state ~= 'title' then
        if player_state == 'ok' then
            local music_choice = math.random( #self.game_music )
            next_music = self.game_music[music_choice]
        else
            local music_choice = math.random( #self.death_sound )
            next_music = self.death_sound[music_choice]
        end
    end


    if next_music == nil then
        return
    end
    next_music:play()
    next_music:setLooping(true)
    self.current_music = next_music
end

return music