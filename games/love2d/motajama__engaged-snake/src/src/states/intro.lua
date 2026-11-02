return function(game)
    local state = {
        timer = 0,
        duration = 3,
    }

    function state:enter()
        self.timer = 0
        self.duration = (game.dataset.intro and game.dataset.intro.duration) or 3
    end

    function state:update(dt)
        self.timer = self.timer + dt
        if self.timer >= self.duration or game.input:any_pressed() then
            game.state_machine:change("menu")
        end
    end

    function state:draw()
        local width = game.renderer.logical_width
        local height = game.renderer.logical_height
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(game.assets:get_image("intro"), 0, 0)

        love.graphics.setColor(1, 0.9, 0.45, 1)
        love.graphics.setFont(game.assets:get_font("title"))
        love.graphics.printf(game.localization:get((game.dataset.intro and game.dataset.intro.title_key) or "intro_title"), 0, 72, width, "center")
        love.graphics.setFont(game.assets:get_font("medium"))
        love.graphics.setColor(0.85, 0.95, 1, 1)
        love.graphics.printf(game.localization:get((game.dataset.intro and game.dataset.intro.body_key) or "intro_body"), 42, 116, width - 84, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(game.localization:get((game.dataset.intro and game.dataset.intro.skip_key) or "intro_skip"), 0, height - 24, width, "center")
    end

    return state
end
