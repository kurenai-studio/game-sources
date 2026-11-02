return function(game)
    local max_entries = 10
    local row_spacing = 11
    local columns = {
        rank = { x = 30, w = 24 },
        player = { x = 58, w = 96 },
        score = { x = 158, w = 58 },
        level = { x = 226, w = 38 },
        win = { x = 276, w = 30 },
    }

    local state = {
        entries = {},
        source = "local",
        message_key = nil,
    }
    local credit = "design&concept->motajama coding->Codex @ GPL3 2026"

    local function top_entries(entries)
        local sorted = {}
        for index, entry in ipairs(entries) do
            sorted[index] = {
                entry = entry,
                source_index = index,
            }
        end
        table.sort(sorted, function(a, b)
            local a_score = a.entry.score or 0
            local b_score = b.entry.score or 0
            if a_score == b_score then
                return a.source_index < b.source_index
            end
            return a_score > b_score
        end)

        local top = {}
        for index = 1, math.min(#sorted, max_entries) do
            top[index] = sorted[index].entry
        end
        return top
    end

    local function load_scores(state_ref)
        local ok, scores = game.online_scores:fetch_scores(max_entries)
        if ok then
            state_ref.entries = top_entries(scores)
            state_ref.source = "online"
            state_ref.message_key = nil
            return
        end

        state_ref.entries = top_entries(game.highscores.entries or {})
        state_ref.source = "local"
        state_ref.message_key = "highscore_local_fallback"
    end

    function state:enter()
        load_scores(self)
    end

    function state:update()
        if game.input:confirm_pressed() or game.input:back_pressed() or game.input:any_pressed() then
            game.state_machine:change("menu")
        end
    end

    function state:draw()
        local width = game.renderer.logical_width
        local height = game.renderer.logical_height
        local header_y = self.message_key and 70 or 50
        love.graphics.setColor(0.08, 0.08, 0.12, 1)
        love.graphics.rectangle("fill", 0, 0, width, height)

        love.graphics.setFont(game.assets:get_font("large"))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(game.localization:get("highscore_title"), 0, 18, width, "center")

        if self.message_key then
            love.graphics.setFont(game.assets:get_font("small"))
            love.graphics.setColor(0.95, 0.78, 0.36, 1)
            love.graphics.printf(game.localization:get(self.message_key), 28, 42, width - 56, "center")
        end

        love.graphics.setFont(game.assets:get_font("small"))
        love.graphics.setColor(1, 1, 1, 1)
        if #self.entries == 0 then
            local empty_key = self.source == "online" and "highscore_online_empty" or "highscore_empty"
            love.graphics.printf(game.localization:get(empty_key), 0, 116, width, "center")
        else
            love.graphics.setColor(0.66, 0.75, 0.84, 1)
            love.graphics.printf("#", columns.rank.x, header_y, columns.rank.w, "right")
            love.graphics.printf(game.localization:get("highscore_player_header"), columns.player.x, header_y, columns.player.w, "left")
            love.graphics.printf(game.localization:get("highscore_score_header"), columns.score.x, header_y, columns.score.w, "right")
            love.graphics.printf(game.localization:get("highscore_level_header"), columns.level.x, header_y, columns.level.w, "right")
            love.graphics.printf(game.localization:get("highscore_win_header"), columns.win.x, header_y, columns.win.w, "center")

            for index, entry in ipairs(self.entries) do
                local y = header_y + 8 + index * row_spacing
                local marker = entry.victory and "*" or " "
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(string.format("%02d", index), columns.rank.x, y, columns.rank.w, "right")
                love.graphics.printf(tostring(entry.name or "PLY"):sub(1, 12), columns.player.x, y, columns.player.w, "left")
                love.graphics.printf(string.format("%05d", entry.score or 0), columns.score.x, y, columns.score.w, "right")
                love.graphics.printf(tostring(entry.level_ended or "-"), columns.level.x, y, columns.level.w, "right")
                love.graphics.printf(marker, columns.win.x, y, columns.win.w, "center")
            end
        end

        love.graphics.setFont(game.assets:get_font("small"))
        love.graphics.printf(game.localization:get("back_hint"), 0, height - 24, width, "center")
        love.graphics.setColor(0.48, 0.56, 0.64, 1)
        love.graphics.printf(credit, width - 286, height - 11, 280, "right")
    end

    return state
end
