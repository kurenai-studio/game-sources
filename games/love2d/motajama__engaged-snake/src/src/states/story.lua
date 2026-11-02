local Typewriter = require("src.systems.typewriter")
local Levels = require("src.systems.levels")

return function(game)
    local state = {
        typewriter = nil,
        frame_timer = 0,
        frame = 1,
        head_frames = 1,
        level = nil,
    }

    function state:enter()
        self.level = Levels.get_level(game.dataset, game.session.level_index)
        game.audio:play_music(game:get_music_id(self.level.id, self.level.music))
        local text = game.localization:get(self.level.story_key)
        self.typewriter = Typewriter.new(text, 45)
        self.frame_timer = 0
        self.frame = 1
        self.head_frames = math.max(1, game.assets:get_head_frame_count())
    end

    function state:update(dt)
        self.frame_timer = self.frame_timer + dt
        if self.frame_timer >= 0.18 then
            self.frame_timer = self.frame_timer - 0.18
            self.frame = self.frame % self.head_frames + 1
        end

        self.typewriter:update(dt)
        if game.input:any_pressed() then
            if self.typewriter:is_done() then
                game.state_machine:change("play")
            else
                self.typewriter:finish()
            end
        end
    end

    function state:draw()
        local width = game.renderer.logical_width
        local height = game.renderer.logical_height
        local head_w, head_h = game.assets:get_head_dimensions()
        local head_scale = math.min(96 / math.max(1, head_w), 96 / math.max(1, head_h))
        local head_draw_w = head_w * head_scale
        local head_draw_h = head_h * head_scale
        local head_x = 20 + math.floor((100 - head_draw_w) * 0.5)
        local head_y = 24 + math.floor((100 - head_draw_h) * 0.5)
        love.graphics.setColor(0.07, 0.08, 0.12, 1)
        love.graphics.rectangle("fill", 0, 0, width, height)

        love.graphics.setColor(0.15, 0.18, 0.25, 1)
        love.graphics.rectangle("fill", 20, 24, 100, 100)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(game.assets:get_image("head"), game.assets:get_head_quad(self.frame), head_x, head_y, 0, head_scale, head_scale)

        love.graphics.setColor(0.12, 0.14, 0.2, 1)
        love.graphics.rectangle("fill", 136, 24, width - 156, 156)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(game.assets:get_font("medium"))
        love.graphics.printf(game.localization:get(self.level.name_key), 148, 34, width - 180, "left")
        love.graphics.setFont(game.assets:get_font("small"))
        love.graphics.printf(self.typewriter:get_text(), 148, 62, width - 180, "left")

        local footer_key = self.typewriter:is_done() and "story_continue" or "story_skip"
        love.graphics.printf(game.localization:get(footer_key), 0, height - 24, width, "center")
    end

    return state
end
