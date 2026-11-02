return function(game)
    local state = {
        selected = 1,
        items = {
            { kind = "toggle", key = "settings_music", setting = "music_enabled" },
            { kind = "toggle", key = "settings_sfx", setting = "sfx_enabled" },
            { kind = "cycle", key = "settings_difficulty", setting = "difficulty" },
            { kind = "cycle", key = "settings_video", setting = "video_mode" },
            { kind = "cycle", key = "settings_language", setting = "language" },
            { kind = "cycle", key = "settings_touch_controls", setting = "touch_controls" },
            { kind = "cycle", key = "settings_controls", setting = "control_layout" },
        },
    }

    local function row_y(index)
        return 54 + (index - 1) * 22
    end

    local function value_label(item)
        local value = game.settings.values[item.setting]
        if type(value) == "boolean" then
            return game.localization:get(value and "value_on" or "value_off")
        end
        if item.setting == "difficulty" then
            return game.localization:get(game:get_difficulty_profile(value).label_key)
        end
        return game.localization:get("value_" .. tostring(value))
    end

    local function cycle_language(direction)
        local options = game.dataset and game.dataset.languages or {}
        if #options == 0 then
            return
        end

        local current = game.settings.values.language
        local index = 1
        for i, language in ipairs(options) do
            if language == current then
                index = i
                break
            end
        end

        index = index + (direction or 1)
        if index < 1 then
            index = #options
        elseif index > #options then
            index = 1
        end

        game.settings.values.language = options[index]
        game.settings:save_now()
        game.localization:set_language(game.settings.values.language)
    end

    local function activate(item, direction)
        if item.kind == "toggle" then
            game.settings:toggle(item.setting)
            if item.setting == "music_enabled" then
                game.audio:apply_music_setting()
            end
        elseif item.setting == "language" then
            cycle_language(direction)
        else
            game.settings:cycle(item.setting, direction or 1)
        end
    end

    function state:update()
        local direction = game.input:get_direction_pressed()
        if direction == "up" then
            self.selected = math.max(1, self.selected - 1)
        elseif direction == "down" then
            self.selected = math.min(#self.items, self.selected + 1)
        elseif direction == "left" then
            activate(self.items[self.selected], -1)
        elseif direction == "right" then
            activate(self.items[self.selected], 1)
        end

        if game.input:confirm_pressed() then
            activate(self.items[self.selected], 1)
        end

        if game.input:back_pressed() then
            game.state_machine:change("menu")
        end

        for _, tap in ipairs(game.input:get_taps()) do
            local width = game.renderer.logical_width
            for index, item in ipairs(self.items) do
                local y = row_y(index)
                if tap.x >= 24 and tap.x <= width - 24 and tap.y >= y - 2 and tap.y <= y + 18 then
                    self.selected = index
                    activate(item, 1)
                    return
                end
            end
        end
    end

    function state:draw()
        local width = game.renderer.logical_width
        local height = game.renderer.logical_height
        love.graphics.setColor(0.08, 0.1, 0.15, 1)
        love.graphics.rectangle("fill", 0, 0, width, height)

        love.graphics.setFont(game.assets:get_font("large"))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(game.localization:get("settings_title"), 0, 20, width, "center")

        love.graphics.setFont(game.assets:get_font("medium"))
        for index, item in ipairs(self.items) do
            local y = row_y(index)
            if index == self.selected then
                love.graphics.setColor(0.97, 0.78, 0.28, 0.95)
                love.graphics.rectangle("fill", 24, y - 2, width - 48, 20)
                love.graphics.setColor(0.06, 0.08, 0.12, 1)
            else
                love.graphics.setColor(0.18, 0.22, 0.3, 0.95)
                love.graphics.rectangle("fill", 24, y - 2, width - 48, 20)
                love.graphics.setColor(0.93, 0.96, 1, 1)
            end

            love.graphics.print(game.localization:get(item.key), 36, y + 2)
            love.graphics.setFont(game.assets:get_font("small"))
            love.graphics.printf(value_label(item), width - 160, y + 4, 124, "right")
            love.graphics.setFont(game.assets:get_font("medium"))
        end

        love.graphics.setFont(game.assets:get_font("small"))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(game.localization:get("settings_hint"), 24, height - 16, width - 48, "center")
    end

    return state
end
