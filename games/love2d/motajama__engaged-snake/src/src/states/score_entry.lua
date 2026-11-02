local Levels = require("src.systems.levels")

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function clean_name(value)
    value = trim(value):gsub("[^%w _%-]", "")
    value = value:gsub("%s+", " ")
    if value == "" then
        return "PLY"
    end
    return value:sub(1, 12)
end

return function(game)
    local state = {
        victory = false,
        name = "",
        submitted = false,
        submit_status = nil,
    }

    local function add_char(current, text)
        text = tostring(text or ""):gsub("[^%w _%-]", "")
        if text == "" then
            return current
        end
        return (current .. text):sub(1, 12)
    end

    local function save_rect()
        return { x = 108, y = 174, w = 104, h = 22 }
    end

    function state:enter(params)
        self.victory = params and params.victory == true
        self.name = game.settings.values.player_name or ""
        self.submitted = false
        self.submit_status = nil
        if love.keyboard and love.keyboard.setTextInput then
            love.keyboard.setTextInput(true)
        end
    end

    function state:leave()
        if love.keyboard and love.keyboard.setTextInput then
            love.keyboard.setTextInput(false)
        end
    end

    function state:submit()
        if self.submitted then
            game.state_machine:change("menu")
            return
        end

        local player_name = clean_name(self.name)
        self.name = player_name
        game.settings.values.player_name = player_name
        game.settings:save_now()

        local entry = {
            name = player_name,
            score = game.session.score or 0,
            level_ended = math.max(1, math.min(game.session.level_index or 1, Levels.count(game.dataset))),
            victory = self.victory,
        }

        game.save:add_highscore(game.highscores, entry)
        local online_ok, online_message = game.online_scores:submit(entry)
        if online_ok then
            self.submit_status = "score_submit_online_saved"
        elseif online_message == "pending" then
            self.submit_status = "score_submit_online_pending"
        elseif online_message == "disabled" then
            self.submit_status = "score_submit_local_saved"
        else
            self.submit_status = "score_submit_online_failed"
        end
        self.submitted = true
    end

    function state:update()
        if not self.submitted then
            for _, text in ipairs(game.input:get_text_inputs()) do
                self.name = add_char(self.name, text)
            end

            if game.input:was_pressed("backspace") then
                self.name = self.name:sub(1, math.max(0, #self.name - 1))
            end

            if game.input:confirm_pressed() then
                self:submit()
            end

            for _, tap in ipairs(game.input:get_taps()) do
                local rect = save_rect()
                if tap.x >= rect.x and tap.x <= rect.x + rect.w and tap.y >= rect.y and tap.y <= rect.y + rect.h then
                    self:submit()
                    return
                end
            end
            return
        end

        local online_status = game.online_scores:update()
        if online_status == "saved" then
            self.submit_status = "score_submit_online_saved"
        elseif online_status and online_status ~= "pending" and online_status ~= "disabled" then
            self.submit_status = "score_submit_online_failed"
        end

        if game.input:any_pressed() then
            game.state_machine:change("menu")
        end
    end

    function state:draw()
        local width = game.renderer.logical_width
        local height = game.renderer.logical_height
        local image_name = self.victory and "victory" or "game_over"
        local title_key = self.victory
            and ((game.dataset.victory and game.dataset.victory.title_key) or "victory_title")
            or ((game.dataset.game_over and game.dataset.game_over.title_key) or "game_over_title")
        local body_key = self.victory
            and ((game.dataset.victory and game.dataset.victory.body_key) or "victory_body")
            or "game_over_score_body"

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(game.assets:get_image(image_name), 0, 0)
        love.graphics.setColor(0.03, 0.04, 0.06, 0.68)
        love.graphics.rectangle("fill", 0, 0, width, height)

        love.graphics.setFont(game.assets:get_font("title"))
        love.graphics.setColor(self.victory and 0.97 or 1, self.victory and 0.96 or 0.85, self.victory and 0.7 or 0.85, 1)
        love.graphics.printf(game.localization:get(title_key), 0, 42, width, "center")

        love.graphics.setFont(game.assets:get_font("medium"))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(game.localization:get(body_key, { score = game.session.score or 0 }), 34, 82, width - 68, "center")

        love.graphics.setFont(game.assets:get_font("small"))
        love.graphics.setColor(0.95, 0.95, 0.9, 1)
        love.graphics.printf(game.localization:get("score_entry_name"), 0, 126, width, "center")

        love.graphics.setColor(0.08, 0.1, 0.14, 0.95)
        love.graphics.rectangle("fill", 78, 144, width - 156, 22)
        love.graphics.setColor(0.9, 0.76, 0.3, 1)
        love.graphics.rectangle("line", 78.5, 144.5, width - 157, 21)

        local display_name = self.name
        if not self.submitted and math.floor((love.timer.getTime() or 0) * 2) % 2 == 0 then
            display_name = display_name .. "_"
        end
        love.graphics.setFont(game.assets:get_font("medium"))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(display_name, 82, 148, width - 164, "center")

        love.graphics.setFont(game.assets:get_font("small"))
        if self.submitted then
            love.graphics.setColor(0.72, 0.95, 0.72, 1)
            love.graphics.printf(game.localization:get(self.submit_status or "score_submit_local_saved"), 24, 178, width - 48, "center")
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(game.localization:get("continue_hint"), 24, height - 26, width - 48, "center")
        else
            local rect = save_rect()
            love.graphics.setColor(0.9, 0.76, 0.3, 1)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
            love.graphics.setColor(0.06, 0.08, 0.12, 1)
            love.graphics.printf(game.localization:get("score_entry_save"), rect.x, rect.y + 6, rect.w, "center")
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(game.localization:get("score_entry_hint"), 24, height - 26, width - 48, "center")
        end
    end

    return state
end
