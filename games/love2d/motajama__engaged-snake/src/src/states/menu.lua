return function(game)
    local state = {
        items = {
            { key = "menu_play", target = "difficulty_select" },
            { key = "menu_highscore", target = "highscore" },
            { key = "menu_settings", target = "settings_menu" },
        },
        selected = 1,
        arrow_timer = 0,
    }

    local function item_rect(index)
        local width = game.renderer.logical_width
        local item_width = 148
        return {
            x = math.floor((width - item_width) * 0.5) + 18,
            y = 114 + (index - 1) * 22,
            w = item_width,
            h = 16,
        }
    end

    function state:activate(index)
        local item = self.items[index]
        game.audio:play_sfx(game:get_sfx_id("menu_confirm", "menu_confirm"))
        game.state_machine:change(item.target)
    end

    function state:enter()
        self.arrow_timer = 0
        local menu_music = game:get_music_id("menu")
        if menu_music then
            game.audio:play_music(menu_music)
        end
    end

    local function set_selected(state_ref, index)
        if state_ref.selected ~= index then
            state_ref.selected = index
            game.audio:play_sfx(game:get_sfx_id("menu_move", "menu_move"))
        end
    end

    function state:update(dt)
        self.arrow_timer = self.arrow_timer + dt
        local direction = game.input:get_direction_pressed()
        if direction == "up" then
            local next_index = self.selected - 1
            if next_index < 1 then
                next_index = #self.items
            end
            set_selected(self, next_index)
        elseif direction == "down" then
            local next_index = self.selected + 1
            if next_index > #self.items then
                next_index = 1
            end
            set_selected(self, next_index)
        end

        if game.input:confirm_pressed() then
            self:activate(self.selected)
        end

        for _, tap in ipairs(game.input:get_taps()) do
            for index, _ in ipairs(self.items) do
                local rect = item_rect(index)
                if tap.x >= rect.x and tap.x <= rect.x + rect.w and tap.y >= rect.y and tap.y <= rect.y + rect.h then
                    if self.selected == index then
                        self:activate(index)
                    else
                        set_selected(self, index)
                    end
                    return
                end
            end
        end
    end

    local function draw_pointer(x, y, frame)
        love.graphics.push()
        love.graphics.translate(x, y)
        if frame == 2 then
            love.graphics.scale(-1, 1)
        end
        love.graphics.polygon("fill", 0, 0, 12, 5, 0, 10)
        love.graphics.pop()
    end

    function state:draw()
        local width = game.renderer.logical_width
        local height = game.renderer.logical_height
        local pointer_frame = math.floor(self.arrow_timer * 6) % 2 + 1
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(game.assets:get_image("title"), 0, 0)

        if game.dataset and type(game.dataset.title) == "string" and game.dataset.title ~= "" then
            love.graphics.setFont(game.assets:get_font("title"))
            love.graphics.setColor(0.04, 0.03, 0.02, 0.9)
            love.graphics.printf(game.dataset.title, 1, 31, width, "center")
            love.graphics.setColor(1, 0.9, 0.45, 1)
            love.graphics.printf(game.dataset.title, 0, 30, width, "center")
        end

        if game.dataset and type(game.dataset.subtitle) == "string" and game.dataset.subtitle ~= "" then
            love.graphics.setFont(game.assets:get_font("small"))
            love.graphics.setColor(0.04, 0.03, 0.02, 0.9)
            love.graphics.printf(game.dataset.subtitle, 25, 67, width - 48, "center")
            love.graphics.setColor(0.9, 0.95, 1, 1)
            love.graphics.printf(game.dataset.subtitle, 24, 66, width - 48, "center")
        end

        love.graphics.setFont(game.assets:get_font("medium"))
        for index, item in ipairs(self.items) do
            local rect = item_rect(index)
            local selected = index == self.selected
            if selected then
                love.graphics.setColor(0.05, 0.03, 0.02, 0.85)
                draw_pointer(rect.x - 17, rect.y + 4, pointer_frame)
                love.graphics.setColor(0.98, 0.84, 0.35, 1)
                draw_pointer(rect.x - 18, rect.y + 3, pointer_frame)
            end
            love.graphics.setColor(0.04, 0.03, 0.02, 0.9)
            love.graphics.print(game.localization:get(item.key), rect.x + 1, rect.y + 3)
            love.graphics.setColor(selected and 0.98 or 0.9, selected and 0.9 or 0.9, selected and 0.58 or 0.86, 1)
            love.graphics.print(game.localization:get(item.key), rect.x, rect.y + 2)
        end

        love.graphics.setFont(game.assets:get_font("small"))
        love.graphics.setColor(0.04, 0.03, 0.02, 0.9)
        love.graphics.printf(game.localization:get("menu_hint"), 1, height - 19, width, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(game.localization:get("menu_hint"), 0, height - 20, width, "center")
    end

    return state
end
